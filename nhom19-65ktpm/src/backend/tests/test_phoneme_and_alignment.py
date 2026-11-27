from app.services.alignment_service import (
    best_variant_match,
    classify_score,
    evaluate_pronunciation,
    levenshtein_distance,
)
from app.services.phoneme_service import (
    PhonemeDictionary,
    arpabet_to_ipa_tokens,
    format_ipa,
    normalize_arpabet,
)


def test_arpabet_to_ipa_and_stress_handling():
    raw = ["P", "R", "AE1", "K", "T", "AH0", "S"]
    assert normalize_arpabet(raw) == ["P", "R", "AE", "K", "T", "AH", "S"]
    ipa = arpabet_to_ipa_tokens(raw)
    assert ipa == ["p", "ɹ", "æ", "k", "t", "ə", "s"]
    assert format_ipa(ipa) == "/pɹæktəs/"


def test_cmudict_lookup_and_oov_fallback():
    dictionary = PhonemeDictionary()
    assert dictionary.entry_count > 100000

    practice_variants = dictionary.get_pronunciations("practice")
    assert practice_variants
    assert normalize_arpabet(practice_variants[0]) == ["P", "R", "AE", "K", "T", "AH", "S"]
    assert dictionary.get_primary_ipa("practice") == (
        ["p", "ɹ", "æ", "k", "t", "ə", "s"],
        "/pɹæktəs/",
    )

    # Out-of-vocabulary word should still yield non-empty phonemes via g2p_en / heuristic.
    oov_variants = dictionary.get_pronunciations("studymate")
    assert oov_variants and len(oov_variants[0]) >= 3


def test_levenshtein_and_best_variant_selection():
    assert levenshtein_distance(["TH", "IH", "NG", "K"], ["S", "IH", "NG", "K"]) == 1

    # "read" has two CMUDict variants: /ɹid/ (R IY D) and /ɹɛd/ (R EH D)
    dictionary = PhonemeDictionary()
    read_variants = dictionary.get_pronunciations("read")
    red_variants = dictionary.get_pronunciations("red")

    match = best_variant_match(read_variants, red_variants)
    assert match.similarity == 1.0
    assert match.expected_norm == ["R", "EH", "D"]


def test_evaluate_pronunciation_exact_match():
    dictionary = PhonemeDictionary()
    res = evaluate_pronunciation(
        target_text="Practice makes perfect.",
        transcript="practice makes perfect",
        dictionary=dictionary,
    )

    assert res.overall_score == 100.0
    assert res.score == 100.0
    assert res.summary.total_words == 3
    assert res.summary.correct_count == 3
    assert res.summary.warning_count == 0
    assert res.summary.error_count == 0
    assert all(w.status == "correct" for w in res.words)
    assert all(w.expected_phonemes == w.user_phonemes for w in res.words)


def test_evaluate_pronunciation_warning_and_skipped_word():
    dictionary = PhonemeDictionary()

    # "think" -> /θɪŋk/ vs "sink" -> /sɪŋk/ => 3/4 phonemes match => 75.0 (warning)
    res_warn = evaluate_pronunciation(
        target_text="think big",
        transcript="sink big",
        dictionary=dictionary,
    )
    assert res_warn.words[0].word == "think"
    assert res_warn.words[0].matched_word == "sink"
    assert res_warn.words[0].score == 75.0
    assert res_warn.words[0].status == "warning"
    assert res_warn.words[1].status == "correct"
    assert res_warn.overall_score == 87.5

    # Skipped middle word should align outer words properly and mark middle word as error
    res_skip = evaluate_pronunciation(
        target_text="practice makes perfect",
        transcript="practice perfect",
        dictionary=dictionary,
    )
    assert [w.status for w in res_skip.words] == ["correct", "error", "correct"]
    assert res_skip.words[1].word == "makes"
    assert res_skip.words[1].matched_word is None
    assert res_skip.words[1].user_phonemes == []
    assert res_skip.words[1].score == 0.0
    assert res_skip.overall_score == 66.67


def test_evaluate_pronunciation_extra_spoken_word_handled():
    dictionary = PhonemeDictionary()
    res = evaluate_pronunciation(
        target_text="hello world",
        transcript="um hello world",
        dictionary=dictionary,
    )
    assert res.overall_score == 100.0
    assert [w.matched_word for w in res.words] == ["hello", "world"]


def test_classify_score_thresholds():
    assert classify_score(80.0) == "correct"
    assert classify_score(79.99) == "warning"
    assert classify_score(50.0) == "warning"
    assert classify_score(49.99) == "error"
    assert classify_score(0.0) == "error"
