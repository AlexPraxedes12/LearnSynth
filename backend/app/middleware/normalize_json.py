from starlette.requests import Request
from starlette.responses import Response

# Marcador BOM UTF-8 (EF BB BF)
_BOM = b"\xef\xbb\xbf"

def _replace_receive(receive, fixed_body: bytes):
    """Cambia el stream del request para entregar 'fixed_body' una única vez."""
    sent = {"done": False}

    async def _receiver():
        if not sent["done"]:
            sent["done"] = True
            return {"type": "http.request", "body": fixed_body, "more_body": False}
        return {"type": "http.request", "body": b"", "more_body": False}

    return _receiver

async def normalize_json_middleware(request: Request, call_next):
    """
    Si Content-Type es application/json (con o sin charset), quita BOM y
    normaliza el body antes de que FastAPI intente parsearlo.
    """
    ctype = request.headers.get("content-type", "")
    if ctype.startswith("application/json"):
        body = await request.body()
        # lstrip BOM si viene con UTF-8 BOM (Windows PowerShell -Encoding UTF8)
        fixed = body.lstrip(_BOM)
        if fixed is not body:
            # Reemplaza el 'receive' de este request con el body normalizado
            request = Request(request.scope, receive=_replace_receive(request._receive, fixed))
    return await call_next(request)
