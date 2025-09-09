import os
import json
import re
import hashlib
import requests
import logging
import asyncio
from pathlib import Path
from typing import List
import threading

# Ensure environment variables are loaded regardless of how the module is executed
try:  # pragma: no cover - exercised via integration
    from .. import config as _config  # type: ignore
except Exception:  # pragma: no cover - direct execution fallback
    import importlib.util

    _config_path = Path(__file__).resolve().parents[1] / "config.py"
    spec = importlib.util.spec_from_file_location("app.config", _config_path)
    _config = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(_config)

from providers import replicate_provider

# Anthropic
import anthropic

# OpenAI (python >=1.x)
from openai import OpenAI

try:
    import tiktoken  # type: ignore
except Exception:  # pragma: no cover - optional dependency
    tiktoken = None

DEFAULT_ANTHROPIC_MODEL = os.getenv("ANTHROPIC_MODEL", "claude-3-5-sonnet-latest")
DEFAULT_OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

logger = logging.getLogger(__name__)

# ---- ENV defaults ----
OSS_BASE = (os.getenv("OSS_API_BASE") or "http://llm:11434/v1").rstrip(
    "/"
)  # must include /v1
OSS_MODEL = os.getenv("OSS_MODEL", "gpt-oss-20b")
TIMEOUT_S = float(os.getenv("LLM_HTTP_TIMEOUT", "60"))

MAX_MODEL_TOKENS = 200_000

# ---- Robust JSON extraction helpers ----
_JSON_TAG = re.compile(r"<json>\s*(\{.*?\})\s*</json>", re.DOTALL)


def _first_json_block(s: str) -> str | None:
    if not s:
        return None
    start = s.find("{")
    if start == -1:
        return None
    depth = 0
    for i in range(start, len(s)):
        c = s[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return s[start : i + 1]
    end = s.rfind("}")
    return s[start : end + 1] if end > start else None


def _extract_json_obj(text: str):
    if not text:
        return {}
    m = _JSON_TAG.search(text)
    if m:
        cand = m.group(1)
        try:
            return json.loads(cand)
        except Exception:
            return {}
    try:
        return json.loads(text.strip())
    except Exception:
        cand = _first_json_block(text)
        if not cand:
            return {}
        try:
            return json.loads(cand)
        except Exception:
            return {}


def _term_in_chunk(term_low: str, chunk_low: str) -> bool:
    """Fuzzy presence check of ``term_low`` inside ``chunk_low``."""
    if re.search(rf"\b{re.escape(term_low)}\b", chunk_low):
        return True
    if term_low.replace("-", " ") in chunk_low:
        return True
    if term_low.endswith("s") and term_low[:-1] in chunk_low:
        return True
    return False


def _norm(s: str) -> str:
    return " ".join((s or "").strip().lower().split())


try:  # pragma: no cover - optional dependency
    from rapidfuzz import fuzz  # type: ignore

    def _near_dup(a: str, b: str) -> bool:
        return fuzz.token_set_ratio(_norm(a), _norm(b)) >= 88

except Exception:  # pragma: no cover - fallback

    def _near_dup(a: str, b: str) -> bool:
        A, B = set(_norm(a).split()), set(_norm(b).split())
        inter = len(A & B)
        denom = max(1, min(len(A), len(B)))
        return inter / denom >= 0.8

# Remove headings like "**Summary**" from definitions
_HDR_RE = re.compile(r"^\s*\*\*(summary|overview|resumen|introducción)\*\*\s*[:-]?\s*", re.I)


def _clean_def(s: str) -> str:
    s = s or ""
    s = _HDR_RE.sub("", s).strip()
    return s

# Thread-safe deduplicator for flashcards and quiz questions


class FlashcardDeduplicator:
    def __init__(self):
        self.seen_terms: set[str] = set()
        self.seen_definitions: list[str] = []
        self.seen_quiz_questions: set[str] = set()
        self._lock = threading.Lock()

    def clear(self):
        with self._lock:
            self.seen_terms.clear()
            self.seen_definitions.clear()
            self.seen_quiz_questions.clear()

    def is_term_seen(self, term: str) -> bool:
        with self._lock:
            return _norm(term) in self.seen_terms

    def add_term(self, term: str):
        with self._lock:
            self.seen_terms.add(_norm(term))

    def is_definition_duplicate(self, definition: str) -> bool:
        with self._lock:
            return any(_near_dup(definition, seen) for seen in self.seen_definitions)

    def add_definition(self, definition: str):
        with self._lock:
            self.seen_definitions.append(definition)

    def is_question_seen(self, question: str) -> bool:
        with self._lock:
            return _norm(question) in self.seen_quiz_questions

    def add_question(self, question: str):
        with self._lock:
            self.seen_quiz_questions.add(_norm(question))


_deduplicator = FlashcardDeduplicator()

# Minimal English stopword list for term extraction
_STOPWORDS = {
    "the",
    "and",
    "for",
    "that",
    "with",
    "this",
    "from",
    "are",
    "was",
    "were",
    "such",
    "into",
    "then",
    "than",
    "some",
    "other",
    "their",
    "about",
    "there",
    "would",
    "could",
    "should",
    "over",
    "under",
    "while",
    "where",
    "have",
    "has",
    "had",
    "any",
    "each",
    "more",
    "most",
    "many",
    "much",
    "very",
    "may",
    "might",
    "can",
    "will",
}

# expanded stopwords (all lowercase)
_STOPWORDS |= {
    "of","in","on","at","by","to","as","is","be","an","or","if","it","its",
    "from","than","via","per","within","into","up","down","about","across",
    "after","before","during","against","without","between","over","under",
    "and","the","a","this","that","these","those",
    # spanish
    "el","la","los","las","un","una","unos","unas","de","del","al","en","y","o",
    "con","sin","para","por","según","entre","sobre","hasta","desde","que","como",
    "esto","esta","estos","estas","ese","esa","eso","esas","esos"
}

# never allow these as terms (generic sections / boilerplate)
_TERM_BLOCKLIST = _TERM_BLOCKLIST if "_TERM_BLOCKLIST" in globals() else set()
_TERM_BLOCKLIST |= {
    "summary","abstract","introduction","intro","overview","conclusion",
    "appendix","references","bibliography","index",
    "resumen","sumario","introducción","conclusión","apéndice","referencias","bibliografía","índice",
    # frequent trivial connectors
    "with","from","that","which","such","including"
}

# Per-request tracking of accepted flashcard terms
_SEEN_FLASHCARD_TERMS: set[str] = set()


def extract_terms_from_text(text: str, target_count: int = 12) -> list[str]:
    """
    Select up to `target_count` candidate terms (1–3 tokens).
    Scoring: frequency (+ extra weight in heading lines starting with '#'),
             prefer bi/tri-grams over unigrams when both exist.
    Filters: expanded stopwords + blocklist, acronym allowance, dedupe and
             prefer the longer overlapping phrase (e.g., 'machine learning' wins over 'machine').
    """
    import re, difflib
    from collections import Counter

    lines = text.splitlines()
    is_heading = [ln.strip().startswith("#") for ln in lines]
    token_lines = [re.findall(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ][A-Za-z0-9\-ÁÉÍÓÚÜÑáéíóúüñ]+", ln) for ln in lines]

    def _ok_uni(tok: str) -> bool:
        low = tok.lower()
        if low in _STOPWORDS or low in _TERM_BLOCKLIST:
            return False
        if len(low) <= 3 and not tok.isupper():  # allow acronyms like TCP, DNA
            return False
        return True

    uni = Counter(); bi = Counter(); tri = Counter()
    for hdr, toks in zip(is_heading, token_lines):
        w = 2 if hdr else 1
        lt = [t for t in toks if _ok_uni(t)]
        # unigrams
        for t in lt:
            uni[t.lower()] += w
        # bigrams
        for i in range(len(lt)-1):
            a, b = lt[i].lower(), lt[i+1].lower()
            if a in _STOPWORDS or b in _STOPWORDS:
                continue
            bi[f"{a} {b}"] += w
        # trigrams
        for i in range(len(lt)-2):
            a,b,c = lt[i].lower(), lt[i+1].lower(), lt[i+2].lower()
            if any(x in _STOPWORDS for x in (a,b,c)):
                continue
            tri[f"{a} {b} {c}"] += w

    def _boost(counter, factor: float):
        return {k: v*factor for k,v in counter.items()}

    scores = {}
    scores.update(_boost(uni, 1.0))
    scores.update(_boost(bi, 1.6))
    scores.update(_boost(tri, 2.2))

    # rank
    candidates = sorted(scores.items(), key=lambda kv: (-kv[1], -len(kv[0])))
    chosen: list[str] = []
    for term, _ in candidates:
        words = term.split()
        if any(w in _TERM_BLOCKLIST for w in words):
            continue
        if all(w in _STOPWORDS for w in words):
            continue
        # prefer longer overlapping phrase
        if any(term in c or c in term for c in chosen):
            longer = max([term] + [c for c in chosen if term in c], key=len)
            chosen = [longer if (c in longer) else c for c in chosen]
            continue
        # fuzzy overlap vs chosen
        if any(difflib.SequenceMatcher(a=term, b=c).ratio() > 0.86 for c in chosen):
            continue
        chosen.append(term)
        if len(chosen) >= target_count:
            break
    return chosen


FLASHCARDS_GUIDED_PROMPT = """You are a precise study-writer.
Define EXACTLY {n} DISTINCT terms from the text below.
Rules:
- Use ONLY the provided TERMS; do not add, merge or split them.
- Ignore generic words (e.g., summary, introduction).
- Definitions must be ≥ 20 words, specific to THIS text.
- No commentary, no markdown.
Return ONLY JSON inside <json> tags:
<json>
{{"flashcards":[{{"term":"...","definition":"..."}}]}}
</json>

TERMS:
{term_bullets}

TEXT:
\"\"\"{chunk}\"\"\"
"""


def generate_flashcards_guided(chunk: str, terms: list[str]) -> list[dict]:
    """Ask the LLM to define the supplied ``terms`` within ``chunk``."""

    logger.debug("generate_flashcards_guided received %d terms", len(terms))
    if not terms:
        return []

    prompt = FLASHCARDS_GUIDED_PROMPT.format(
        n=len(terms),
        term_bullets="\n".join(f"- {t}" for t in terms),
        chunk=chunk,
    )
    raw = ask_llm(
        prompt,
        max_tokens=2000,
        temperature=0.25,
        top_p=0.8,
        repetition_penalty=1.12,
    )
    data = _extract_json_obj(raw)
    items = data.get("flashcards") or []
    return items


def retry_define_terms(
    chunk_text: str, missing_terms: list[str], existing_defs: list[str]
) -> list[dict]:
    if not missing_terms:
        return []
    prompt = f'''You previously defined some terms but a few were too short or duplicated.
Create EXACTLY {len(missing_terms)} NEW definitions that do not overlap with the existing ones.
Return ONLY JSON inside <json> tags:
<json>
{{"flashcards":[{{"term":"...","definition":"..."}}]}}
</json>

EXISTING DEFINITIONS (first 20 words each):
{chr(10).join("- "+d[:160] for d in existing_defs)}

TERMS TO DEFINE:
{chr(10).join("- "+t for t in missing_terms)}

TEXT:
"""{chunk_text}"""
'''
    raw = ask_llm(
        prompt,
        max_tokens=1200,
        temperature=0.28,
        top_p=0.8,
        repetition_penalty=1.12,
    )
    data = _extract_json_obj(raw)
    return data.get("flashcards") or []


def get_llm_provider(preferred_provider: str = "replicate") -> str:
    """Return an available provider, falling back to OpenAI when needed."""
    if preferred_provider == "replicate":
        try:
            if not os.getenv("REPLICATE_API_KEY") and not os.getenv(
                "REPLICATE_API_TOKEN"
            ):
                print("Replicate API key not found, falling back to OpenAI")
                return "openai"
            return "replicate"
        except Exception as e:
            print(f"Replicate provider failed: {e}, using OpenAI fallback")
            return "openai"
    return preferred_provider


def _normalize_provider(name: str) -> str:
    n = (name or "").strip().lower()
    aliases = {
        "openai": "openai",
        "gpt": "openai",
        "gpt-4": "openai",
        "gpt-4o": "openai",
        "local": "llamacpp",
        "llama.cpp": "llamacpp",
        "gguf": "llamacpp",
        # Remotos/OSS:
        "replicate": "replicate",
        "remote": "oss",
        "backend": "oss",
        "oss": "oss",
    }
    return aliases.get(n, n)


# usa prompts existentes si están definidos, si no deja lista vacía
OPENAI_DEEP_PROMPTS = globals().get("OPENAI_DEEP_PROMPTS", [])
LLAMACPP_DEEP_PROMPTS = globals().get("LLAMACPP_DEEP_PROMPTS", [])
GENERIC_DEEP_PROMPTS = globals().get("OPENAI_DEEP_PROMPTS", []) or []


def build_deep_prompts(provider: str):
    p = _normalize_provider(provider)
    try:
        if p == "openai":
            return OPENAI_DEEP_PROMPTS
        if p == "llamacpp":
            return LLAMACPP_DEEP_PROMPTS
        if p == "oss" or p == "replicate":
            return GENERIC_DEEP_PROMPTS
        logger.warning("Unknown LLM provider: %s; using generic prompts", provider)
        return GENERIC_DEEP_PROMPTS
    except Exception:
        logger.exception(
            "Deep prompts build failed; using generic. provider=%s", provider
        )
        return GENERIC_DEEP_PROMPTS


def _encoding():
    """Return tiktoken encoding for the active model if available."""
    if not tiktoken:
        return None
    provider = (os.getenv("LLM_PROVIDER") or "anthropic").lower()
    if provider == "openai":
        model = os.getenv("OPENAI_MODEL", DEFAULT_OPENAI_MODEL)
    else:
        model = os.getenv("ANTHROPIC_MODEL", DEFAULT_ANTHROPIC_MODEL)
    try:
        return tiktoken.encoding_for_model(model)
    except Exception:
        return tiktoken.get_encoding("cl100k_base")


def estimate_tokens(text: str) -> int:
    """Estimate token count for text using tiktoken when possible."""
    enc = _encoding()
    if enc:
        try:
            return len(enc.encode(text))
        except Exception:
            pass
    # Fallback rough estimate (4 chars per token)
    return max(1, len(text) // 4)


def truncate_text_to_tokens(text: str, max_tokens: int) -> str:
    """Truncate text to the given number of tokens."""
    if estimate_tokens(text) <= max_tokens:
        return text
    enc = _encoding()
    if enc:
        tokens = enc.encode(text)[:max_tokens]
        return enc.decode(tokens)
    words = text.split()
    result = []
    count = 0
    for w in words:
        token_len = estimate_tokens(w + " ")
        if count + token_len > max_tokens:
            break
        result.append(w)
        count += token_len
    return " ".join(result)


def split_text_into_chunks(text: str, max_tokens: int = 10_000):
    """Split text into chunks each under `max_tokens` tokens."""
    if estimate_tokens(text) <= max_tokens:
        return [text]
    words = text.split()
    chunks = []
    current = []
    count = 0
    for w in words:
        tlen = estimate_tokens(w + " ")
        if tlen > max_tokens:
            raise ValueError("Token limit too small for given text")
        if count + tlen > max_tokens:
            chunks.append(" ".join(current))
            current = [w]
            count = tlen
        else:
            current.append(w)
            count += tlen
    if current:
        chunks.append(" ".join(current))
    return chunks


def _anthropic_ask(prompt: str, **_: dict) -> str:
    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    resp = client.messages.create(
        model=os.getenv("ANTHROPIC_MODEL", "claude-3-5-sonnet-latest"),
        max_tokens=1200,
        messages=[{"role": "user", "content": prompt}],
    )
    # Concatenate text blocks
    chunks: List[str] = []
    for part in getattr(resp, "content", []) or []:
        if getattr(part, "type", None) == "text":
            chunks.append(getattr(part, "text", ""))
    return "".join(chunks).strip()


def _openai_ask(prompt: str, **_: dict) -> str:
    client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
    resp = client.chat.completions.create(
        model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
        messages=[{"role": "user", "content": prompt}],
        temperature=0.2,
    )
    return resp.choices[0].message.content.strip()


def _oss_ask(prompt: str, **params) -> str:
    '''
    Call Ollama's OpenAI-compatible endpoint /v1/chat/completions.
    Do NOT call native paths like /api/chat.
    '''
    url = f"{OSS_BASE}/chat/completions"  # e.g., http://llm:11434/v1/chat/completions
    payload = {
        "model": OSS_MODEL,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": params.get("temperature", 0.2),
    }
    resp = requests.post(url, json=payload, timeout=TIMEOUT_S)
    resp.raise_for_status()
    data = resp.json()
    return data["choices"][0]["message"]["content"].strip()


def _replicate_ask(prompt: str, **params) -> str:
    loop = asyncio.new_event_loop()
    try:
        return loop.run_until_complete(replicate_provider.complete(prompt, **params))
    finally:
        loop.close()


def ask_llm(prompt: str, **params) -> str:
    """
    Main entrypoint. Use OSS by default; if it fails and a fallback is configured,
    try the fallback provider (OpenAI/Anthropic).
    """
    provider = get_llm_provider(os.getenv("LLM_PROVIDER") or "oss")

    try:
        if provider == "oss":
            return _oss_ask(prompt, **params)
        elif provider == "openai":
            return _openai_ask(prompt, **params)  # existing function
        elif provider == "anthropic":
            return _anthropic_ask(prompt, **params)  # existing function
        elif provider == "replicate":
            return _replicate_ask(prompt, **params)
        else:
            raise ValueError(f"Unknown LLM provider: {provider}")
    except Exception as e:
        # Optional fallback
        fb = get_llm_provider(os.getenv("LLM_FALLBACK_PROVIDER") or "")
        if fb == "openai":
            return _openai_ask(prompt)
        if fb == "anthropic":
            return _anthropic_ask(prompt)
        if fb == "replicate":
            return _replicate_ask(prompt)
        raise


def make_deep_prompts(text: str) -> list[dict]:
    """Generate reflective prompts for the provided text using the active LLM.

    The model is instructed to respond **only** with a JSON array of objects
    having the shape ``{"prompt": string, "hint": string?}``.  Any parse
    failure results in an empty list so callers can safely ignore errors.

    Notes:
        This helper intentionally truncates input to keep token counts small
        and responses fast/deterministic.
    """

    snippet = truncate_text_to_tokens(text, 800)
    prompt = (
        "You are an expert tutor. Craft 5-8 reflective prompts to deepen "
        "understanding of the following material. Respond ONLY with a JSON "
        "array of objects where each object has 'prompt' and optional 'hint' "
        "fields.\n\n" + snippet
    )

    try:
        raw = ask_llm(prompt)
        data = _extract_json_obj(raw)
        if isinstance(data, dict):
            data = data.get("deep_prompts") or data.get("prompts") or []
        if not isinstance(data, list):
            return []
        results: list[dict] = []
        for item in data:
            if isinstance(item, dict):
                p = (item.get("prompt") or item.get("text") or "").strip()
                if not p:
                    continue
                obj = {"prompt": p}
                h = (item.get("hint") or item.get("explanation") or "").strip()
                if h:
                    obj["hint"] = h
                results.append(obj)
            elif isinstance(item, str) and item.strip():
                results.append({"prompt": item.strip()})
        return results
    except Exception as exc:  # pragma: no cover - parsing is best effort
        logger.warning("Failed to parse deep prompts: %s", exc)
        return []


# --- New helpers for scalable item generation ---


def tokenize_words(text: str) -> list[str]:
    """Very small word tokenizer based on whitespace."""
    return [w for w in text.replace("\n", " ").split() if w]


def compute_targets(text: str) -> dict[str, int]:
    """Return study item targets from environment variables.

    Values are taken from environment variables loaded via :mod:`app.config`.
    When a variable is missing and a default value is used a warning is logged.
    """

    mappings = {
        "FLASHCARD_TARGET": ("flashcards", 12),
        "QUIZ_TARGET": ("quiz", 14),
        "DEEP_TARGET": ("deep_prompts", 8),
        "CLOZE_TARGET": ("cloze", 10),
    }

    targets: dict[str, int] = {}
    for env_var, (key, default) in mappings.items():
        value = os.getenv(env_var)
        if value is None:
            logger.warning("%s not set, using default %s", env_var, default)
            value = default
        targets[key] = int(value)

    logger.info(
        "compute_targets resolved FLASHCARD_TARGET=%s QUIZ_TARGET=%s",
        targets.get("flashcards"),
        targets.get("quiz"),
    )

    return targets


def chunk_text(
    text: str, size: int = 200, *, dedup_threshold: float = 0.9
) -> list[str]:
    """Split text into sentence-based chunks and drop near duplicates.

    Parameters
    ----------
    text:
        Input text to split.
    size:
        Maximum number of words per chunk.
    dedup_threshold:
        If the word overlap ratio between a new chunk and the previous chunk
        exceeds this threshold, the chunk is discarded.
    """
    sentences = re.split(r"(?<=[.!?])\s+", text.strip())
    chunks: list[str] = []
    current: list[str] = []
    current_words: list[str] = []
    prev_words: set[str] = set()
    seen_hashes: set[str] = set()
    for sentence in sentences:
        words = sentence.split()
        if not words:
            continue
        if current_words and len(current_words) + len(words) > size:
            chunk = " ".join(current).strip()
            chunk_words = set(current_words)
            overlap = len(chunk_words & prev_words) / max(1, len(chunk_words))
            chunk_hash = hashlib.sha256(chunk.encode("utf-8")).hexdigest()
            if overlap < dedup_threshold and chunk_hash not in seen_hashes:
                chunks.append(chunk)
                logger.debug("chunk %d hash=%s", len(chunks), chunk_hash)
                prev_words = chunk_words
                seen_hashes.add(chunk_hash)
            current = []
            current_words = []
        current.append(sentence)
        current_words.extend(words)

    if current_words:
        chunk = " ".join(current).strip()
        chunk_words = set(current_words)
        overlap = len(chunk_words & prev_words) / max(1, len(chunk_words))
        chunk_hash = hashlib.sha256(chunk.encode("utf-8")).hexdigest()
        if overlap < dedup_threshold and chunk_hash not in seen_hashes:
            chunks.append(chunk)
            logger.debug("chunk %d hash=%s", len(chunks), chunk_hash)

    return chunks


def _dedup_flashcards(items: list[dict]) -> list[dict]:
    """Remove invalid or duplicate flashcards."""
    logger.info("_dedup_flashcards processing %d items", len(items))
    seen_terms: set[str] = set()
    accepted_defs: list[str] = []
    deduped: list[dict] = []
    for m in items:
        t_raw = m.get("term", "")
        raw_def = (m.get("definition") or "").strip()
        definition = _clean_def(raw_def)
        t_norm = _norm(t_raw)
        if (not t_norm) or (t_norm in _STOPWORDS) or (t_norm in _TERM_BLOCKLIST):
            continue
        if len(definition.split()) < 15:
            continue
        if t_norm in seen_terms:
            continue
        if any(_near_dup(definition, prev) for prev in accepted_defs):
            continue
        seen_terms.add(t_norm)
        accepted_defs.append(definition)
        deduped.append({"term": t_raw.strip(), "definition": definition})
    return deduped


def validate_quiz_item(item: dict) -> dict | None:
    """Validate and normalize a quiz item.

    Returns a sanitized item with ``question``, ``options`` and ``answerIndex``
    if valid, otherwise ``None``. Validation ensures the answer index matches an
    option, options are unique and non-empty, and any textual answer corresponds
    to one of the options.
    """

    logger.info("validate_quiz_item called for question=%s", item.get("question"))
    q = (item.get("question") or "").strip()
    opts = [(o or "").strip() for o in (item.get("options") or [])]
    if not q or len(opts) < 2:
        return None
    if any(not o for o in opts):
        return None
    lower_opts = [o.lower() for o in opts]
    if len(set(lower_opts)) != len(opts):
        return None

    ans_idx = item.get("answerIndex")
    ans_text = (item.get("answer") or "").strip()
    if ans_idx is None:
        if not ans_text:
            return None
        try:
            ans_idx = lower_opts.index(ans_text.lower())
        except ValueError:
            return None
    else:
        try:
            ans_idx = int(ans_idx)
        except Exception:
            return None
        if not (0 <= ans_idx < len(opts)):
            return None
        if ans_text and lower_opts[ans_idx] != ans_text.lower():
            return None

    return {"question": q, "options": opts, "answerIndex": ans_idx}


def _dedup_quiz(items: list[dict]) -> list[dict]:
    seen: set[str] = set()
    deduped: list[dict] = []
    for m in items:
        valid = validate_quiz_item(m)
        if not valid:
            continue
        q = valid["question"]
        opts = valid["options"]
        key = q.lower() + "|" + "|".join(sorted(o.lower() for o in opts))
        if key in seen:
            continue
        seen.add(key)
        deduped.append(valid)
    return deduped


def _dedup_prompts(items: list[dict]) -> list[dict]:
    seen: set[str] = set()
    deduped: list[dict] = []
    for m in items:
        p = (m.get("prompt") or m.get("text") or "").strip()
        if not p:
            continue
        key = p.lower()
        if key in seen:
            continue
        seen.add(key)
        obj = {"prompt": p}
        h = (m.get("hint") or m.get("explanation") or "").strip()
        if h:
            obj["hint"] = h
        deduped.append(obj)
    return deduped


def _dedup_cloze(items: list[dict]) -> list[dict]:
    seen: set[str] = set()
    deduped: list[dict] = []
    for m in items:
        s = (m.get("sentence") or "").strip()
        opts = [(o or "").strip() for o in (m.get("options") or [])]
        if not s or len(opts) < 2:
            continue
        key = s.lower()
        if key in seen:
            continue
        seen.add(key)
        ans = m.get("answerIndex")
        if ans is None:
            ans = m.get("answer")
        try:
            ans_idx = int(ans)
        except Exception:
            ans_idx = 0
        deduped.append({"sentence": s, "options": opts, "answerIndex": ans_idx})
    return deduped


SIMPLE_CLOZE_PROMPT = """
Create 3 fill-in-the-blank sentences from this text.
Format each as: "Complete sentence with _____ for the missing word"
Keep it simple. Use important terms from the text.

Text: {text}

Example output:
- Tom _____ the fence with white paint.
- Huck lived in the _____ without a home.
"""


def _parse_cloze_output(raw: str) -> list[dict]:
    """Parse cloze drills from various LLM outputs.

    Accepts JSON arrays or simple bullet lines. Returns a list of dicts with
    consistent keys: sentence, options, answerIndex.
    """

    try:
        data = _extract_json_obj(raw)
        if isinstance(data, dict):
            data = data.get("cloze") or data.get("items") or []
        if isinstance(data, list):
            results: list[dict] = []
            for item in data:
                if isinstance(item, dict):
                    s = (item.get("sentence") or item.get("text") or "").strip()
                    opts = item.get("options") or []
                    if not isinstance(opts, list):
                        opts = []
                    try:
                        idx = int(item.get("answerIndex") or item.get("answer") or 0)
                    except Exception:
                        idx = 0
                    if s:
                        results.append(
                            {"sentence": s, "options": opts, "answerIndex": idx}
                        )
                elif isinstance(item, str):
                    s = item.strip()
                    if s:
                        results.append({"sentence": s, "options": [], "answerIndex": 0})
            if results:
                return results
    except Exception:
        pass

    lines = [
        line.lstrip("-*0123456789. ").strip()
        for line in raw.splitlines()
        if line.strip()
    ]
    return [
        {"sentence": line, "options": [], "answerIndex": 0} for line in lines if line
    ]


def call_gpt_oss_structured(text: str) -> list[dict]:
    """Ask gpt-oss for cloze drills with a structured JSON prompt."""

    prompt = (
        "You are a CLOZE drill generator. Create 3 items in JSON format with "
        "fields: sentence, options (array of 4 choices), answerIndex.\n"
        f"Text:\n{text}"
    )
    raw = _oss_ask(prompt)
    return _parse_cloze_output(raw)


def call_gpt_oss_simple(text: str) -> list[dict]:
    """Ask gpt-oss with a simpler prompt returning bullet lines."""

    prompt = SIMPLE_CLOZE_PROMPT.format(text=text)
    raw = _oss_ask(prompt)
    return _parse_cloze_output(raw)


def call_gpt_oss_minimal(text: str) -> list[dict]:
    """Minimal prompt for gpt-oss as a last resort."""

    prompt = f"Text: {text}\nCreate 3 fill-in-the-blank questions:"
    raw = _oss_ask(prompt)
    return _parse_cloze_output(raw)


def generate_cloze_drills_robust(text: str) -> list[dict]:
    """Generate cloze drills with progressive simplification for gpt-oss."""

    try:
        result = call_gpt_oss_structured(text)
        if result:
            return result
    except Exception as e:  # pragma: no cover - network failures
        print(f"Complex prompt failed: {e}")

    try:
        result = call_gpt_oss_simple(text)
        if result:
            return result
    except Exception as e:  # pragma: no cover - network failures
        print(f"Simple prompt failed: {e}")

    return call_gpt_oss_minimal(text)


def generate_cloze_like_quiz(text: str) -> list[dict]:
    """Use the quiz-style prompt pattern to make cloze questions."""

    prompt = f"Text: {text}\nCreate 3 fill-in-the-blank questions:"
    raw = _oss_ask(prompt)
    return _parse_cloze_output(raw)


def generate_items(text: str) -> dict[str, list]:
    """Generate all study items using small batched LLM calls."""
    logger.info("[generate_items] received %d chars: %s", len(text), text[:200])
    _deduplicator.clear()
    _SEEN_FLASHCARD_TERMS.clear()
    targets = compute_targets(text)
    chunks = chunk_text(text)
    if not chunks:
        return {k: [] for k in targets}

    flashcards: list[dict] = []
    quiz: list[dict] = []
    deep_prompts: list[dict] = []
    cloze: list[dict] = []

    # Phase 1: pre-select unique terms across the text
    terms = extract_terms_from_text(
        text, targets["flashcards"] * 2
    )  # extract more terms as a buffer for chunking
    logger.info(f"Extracted {len(terms)} terms: {terms}")
    remaining_terms = {t.lower(): t for t in terms}
    accepted_defs: list[str] = []

    for idx, chunk in enumerate(chunks):
        if len(flashcards) < targets["flashcards"] and remaining_terms:
            remaining = targets["flashcards"] - len(flashcards)
            chunks_left = max(1, len(chunks) - idx)
            need_here = min(6, max(3, (remaining + chunks_left - 1) // chunks_left))
            chunk_lower = chunk.lower()
            chunk_terms = [
                original
                for low, original in list(remaining_terms.items())
                if _term_in_chunk(low, chunk_lower)
            ][:need_here]
            logger.info(
                "Chunk %d: matched %d terms %s",
                idx,
                len(chunk_terms),
                chunk_terms,
            )
            items = generate_flashcards_guided(chunk, chunk_terms)
            logger.info(
                "Chunk %d: generate_flashcards_guided returned %d items",
                idx,
                len(items),
            )
            retry_terms: list[str] = []
            validated_count = 0
            for m in items:
                term_raw = (m.get("term") or "").strip()
                term = _norm(term_raw)
                raw_def = (m.get("definition") or "").strip()
                definition = _clean_def(raw_def)
                if not term or term in _STOPWORDS or term in _TERM_BLOCKLIST:
                    continue
                if len(definition.split()) < 15:
                    retry_terms.append(term_raw)
                    continue
                if term not in remaining_terms:
                    continue
                if term in _SEEN_FLASHCARD_TERMS:
                    continue
                if any(_near_dup(definition, prev) for prev in accepted_defs):
                    retry_terms.append(term_raw)
                    continue
                _SEEN_FLASHCARD_TERMS.add(term)
                accepted_defs.append(definition)
                remaining_terms.pop(term, None)
                flashcards.append({"term": term_raw, "definition": definition})
                validated_count += 1
            if retry_terms and len(flashcards) < targets["flashcards"]:
                missing = min(
                    targets["flashcards"] - len(flashcards),
                    len(retry_terms),
                )
                to_retry = retry_terms[:missing]
                retry_items = retry_define_terms(chunk, to_retry, accepted_defs)
                for m in retry_items:
                    term_raw = (m.get("term") or "").strip()
                    term = _norm(term_raw)
                    raw_def = (m.get("definition") or "").strip()
                    definition = _clean_def(raw_def)
                    if not term or term in _STOPWORDS or term in _TERM_BLOCKLIST:
                        continue
                    if len(definition.split()) < 15:
                        continue
                    if term not in remaining_terms:
                        continue
                    if term in _SEEN_FLASHCARD_TERMS:
                        continue
                    if any(_near_dup(definition, prev) for prev in accepted_defs):
                        continue
                    _SEEN_FLASHCARD_TERMS.add(term)
                    accepted_defs.append(definition)
                    remaining_terms.pop(term, None)
                    flashcards.append({"term": term_raw, "definition": definition})
                    validated_count += 1
            logger.info(
                "Chunk %d: %d flashcards passed validation",
                idx,
                validated_count,
            )

        if len(quiz) < targets["quiz"]:
            need_q = min(4, targets["quiz"] - len(quiz))
            prompt_q = (
                f"Create {need_q} quiz questions from: {chunk}\n"
                "Return JSON: {\"quiz\":[{\"question\":\"Q?\", \"options\":[\"A\",\"B\",\"C\",\"D\"], \"answerIndex\":0}]}"
            )
            raw_q = ask_llm(prompt_q)
            data_q = _extract_json_obj(raw_q)
            items_q = data_q.get("quiz") or []
            filtered_q = []
            for m in items_q:
                question = (m.get("question") or "").strip()
                if not question:
                    continue
                if _deduplicator.is_question_seen(question):
                    continue
                _deduplicator.add_question(question)
                validated = validate_quiz_item(m)
                if validated:
                    filtered_q.append(validated)
            quiz.extend(filtered_q)

        if len(deep_prompts) < targets["deep_prompts"]:
            need_dp = min(3, targets["deep_prompts"] - len(deep_prompts))
            prompt_dp = (
                f"Create {need_dp} reflective prompts from: {chunk}\n"
                "Return JSON: {\"deep_prompts\":[{\"prompt\":\"P\", \"hint\":\"H\"}]}"
            )
            raw_dp = ask_llm(prompt_dp)
            data_dp = _extract_json_obj(raw_dp)
            items_dp = data_dp.get("deep_prompts") or []
            deep_prompts.extend(items_dp[:need_dp])

        if len(cloze) < targets["cloze"]:
            need_c = min(3, targets["cloze"] - len(cloze))
            prompt_c = (
                f"Create {need_c} fill-in-the-blank questions from: {chunk}\n"
                "Return JSON: {\"cloze\":[{\"sentence\":\"S with ___\", \"options\":[\"A\",\"B\",\"C\",\"D\"], \"answerIndex\":0}]}"
            )
            raw_c = ask_llm(prompt_c)
            data_c = _extract_json_obj(raw_c)
            items_c = data_c.get("cloze") or []
            cloze.extend(items_c[:need_c])

        logger.debug(
            "Progress after chunk %d: flashcards=%d quiz=%d deep=%d cloze=%d",
            idx + 1,
            len(flashcards),
            len(quiz),
            len(deep_prompts),
            len(cloze),
        )
        logger.info(
            "Chunk %d summary: flashcards_total=%d, dedup_seen_terms=%s, dedup_seen_definitions=%d, remaining_terms=%s",
            idx,
            len(flashcards),
            _deduplicator.seen_terms,
            len(_deduplicator.seen_definitions),
            list(remaining_terms.values()),
        )

        if (
            len(flashcards) >= targets["flashcards"]
            and len(quiz) >= targets["quiz"]
            and len(deep_prompts) >= targets["deep_prompts"]
            and len(cloze) >= targets["cloze"]
        ):
            break

    if len(flashcards) < targets["flashcards"] and remaining_terms:
        missing_n = targets["flashcards"] - len(flashcards)
        missing_terms = list(remaining_terms.values())[:missing_n]
        big_text = " ".join(chunks)
        extra = generate_flashcards_guided(big_text, missing_terms)
        retry_terms: list[str] = []
        for m in extra:
            term_raw = (m.get("term") or "").strip()
            term = _norm(term_raw)
            raw_def = (m.get("definition") or "").strip()
            definition = _clean_def(raw_def)
            if not term or term in _STOPWORDS or term in _TERM_BLOCKLIST:
                continue
            if len(definition.split()) < 15:
                retry_terms.append(term_raw)
                continue
            if term not in remaining_terms:
                continue
            if term in _SEEN_FLASHCARD_TERMS:
                continue
            if any(_near_dup(definition, prev) for prev in accepted_defs):
                retry_terms.append(term_raw)
                continue
            _SEEN_FLASHCARD_TERMS.add(term)
            accepted_defs.append(definition)
            remaining_terms.pop(term, None)
            flashcards.append({"term": term_raw, "definition": definition})

        if retry_terms and len(flashcards) < targets["flashcards"]:
            missing = min(
                targets["flashcards"] - len(flashcards),
                len(retry_terms),
            )
            to_retry = retry_terms[:missing]
            extra2 = retry_define_terms(big_text, to_retry, accepted_defs)
            for m in extra2:
                term_raw = (m.get("term") or "").strip()
                term = _norm(term_raw)
                raw_def = (m.get("definition") or "").strip()
                definition = _clean_def(raw_def)
                if not term or term in _STOPWORDS or term in _TERM_BLOCKLIST:
                    continue
                if len(definition.split()) < 15:
                    continue
                if term not in remaining_terms:
                    continue
                if term in _SEEN_FLASHCARD_TERMS:
                    continue
                if any(_near_dup(definition, prev) for prev in accepted_defs):
                    continue
                _SEEN_FLASHCARD_TERMS.add(term)
                accepted_defs.append(definition)
                remaining_terms.pop(term, None)
                flashcards.append({"term": term_raw, "definition": definition})

    flashcards = _dedup_flashcards(flashcards)[: targets["flashcards"]]
    quiz = _dedup_quiz(quiz)[: targets["quiz"]]
    deep_prompts = _dedup_prompts(deep_prompts)[: targets["deep_prompts"]]
    cloze = _dedup_cloze(cloze)[: targets["cloze"]]

    logger.info("flashcards_final_count=%d", len(flashcards))

    return {
        "flashcards": flashcards,
        "quiz": quiz,
        "deep_prompts": deep_prompts,
        "cloze": cloze,
    }


def generate_quiz(text: str) -> list[dict]:
    items = generate_items(text)
    return items.get("quiz", [])


def generate_cloze_drills(text: str) -> list[dict]:
    logger.info("[generate_cloze_drills] received %d chars: %s", len(text), text[:200])
    return generate_cloze_drills_robust(text)


def generate_flashcards(text: str) -> list[dict]:
    items = generate_items(text)
    return items.get("flashcards", [])


def generate_study_content(text: str) -> dict:
    result: dict[str, list] = {}
    try:
        result["quiz"] = generate_quiz(text)
        print("Quiz generated successfully")
    except Exception as e:  # pragma: no cover - best effort
        print(f"Quiz generation failed: {e}")
        result["quiz"] = []

    try:
        result["cloze_drills"] = generate_cloze_drills(text)
        print("Cloze drills generated successfully")
    except Exception as e:  # pragma: no cover - best effort
        print(f"Cloze drills generation failed: {e}")
        result["cloze_drills"] = []

    try:
        result["flashcards"] = generate_flashcards(text)
        print("Flashcards generated successfully")
    except Exception as e:  # pragma: no cover - best effort
        print(f"Flashcards generation failed: {e}")
        result["flashcards"] = []

    return result
