from typing import Literal
from pydantic import BaseModel, Field


CorrectLetter = Literal["A", "B", "C", "D"]
TargetLanguage = Literal["auto", "vi", "en"]


class FlashcardSchema(BaseModel):
    """Two-sided study flashcard generated from lesson content."""

    front: str = Field(
        ...,
        min_length=1,
        description="Mặt trước thẻ: khái niệm, thuật ngữ hoặc từ vựng trọng tâm.",
        examples=["Spaced Repetition (SM-2)"],
    )
    back: str = Field(
        ...,
        min_length=1,
        description="Mặt sau thẻ: định nghĩa, ý nghĩa hoặc giải thích ngắn gọn dễ nhớ.",
        examples=["Thuật toán lặp lại ngắt quãng tối ưu thời điểm ôn tập để chống quên."],
    )
    ipa: str | None = Field(
        default=None,
        description="Phiên âm IPA (nếu mặt trước là từ/cụm từ tiếng Anh), hoặc null.",
        examples=["/speɪst ˌrep.əˈtɪʃ.ən/"],
    )


class QuizQuestionSchema(BaseModel):
    """Four-choice multiple-choice quiz question with explanation."""

    question: str = Field(
        ...,
        min_length=1,
        description="Nội dung câu hỏi trắc nghiệm kiểm tra mức độ hiểu bài.",
        examples=["Mục đích chính của thuật toán SM-2 là gì?"],
    )
    options: list[str] = Field(
        ...,
        min_length=4,
        max_length=4,
        description="Danh sách đúng 4 phương án trả lời theo thứ tự A, B, C, D.",
        examples=[[
            "Tính khoảng thời gian ôn tập tối ưu dựa trên độ khó",
            "Nén dung lượng tệp âm thanh WAV",
            "Mã hóa mật khẩu người dùng",
            "Chuyển đổi ảnh sang văn bản",
        ]],
    )
    correct_option: CorrectLetter = Field(
        ...,
        description="Ký tự đáp án đúng: A, B, C hoặc D.",
        examples=["A"],
    )
    correct_index: int = Field(
        ...,
        ge=0,
        le=3,
        description="Chỉ số đáp án đúng (0=A, 1=B, 2=C, 3=D) tương thích Flutter QuizQuestion.",
        examples=[0],
    )
    explanation: str = Field(
        ...,
        min_length=1,
        description="Giải thích ngắn gọn lý do vì sao đáp án đó đúng.",
        examples=["SM-2 điều chỉnh ease_factor và interval sau mỗi lần ôn để tối ưu trí nhớ dài hạn."],
    )


class GenerateStudyKitResponse(BaseModel):
    """Strict structured response for POST /api/ai/generate-flashcards."""

    summary: str = Field(
        ...,
        description="Bản tóm tắt cô đọng nội dung chính của bài học.",
    )
    key_points: list[str] = Field(
        default_factory=list,
        description="Danh sách các ý trọng tâm được trích xuất từ tài liệu.",
    )
    flashcards: list[FlashcardSchema] = Field(
        default_factory=list,
        description="Danh sách thẻ ghi nhớ Flashcard.",
    )
    quiz: list[QuizQuestionSchema] = Field(
        default_factory=list,
        description="Danh sách câu hỏi trắc nghiệm Quiz 4 lựa chọn.",
    )
    source_char_count: int = Field(
        ...,
        ge=0,
        description="Độ dài văn bản bài học đã đưa vào phân tích (ký tự).",
    )
    used_fallback_parser: bool = Field(
        default=False,
        description="True nếu phản hồi thô của LLM cần qua bộ fallback parser để phục hồi JSON.",
    )
    model: str = Field(
        ...,
        description="Tên mô hình LLM hoặc chế độ xử lý đã sử dụng.",
        examples=["gemini-2.5-flash"],
    )


class LegacyFlashcardsRequest(BaseModel):
    """JSON request payload for mobile-compatible POST /api/ai/flashcards."""

    text: str = Field(..., min_length=20, description="Văn bản bài học cần tạo flashcards/quiz.")
    num_flashcards: int = Field(default=6, ge=1, le=20)
    num_quiz: int = Field(default=4, ge=1, le=15)
    language: TargetLanguage = Field(default="auto")


class LegacyFlashcardsResponse(BaseModel):
    """Mobile-compatible response payload exposing `cards` alongside full study kit."""

    cards: list[FlashcardSchema]
    summary: str
    key_points: list[str]
    flashcards: list[FlashcardSchema]
    quiz: list[QuizQuestionSchema]
    used_fallback_parser: bool = False
    model: str
