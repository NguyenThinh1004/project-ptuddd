import logging
import threading
from functools import lru_cache

import numpy as np
from faster_whisper import WhisperModel

from app.config import get_settings

logger = logging.getLogger(__name__)


class WhisperASRService:
    """Offline English speech-to-text service powered by faster-whisper."""

    def __init__(
        self,
        model_size: str = "base.en",
        device: str = "cpu",
        compute_type: str = "int8",
    ) -> None:
        self.model_size = model_size
        self.device = device
        self.compute_type = compute_type
        self._model: WhisperModel | None = None
        self._lock = threading.Lock()

    @property
    def is_loaded(self) -> bool:
        return self._model is not None

    def load_model(self) -> WhisperModel:
        if self._model is None:
            with self._lock:
                if self._model is None:
                    logger.info(
                        "Loading faster-whisper model '%s' (device=%s, compute_type=%s)...",
                        self.model_size,
                        self.device,
                        self.compute_type,
                    )
                    self._model = WhisperModel(
                        self.model_size,
                        device=self.device,
                        compute_type=self.compute_type,
                    )
                    logger.info("faster-whisper model '%s' loaded.", self.model_size)
        return self._model

    def transcribe(self, audio_16k_mono: np.ndarray) -> str:
        """Transcribe 16kHz mono float32 PCM audio into an English transcript."""
        model = self.load_model()
        # Do NOT pass target_text as initial_prompt so Whisper transcribes what was actually spoken
        # rather than biasing toward the expected reference sentence.
        segments, _ = model.transcribe(
            audio_16k_mono,
            language="en",
            beam_size=2,
            condition_on_previous_text=False,
            vad_filter=False,
        )
        transcript = " ".join(seg.text.strip() for seg in segments if seg.text.strip())
        return transcript.strip()


@lru_cache
def get_asr_service() -> WhisperASRService:
    settings = get_settings()
    return WhisperASRService(
        model_size=settings.whisper_model,
        device=settings.whisper_device,
        compute_type=settings.whisper_compute_type,
    )
