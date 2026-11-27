from typing import Literal
from pydantic import BaseModel, Field


WordStatus = Literal["correct", "warning", "error"]
LegacyWordStatus = Literal["correct", "close", "wrong"]


class WordEvaluation(BaseModel):
    """Detailed phoneme-level pronunciation analysis for a single target word."""

    word: str = Field(..., description="Target word from the reference sentence.", examples=["practice"])
    score: float = Field(
        ...,
        ge=0.0,
        le=100.0,
        description="Pronunciation accuracy score (0-100) computed from phoneme Levenshtein distance.",
        examples=[85.71],
    )
    status: WordStatus = Field(
        ...,
        description="Evaluation status: 'correct' (>=80), 'warning' (50-79.99), or 'error' (<50).",
        examples=["correct"],
    )
    expected_phonemes: list[str] = Field(
        ...,
        description="Expected IPA phoneme sequence derived from NLTK CMUDict (or G2P fallback).",
        examples=[["p", "ɹ", "æ", "k", "t", "ɪ", "s"]],
    )
    user_phonemes: list[str] = Field(
        ...,
        description="Recognized IPA phoneme sequence spoken by the user (empty if the word was skipped).",
        examples=[["p", "ɹ", "æ", "k", "t", "ɪ", "s"]],
    )
    ipa: str = Field(
        default="",
        description="Formatted expected IPA string for display.",
        examples=["/pɹæktɪs/"],
    )
    expected_arpabet: list[str] = Field(
        default_factory=list,
        description="Normalized expected Arpabet phoneme sequence (stress digits stripped).",
        examples=[["P", "R", "AE", "K", "T", "IH", "S"]],
    )
    user_arpabet: list[str] = Field(
        default_factory=list,
        description="Normalized user Arpabet phoneme sequence (stress digits stripped).",
        examples=[["P", "R", "AE", "K", "T", "IH", "S"]],
    )
    matched_word: str | None = Field(
        default=None,
        description="Recognized transcript word aligned with this target word, or null if skipped.",
        examples=["practice"],
    )


class EvaluationSummary(BaseModel):
    """Aggregate counts across evaluated target words."""

    total_words: int = Field(..., ge=0, examples=[6])
    correct_count: int = Field(..., ge=0, examples=[5])
    warning_count: int = Field(..., ge=0, examples=[1])
    error_count: int = Field(..., ge=0, examples=[0])


class SpeechEvaluateResponse(BaseModel):
    """Response payload for POST /api/speech/evaluate."""

    overall_score: float = Field(
        ...,
        ge=0.0,
        le=100.0,
        description="Overall sentence pronunciation score from 0 to 100.",
        examples=[91.67],
    )
    score: float = Field(
        ...,
        ge=0.0,
        le=100.0,
        description="Alias of overall_score for mobile client compatibility.",
        examples=[91.67],
    )
    target_text: str = Field(
        ...,
        description="Reference target sentence submitted for evaluation.",
        examples=["Practice makes perfect every single day."],
    )
    transcript: str = Field(
        ...,
        description="Text recognized by ASR from the user's audio recording.",
        examples=["practice makes perfect every single day"],
    )
    words: list[WordEvaluation] = Field(
        ...,
        description="Word-by-word pronunciation breakdown with expected vs user phonemes.",
    )
    summary: EvaluationSummary = Field(
        ...,
        description="Count of correct, warning, and error words.",
    )


class LegacyWordResult(BaseModel):
    """Mobile-compatible word item for POST /api/speech/assess."""

    word: str
    ipa: str
    status: LegacyWordStatus
    score: float
    expected_phonemes: list[str]
    user_phonemes: list[str]


class SpeechAssessResponse(BaseModel):
    """Backward-compatible response payload for POST /api/speech/assess."""

    score: float = Field(..., ge=0.0, le=100.0)
    overall_score: float = Field(..., ge=0.0, le=100.0)
    transcript: str
    words: list[LegacyWordResult]


class HealthResponse(BaseModel):
    """Service health status."""

    status: str = Field(..., examples=["ok"])
    cmudict_loaded: bool = Field(..., examples=[True])
    cmudict_entries: int = Field(..., examples=[134373])
    whisper_model: str = Field(..., examples=["base.en"])
    whisper_loaded: bool = Field(..., examples=[False])
