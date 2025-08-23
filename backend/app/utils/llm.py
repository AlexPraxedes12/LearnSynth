import os, time, random, json
from pathlib import Path
from dotenv import load_dotenv
import logging
from typing import List
from fastapi import HTTPException

# Anthropic
import anthropic
from anthropic import (
    APIStatusError as AnthropicAPIStatusError,
    RateLimitError as AnthropicRateLimitError,
)

# OpenAI (python >=1.x)
from openai import OpenAI
from openai import (
    APIConnectionError as OpenAIConnError,
    RateLimitError as OpenAIRateLimitError,
    APIError as OpenAIAPIError,
)

try:
    import tiktoken  # type: ignore
except Exception:  # pragma: no cover - optional dependency
    tiktoken = None

# Load API key from backend/.env
env_path = Path(__file__).resolve().parents[2] / '.env'
load_dotenv(env_path)

DEFAULT_ANTHROPIC_MODEL = os.getenv(
    "ANTHROPIC_MODEL", "claude-3-5-sonnet-latest"
)
DEFAULT_OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

logger = logging.getLogger(__name__)

MAX_MODEL_TOKENS = 200_000


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


def _anthropic_ask(prompt: str) -> str:
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


def _openai_ask(prompt: str) -> str:
    client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
    resp = client.chat.completions.create(
        model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
        messages=[{"role": "user", "content": prompt}],
        temperature=0.2,
    )
    return resp.choices[0].message.content.strip()


def ask_llm(prompt: str) -> str:
    """
    Ask the primary provider first with retries on transient failures.
    If all attempts fail, try the fallback provider (if set) with the same policy.
    Raise HTTPException(503) if neither succeeds.
    """

    primary = (os.getenv("LLM_PROVIDER") or "anthropic").strip().lower()
    fallback = (os.getenv("LLM_FALLBACK_PROVIDER") or "").strip().lower()

    providers = [primary]
    if fallback and fallback != primary:
        providers.append(fallback)

    last_error = None

    def _call_provider(name: str) -> str:
        if name == "anthropic":
            return _anthropic_ask(prompt)
        elif name == "openai":
            return _openai_ask(prompt)
        else:
            raise ValueError(f"Unknown LLM provider: {name}")

    for provider in providers:
        for attempt in range(5):
            try:
                return _call_provider(provider)
            except (AnthropicAPIStatusError, AnthropicRateLimitError) as e:
                sleep = min(8.0, 0.5 * (2 ** attempt)) + random.random()
                time.sleep(sleep)
                last_error = e
                continue
            except (OpenAIAPIError, OpenAIConnError, OpenAIRateLimitError) as e:
                sleep = min(8.0, 0.5 * (2 ** attempt)) + random.random()
                time.sleep(sleep)
                last_error = e
                continue
            except Exception as e:
                last_error = e
                break

    raise HTTPException(status_code=503, detail=f"LLM unavailable: {last_error}")


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
        data = json.loads(raw)
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
