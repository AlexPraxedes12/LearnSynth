import os
from typing import AsyncGenerator

try:  # pragma: no cover - optional import for sync helper
    from app.utils.llm import ask_llm as _ask_llm
except Exception:  # pragma: no cover - tests may stub
    def _ask_llm(prompt: str, **kw) -> str:  # type: ignore
        raise RuntimeError("ask_llm unavailable")

try:  # pragma: no cover - allow tests to stub module
    from app.utils.llm import get_llm_provider
except Exception:  # pragma: no cover - fallback for tests
    def get_llm_provider(preferred_provider: str = "replicate") -> str:
        return preferred_provider

PROVIDER = get_llm_provider(os.getenv("LLM_PROVIDER", "replicate").lower())

# Fallback providers (optional)
try:  # noqa: SIM105
    from providers.openai_provider import stream as openai_stream, complete as openai_complete
except Exception:  # pragma: no cover - optional
    openai_stream = openai_complete = None

try:  # noqa: SIM105
    from providers.anthropic_provider import stream as claude_stream, complete as claude_complete
except Exception:  # pragma: no cover - optional
    claude_stream = claude_complete = None

# Default provider: Replicate
from providers.replicate_provider import stream as replicate_stream, complete as replicate_complete


async def stream(prompt: str, **kw) -> AsyncGenerator[str, None]:
    """Stream text chunks from the configured provider."""
    if PROVIDER == "replicate":
        async for x in replicate_stream(prompt, **kw):
            yield x
        return
    if PROVIDER == "openai" and openai_stream:
        async for x in openai_stream(prompt, **kw):
            yield x
        return
    if PROVIDER == "anthropic" and claude_stream:
        async for x in claude_stream(prompt, **kw):
            yield x
        return
    # Default fallback -> replicate
    async for x in replicate_stream(prompt, **kw):
        yield x


async def complete(prompt: str, **kw) -> str:
    """Return the full completion from the configured provider."""
    if PROVIDER == "replicate":
        return await replicate_complete(prompt, **kw)
    if PROVIDER == "openai" and openai_complete:
        return await openai_complete(prompt, **kw)
    if PROVIDER == "anthropic" and claude_complete:
        return await claude_complete(prompt, **kw)
    return await replicate_complete(prompt, **kw)


def ask_llm(prompt: str, **kwargs) -> str:
    """Synchronous wrapper forwarding keyword args to the underlying helper."""
    return _ask_llm(prompt, **kwargs)
