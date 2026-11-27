from contextlib import asynccontextmanager
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers.speech import router as speech_router
from app.services.asr_service import get_asr_service
from app.services.phoneme_service import get_phoneme_dictionary

logger = logging.getLogger(__name__)

API_DESCRIPTION = """
Microservice AI phân tích và chấm điểm phát âm tiếng Anh theo âm vị chuẩn quốc tế (**StudyMate AI**).

### Quy trình xử lý (Pipeline)
1. **Giải mã âm thanh In-Memory (`PyAV`):** Hỗ trợ WAV, MP3, M4A, OGG, FLAC và chuẩn hóa về 16 kHz mono PCM.
2. **Nhận dạng giọng nói (`Faster-Whisper`):** Chuyển giọng nói người dùng thành văn bản tiếng Anh offline trên CPU (`base.en` int8).
3. **Từ điển âm vị (`NLTK CMUDict` + `g2p-en`):** Sinh chuỗi âm vị chuẩn Arpabet/IPA cho câu mẫu và giọng nói người dùng.
4. **Phoneme Alignment & Levenshtein Distance:**
   - Căn chỉnh cấp từ bằng **Needleman-Wunsch** theo độ tương đồng âm vị (xử lý tốt trường hợp đọc thiếu hoặc dư từ).
   - Tính khoảng cách chỉnh sửa **Levenshtein** trên chuỗi âm vị Arpabet chuẩn hóa, tự động chọn biến thể phát âm gần nhất trong CMUDict.
5. **Chấm điểm 0–100% & Phân loại:**
   - `correct`: `score >= 80`
   - `warning`: `50 <= score < 80`
   - `error`: `score < 50` (hoặc từ bị bỏ sót)
"""

OPENAPI_TAGS = [
    {
        "name": "Speech Pronunciation Evaluation",
        "description": "Các endpoint phân tích âm vị và chấm điểm phát âm tiếng Anh.",
    },
    {
        "name": "System",
        "description": "Kiểm tra tình trạng hoạt động và tài nguyên AI của microservice.",
    },
]


@asynccontextmanager
async def lifespan(_app: FastAPI):
    settings = get_settings()
    dictionary = get_phoneme_dictionary()
    logger.info("Loaded CMUDict with %d entries.", dictionary.entry_count)
    if settings.whisper_preload:
        get_asr_service().load_model()
    yield


def create_app() -> FastAPI:
    settings = get_settings()

    application = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description=API_DESCRIPTION,
        openapi_tags=OPENAPI_TAGS,
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
        lifespan=lifespan,
    )

    application.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    application.include_router(speech_router)
    return application


app = create_app()
