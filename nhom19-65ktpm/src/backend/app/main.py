from contextlib import asynccontextmanager
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers.ai import router as ai_router
from app.routers.auth import router as auth_router
from app.routers.speech import router as speech_router
from app.services.asr_service import get_asr_service
from app.services.auth_service import get_auth_service
from app.services.phoneme_service import get_phoneme_dictionary

logger = logging.getLogger(__name__)

API_DESCRIPTION = """
Microservice AI của hệ thống **StudyMate AI**, gồm 3 phân hệ:

### 1. Xác thực bảo mật JWT (`/api/auth/*`)
- Đăng ký (`/api/auth/register`), đăng nhập (`/api/auth/login` hoặc `/api/auth/token`), lấy hồ sơ (`/api/auth/me`).
- Cấp phát & xác thực token **JWT HS256 Bearer** bảo vệ các API AI sinh tri thức.

### 2. AI Tóm tắt bài học & Sinh Flashcards / Quiz (`/api/ai/generate-flashcards`)
- Nhận văn bản trực tiếp hoặc tải lên tài liệu `.txt`, `.md`, `.pdf`, `.docx`.
- Sử dụng **Google Gemini API (`google-genai`)** với Strict JSON Schema + **Fallback Parser đa tầng** (gỡ markdown fence, sửa JSON lỗi/cắt cụt, chuẩn hóa item lẻ, trích xuất văn bản thô).
- Sinh bản tóm tắt bài học, các ý trọng tâm, thẻ Flashcard 2 mặt và câu hỏi Quiz 4 phương án A/B/C/D kèm giải thích.

### 3. Chấm điểm phát âm âm vị (`/api/speech/evaluate`)
- Giải mã WAV/MP3/M4A in-memory (`PyAV`), nhận dạng giọng nói offline (`Faster-Whisper`).
- Đối chiếu âm vị **NLTK CMUDict / IPA** bằng Needleman-Wunsch + Levenshtein Distance, chấm điểm 0–100%.
"""

OPENAPI_TAGS = [
    {
        "name": "Authentication (JWT)",
        "description": "Đăng ký, đăng nhập và cấp phát Bearer JWT Token.",
    },
    {
        "name": "AI Study Assistant (Gemini LLM)",
        "description": "Tóm tắt bài học và sinh Flashcards / Quiz tự động (yêu cầu JWT).",
    },
    {
        "name": "Speech Pronunciation Evaluation",
        "description": "Phân tích âm vị và chấm điểm phát âm tiếng Anh.",
    },
    {
        "name": "System",
        "description": "Kiểm tra tình trạng hoạt động và tài nguyên AI của microservice.",
    },
]


@asynccontextmanager
async def lifespan(_app: FastAPI):
    settings = get_settings()
    get_auth_service()
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

    application.include_router(auth_router)
    application.include_router(ai_router)
    application.include_router(speech_router)
    return application


app = create_app()
