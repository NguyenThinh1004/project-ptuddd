from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm

from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse, UserPublic
from app.services.auth_service import (
    AuthService,
    EmailAlreadyExistsError,
    InvalidCredentialsError,
    get_auth_service,
)

router = APIRouter(prefix="/api/auth", tags=["Authentication (JWT)"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/token")


async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    auth_service: Annotated[AuthService, Depends(get_auth_service)],
) -> UserPublic:
    """Validate Bearer JWT token and return the authenticated user."""
    try:
        return auth_service.verify_token(token)
    except InvalidCredentialsError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Đăng ký tài khoản mới và cấp JWT Token",
    responses={
        201: {"description": "Đăng ký thành công, trả về JWT access token."},
        409: {"description": "Email đã tồn tại."},
    },
)
async def register(
    payload: RegisterRequest,
    auth_service: Annotated[AuthService, Depends(get_auth_service)],
) -> TokenResponse:
    try:
        user = auth_service.register_user(
            full_name=payload.full_name,
            email=payload.email,
            password=payload.password,
        )
    except EmailAlreadyExistsError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc
    return auth_service.issue_token(user)


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Đăng nhập bằng Email/Mật khẩu (JSON)",
    responses={
        200: {"description": "Đăng nhập thành công."},
        401: {"description": "Sai email hoặc mật khẩu."},
    },
)
async def login(
    payload: LoginRequest,
    auth_service: Annotated[AuthService, Depends(get_auth_service)],
) -> TokenResponse:
    try:
        user = auth_service.authenticate_user(payload.email, payload.password)
    except InvalidCredentialsError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc
    return auth_service.issue_token(user)


@router.post(
    "/token",
    response_model=TokenResponse,
    summary="OAuth2 Password Token (dùng cho nút Authorize trên Swagger /docs)",
    description="Nhận `username` (email) và `password` theo chuẩn OAuth2 form để cấp JWT Bearer token.",
)
async def login_oauth2_form(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    auth_service: Annotated[AuthService, Depends(get_auth_service)],
) -> TokenResponse:
    try:
        user = auth_service.authenticate_user(form_data.username, form_data.password)
    except InvalidCredentialsError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc
    return auth_service.issue_token(user)


@router.get(
    "/me",
    response_model=UserPublic,
    summary="Lấy thông tin người dùng hiện tại từ JWT Token",
)
async def read_current_user(
    current_user: Annotated[UserPublic, Depends(get_current_user)],
) -> UserPublic:
    return current_user
