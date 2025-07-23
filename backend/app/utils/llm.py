import os
from pathlib import Path
from dotenv import load_dotenv
import logging
from fastapi import HTTPException
import anthropic
import openai
try:
    import tiktoken  # type: ignore
except Exception:  # pragma: no cover - optional dependency
    tiktoken = None

# Load API key from backend/.env
env_path = Path(__file__).resolve().parents[2] / '.env'
load_dotenv(env_path)

anthropic_client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
openai.api_key = os.getenv("OPENAI_API_KEY")

PROVIDER = os.getenv("MODEL_PROVIDER", "claude").lower()
CLAUDE_MODEL = os.getenv("CLAUDE_MODEL", "claude-3-haiku-20240307")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-3.5-turbo")

logger = logging.getLogger(__name__)

MAX_MODEL_TOKENS = 200_000


def _encoding():
    """Return tiktoken encoding for the active model if available."""
    if not tiktoken:
        return None
    model = CLAUDE_MODEL if PROVIDER != "openai" else OPENAI_MODEL
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

def ask_llm(prompt: str) -> str:
    """Send a prompt to the configured LLM provider."""
    try:
        if PROVIDER == "openai":
            logger.info("Using provider=%s model=%s", PROVIDER, OPENAI_MODEL)
            resp = openai.ChatCompletion.create(
                model=OPENAI_MODEL,
                messages=[{"role": "user", "content": prompt}],
            )
            return resp["choices"][0]["message"]["content"].strip()

        logger.info("Using provider=%s model=%s", PROVIDER, CLAUDE_MODEL)
        resp = anthropic_client.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=1024,
            system="You are a helpful assistant.",
            messages=[{"role": "user", "content": prompt}],
        )
        return resp.content[0].text.strip()
    except Exception as exc:
        logger.exception("LLM request failed with %s: %s", PROVIDER, exc)
        raise HTTPException(status_code=500, detail="LLM request failed")
