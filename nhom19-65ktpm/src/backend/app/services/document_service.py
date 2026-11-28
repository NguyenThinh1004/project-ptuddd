import io
from pathlib import Path
import re

from docx import Document
from pypdf import PdfReader

SUPPORTED_DOCUMENT_EXTENSIONS: frozenset[str] = frozenset({
    ".txt",
    ".md",
    ".pdf",
    ".docx",
})


class DocumentExtractionError(ValueError):
    """Raised when an uploaded study document cannot be validated or extracted."""


def _clean_extracted_text(raw: str, max_chars: int) -> str:
    text = re.sub(r"\r\n?", "\n", raw)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text).strip()
    if len(text) > max_chars:
        text = text[:max_chars].rstrip()
    return text


def extract_text_from_document(
    file_bytes: bytes,
    filename: str | None,
    max_chars: int = 40000,
) -> str:
    """Extract readable lesson text from TXT, MD, PDF, or DOCX bytes."""
    if not file_bytes:
        raise DocumentExtractionError("Tệp tài liệu rỗng (0 bytes).")

    ext = Path(filename or "").suffix.lower()
    if ext not in SUPPORTED_DOCUMENT_EXTENSIONS:
        supported = ", ".join(sorted(SUPPORTED_DOCUMENT_EXTENSIONS))
        raise DocumentExtractionError(
            f"Định dạng tài liệu '{ext or '(không có đuôi)'}' chưa hỗ trợ. Hỗ trợ: {supported}."
        )

    extracted = ""
    try:
        if ext in {".txt", ".md"}:
            try:
                extracted = file_bytes.decode("utf-8")
            except UnicodeDecodeError:
                extracted = file_bytes.decode("latin-1")
        elif ext == ".pdf":
            reader = PdfReader(io.BytesIO(file_bytes))
            pages_text = [page.extract_text() or "" for page in reader.pages]
            extracted = "\n\n".join(part for part in pages_text if part.strip())
        elif ext == ".docx":
            doc = Document(io.BytesIO(file_bytes))
            parts: list[str] = [p.text for p in doc.paragraphs if p.text.strip()]
            for table in doc.tables:
                for row in table.rows:
                    row_cells = [cell.text.strip() for cell in row.cells if cell.text.strip()]
                    if row_cells:
                        parts.append(" | ".join(row_cells))
            extracted = "\n".join(parts)
    except DocumentExtractionError:
        raise
    except Exception as exc:
        raise DocumentExtractionError(f"Không thể đọc nội dung tài liệu '{filename}': {exc}") from exc

    cleaned = _clean_extracted_text(extracted, max_chars=max_chars)
    if len(cleaned) < 20:
        raise DocumentExtractionError(
            "Nội dung trích xuất từ tài liệu quá ngắn hoặc không chứa văn bản đọc được."
        )
    return cleaned
