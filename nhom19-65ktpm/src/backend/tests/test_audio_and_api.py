import io
import math
import struct
import wave

import av
import numpy as np
import pytest
from fastapi.testclient import TestClient

from app.config import Settings, get_settings
from app.main import create_app
from app.services.asr_service import get_asr_service
from app.services.audio_service import AudioDecodingError, decode_audio_to_16k_mono


def _make_wav_bytes(duration_sec: float = 0.5, sample_rate: int = 16000) -> bytes:
    num_samples = int(duration_sec * sample_rate)
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        frames = bytearray()
        for i in range(num_samples):
            val = int(12000 * math.sin(2 * math.pi * 440.0 * i / sample_rate))
            frames.extend(struct.pack("<h", val))
        wf.writeframes(bytes(frames))
    return buf.getvalue()


def _make_mp3_bytes(duration_sec: float = 0.5, sample_rate: int = 16000) -> bytes:
    buf = io.BytesIO()
    num_samples = int(duration_sec * sample_rate)
    t = np.linspace(0, duration_sec, num_samples, endpoint=False, dtype=np.float32)
    samples = (0.3 * np.sin(2 * math.pi * 440.0 * t)).reshape(1, -1)

    with av.open(buf, mode="w", format="mp3") as container:
        stream = container.add_stream("mp3", rate=sample_rate)
        frame = av.AudioFrame.from_ndarray(samples, format="fltp", layout="mono")
        frame.sample_rate = sample_rate
        for packet in stream.encode(frame):
            container.mux(packet)
        for packet in stream.encode(None):
            container.mux(packet)
    return buf.getvalue()


class _FakeASRService:
    def __init__(self, transcript: str = "practice makes perfect") -> None:
        self._transcript = transcript
        self.is_loaded = True

    def transcribe(self, audio_16k_mono: np.ndarray) -> str:
        assert audio_16k_mono.ndim == 1
        assert audio_16k_mono.dtype == np.float32
        return self._transcript


@pytest.fixture
def client():
    app = create_app()
    fake_asr = _FakeASRService()
    app.dependency_overrides[get_asr_service] = lambda: fake_asr
    with TestClient(app) as test_client:
        yield test_client


def test_decode_wav_and_mp3_in_memory():
    wav_pcm = decode_audio_to_16k_mono(_make_wav_bytes(), "sample.wav")
    assert wav_pcm.dtype == np.float32
    assert wav_pcm.ndim == 1
    assert len(wav_pcm) >= 7000

    mp3_pcm = decode_audio_to_16k_mono(_make_mp3_bytes(), "sample.mp3")
    assert mp3_pcm.dtype == np.float32
    assert mp3_pcm.ndim == 1
    assert len(mp3_pcm) >= 7000


def test_decode_rejects_invalid_audio():
    with pytest.raises(AudioDecodingError):
        decode_audio_to_16k_mono(b"", "empty.wav")
    with pytest.raises(AudioDecodingError):
        decode_audio_to_16k_mono(b"not audio bytes", "bad.txt")
    with pytest.raises(AudioDecodingError):
        decode_audio_to_16k_mono(_make_wav_bytes(duration_sec=0.02), "short.wav")


def test_health_and_swagger_docs(client: TestClient):
    health = client.get("/health")
    assert health.status_code == 200
    body = health.json()
    assert body["status"] == "ok"
    assert body["cmudict_loaded"] is True
    assert body["cmudict_entries"] > 100000

    docs = client.get("/docs")
    assert docs.status_code == 200
    assert "Swagger UI" in docs.text

    openapi = client.get("/openapi.json")
    assert openapi.status_code == 200
    paths = openapi.json()["paths"]
    assert "/api/speech/evaluate" in paths
    assert "/api/speech/assess" in paths


def test_post_evaluate_wav_and_mp3(client: TestClient):
    wav_bytes = _make_wav_bytes()
    res = client.post(
        "/api/speech/evaluate",
        files={"audio": ("speech.wav", wav_bytes, "audio/wav")},
        data={"target_text": "Practice makes perfect"},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["overall_score"] == 100.0
    assert data["score"] == 100.0
    assert data["transcript"] == "practice makes perfect"
    assert len(data["words"]) == 3
    for word_item in data["words"]:
        assert set(word_item.keys()) >= {
            "word",
            "score",
            "status",
            "expected_phonemes",
            "user_phonemes",
        }
        assert word_item["status"] == "correct"

    # Also test MP3 + alias field names ("file" and "text")
    mp3_bytes = _make_mp3_bytes()
    res_mp3 = client.post(
        "/api/speech/evaluate",
        files={"file": ("speech.mp3", mp3_bytes, "audio/mpeg")},
        data={"text": "Practice makes"},
    )
    assert res_mp3.status_code == 200
    assert res_mp3.json()["overall_score"] == 100.0


def test_post_assess_legacy_compatibility():
    app = create_app()
    app.dependency_overrides[get_asr_service] = lambda: _FakeASRService("sink big")
    with TestClient(app) as test_client:
        res = test_client.post(
            "/api/speech/assess",
            files={"audio": ("speech.wav", _make_wav_bytes(), "audio/wav")},
            data={"target_text": "think big"},
        )
        assert res.status_code == 200
        payload = res.json()
        assert payload["score"] == 87.5
        assert payload["words"][0]["status"] == "close"
        assert payload["words"][1]["status"] == "correct"


def test_evaluate_validation_errors(client: TestClient):
    wav_bytes = _make_wav_bytes()

    # Empty target_text
    res_empty_text = client.post(
        "/api/speech/evaluate",
        files={"audio": ("speech.wav", wav_bytes, "audio/wav")},
        data={"target_text": "   "},
    )
    assert res_empty_text.status_code == 422

    # Missing audio
    res_missing_audio = client.post(
        "/api/speech/evaluate",
        data={"target_text": "hello world"},
    )
    assert res_missing_audio.status_code == 422

    # Unsupported extension
    res_bad_ext = client.post(
        "/api/speech/evaluate",
        files={"audio": ("notes.txt", b"hello", "text/plain")},
        data={"target_text": "hello world"},
    )
    assert res_bad_ext.status_code == 400

    # Oversized file
    app = create_app()
    app.dependency_overrides[get_settings] = lambda: Settings(max_audio_size_mb=0)
    app.dependency_overrides[get_asr_service] = lambda: _FakeASRService()
    with TestClient(app) as small_client:
        res_large = small_client.post(
            "/api/speech/evaluate",
            files={"audio": ("speech.wav", wav_bytes, "audio/wav")},
            data={"target_text": "hello"},
        )
        assert res_large.status_code == 413
