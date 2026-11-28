from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from fastapi.concurrency import run_in_threadpool

from app.config import Settings, get_settings
from app.routers.auth import get_current_user
from app.schemas.ai import (
    GenerateStudyKitResponse,
    LegacyFlashcardsRequest,
    LegacyFlashcardsResponse,
    TargetLanguage,
)
from app.schemas.auth import UserPublic
from app.services.document_service import DocumentExtractionError, extract_text_from_document
from app.services.llm_service import (
    GeminiStudyService,
    LLMGenerationError,
    LLMNotConfiguredError,
    get_llm_service,
)

router = APIRouter(prefix="/api/ai", tags=["AI Study Assistant (Gemini LLM)"])


def _run_llm_generation(
    llm_service: GeminiStudyService,
    lesson_text: str,
    num_flashcards: int,
    num_quiz: int,
    language: TargetLanguage,
) -> GenerateStudyKitResponse:
    return llm_service.generate_study_kit(
        lesson_text=lesson_text,
        num_flashcards=num_flashcards,
        num_quiz=num_quiz,
        language=language,
    )


@router.post(
    "/generate-flashcards",
    response_model=GenerateStudyKitResponse,
    summary="Tóm tắt bài học và sinh Flashcards + Quiz tự động bằng Gemini LLM (JWT)",
    description=(
        "Yêu cầu Bearer JWT Token (`Authorization: Bearer <token>`). "
        "Nhận vào văn bản bài học (`text`) và/hoặc tệp tài liệu (`file`: `.txt`, `.md`, `.pdf`, `.docx`), "
        "trích xuất các ý chính bằng Google Gemini API theo Strict JSON Schema (kèm cơ chế fallback parsing "
        "khi phản hồi lệch chuẩn) để tạo bản tóm tắt, bộ thẻ Flashcards 2 mặt và câu hỏi trắc nghiệm Quiz 4 lựa chọn."
    ),
    responses={
        200: {"description": "Sinh tóm tắt, Flashcards và Quiz thành công."},
        400: {"description": "Tệp tài liệu lỗi hoặc định dạng không được hỗ trợ."},
        401: {"description": "Thiếu hoặc sai JWT Bearer Token."},
        413: {"description": "Dung lượng tệp tài liệu vượt quá giới hạn."},
        422: {"description": "Thiếu cả `text` lẫn `file`, hoặc nội dung quá ngắn (<20 ký tự)."},
        502: {"description": "Lỗi từ Gemini API hoặc không thể phục hồi JSON hợp lệ."},
        503: {"description": "Chưa cấu hình GEMINI_API_KEY."},
    },
)
async def generate_flashcards_and_quiz(
    _current_user: Annotated[UserPublic, Depends(get_current_user)],
    settings: Annotated[Settings, Depends(get_settings)],
    llm_service: Annotated[GeminiStudyService, Depends(get_llm_service)],
    text: Annotated[
        str | None,
        Form(description="Nội dung văn bản bài học cần tóm tắt và tạo câu hỏi."),
    ] = None,
    file: Annotated[
        UploadFile | None,
        File(description="Tệp tài liệu bài học tùy chọn (.txt, .md, .pdf, .docx)."),
    ] = None,
    num_flashcards: Annotated[
        int,
        Form(ge=1, le=20, description="Số lượng thẻ Flashcard tối đa cần sinh (1-20)."),
    ] = 6,
    num_quiz: Annotated[
        int,
        Form(ge=1, le=15, description="Số lượng câu hỏi Quiz trắc nghiệm tối đa (1-15)."),
    ] = 4,
    language: Annotated[
        TargetLanguage,
        Form(description="Ngôn ngữ đầu ra: `auto` (theo tài liệu), `vi`, hoặc `en`."),
    ] = "auto",
) -> GenerateStudyKitResponse:
    parts: list[str] = []
    if text and text.strip():
        parts.append(text.strip())

    if file is not None:
        file_bytes = await file.read()
        if len(file_bytes) > settings.max_document_bytes:
            raise HTTPException(
                status_code=status.HTTP_413_CONTENT_TOO_LARGE,
                detail=f"Kích thước tài liệu vượt quá giới hạn {settings.max_document_size_mb} MB.",
            )
        try:
            extracted = await run_in_threadpool(
                extract_text_from_document,
                file_bytes,
                file.filename,
                settings.max_source_chars,
            )
        except DocumentExtractionError as exc:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
        parts.append(extracted)

    combined_text = "\n\n".join(parts).strip()
    if len(combined_text) > settings.max_source_chars:
        combined_text = combined_text[: settings.max_source_chars].rstrip()

    if len(combined_text) < 20:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Vui lòng cung cấp văn bản bài học (`text`) hoặc tệp tài liệu (`file`) có ít nhất 20 ký tự.",
        )

    try:
        return await run_in_threadpool(
            _run_llm_generation,
            llm_service,
            combined_text,
            num_flashcards,
            num_quiz,
            language,
        )
    except LLMNotConfiguredError as exc:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)) from exc
    except LLMGenerationError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc)) from exc


@router.post(
    "/flashcards",
    response_model=LegacyFlashcardsResponse,
    summary="Alias tương thích Mobile Client (/api/ai/flashcards, JWT)",
    description=(
        "Nhận JSON `{\"text\": \"...\"}` cho `AiAudioService` trên Flutter (yêu cầu Bearer JWT), "
        "trả về `cards` kèm `summary`, `key_points`, `flashcards` và `quiz`."
    ),
)
async def generate_flashcards_legacy(
    payload: LegacyFlashcardsRequest,
    _current_user: Annotated[UserPublic, Depends(get_current_user)],
    settings: Annotated[Settings, Depends(get_settings)],
    llm_service: Annotated[GeminiStudyService, Depends(get_llm_service)],
) -> LegacyFlashcardsResponse:
    cleaned = payload.text.strip()[: settings.max_source_chars]
    try:
        result = await run_in_threadpool(
            _run_llm_generation,
            llm_service,
            cleaned,
            payload.num_flashcards,
            payload.num_quiz,
            payload.language,
        )
    except LLMNotConfiguredError as exc:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)) from exc
    except LLMGenerationError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc)) from exc

    return LegacyFlashcardsResponse(
        cards=result.flashcards,
        summary=result.summary,
        key_points=result.key_points,
        flashcards=result.flashcards,
        quiz=result.quiz,
        used_fallback_parser=result.used_fallback_parser,
        model=result.model,
    )
