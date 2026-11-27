from dataclasses import dataclass
from typing import Sequence

from app.schemas.speech import EvaluationSummary, SpeechEvaluateResponse, WordEvaluation, WordStatus
from app.services.phoneme_service import (
    PhonemeDictionary,
    arpabet_to_ipa_tokens,
    format_ipa,
    normalize_arpabet,
    tokenize_words,
)


def levenshtein_distance(seq1: Sequence[str], seq2: Sequence[str]) -> int:
    """Compute exact Levenshtein edit distance between two phoneme sequences."""
    len1, len2 = len(seq1), len(seq2)
    if len1 == 0:
        return len2
    if len2 == 0:
        return len1

    prev = list(range(len2 + 1))
    for i, token1 in enumerate(seq1, start=1):
        curr = [i]
        for j, token2 in enumerate(seq2, start=1):
            cost = 0 if token1 == token2 else 1
            curr.append(min(curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost))
        prev = curr
    return prev[len2]


def phoneme_similarity(seq1: Sequence[str], seq2: Sequence[str]) -> float:
    """Return normalized similarity in [0.0, 1.0] from Levenshtein distance."""
    max_len = max(len(seq1), len(seq2))
    if max_len == 0:
        return 1.0
    dist = levenshtein_distance(seq1, seq2)
    return max(0.0, 1.0 - (dist / max_len))


@dataclass(frozen=True)
class PronunciationMatch:
    similarity: float
    distance: int
    expected_raw: list[str]
    expected_norm: list[str]
    user_raw: list[str]
    user_norm: list[str]


def best_variant_match(
    target_variants: list[list[str]],
    user_variants: list[list[str]],
) -> PronunciationMatch:
    """Pick the (target, user) CMUDict variant pair with minimum phoneme Levenshtein distance."""
    if not target_variants and not user_variants:
        return PronunciationMatch(1.0, 0, [], [], [], [])
    if not target_variants:
        u_raw = user_variants[0]
        u_norm = normalize_arpabet(u_raw)
        return PronunciationMatch(0.0, len(u_norm), [], [], u_raw, u_norm)
    if not user_variants:
        t_raw = target_variants[0]
        t_norm = normalize_arpabet(t_raw)
        return PronunciationMatch(0.0, len(t_norm), t_raw, t_norm, [], [])

    best: PronunciationMatch | None = None
    for t_raw in target_variants:
        t_norm = normalize_arpabet(t_raw)
        for u_raw in user_variants:
            u_norm = normalize_arpabet(u_raw)
            dist = levenshtein_distance(t_norm, u_norm)
            sim = phoneme_similarity(t_norm, u_norm)
            candidate = PronunciationMatch(sim, dist, t_raw, t_norm, u_raw, u_norm)
            if best is None or (sim, -dist) > (best.similarity, -best.distance):
                best = candidate
    assert best is not None
    return best


def classify_score(score: float) -> WordStatus:
    """Map numeric 0-100 score to status ('correct' | 'warning' | 'error')."""
    if score >= 80.0:
        return "correct"
    if score >= 50.0:
        return "warning"
    return "error"


def align_word_sequences(
    target_tokens: list[str],
    spoken_tokens: list[str],
    dictionary: PhonemeDictionary,
) -> list[tuple[str, str | None, PronunciationMatch]]:
    """
    Align target words with recognized transcript words using Needleman-Wunsch
    scored by phoneme similarity, returning one entry per target word.
    """
    n = len(target_tokens)
    m = len(spoken_tokens)
    target_pron = [dictionary.get_pronunciations(w) for w in target_tokens]
    spoken_pron = [dictionary.get_pronunciations(w) for w in spoken_tokens]

    if n == 0:
        return []
    if m == 0:
        return [
            (
                target_tokens[i],
                None,
                best_variant_match(target_pron[i], []),
            )
            for i in range(n)
        ]

    gap_penalty = -0.35
    match_cache: dict[tuple[int, int], PronunciationMatch] = {}

    def subst_score(i: int, j: int) -> float:
        match = best_variant_match(target_pron[i], spoken_pron[j])
        match_cache[(i, j)] = match
        # Exact word spelling bonus breaks ties between homophones or identical tokens.
        exact_bonus = 0.1 if target_tokens[i].lower() == spoken_tokens[j].lower() else 0.0
        return match.similarity * 2.0 - 0.5 + exact_bonus

    dp: list[list[float]] = [[0.0] * (m + 1) for _ in range(n + 1)]
    back: list[list[str]] = [[""] * (m + 1) for _ in range(n + 1)]

    for i in range(1, n + 1):
        dp[i][0] = i * gap_penalty
        back[i][0] = "U"  # Target word skipped (deletion)
    for j in range(1, m + 1):
        dp[0][j] = j * gap_penalty
        back[0][j] = "L"  # Extra spoken word (insertion)

    for i in range(1, n + 1):
        for j in range(1, m + 1):
            diag = dp[i - 1][j - 1] + subst_score(i - 1, j - 1)
            up = dp[i - 1][j] + gap_penalty
            left = dp[i][j - 1] + gap_penalty
            if diag >= up and diag >= left:
                dp[i][j] = diag
                back[i][j] = "D"
            elif up >= left:
                dp[i][j] = up
                back[i][j] = "U"
            else:
                dp[i][j] = left
                back[i][j] = "L"

    aligned_reversed: list[tuple[str, str | None, PronunciationMatch]] = []
    i, j = n, m
    while i > 0 or j > 0:
        move = back[i][j]
        if move == "D":
            aligned_reversed.append(
                (target_tokens[i - 1], spoken_tokens[j - 1], match_cache[(i - 1, j - 1)])
            )
            i -= 1
            j -= 1
        elif move == "U":
            aligned_reversed.append(
                (target_tokens[i - 1], None, best_variant_match(target_pron[i - 1], []))
            )
            i -= 1
        else:
            j -= 1

    aligned_reversed.reverse()
    return aligned_reversed


def evaluate_pronunciation(
    target_text: str,
    transcript: str,
    dictionary: PhonemeDictionary,
) -> SpeechEvaluateResponse:
    """Compare target sentence and user transcript at word & phoneme granularity."""
    target_tokens = tokenize_words(target_text)
    spoken_tokens = tokenize_words(transcript)

    aligned = align_word_sequences(target_tokens, spoken_tokens, dictionary)
    word_results: list[WordEvaluation] = []
    counts = {"correct": 0, "warning": 0, "error": 0}

    for target_word, matched_word, match in aligned:
        score = round(match.similarity * 100.0, 2) if matched_word is not None else 0.0
        status = classify_score(score)
        counts[status] += 1

        expected_ipa = arpabet_to_ipa_tokens(match.expected_raw)
        user_ipa = arpabet_to_ipa_tokens(match.user_raw) if matched_word is not None else []

        word_results.append(
            WordEvaluation(
                word=target_word,
                score=score,
                status=status,
                expected_phonemes=expected_ipa,
                user_phonemes=user_ipa,
                ipa=format_ipa(expected_ipa),
                expected_arpabet=match.expected_norm,
                user_arpabet=match.user_norm if matched_word is not None else [],
                matched_word=matched_word,
            )
        )

    overall_score = (
        round(sum(item.score for item in word_results) / len(word_results), 2)
        if word_results
        else 0.0
    )

    return SpeechEvaluateResponse(
        overall_score=overall_score,
        score=overall_score,
        target_text=target_text.strip(),
        transcript=transcript.strip(),
        words=word_results,
        summary=EvaluationSummary(
            total_words=len(word_results),
            correct_count=counts["correct"],
            warning_count=counts["warning"],
            error_count=counts["error"],
        ),
    )
