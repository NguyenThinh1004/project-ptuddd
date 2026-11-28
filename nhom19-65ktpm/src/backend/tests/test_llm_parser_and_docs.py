import io

from docx import Document
import pytest

from app.services.document_service import DocumentExtractionError, extract_text_from_document
from app.services.llm_service import parse_llm_study_payload


def _make_minimal_pdf_bytes(text: str) -> bytes:
    """Create a valid minimal single-page PDF containing readable ASCII text."""
    escaped = text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")
    stream = f"BT\n/F1 12 Tf\n72 720 Td\n({escaped}) Tj\nET\n".encode("latin-1")

    objects = [
        b"1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n",
        b"2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n",
        (
            b"3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
            b"/Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n"
        ),
        (
            f"4 0 obj\n<< /Length {len(stream)} >>\nstream\n".encode("latin-1")
            + stream
            + b"endstream\nendobj\n"
        ),
        b"5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n",
    ]

    pdf = bytearray(b"%PDF-1.4\n")
    offsets = [0]
    for obj in objects:
        offsets.append(len(pdf))
        pdf.extend(obj)
    xref_pos = len(pdf)
    pdf.extend(f"xref\n0 {len(offsets)}\n".encode("latin-1"))
    pdf.extend(b"0000000000 65535 f \n")
    for off in offsets[1:]:
        pdf.extend(f"{off:010d} 00000 n \n".encode("latin-1"))
    pdf.extend(
        (
            f"trailer\n<< /Size {len(offsets)} /Root 1 0 R >>\n"
            f"startxref\n{xref_pos}\n%%EOF\n"
        ).encode("latin-1")
    )
    return bytes(pdf)


def _make_docx_bytes(paragraphs: list[str]) -> bytes:
    doc = Document()
    for p in paragraphs:
        doc.add_paragraph(p)
    buf = io.BytesIO()
    doc.save(buf)
    return buf.getvalue()


def test_parse_clean_json():
    raw = """{
      "summary": "SM-2 schedules reviews based on recall quality.",
      "key_points": ["Ease factor adapts to difficulty", "Intervals grow over time"],
      "flashcards": [
        {"front": "Ease Factor", "back": "Multiplier controlling interval growth", "ipa": null}
      ],
      "quiz": [
        {
          "question": "What does SM-2 optimize?",
          "options": ["Review intervals", "Audio bitrate", "Screen brightness", "SQL joins"],
          "correct_option": "A",
          "correct_index": 0,
          "explanation": "SM-2 spaces reviews to combat the forgetting curve."
        }
      ]
    }"""
    parsed = parse_llm_study_payload(raw)
    assert parsed is not None
    assert parsed.used_fallback_parser is False
    assert len(parsed.flashcards) == 1
    assert len(parsed.quiz) == 1
    assert parsed.quiz[0].correct_option == "A"


def test_parse_fallback_markdown_fences_trailing_commas_and_dict_options():
    raw = """Here is the generated JSON for your lesson:
```json
{
  "summary": "Pomodoro boosts deep focus.",
  "key_points": ["25 minutes focus", "5 minutes break",],
  "flashcards": [
    {"term": "Pomodoro", "definition": "25-minute focused work interval",},
  ],
  "quiz": [
    {
      "question": "How long is one standard Pomodoro sprint?",
      "options": {
        "A": "A. 10 minutes",
        "B": "B. 25 minutes",
        "C": "C. 60 minutes",
        "D": "D. 90 minutes"
      },
      "correct_answer": "B",
      "explanation": "A standard Pomodoro work block lasts 25 minutes.",
    },
    {
      "question": "Invalid incomplete item",
      "options": ["Only one"]
    }
  ],
}
```
Hope this helps!"""
    parsed = parse_llm_study_payload(raw)
    assert parsed is not None
    assert parsed.used_fallback_parser is True
    assert parsed.flashcards[0].front == "Pomodoro"
    assert len(parsed.quiz) == 1
    assert parsed.quiz[0].options == ["10 minutes", "25 minutes", "60 minutes", "90 minutes"]
    assert parsed.quiz[0].correct_option == "B"
    assert parsed.quiz[0].correct_index == 1


def test_parse_fallback_truncated_json():
    truncated = """{
      "summary": "HTTP is stateless.",
      "key_points": ["Request-response model"],
      "flashcards": [
        {"front": "HTTP", "back": "Hypertext Transfer Protocol"}
      ],
      "quiz": [
        {
          "question": "Which protocol is stateless?",
          "options": ["HTTP", "TCP", "SSH", "FTP"],
          "correct_option": "A",
          "correct_index": 0,
          "explanation": "HTTP does not retain session state by default."""
    parsed = parse_llm_study_payload(truncated)
    assert parsed is not None
    assert parsed.used_fallback_parser is True
    assert len(parsed.flashcards) == 1
    assert len(parsed.quiz) == 1


def test_parse_fallback_prose_blocks():
    prose = """Summary: FastAPI builds high-performance Python APIs using type hints.

Front: Pydantic
Back: Data validation library using Python type annotations.

Question: What powers FastAPI request validation?
A) Pydantic
B) Tkinter
C) Matplotlib
D) Pygame
Answer: A
Explanation: FastAPI relies on Pydantic models for validation and OpenAPI schemas."""
    parsed = parse_llm_study_payload(prose)
    assert parsed is not None
    assert parsed.used_fallback_parser is True
    assert len(parsed.flashcards) == 1
    assert len(parsed.quiz) == 1
    assert parsed.quiz[0].correct_index == 0


def test_document_extraction_txt_pdf_docx():
    txt = extract_text_from_document(
        b"Spaced repetition improves long-term memory retention significantly.",
        "lesson.md",
    )
    assert "Spaced repetition" in txt

    pdf_bytes = _make_minimal_pdf_bytes("Spaced repetition improves memory retention.")
    pdf_txt = extract_text_from_document(pdf_bytes, "notes.pdf")
    assert "Spaced repetition" in pdf_txt

    docx_bytes = _make_docx_bytes(
        ["Active recall forces retrieval from memory.", "Testing strengthens neural pathways."]
    )
    docx_txt = extract_text_from_document(docx_bytes, "chapter1.docx")
    assert "Active recall" in docx_txt

    with pytest.raises(DocumentExtractionError):
        extract_text_from_document(b"", "empty.txt")
    with pytest.raises(DocumentExtractionError):
        extract_text_from_document(b"short", "short.txt")
    with pytest.raises(DocumentExtractionError):
        extract_text_from_document(b"binary data here enough length", "archive.zip")
