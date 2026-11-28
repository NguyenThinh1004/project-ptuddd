import logging
import re
from functools import lru_cache
from typing import Iterable

import nltk
from nltk.corpus import cmudict

logger = logging.getLogger(__name__)

# Complete Arpabet -> IPA table covering all 39 standard CMUDict phonemes.
# Stress-sensitive entries (AH0 -> ə, ER0 -> ɚ) are handled before stripping stress digits.
ARPABET_TO_IPA: dict[str, str] = {
    "AA": "ɑ",
    "AE": "æ",
    "AH": "ʌ",
    "AH0": "ə",
    "AO": "ɔ",
    "AW": "aʊ",
    "AY": "aɪ",
    "B": "b",
    "CH": "tʃ",
    "D": "d",
    "DH": "ð",
    "EH": "ɛ",
    "ER": "ɝ",
    "ER0": "ɚ",
    "EY": "eɪ",
    "F": "f",
    "G": "ɡ",
    "HH": "h",
    "IH": "ɪ",
    "IY": "i",
    "JH": "dʒ",
    "K": "k",
    "L": "l",
    "M": "m",
    "N": "n",
    "NG": "ŋ",
    "OW": "oʊ",
    "OY": "ɔɪ",
    "P": "p",
    "R": "ɹ",
    "S": "s",
    "SH": "ʃ",
    "T": "t",
    "TH": "θ",
    "UH": "ʊ",
    "UW": "u",
    "V": "v",
    "W": "w",
    "Y": "j",
    "Z": "z",
    "ZH": "ʒ",
}

_LETTER_FALLBACK_ARPABET: dict[str, list[str]] = {
    "a": ["AE"],
    "b": ["B"],
    "c": ["K"],
    "d": ["D"],
    "e": ["EH"],
    "f": ["F"],
    "g": ["G"],
    "h": ["HH"],
    "i": ["IH"],
    "j": ["JH"],
    "k": ["K"],
    "l": ["L"],
    "m": ["M"],
    "n": ["N"],
    "o": ["AA"],
    "p": ["P"],
    "q": ["K"],
    "r": ["R"],
    "s": ["S"],
    "t": ["T"],
    "u": ["AH"],
    "v": ["V"],
    "w": ["W"],
    "x": ["K", "S"],
    "y": ["Y"],
    "z": ["Z"],
}

_WORD_TOKEN_RE = re.compile(r"[A-Za-z0-9]+(?:'[A-Za-z0-9]+)*")
_STRESS_RE = re.compile(r"[012]$")


def strip_stress(phoneme: str) -> str:
    """Remove trailing CMUDict lexical stress marker (0, 1, 2)."""
    return _STRESS_RE.sub("", phoneme.upper())


def normalize_arpabet(phonemes: Iterable[str]) -> list[str]:
    """Normalize a sequence of Arpabet tokens by stripping stress digits."""
    return [strip_stress(p) for p in phonemes if p and p.strip()]


def arpabet_to_ipa_tokens(phonemes: Iterable[str]) -> list[str]:
    """Convert raw Arpabet phonemes (optionally stressed) into IPA symbol tokens."""
    ipa_tokens: list[str] = []
    for raw in phonemes:
        token = raw.strip().upper()
        if not token:
            continue
        if token in ARPABET_TO_IPA:
            ipa_tokens.append(ARPABET_TO_IPA[token])
        else:
            base = strip_stress(token)
            ipa_tokens.append(ARPABET_TO_IPA.get(base, base.lower()))
    return ipa_tokens


def format_ipa(ipa_tokens: Iterable[str]) -> str:
    """Format a sequence of IPA tokens as /.../."""
    joined = "".join(ipa_tokens)
    return f"/{joined}/" if joined else ""


def tokenize_words(text: str) -> list[str]:
    """Extract English word tokens (preserving contractions) in spoken order."""
    return _WORD_TOKEN_RE.findall(text or "")


def _ensure_nltk_resource(resource_path: str, download_name: str) -> None:
    try:
        nltk.data.find(resource_path)
    except LookupError:
        logger.info("Downloading missing NLTK resource: %s", download_name)
        nltk.download(download_name, quiet=True)


class PhonemeDictionary:
    """Pronunciation dictionary backed by NLTK CMUDict with g2p-en OOV fallback."""

    def __init__(self, entries: dict[str, list[list[str]]] | None = None, enable_g2p: bool = True) -> None:
        if entries is None:
            _ensure_nltk_resource("corpora/cmudict", "cmudict")
            entries = cmudict.dict()
        self._entries: dict[str, list[list[str]]] = {
            k.lower(): v for k, v in entries.items()
        }
        self._enable_g2p = enable_g2p
        self._g2p = None

    @property
    def entry_count(self) -> int:
        return len(self._entries)

    def _get_g2p(self):
        if not self._enable_g2p:
            return None
        if self._g2p is None:
            try:
                _ensure_nltk_resource("taggers/averaged_perceptron_tagger_eng", "averaged_perceptron_tagger_eng")
                _ensure_nltk_resource("corpora/cmudict", "cmudict")
                from g2p_en import G2p

                self._g2p = G2p()
            except Exception as exc:  # pragma: no cover - defensive fallback
                logger.warning("Could not initialize g2p_en, falling back to letter heuristic: %s", exc)
                self._enable_g2p = False
                return None
        return self._g2p

    def _g2p_fallback(self, word: str) -> list[str]:
        g2p = self._get_g2p()
        if g2p is not None:
            try:
                raw_phones = g2p(word)
                phones = [
                    p.strip().upper()
                    for p in raw_phones
                    if p and p.strip() and re.match(r"^[A-Za-z]+[012]?$", p.strip())
                ]
                if phones:
                    return phones
            except Exception as exc:  # pragma: no cover - defensive fallback
                logger.warning("g2p_en failed for %r: %s", word, exc)

        # Deterministic letter-by-letter fallback so OOV words never return empty phonemes.
        fallback: list[str] = []
        for ch in word.lower():
            if ch in _LETTER_FALLBACK_ARPABET:
                fallback.extend(_LETTER_FALLBACK_ARPABET[ch])
        return fallback

    def get_pronunciations(self, word: str) -> list[list[str]]:
        """Return candidate Arpabet phoneme sequences (including stress digits when from CMUDict)."""
        cleaned = re.sub(r"[^a-zA-Z0-9']", "", word).lower()
        if not cleaned:
            return []

        if cleaned in self._entries:
            return self._entries[cleaned]

        # Handle simple possessive / apostrophe forms like "student's" if base is present.
        if cleaned.endswith("'s") and cleaned[:-2] in self._entries:
            return [variant + ["Z"] for variant in self._entries[cleaned[:-2]]]

        fallback = self._g2p_fallback(cleaned)
        return [fallback] if fallback else []

    def get_primary_ipa(self, word: str) -> tuple[list[str], str]:
        """Return (ipa_tokens, formatted_ipa_string) for a single word."""
        variants = self.get_pronunciations(word)
        if not variants:
            return [], ""
        ipa_tokens = arpabet_to_ipa_tokens(variants[0])
        return ipa_tokens, format_ipa(ipa_tokens)


@lru_cache
def get_phoneme_dictionary() -> PhonemeDictionary:
    """Return process-wide cached PhonemeDictionary instance."""
    return PhonemeDictionary()
