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

DEFAULT_ANTHROPIC_MODEL = os.getenv("ANTHROPIC_MODEL", "claude-3-haiku-20240307")
DEFAULT_OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-3.5-turbo")
DEFAULT_OSS_MODEL = os.getenv("OPENAI_OSS_MODEL", "gpt-oss")

logger = logging.getLogger(__name__)

MAX_MODEL_TOKENS = 200_000


def _encoding():
    """Return tiktoken encoding for the active model if available."""
    if not tiktoken:
        return None
    provider = (os.getenv("LLM_PROVIDER") or "anthropic").lower()
    if provider == "openai":
        model = os.getenv("OPENAI_MODEL", DEFAULT_OPENAI_MODEL)
    elif provider == "oss":
        model = os.getenv("OPENAI_OSS_MODEL", DEFAULT_OSS_MODEL)
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

def ask_llm(prompt: str, system: str | None = None, model_override: str | None = None) -> str:
    """Send a prompt to the configured LLM provider and return plain text."""
    provider = (os.getenv("LLM_PROVIDER") or "anthropic").lower()
    try:
        if provider == "openai":
            api_key = os.getenv("OPENAI_API_KEY")
            model = model_override or os.getenv("OPENAI_MODEL", DEFAULT_OPENAI_MODEL)
            logger.info("Using provider=%s model=%s", provider, model)
            if hasattr(openai, "OpenAI"):
                client = openai.OpenAI(api_key=api_key)
                messages = []
                if system:
                    messages.append({"role": "system", "content": system})
                messages.append({"role": "user", "content": prompt})
                resp = client.chat.completions.create(model=model, messages=messages)
                return resp.choices[0].message.content.strip()
            # Fallback for very old clients
            openai.api_key = api_key
            messages = []
            if system:
                messages.append({"role": "system", "content": system})
            messages.append({"role": "user", "content": prompt})
            resp = openai.ChatCompletion.create(model=model, messages=messages)
            return resp["choices"][0]["message"]["content"].strip()

        if provider == "oss":
            api_key = os.getenv("OPENAI_API_KEY", "not-needed")
            base_url = os.getenv("OPENAI_BASE_URL", "http://localhost:11434/v1")
            model = model_override or os.getenv("OPENAI_OSS_MODEL", DEFAULT_OSS_MODEL)
            logger.info("Using provider=%s model=%s", provider, model)
            if hasattr(openai, "OpenAI"):
                client = openai.OpenAI(api_key=api_key, base_url=base_url)
                messages = []
                if system:
                    messages.append({"role": "system", "content": system})
                messages.append({"role": "user", "content": prompt})
                resp = client.chat.completions.create(model=model, messages=messages)
                return resp.choices[0].message.content.strip()
            import requests

            messages = []
            if system:
                messages.append({"role": "system", "content": system})
            messages.append({"role": "user", "content": prompt})
            headers = {"Authorization": f"Bearer {api_key}"}
            resp = requests.post(
                f"{base_url}/chat/completions",
                headers=headers,
                json={"model": model, "messages": messages},
                timeout=60,
            )
            if resp.status_code != 200:
                raise RuntimeError(
                    f"oss request failed ({resp.status_code}): {resp.text}"
                )
            data = resp.json()
            return data["choices"][0]["message"]["content"].strip()

        # Fallback to anthropic
        provider = "anthropic"
        model = model_override or os.getenv("ANTHROPIC_MODEL", DEFAULT_ANTHROPIC_MODEL)
        logger.info("Using provider=%s model=%s", provider, model)
        resp = anthropic_client.messages.create(
            model=model,
            max_tokens=1024,
            system=system or "You are a helpful assistant.",
            messages=[{"role": "user", "content": prompt}],
        )
        return resp.content[0].text.strip()
    except Exception as exc:
        logger.exception("LLM request failed: %s", exc)
        status = getattr(getattr(exc, "response", None), "status_code", None)
        body = getattr(getattr(exc, "response", None), "text", None)
        detail = f"{provider} request failed"
        if status:
            detail += f" (status {status})"
        detail += f": {body or exc}"
        raise HTTPException(status_code=500, detail=detail)
