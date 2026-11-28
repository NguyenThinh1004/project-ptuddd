from datetime import datetime, timedelta, timezone
from pathlib import Path

import jwt
import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.services.auth_service import AuthService, get_auth_service


@pytest.fixture
def auth_client(tmp_path: Path):
    db_file = tmp_path / "test_auth.db"
    service = AuthService(
        db_path=str(db_file),
        secret_key="test-jwt-secret-key",
        algorithm="HS256",
        expire_minutes=60,
    )
    app = create_app()
    app.dependency_overrides[get_auth_service] = lambda: service
    with TestClient(app) as client:
        yield client, service


def test_register_login_and_me_flow(auth_client):
    client, _ = auth_client

    reg = client.post(
        "/api/auth/register",
        json={
            "full_name": "Nguyen Van Thinh",
            "email": "Thinh@StudyMate.ai",
            "password": "Password123",
        },
    )
    assert reg.status_code == 201
    reg_data = reg.json()
    assert reg_data["token_type"] == "bearer"
    assert reg_data["user"]["email"] == "thinh@studymate.ai"
    token = reg_data["access_token"]

    # Duplicate email rejected
    dup = client.post(
        "/api/auth/register",
        json={
            "full_name": "Another",
            "email": "thinh@studymate.ai",
            "password": "Password123",
        },
    )
    assert dup.status_code == 409

    # JSON login
    login = client.post(
        "/api/auth/login",
        json={"email": "thinh@studymate.ai", "password": "Password123"},
    )
    assert login.status_code == 200
    assert login.json()["access_token"]

    # OAuth2 form login for Swagger Authorize
    oauth_res = client.post(
        "/api/auth/token",
        data={"username": "thinh@studymate.ai", "password": "Password123"},
    )
    assert oauth_res.status_code == 200
    assert oauth_res.json()["token_type"] == "bearer"

    # Protected /me endpoint
    me = client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert me.status_code == 200
    assert me.json()["email"] == "thinh@studymate.ai"


def test_invalid_login_and_jwt_errors(auth_client):
    client, service = auth_client
    user = service.register_user("Hung", "hung@studymate.ai", "Secret123")

    bad_login = client.post(
        "/api/auth/login",
        json={"email": "hung@studymate.ai", "password": "wrong"},
    )
    assert bad_login.status_code == 401

    assert client.get("/api/auth/me").status_code == 401
    assert (
        client.get("/api/auth/me", headers={"Authorization": "Bearer not.a.jwt"}).status_code
        == 401
    )

    expired_token = jwt.encode(
        {
            "sub": user.id,
            "email": user.email,
            "exp": int((datetime.now(timezone.utc) - timedelta(minutes=5)).timestamp()),
        },
        "test-jwt-secret-key",
        algorithm="HS256",
    )
    assert (
        client.get("/api/auth/me", headers={"Authorization": f"Bearer {expired_token}"}).status_code
        == 401
    )
