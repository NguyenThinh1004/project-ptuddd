import io
from pathlib import Path

import av
import numpy as np

SUPPORTED_AUDIO_EXTENSIONS: frozenset[str] = frozenset({
    ".wav",
    ".mp3",
    ".m4a",
    ".aac",
    ".ogg",
    ".flac",
    ".webm",
})

TARGET_SAMPLE_RATE = 16000


class AudioDecodingError(ValueError):
    """Raised when uploaded audio cannot be validated or decoded."""


def validate_audio_filename(filename: str | None) -> str:
    """Validate audio filename extension and return lowercase extension (or empty if unnamed)."""
    if not filename:
        return ""
    ext = Path(filename).suffix.lower()
    if ext and ext not in SUPPORTED_AUDIO_EXTENSIONS:
        supported = ", ".join(sorted(SUPPORTED_AUDIO_EXTENSIONS))
        raise AudioDecodingError(
            f"Định dạng tệp âm thanh '{ext}' chưa được hỗ trợ. Hỗ trợ: {supported}."
        )
    return ext


def decode_audio_to_16k_mono(audio_bytes: bytes, filename: str | None = None) -> np.ndarray:
    """
    Decode WAV/MP3/M4A/OGG/FLAC bytes in-memory into a 16kHz mono float32 numpy array
    ready for Whisper inference, without requiring an external ffmpeg binary.
    """
    if not audio_bytes:
        raise AudioDecodingError("Tệp âm thanh rỗng (0 bytes).")

    validate_audio_filename(filename)

    buffer = io.BytesIO(audio_bytes)
    resampler = av.AudioResampler(format="flt", layout="mono", rate=TARGET_SAMPLE_RATE)
    chunks: list[np.ndarray] = []

    try:
        with av.open(buffer, mode="r") as container:
            audio_streams = [s for s in container.streams if s.type == "audio"]
            if not audio_streams:
                raise AudioDecodingError("Không tìm thấy luồng âm thanh (audio stream) hợp lệ trong tệp.")

            stream = audio_streams[0]
            for frame in container.decode(stream):
                resampled_frames = resampler.resample(frame)
                if not isinstance(resampled_frames, list):
                    resampled_frames = [resampled_frames]
                for out_frame in resampled_frames:
                    arr = out_frame.to_ndarray()
                    chunks.append(arr.reshape(-1).astype(np.float32, copy=False))

            # Flush resampler tail samples.
            tail_frames = resampler.resample(None)
            if tail_frames is not None:
                if not isinstance(tail_frames, list):
                    tail_frames = [tail_frames]
                for out_frame in tail_frames:
                    arr = out_frame.to_ndarray()
                    if arr.size > 0:
                        chunks.append(arr.reshape(-1).astype(np.float32, copy=False))
    except AudioDecodingError:
        raise
    except Exception as exc:
        raise AudioDecodingError(f"Không thể giải mã tệp âm thanh: {exc}") from exc

    if not chunks:
        raise AudioDecodingError("Tệp âm thanh không chứa dữ liệu mẫu (samples) nào.")

    pcm = np.concatenate(chunks).astype(np.float32, copy=False)
    if pcm.size < int(TARGET_SAMPLE_RATE * 0.1):
        raise AudioDecodingError("Đoạn ghi âm quá ngắn (< 0.1 giây).")

    max_amp = float(np.max(np.abs(pcm)))
    if max_amp > 1.0:
        pcm = pcm / max_amp

    return pcm
