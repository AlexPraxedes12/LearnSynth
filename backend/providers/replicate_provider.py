import os, json, threading, asyncio

try:  # pragma: no cover - optional dependency
    import replicate  # type: ignore
except Exception:  # pragma: no cover - optional
    replicate = None  # type: ignore

REPLICATE_TOKEN = os.getenv("REPLICATE_API_TOKEN", "")
REPLICATE_MODEL = os.getenv("REPLICATE_MODEL", "openai/gpt-oss-20b")

if REPLICATE_TOKEN and replicate:
    replicate.Client(api_token=REPLICATE_TOKEN)


def _norm_piece(piece) -> str:
    """Normalize pieces from replicate.stream to strings."""
    if piece is None:
        return ""
    if isinstance(piece, (bytes, bytearray)):
        try:
            return piece.decode("utf-8", errors="ignore")
        except Exception:
            return str(piece)
    if isinstance(piece, str):
        return piece
    try:
        return json.dumps(piece, ensure_ascii=False)
    except Exception:
        return str(piece)


async def stream(
    prompt: str,
    max_tokens: int = 1536,
    temperature: float = 0.2,
    top_p: float = 0.9,
    repetition_penalty: float | None = None,
):
    """Asynchronously yield pieces of text from Replicate's streaming API."""
    if not REPLICATE_TOKEN:
        raise RuntimeError("REPLICATE_API_TOKEN no configurado")

    if not replicate:  # pragma: no cover - missing dependency
        raise RuntimeError("replicate package not installed")

    q: asyncio.Queue[str] = asyncio.Queue()
    loop = asyncio.get_running_loop()

    def worker():
        try:
            inp = {
                "prompt": prompt,
                "max_new_tokens": max_tokens,
                "temperature": temperature,
                "top_p": top_p,
            }
            if repetition_penalty is not None:
                inp["repetition_penalty"] = repetition_penalty
            for event in replicate.stream(REPLICATE_MODEL, input=inp):
                loop.call_soon_threadsafe(q.put_nowait, _norm_piece(event))
        except Exception as e:
            loop.call_soon_threadsafe(q.put_nowait, f"__ERROR__:{e}")
        finally:
            loop.call_soon_threadsafe(q.put_nowait, "__DONE__")

    threading.Thread(target=worker, daemon=True).start()

    while True:
        item = await q.get()
        if item == "__DONE__":
            break
        if item.startswith("__ERROR__:"):
            raise RuntimeError(item[len("__ERROR__:"):])
        yield item


async def complete(
    prompt: str,
    max_tokens: int = 1536,
    temperature: float = 0.2,
    top_p: float = 0.9,
    repetition_penalty: float | None = None,
) -> str:
    """Non-streaming completion using Replicate."""
    buf = []
    async for piece in stream(
        prompt,
        max_tokens=max_tokens,
        temperature=temperature,
        top_p=top_p,
        repetition_penalty=repetition_penalty,
    ):
        buf.append(piece)
    return "".join(buf)
