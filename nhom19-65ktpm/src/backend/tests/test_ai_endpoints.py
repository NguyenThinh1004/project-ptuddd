import json
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.services.auth_service import AuthService, get_auth_service
from app.services.llm_service import GeminiStudyService, get_llm_service


class _StubGeminiStudyService(GeminiStudyService):
    def __init__(self, responses: list[str], api_key: str = "fake-key") -> None:
        super().__init__(api_key=api_key, model_name="gemini-2.5-flash", allow_local_fallback=False)
        self._responses = list(responses)
        self.calls: list[str] = []

    def _call_gemini(self, prompt: str) -> str:
        self.calls.append(prompt)
        return self._responses.pop(0)


@pytest.fixture
def setup_app(tmp_path: Path):
    auth_service = AuthService(
        db_path=str(tmp_path / "ai_test_auth.db"),
        secret_key="ai-test-secret",
        algorithm="HS256",
        expire_minutes=60,
    )
    user = auth_service.register_user("Tester", "tester@studymate.ai", "Secret123")
    token = auth_service.issue_token(user).access_token
    headers = {"Authorization": f"Bearer {token}"}

    app = create_app()
    app.dependency_overrides[get_auth_service] = lambda: auth_service
    return app, headers


def test_ai_endpoints_require_jwt(setup_app):
    app, _ = setup_app
    with TestClient(app) as client:
        res1 = client.post("/api/ai/generate-flashcards", data={"text": "A" * 40})
        assert res1.status_code == 401

        res2 = client.post("/api/ai/flashcards", json={"text": "A" * 40})
        assert res2.status_code == 401


def test_generate_flashcards_with_text_and_file(setup_app):
    app, headers = setup_app
    valid_payload = json.dumps(
        {
            "summary": "JWT enables stateless API authentication.",
            "key_points": ["Signed header.payload.signature", "Verified with secret key"],
            "flashcards": [
                {"front": "JWT", "back": "JSON Web Token for stateless auth", "ipa": None},
                {"front": "Bearer Token", "back": "Authorization header scheme", "ipa": None},
            ],
            "quiz": [
                {
                    "question": "Which algorithm uses a shared HMAC secret?",
                    "options": ["HS256", "PNG", "WAV", "CSS"],
                    "correct_option": "A",
                    "correct_index": 0,
                    "explanation": "HS256 signs JWT tokens using HMAC-SHA256.",
                }
            ],
        }
    )
    stub_llm = _StubGeminiStudyService([valid_payload, valid_payload])
    app.dependency_overrides[get_llm_service] = lambda: stub_llm

    with TestClient(app) as client:
        # Text input
        res = client.post(
            "/api/ai/generate-flashcards",
            headers=headers,
            data={
                "text": "JWT (JSON Web Token) is an open standard for securely transmitting claims.",
                "num_flashcards": "5",
                "num_quiz": "3",
                "language": "en",
            },
        )
        assert res.status_code == 200
        body = res.json()
        assert body["summary"].startswith("JWT")
        assert len(body["flashcards"]) == 2
        assert len(body["quiz"]) == 1
        assert body["quiz"][0]["correct_option"] == "A"
        assert body["used_fallback_parser"] is False

        # File upload (.txt)
        res_file = client.post(
            "/api/ai/generate-flashcards",
            headers=headers,
            files={"file": ("lecture.txt", b"JWT tokens consist of three Base64Url parts.", "text/plain")},
        )
        assert res_file.status_code == 200
        assert res_file.json()["source_char_count"] >= 20


def test_generate_flashcards_retries_and_recovers_malformed_json(setup_app):
    app, headers = setup_app
    broken_first = "Apologies, I could not format that properly."
    repaired_second = """```json
    {
      "summary": "Recovered summary.",
      "key_points": ["Recovered point"],
      "flashcards": [{"front": "Concept", "back": "Explanation",}],
      "quiz": [{
        "question": "Recovered question?",
        "options": ["One", "Two", "Three", "Four"],
        "correct_option": "C",
        "explanation": "Three is index 2."
      }]
    }
    ```"""
    stub_llm = _StubGeminiStudyService([broken_first, repaired_second])
    app.dependency_overrides[get_llm_service] = lambda: stub_llm

    with TestClient(app) as client:
        res = client.post(
            "/api/ai/generate-flashcards",
            headers=headers,
            data={"text": "Lesson text long enough to trigger LLM generation and retry recovery."},
        )
        assert res.status_code == 200
        body = res.json()
        assert len(stub_llm.calls) == 2
        assert body["used_fallback_parser"] is True
        assert body["quiz"][0]["correct_index"] == 2


def test_legacy_ai_flashcards_endpoint_and_errors(setup_app):
    app, headers = setup_app
    payload = json.dumps(
        {
            "summary": "Pronunciation relies on phonemes.",
            "key_points": ["CMUDict maps words to Arpabet"],
            "flashcards": [{"front": "Phoneme", "back": "Smallest unit of sound", "ipa": "/ˈfoʊniːm/"}],
            "quiz": [
                {
                    "question": "What is a phoneme?",
                    "options": ["Smallest sound unit", "Video codec", "Database index", "TCP port"],
                    "correct_option": "A",
                    "correct_index": 0,
                    "explanation": "A phoneme distinguishes one word from another.",
                }
            ],
        }
    )
    app.dependency_overrides[get_llm_service] = lambda: _StubGeminiStudyService([payload])

    with TestClient(app) as client:
        res = client.post(
            "/api/ai/flashcards",
            headers=headers,
            json={"text": "Phonemes are the smallest units of sound in speech."},
        )
        assert res.status_code == 200
        data = res.json()
        assert data["cards"][0]["front"] == "Phoneme"
        assert data["cards"][0]["ipa"] == "/ˈfoʊniːm/"

        # Missing input
        res_empty = client.post("/api/ai/generate-flashcards", headers=headers, data={"text": "too short"})
        assert res_empty.status_code == 422

        # Missing API key returns 503
        app.dependency_overrides[get_llm_service] = lambda: _StubGeminiStudyService([], api_key="")
        res_nokey = client.post(
            "/api/ai/generate-flashcards",
            headers=headers,
            data={"text": "Valid length lesson content to test missing API key handling."},
        )
        assert res_nokey.status_code == 503

        # OpenAPI schema includes auth & AI endpoints
        openapi = client.get("/openapi.json").json()
        assert "/api/auth/register" in openapi["paths"]
        assert "/api/auth/token" in openapi["paths"]
        assert "/api/ai/generate-flashcards" in openapi["paths"]
        assert "/api/ai/flashcards" in openapi["paths"]
