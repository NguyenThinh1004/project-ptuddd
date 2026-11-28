from datetime import datetime, timedelta, timezone
from functools import lru_cache
import hashlib
import hmac
from pathlib import Path
import secrets
import sqlite3
import uuid

import jwt

from app.config import get_settings
from app.schemas.auth import TokenResponse, UserPublic


class AuthError(Exception):
    """Base authentication exception."""


class EmailAlreadyExistsError(AuthError):
    """Raised when registering an email that already exists."""


class InvalidCredentialsError(AuthError):
    """Raised when login credentials or JWT token are invalid."""


def _hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 200_000)
    return f"pbkdf2_sha256${salt.hex()}${digest.hex()}"


def _verify_password(password: str, stored_hash: str) -> bool:
    try:
        scheme, salt_hex, digest_hex = stored_hash.split("$", 2)
    except ValueError:
        return False
    if scheme != "pbkdf2_sha256":
        return False
    salt = bytes.fromhex(salt_hex)
    expected = bytes.fromhex(digest_hex)
    actual = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 200_000)
    return hmac.compare_digest(actual, expected)


class AuthService:
    """SQLite-backed user management and HS256 JWT authentication service."""

    def __init__(
        self,
        db_path: str,
        secret_key: str,
        algorithm: str = "HS256",
        expire_minutes: int = 1440,
    ) -> None:
        self.db_path = db_path
        self.secret_key = secret_key
        self.algorithm = algorithm
        self.expire_minutes = expire_minutes
        self._init_db()

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path, timeout=10)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self) -> None:
        if self.db_path != ":memory:":
            Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
        with self._connect() as conn:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS users (
                    id TEXT PRIMARY KEY,
                    full_name TEXT NOT NULL,
                    email TEXT UNIQUE NOT NULL,
                    password_hash TEXT NOT NULL,
                    created_at TEXT NOT NULL
                )
                """
            )
            conn.commit()

    def register_user(self, full_name: str, email: str, password: str) -> UserPublic:
        normalized_email = email.strip().lower()
        user_id = f"usr_{uuid.uuid4().hex[:12]}"
        created_at = datetime.now(timezone.utc).isoformat()
        password_hash = _hash_password(password)

        try:
            with self._connect() as conn:
                conn.execute(
                    """
                    INSERT INTO users (id, full_name, email, password_hash, created_at)
                    VALUES (?, ?, ?, ?, ?)
                    """,
                    (user_id, full_name.strip(), normalized_email, password_hash, created_at),
                )
                conn.commit()
        except sqlite3.IntegrityError as exc:
            raise EmailAlreadyExistsError("Email đã được đăng ký.") from exc

        return UserPublic(
            id=user_id,
            full_name=full_name.strip(),
            email=normalized_email,
            created_at=created_at,
        )

    def authenticate_user(self, email: str, password: str) -> UserPublic:
        normalized_email = email.strip().lower()
        with self._connect() as conn:
            row = conn.execute(
                "SELECT id, full_name, email, password_hash, created_at FROM users WHERE email = ?",
                (normalized_email,),
            ).fetchone()

        if row is None or not _verify_password(password, row["password_hash"]):
            raise InvalidCredentialsError("Email hoặc mật khẩu không chính xác.")

        return UserPublic(
            id=row["id"],
            full_name=row["full_name"],
            email=row["email"],
            created_at=row["created_at"],
        )

    def get_user_by_id(self, user_id: str) -> UserPublic | None:
        with self._connect() as conn:
            row = conn.execute(
                "SELECT id, full_name, email, created_at FROM users WHERE id = ?",
                (user_id,),
            ).fetchone()
        if row is None:
            return None
        return UserPublic(
            id=row["id"],
            full_name=row["full_name"],
            email=row["email"],
            created_at=row["created_at"],
        )

    def issue_token(self, user: UserPublic) -> TokenResponse:
        now = datetime.now(timezone.utc)
        expires_delta = timedelta(minutes=self.expire_minutes)
        payload = {
            "sub": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "iat": int(now.timestamp()),
            "exp": int((now + expires_delta).timestamp()),
        }
        token = jwt.encode(payload, self.secret_key, algorithm=self.algorithm)
        return TokenResponse(
            access_token=token,
            token_type="bearer",
            expires_in=int(expires_delta.total_seconds()),
            user=user,
        )

    def verify_token(self, token: str) -> UserPublic:
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
        except jwt.ExpiredSignatureError as exc:
            raise InvalidCredentialsError("Token JWT đã hết hạn.") from exc
        except jwt.InvalidTokenError as exc:
            raise InvalidCredentialsError("Token JWT không hợp lệ.") from exc

        user_id = payload.get("sub")
        if not user_id:
            raise InvalidCredentialsError("Token JWT thiếu định danh người dùng.")

        user = self.get_user_by_id(str(user_id))
        if user is None:
            raise InvalidCredentialsError("Tài khoản của token không tồn tại.")
        return user


@lru_cache
def get_auth_service() -> AuthService:
    settings = get_settings()
    return AuthService(
        db_path=settings.auth_db_path,
        secret_key=settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
        expire_minutes=settings.jwt_expire_minutes,
    )
