from pydantic import BaseModel, Field, field_validator
import re

_EMAIL_RE = re.compile(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")


class RegisterRequest(BaseModel):
    """User registration payload."""

    full_name: str = Field(..., min_length=2, max_length=100, examples=["Nguyễn Văn Thịnh"])
    email: str = Field(..., examples=["thinh@studymate.ai"])
    password: str = Field(..., min_length=6, max_length=128, examples=["Secret123"])

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        cleaned = v.strip().lower()
        if not _EMAIL_RE.match(cleaned):
            raise ValueError("Email không đúng định dạng.")
        return cleaned

    @field_validator("full_name")
    @classmethod
    def validate_full_name(cls, v: str) -> str:
        cleaned = v.strip()
        if len(cleaned) < 2:
            raise ValueError("Họ và tên phải có ít nhất 2 ký tự.")
        return cleaned


class LoginRequest(BaseModel):
    """User login payload."""

    email: str = Field(..., examples=["thinh@studymate.ai"])
    password: str = Field(..., min_length=1, max_length=128, examples=["Secret123"])

    @field_validator("email")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.strip().lower()


class UserPublic(BaseModel):
    """Public user representation returned in auth responses."""

    id: str = Field(..., examples=["usr_a1b2c3d4e5f6"])
    full_name: str = Field(..., examples=["Nguyễn Văn Thịnh"])
    email: str = Field(..., examples=["thinh@studymate.ai"])
    created_at: str = Field(..., examples=["2026-11-28T07:00:00+00:00"])


class TokenResponse(BaseModel):
    """JWT Bearer token response."""

    access_token: str = Field(..., description="JWT Bearer access token.")
    token_type: str = Field(default="bearer", examples=["bearer"])
    expires_in: int = Field(..., description="Token expiration in seconds.", examples=[86400])
    user: UserPublic
