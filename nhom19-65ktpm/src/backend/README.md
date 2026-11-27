# StudyMate AI — Speech Pronunciation Evaluation Microservice

Backend FastAPI phân tích và chấm điểm phát âm tiếng Anh theo âm vị chuẩn quốc tế (**NLTK CMUDict / IPA**), kết hợp **Faster-Whisper** (offline CPU) và thuật toán **Phoneme Alignment (Needleman-Wunsch + Levenshtein Distance)**.

## Tính năng chính

- **`POST /api/speech/evaluate`**: Nhận tệp âm thanh (`WAV`, `MP3`, `M4A`, `OGG`, `FLAC`) và văn bản câu mẫu `target_text`, trả về:
  - `overall_score` (`0–100`)
  - `transcript` (văn bản nhận dạng từ giọng nói)
  - `words[]`: từng từ với `word`, `score`, `status` (`correct` | `warning` | `error`), `expected_phonemes` (IPA), `user_phonemes` (IPA), `ipa`, `expected_arpabet`, `user_arpabet`, `matched_word`
  - `summary`: thống kê `total_words`, `correct_count`, `warning_count`, `error_count`
- **`POST /api/speech/assess`**: Alias tương thích ngược cho ứng dụng Flutter hiện có (`status`: `correct` | `close` | `wrong`).
- **`GET /health`**: Kiểm tra trạng thái CMUDict và Whisper.
- **Swagger / OpenAPI Docs**: Tự động tại `/docs` và `/redoc`.

## Cài đặt & Chạy local (Python 3.12 + `uv`)

```powershell
cd nhom19-65ktpm/src/backend
uv venv --python 3.12 .venv
uv pip install --python .venv\Scripts\python.exe -r requirements.txt
copy .env.example .env
.venv\Scripts\uvicorn.exe app.main:app --host 0.0.0.0 --port 8000 --reload
```

Mở Swagger UI tại: `http://localhost:8000/docs`

## Chạy kiểm thử

```powershell
cd nhom19-65ktpm/src/backend
.venv\Scripts\pytest.exe -v
```
