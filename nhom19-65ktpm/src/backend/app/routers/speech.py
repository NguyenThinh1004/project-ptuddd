from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from fastapi.concurrency import run_in_threadpool

from app.config import Settings, get_settings
from app.schemas.speech import (
    HealthResponse,
    LegacyWordResult,
    LegacyWordStatus,
    SpeechAssessResponse,
    SpeechEvaluateResponse,
)
from app.services.alignment_service import evaluate_pronunciation
from app.services.asr_service import WhisperASRService, get_asr_service
from app.services.audio_service import AudioDecodingError, decode_audio_to_16k_mono
from app.services.phoneme_service import PhonemeDictionary, get_phoneme_dictionary, tokenize_words

router = APIRouter(tags=["Speech Pronunciation Evaluation"])


def _to_legacy_status(status_value: str) -> LegacyWordStatus:
    if status_value == "correct":
        return "correct"
    if status_value == "warning":
        return "close"
    return "wrong"


async def _run_evaluation(
    audio_upload: UploadFile | None,
    file_alias: UploadFile | None,
    target_text: str | None,
    text_alias: str | None,
    settings: Settings,
    dictionary: PhonemeDictionary,
    asr_service: WhisperASRService,
) -> SpeechEvaluateResponse:
    upload = audio_upload or file_alias
    reference_text = (target_text if target_text is not None else text_alias) or ""
    reference_text = reference_text.strip()

    if not reference_text or not tokenize_words(reference_text):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Văn bản câu mẫu (target_text) không được để trống và phải chứa ít nhất một từ hợp lệ.",
        )

    if upload is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Thiếu tệp âm thanh (field 'audio' hoặc 'file').",
        )

    audio_bytes = await upload.read()
    if len(audio_bytes) > settings.max_audio_bytes:
        raise HTTPException(
            status_code=status.HTTP_413_CONTENT_TOO_LARGE,
            detail=f"Kích thước tệp vượt quá giới hạn {settings.max_audio_size_mb} MB.",
        )

    try:
        audio_pcm = await run_in_threadpool(decode_audio_to_16k_mono, audio_bytes, upload.filename)
    except AudioDecodingError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc

    transcript = await run_in_threadpool(asr_service.transcribe, audio_pcm)
    return evaluate_pronunciation(
        target_text=reference_text,
        transcript=transcript,
        dictionary=dictionary,
    )


@router.get(
    "/health",
    response_model=HealthResponse,
    tags=["System"],
    summary="Kiểm tra trạng thái microservice",
    description="Trả về trạng thái sẵn sàng của NLTK CMUDict và cấu hình Whisper ASR.",
)
async def health_check(
    settings: Annotated[Settings, Depends(get_settings)],
    dictionary: Annotated[PhonemeDictionary, Depends(get_phoneme_dictionary)],
    asr_service: Annotated[WhisperASRService, Depends(get_asr_service)],
) -> HealthResponse:
    return HealthResponse(
        status="ok",
        cmudict_loaded=dictionary.entry_count > 0,
        cmudict_entries=dictionary.entry_count,
        whisper_model=settings.whisper_model,
        whisper_loaded=asr_service.is_loaded,
    )


@router.post(
    "/api/speech/evaluate",
    response_model=SpeechEvaluateResponse,
    summary="Chấm điểm phát âm âm vị (NLTK CMUDict/IPA)",
    description=(
        "Nhận tệp âm thanh (WAV, MP3, M4A, OGG, FLAC) và câu mẫu tiếng Anh, "
        "chuyển giọng nói thành văn bản qua Faster-Whisper, sinh chuỗi âm vị chuẩn từ NLTK CMUDict/IPA "
        "(kèm fallback G2P cho từ ngoài từ điển), đối chiếu từng từ bằng Needleman-Wunsch và "
        "Levenshtein Distance trên âm vị Arpabet chuẩn hóa, sau đó trả về điểm tổng 0–100 và "
        "phân tích chi tiết từng từ (`correct` | `warning` | `error`)."
    ),
    responses={
        200: {"description": "Đánh giá phát âm thành công."},
        400: {"description": "Tệp âm thanh lỗi, quá ngắn hoặc định dạng không hỗ trợ."},
        413: {"description": "Dung lượng tệp âm thanh vượt giới hạn cho phép."},
        422: {"description": "Thiếu tệp âm thanh hoặc `target_text` không hợp lệ."},
    },
)
async def evaluate_speech(
    audio: Annotated[
        UploadFile | None,
        File(description="Tệp âm thanh giọng nói người dùng (khuyên dùng WAV hoặc MP3; hỗ trợ thêm M4A, OGG, FLAC)."),
    ] = None,
    target_text: Annotated[
        str | None,
        Form(description="Câu mẫu tiếng Anh chuẩn để chấm điểm phát âm.", examples=["Practice makes perfect every single day."]),
    ] = None,
    file: Annotated[
        UploadFile | None,
        File(description="Alias tùy chọn cho field `audio`."),
    ] = None,
    text: Annotated[
        str | None,
        Form(description="Alias tùy chọn cho field `target_text`."),
    ] = None,
    settings: Settings = Depends(get_settings),
    dictionary: PhonemeDictionary = Depends(get_phoneme_dictionary),
    asr_service: WhisperASRService = Depends(get_asr_service),
) -> SpeechEvaluateResponse:
    return await _run_evaluation(
        audio_upload=audio,
        file_alias=file,
        target_text=target_text,
        text_alias=text,
        settings=settings,
        dictionary=dictionary,
        asr_service=asr_service,
    )


@router.post(
    "/api/speech/assess",
    response_model=SpeechAssessResponse,
    summary="Alias tương thích Mobile Client cũ (/api/speech/assess)",
    description=(
        "Endpoint tương thích ngược với Flutter `AiAudioService`, dùng chung pipeline "
        "chấm điểm của `/api/speech/evaluate` nhưng map trạng thái từ sang `correct | close | wrong`."
    ),
)
async def assess_speech_legacy(
    audio: Annotated[
        UploadFile | None,
        File(description="Tệp âm thanh giọng nói người dùng (WAV/MP3/M4A)."),
    ] = None,
    target_text: Annotated[
        str | None,
        Form(description="Câu mẫu tiếng Anh chuẩn."),
    ] = None,
    file: Annotated[
        UploadFile | None,
        File(description="Alias tùy chọn cho field `audio`."),
    ] = None,
    text: Annotated[
        str | None,
        Form(description="Alias tùy chọn cho field `target_text`."),
    ] = None,
    settings: Settings = Depends(get_settings),
    dictionary: PhonemeDictionary = Depends(get_phoneme_dictionary),
    asr_service: WhisperASRService = Depends(get_asr_service),
) -> SpeechAssessResponse:
    evaluated = await _run_evaluation(
        audio_upload=audio,
        file_alias=file,
        target_text=target_text,
        text_alias=text,
        settings=settings,
        dictionary=dictionary,
        asr_service=asr_service,
    )
    return SpeechAssessResponse(
        score=evaluated.overall_score,
        overall_score=evaluated.overall_score,
        transcript=evaluated.transcript,
        words=[
            LegacyWordResult(
                word=w.word,
                ipa=w.ipa,
                status=_to_legacy_status(w.status),
                score=w.score,
                expected_phonemes=w.expected_phonemes,
                user_phonemes=w.user_phonemes,
            )
            for w in evaluated.words
        ],
    )
