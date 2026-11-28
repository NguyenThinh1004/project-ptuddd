# StudyMate AI — Backend AI Microservice

Backend **Python 3.12 + FastAPI** của hệ thống **StudyMate AI**, cung cấp:
1. **Chấm điểm phát âm âm vị tiếng Anh** (NLTK CMUDict / IPA + Faster-Whisper + Levenshtein Alignment).
2. **Tóm tắt bài học & sinh Flashcards/Quiz tự động** (Google Gemini API + Strict JSON Schema + Fallback Parser đa tầng).
3. **Xác thực người dùng bằng JWT Token** (HS256 + SQLite).

## Các Endpoint chính

### Xác thực JWT
- `POST /api/auth/register` — Đăng ký tài khoản mới và nhận JWT Bearer token.
- `POST /api/auth/login` — Đăng nhập bằng JSON (`email`, `password`).
- `POST /api/auth/token` — Đăng nhập theo chuẩn OAuth2 form (hỗ trợ nút **Authorize** trên Swagger `/docs`).
- `GET /api/auth/me` — Lấy thông tin tài khoản từ Bearer token.

### AI Tóm tắt & Sinh Flashcards/Quiz (Yêu cầu Bearer JWT)
- `POST /api/ai/generate-flashcards` — Nhận `multipart/form-data` gồm `text` và/hoặc `file` (`.txt`, `.md`, `.pdf`, `.docx`), tùy chọn `num_flashcards`, `num_quiz`, `language`. Trả về `summary`, `key_points`, `flashcards`, `quiz` (4 phương án A/B/C/D, `correct_option`, `correct_index`, `explanation`).
- `POST /api/ai/flashcards` — Alias JSON tương thích trực tiếp với Flutter `AiAudioService`.

### Chấm điểm phát âm âm vị
- `POST /api/speech/evaluate` — Nhận tệp âm thanh (`WAV`, `MP3`, `M4A`, `OGG`, `FLAC`) và `target_text`, trả về `overall_score` (`0–100`) và phân tích từng từ (`correct` | `warning` | `error`, `expected_phonemes`, `user_phonemes`).
- `POST /api/speech/assess` — Alias tương thích ngược cho Flutter (`correct` | `close` | `wrong`).
- `GET /health` — Kiểm tra trạng thái CMUDict và Whisper.

Flutter gọi `/api/speech/evaluate` bằng multipart gồm tệp WAV và `target_text`.
Mặc định API base URL là `http://127.0.0.1:8000` trên web/desktop và
`http://10.0.2.2:8000` trên Android Emulator. Có thể ghi đè khi chạy Flutter:
`--dart-define=STUDYMATE_API_BASE_URL=https://<backend-host>`.

## Cài đặt & Chạy local (Python 3.12 + `uv`)

```powershell
cd nhom19-65ktpm/src/backend
uv venv --python 3.12 .venv
uv pip install --python .venv\Scripts\python.exe -r requirements.txt
copy .env.example .env
# Mở .env điền GEMINI_API_KEY và JWT_SECRET_KEY
.venv\Scripts\uvicorn.exe app.main:app --host 0.0.0.0 --port 8000 --reload
```

Mở Swagger UI tại: `http://localhost:8000/docs` (bấm **Authorize** sau khi đăng ký/đăng nhập để test `/api/ai/generate-flashcards`).

## Chạy kiểm thử

```powershell
cd nhom19-65ktpm/src/backend
.venv\Scripts\pytest.exe -v
```
