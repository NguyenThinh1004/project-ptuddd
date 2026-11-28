from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application configuration loaded from environment variables or .env file."""

    app_name: str = "StudyMate AI - Backend API"
    app_version: str = "1.1.0"
    host: str = "0.0.0.0"
    port: int = 8000

    # Speech ASR
    whisper_model: str = "base.en"
    whisper_device: str = "cpu"
    whisper_compute_type: str = "int8"
    whisper_preload: bool = False

    # Google Gemini LLM
    gemini_api_key: str = ""
    gemini_model: str = "gemini-2.5-flash"
    llm_local_fallback: bool = False

    # JWT Auth & SQLite user store
    jwt_secret_key: str = "studymate-dev-secret-change-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 1440
    auth_db_path: str = "data/auth.db"

    # Validation limits
    max_audio_size_mb: int = 20
    max_document_size_mb: int = 10
    max_source_chars: int = 40000
    cors_origins: str = "*"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def cors_origin_list(self) -> list[str]:
        if self.cors_origins.strip() == "*":
            return ["*"]
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]

    @property
    def max_audio_bytes(self) -> int:
        return self.max_audio_size_mb * 1024 * 1024

    @property
    def max_document_bytes(self) -> int:
        return self.max_document_size_mb * 1024 * 1024


@lru_cache
def get_settings() -> Settings:
    return Settings()
