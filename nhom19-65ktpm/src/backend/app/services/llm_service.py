from dataclasses import dataclass
from functools import lru_cache
import json
import logging
import re
from typing import Any

from google import genai
from google.genai import types
from pydantic import BaseModel, Field

from app.config import Settings, get_settings
from app.schemas.ai import (
    CorrectLetter,
    FlashcardSchema,
    GenerateStudyKitResponse,
    QuizQuestionSchema,
    TargetLanguage,
)

logger = logging.getLogger(__name__)

_LETTERS: tuple[CorrectLetter, ...] = ("A", "B", "C", "D")
_OPTION_PREFIX_RE = re.compile(r"^\s*(?:[A-Da-d][\.\)\:\-]\s+)")


class LLMServiceError(RuntimeError):
    """Base error for LLM generation."""


class LLMNotConfiguredError(LLMServiceError):
    """Raised when GEMINI_API_KEY is missing and local fallback is disabled."""


class LLMGenerationError(LLMServiceError):
    """Raised when the upstream Gemini API fails or produces unrecoverable output."""


class _GeminiPayloadSchema(BaseModel):
    """Strict schema passed to Gemini structured JSON output."""

    summary: str = Field(..., description="Concise summary of the lesson.")
    key_points: list[str] = Field(..., description="Bullet list of key takeaways.")
    flashcards: list[FlashcardSchema] = Field(..., description="Generated flashcards.")
    quiz: list[QuizQuestionSchema] = Field(..., description="Generated 4-option MCQs.")


SYSTEM_INSTRUCTION = """You are an expert academic tutor and curriculum designer for StudyMate AI.
Your task is to analyze study materials and produce high-precision learning artifacts in STRICT JSON format.

Mandatory Rules:
1. Return ONLY a valid JSON object matching the required schema — NO markdown fences, NO commentary outside JSON.
2. Summary (`summary`): Write a clear, concise 2-4 sentence synthesis capturing the core thesis and context.
3. Key Points (`key_points`): Extract 3-6 essential, distinct takeaways.
4. Flashcards (`flashcards`):
   - `front`: A crisp concept, term, principle, or vocabulary item (never an empty string or full paragraph).
   - `back`: A clear, accurate definition, mechanism, or explanation grounded strictly in the source text.
   - `ipa`: Provide standard IPA like `/.../` ONLY if `front` is an English vocabulary word/phrase; otherwise `null`.
5. Quiz (`quiz`):
   - `question`: A meaningful comprehension or application question (avoid trivial copy-paste).
   - `options`: Exactly 4 plausible, distinct answer strings (do NOT prepend "A.", "B.", "C.", "D." inside option strings).
   - `correct_option`: Exactly one uppercase letter `"A"`, `"B"`, `"C"`, or `"D"`.
   - `correct_index`: Integer `0`, `1`, `2`, or `3` matching `correct_option` (`A=0, B=1, C=2, D=3`).
   - `explanation`: 1-2 sentences explaining why the correct choice is right and/or why distractors are wrong.
6. Stay strictly faithful to facts in the provided lesson material; do not hallucinate unsupported claims."""


def build_generation_prompt(
    lesson_text: str,
    num_flashcards: int,
    num_quiz: int,
    language: TargetLanguage,
) -> str:
    lang_directive = {
        "auto": "Match the primary language of the lesson material (Vietnamese or English).",
        "vi": "Write summary, key_points, flashcard explanations, and quiz questions in Vietnamese (keep technical English terms where natural).",
        "en": "Write all generated fields in clear academic English.",
    }[language]

    return f"""Analyze the following lesson content and generate a structured study kit.

Requirements:
- Language: {lang_directive}
- Generate up to {num_flashcards} high-value flashcards.
- Generate up to {num_quiz} multiple-choice quiz questions with exactly 4 options each.
- Follow this exact JSON shape:
{{
  "summary": "string",
  "key_points": ["string"],
  "flashcards": [
    {{"front": "string", "back": "string", "ipa": "string or null"}}
  ],
  "quiz": [
    {{
      "question": "string",
      "options": ["option A", "option B", "option C", "option D"],
      "correct_option": "A",
      "correct_index": 0,
      "explanation": "string"
    }}
  ]
}}

<LESSON_CONTENT>
{lesson_text}
</LESSON_CONTENT>"""


def build_repair_prompt(malformed_output: str) -> str:
    return (
        "The previous output could not be parsed as strict JSON matching the schema. "
        "Convert and repair it into a single valid JSON object with keys "
        "`summary`, `key_points`, `flashcards`, and `quiz` (each quiz having 4 `options`, "
        "`correct_option` in A/B/C/D, `correct_index` 0..3, and `explanation`). "
        "Output ONLY valid JSON.\n\n"
        f"<RAW_OUTPUT>\n{malformed_output[:12000]}\n</RAW_OUTPUT>"
    )


@dataclass
class ParsedStudyKit:
    summary: str
    key_points: list[str]
    flashcards: list[FlashcardSchema]
    quiz: list[QuizQuestionSchema]
    used_fallback_parser: bool


def _strip_code_fences(text: str) -> str:
    fenced = re.search(r"```(?:json)?\s*([\s\S]*?)```", text, flags=re.IGNORECASE)
    if fenced:
        return fenced.group(1).strip()
    return text.strip()


def _extract_outer_json(text: str) -> str:
    start = text.find("{")
    if start == -1:
        return text
    depth = 0
    in_str = False
    escape = False
    for idx in range(start, len(text)):
        ch = text[idx]
        if in_str:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_str = False
        else:
            if ch == '"':
                in_str = True
            elif ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    return text[start : idx + 1]
    return text[start:]


def _escape_control_chars_in_strings(text: str) -> str:
    out: list[str] = []
    in_str = False
    escape = False
    for ch in text:
        if in_str:
            if escape:
                out.append(ch)
                escape = False
            elif ch == "\\":
                out.append(ch)
                escape = True
            elif ch == '"':
                out.append(ch)
                in_str = False
            elif ch == "\n":
                out.append("\\n")
            elif ch == "\r":
                out.append("\\r")
            elif ch == "\t":
                out.append("\\t")
            else:
                out.append(ch)
        else:
            if ch == '"':
                in_str = True
            out.append(ch)
    return "".join(out)


def _close_truncated_json(text: str) -> str:
    """Attempt to close unclosed strings, arrays, and objects if LLM output truncated."""
    in_str = False
    escape = False
    stack: list[str] = []
    for ch in text:
        if in_str:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_str = False
        else:
            if ch == '"':
                in_str = True
            elif ch in "{[":
                stack.append("}" if ch == "{" else "]")
            elif ch in "}]" and stack:
                stack.pop()

    repaired = text.rstrip()
    if in_str:
        repaired += '"'
    repaired = re.sub(r",\s*$", "", repaired)
    while stack:
        repaired = re.sub(r",\s*$", "", repaired)
        repaired += stack.pop()
    return repaired


def _repair_json_text(raw: str) -> str:
    cleaned = _strip_code_fences(raw)
    cleaned = _extract_outer_json(cleaned)
    cleaned = (
        cleaned.replace("\u201c", '"')
        .replace("\u201d", '"')
        .replace("\u2018", "'")
        .replace("\u2019", "'")
    )
    cleaned = _escape_control_chars_in_strings(cleaned)
    cleaned = re.sub(r",\s*([}\]])", r"\1", cleaned)
    cleaned = re.sub(r"\bTrue\b", "true", cleaned)
    cleaned = re.sub(r"\bFalse\b", "false", cleaned)
    cleaned = re.sub(r"\bNone\b", "null", cleaned)
    return _close_truncated_json(cleaned)


def _clean_option_text(opt: Any) -> str:
    return _OPTION_PREFIX_RE.sub("", str(opt or "").strip()).strip()


def _coerce_flashcards(raw_cards: Any) -> list[FlashcardSchema]:
    if not isinstance(raw_cards, list):
        return []
    items: list[FlashcardSchema] = []
    for entry in raw_cards:
        if not isinstance(entry, dict):
            continue
        front = str(entry.get("front") or entry.get("term") or entry.get("concept") or "").strip()
        back = str(entry.get("back") or entry.get("definition") or entry.get("answer") or "").strip()
        ipa_raw = entry.get("ipa")
        ipa = str(ipa_raw).strip() if ipa_raw not in (None, "", "null") else None
        if front and back:
            items.append(FlashcardSchema(front=front, back=back, ipa=ipa))
    return items


def _resolve_correct_answer(
    options: list[str],
    raw_option: Any,
    raw_index: Any,
) -> tuple[CorrectLetter, int]:
    # 1. Explicit integer index (0..3)
    if isinstance(raw_index, int) and 0 <= raw_index <= 3:
        return _LETTERS[raw_index], raw_index

    # 2. Letter string like "A", "B.", "Option C"
    if raw_option is not None:
        text = str(raw_option).strip()
        letter_match = re.match(r"^(?:option\s*)?([A-Da-d])(?:[\.\)\:]|$|\s)", text)
        if letter_match:
            letter = letter_match.group(1).upper()
            idx = _LETTERS.index(letter)  # type: ignore[arg-type]
            return _LETTERS[idx], idx
        # Match against option text value
        cleaned = _clean_option_text(text).lower()
        for idx, opt in enumerate(options):
            if opt.lower() == cleaned:
                return _LETTERS[idx], idx

    if isinstance(raw_index, str) and raw_index.strip().isdigit():
        idx = int(raw_index.strip())
        if 0 <= idx <= 3:
            return _LETTERS[idx], idx

    return "A", 0


def _coerce_quiz(raw_quiz: Any) -> list[QuizQuestionSchema]:
    if not isinstance(raw_quiz, list):
        return []
    items: list[QuizQuestionSchema] = []
    for entry in raw_quiz:
        if not isinstance(entry, dict):
            continue
        question = str(entry.get("question") or entry.get("prompt") or "").strip()
        raw_options = entry.get("options") or entry.get("choices")

        options: list[str] = []
        if isinstance(raw_options, dict):
            for letter in _LETTERS:
                val = raw_options.get(letter) or raw_options.get(letter.lower())
                if val is not None:
                    options.append(_clean_option_text(val))
        elif isinstance(raw_options, list):
            options = [_clean_option_text(o) for o in raw_options if str(o or "").strip()]

        if not question or len(options) != 4 or any(not o for o in options):
            continue

        raw_opt = entry.get("correct_option") or entry.get("correct_answer") or entry.get("answer")
        raw_idx = entry.get("correct_index")
        correct_letter, correct_idx = _resolve_correct_answer(options, raw_opt, raw_idx)
        explanation = str(
            entry.get("explanation")
            or entry.get("rationale")
            or f"Đáp án đúng là {correct_letter}: {options[correct_idx]}."
        ).strip()

        items.append(
            QuizQuestionSchema(
                question=question,
                options=options,
                correct_option=correct_letter,
                correct_index=correct_idx,
                explanation=explanation,
            )
        )
    return items


def _coerce_dict_payload(data: dict[str, Any], used_fallback: bool) -> ParsedStudyKit | None:
    summary = str(
        data.get("summary") or data.get("lesson_summary") or data.get("overview") or ""
    ).strip()
    raw_points = data.get("key_points") or data.get("highlights") or []
    key_points = [str(p).strip() for p in raw_points if str(p or "").strip()] if isinstance(raw_points, list) else []

    flashcards = _coerce_flashcards(data.get("flashcards") or data.get("cards"))
    quiz = _coerce_quiz(data.get("quiz") or data.get("quizzes") or data.get("questions"))

    if not summary and not flashcards and not quiz:
        return None
    if not summary:
        summary = " ".join(key_points[:3]) if key_points else (flashcards[0].back if flashcards else "")

    return ParsedStudyKit(
        summary=summary,
        key_points=key_points,
        flashcards=flashcards,
        quiz=quiz,
        used_fallback_parser=used_fallback,
    )


def _parse_prose_fallback(raw_text: str) -> ParsedStudyKit | None:
    """Last-resort regex parser when LLM ignores JSON and emits labeled prose blocks."""
    summary_match = re.search(
        r"(?:summary|tóm tắt)\s*:\s*(.+?)(?=\n\s*(?:front|mặt trước|question|câu hỏi|q\d*[:\.])|\Z)",
        raw_text,
        flags=re.IGNORECASE | re.DOTALL,
    )
    summary = re.sub(r"\s+", " ", summary_match.group(1)).strip() if summary_match else ""

    flashcards: list[FlashcardSchema] = []
    for m in re.finditer(
        r"(?:front|mặt trước)\s*:\s*(.+?)\n+\s*(?:back|mặt sau)\s*:\s*(.+?)(?=\n+\s*(?:front|mặt trước|question|câu hỏi|q\d*[:\.])|\Z)",
        raw_text,
        flags=re.IGNORECASE | re.DOTALL,
    ):
        front = m.group(1).strip()
        back = re.sub(r"\s+", " ", m.group(2)).strip()
        if front and back:
            flashcards.append(FlashcardSchema(front=front, back=back))

    quiz: list[QuizQuestionSchema] = []
    quiz_pattern = re.compile(
        r"(?:question|câu hỏi|q\d+)\s*[:\.]\s*(.+?)\n+"
        r"\s*A[\.\)]\s*(.+?)\n+"
        r"\s*B[\.\)]\s*(.+?)\n+"
        r"\s*C[\.\)]\s*(.+?)\n+"
        r"\s*D[\.\)]\s*(.+?)\n+"
        r"\s*(?:answer|correct|đáp án)\s*:\s*([A-Da-d])"
        r"(?:\n+\s*(?:explanation|giải thích)\s*:\s*(.+?))?(?=\n+\s*(?:question|câu hỏi|q\d+)\s*[:\.]|\Z)",
        flags=re.IGNORECASE | re.DOTALL,
    )
    for m in quiz_pattern.finditer(raw_text):
        options = [m.group(2).strip(), m.group(3).strip(), m.group(4).strip(), m.group(5).strip()]
        letter = m.group(6).upper()
        idx = _LETTERS.index(letter)  # type: ignore[arg-type]
        explanation = (m.group(7) or f"Đáp án đúng là {letter}: {options[idx]}.").strip()
        quiz.append(
            QuizQuestionSchema(
                question=m.group(1).strip(),
                options=options,
                correct_option=_LETTERS[idx],
                correct_index=idx,
                explanation=explanation,
            )
        )

    if not flashcards and not quiz:
        return None
    if not summary:
        summary = flashcards[0].back if flashcards else quiz[0].explanation
    return ParsedStudyKit(
        summary=summary,
        key_points=[],
        flashcards=flashcards,
        quiz=quiz,
        used_fallback_parser=True,
    )


def parse_llm_study_payload(raw_text: str) -> ParsedStudyKit | None:
    """
    Multi-stage resilient parser:
    1. Strict json.loads + Pydantic schema check.
    2. Repaired JSON extraction (strip code fences, fix trailing commas/newlines/truncation).
    3. Lenient item-by-item coercion (dict options, alternate field names).
    4. Prose regex block fallback.
    """
    if not raw_text or not raw_text.strip():
        return None

    # Stage 1: Clean JSON fast path
    try:
        parsed_raw = json.loads(raw_text)
        if isinstance(parsed_raw, dict):
            validated = _GeminiPayloadSchema.model_validate(parsed_raw)
            return ParsedStudyKit(
                summary=validated.summary.strip(),
                key_points=[p.strip() for p in validated.key_points if p.strip()],
                flashcards=validated.flashcards,
                quiz=validated.quiz,
                used_fallback_parser=False,
            )
    except Exception:
        pass

    # Stage 2 & 3: JSON repair + lenient coercion
    try:
        repaired_str = _repair_json_text(raw_text)
        repaired_obj = json.loads(repaired_str)
        if isinstance(repaired_obj, dict):
            coerced = _coerce_dict_payload(repaired_obj, used_fallback=True)
            if coerced is not None:
                return coerced
    except Exception:
        pass

    # Stage 4: Prose regex extraction
    return _parse_prose_fallback(raw_text)


def _local_heuristic_study_kit(lesson_text: str, num_flashcards: int, num_quiz: int) -> ParsedStudyKit:
    """Deterministic local extractor used only when LLM_LOCAL_FALLBACK=true."""
    sentences = [s.strip() for s in re.split(r"(?<=[.!?])\s+|\n+", lesson_text) if len(s.strip()) >= 20]
    if not sentences:
        sentences = [lesson_text.strip()]

    summary = " ".join(sentences[:2])
    key_points = sentences[: min(4, len(sentences))]
    flashcards: list[FlashcardSchema] = []
    for idx, sent in enumerate(sentences[:num_flashcards], start=1):
        words = sent.split()
        front = " ".join(words[: min(5, len(words))]).rstrip(",.:;")
        flashcards.append(FlashcardSchema(front=f"Khái niệm {idx}: {front}", back=sent))

    quiz: list[QuizQuestionSchema] = []
    for idx, sent in enumerate(sentences[:num_quiz], start=1):
        other = sentences[(idx) % len(sentences)]
        options = [
            sent[:140],
            f"Không liên quan đến: {other[:100]}",
            "Chỉ áp dụng cho dữ liệu nhị phân",
            "Không có phương án nào đúng",
        ]
        quiz.append(
            QuizQuestionSchema(
                question=f"Ý nào sau đây phản ánh đúng nội dung phần {idx} của bài học?",
                options=options,
                correct_option="A",
                correct_index=0,
                explanation=f"Nội dung bài học nêu rõ: {sent[:180]}",
            )
        )

    return ParsedStudyKit(
        summary=summary,
        key_points=key_points,
        flashcards=flashcards,
        quiz=quiz,
        used_fallback_parser=True,
    )


class GeminiStudyService:
    """Google Gemini LLM service for lesson summarization and Flashcard/Quiz generation."""

    def __init__(
        self,
        api_key: str,
        model_name: str = "gemini-2.5-flash",
        allow_local_fallback: bool = False,
    ) -> None:
        self.api_key = api_key.strip()
        self.model_name = model_name
        self.allow_local_fallback = allow_local_fallback
        self._client: genai.Client | None = None

    def _get_client(self) -> genai.Client:
        if self._client is None:
            self._client = genai.Client(api_key=self.api_key)
        return self._client

    def _call_gemini(self, prompt: str) -> str:
        client = self._get_client()
        response = client.models.generate_content(
            model=self.model_name,
            contents=prompt,
            config=types.GenerateContentConfig(
                system_instruction=SYSTEM_INSTRUCTION,
                temperature=0.2,
                response_mime_type="application/json",
                response_schema=_GeminiPayloadSchema,
            ),
        )
        return (response.text or "").strip()

    def generate_study_kit(
        self,
        lesson_text: str,
        num_flashcards: int = 6,
        num_quiz: int = 4,
        language: TargetLanguage = "auto",
    ) -> GenerateStudyKitResponse:
        if not self.api_key:
            if self.allow_local_fallback:
                local = _local_heuristic_study_kit(lesson_text, num_flashcards, num_quiz)
                return GenerateStudyKitResponse(
                    summary=local.summary,
                    key_points=local.key_points,
                    flashcards=local.flashcards,
                    quiz=local.quiz,
                    source_char_count=len(lesson_text),
                    used_fallback_parser=True,
                    model="local-heuristic-fallback",
                )
            raise LLMNotConfiguredError(
                "Chưa cấu hình GEMINI_API_KEY trong biến môi trường hoặc tệp .env."
            )

        prompt = build_generation_prompt(
            lesson_text=lesson_text,
            num_flashcards=num_flashcards,
            num_quiz=num_quiz,
            language=language,
        )

        try:
            raw_output = self._call_gemini(prompt)
        except Exception as exc:
            logger.exception("Gemini API call failed: %s", exc)
            raise LLMGenerationError(f"Lỗi khi gọi Google Gemini API: {exc}") from exc

        parsed = parse_llm_study_payload(raw_output)
        if parsed is None:
            logger.warning("Primary parse failed; retrying once with JSON repair prompt.")
            try:
                repaired_raw = self._call_gemini(build_repair_prompt(raw_output))
                parsed = parse_llm_study_payload(repaired_raw)
                if parsed is not None:
                    parsed.used_fallback_parser = True
            except Exception as exc:
                logger.warning("Gemini repair retry failed: %s", exc)

        if parsed is None:
            if self.allow_local_fallback:
                parsed = _local_heuristic_study_kit(lesson_text, num_flashcards, num_quiz)
            else:
                raise LLMGenerationError(
                    "Phản hồi từ Gemini không đúng định dạng JSON và không thể phục hồi sau fallback parsing."
                )

        return GenerateStudyKitResponse(
            summary=parsed.summary,
            key_points=parsed.key_points,
            flashcards=parsed.flashcards[:num_flashcards],
            quiz=parsed.quiz[:num_quiz],
            source_char_count=len(lesson_text),
            used_fallback_parser=parsed.used_fallback_parser,
            model=self.model_name,
        )


@lru_cache
def get_llm_service() -> GeminiStudyService:
    settings: Settings = get_settings()
    return GeminiStudyService(
        api_key=settings.gemini_api_key,
        model_name=settings.gemini_model,
        allow_local_fallback=settings.llm_local_fallback,
    )
