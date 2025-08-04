import sys
import types
from pathlib import Path
from io import BytesIO
import asyncio

# Minimal stubs for FastAPI and related imports so `main` can be loaded
fastapi_stub = types.ModuleType("fastapi")

class HTTPException(Exception):
    def __init__(self, status_code: int, detail: str):
        self.status_code = status_code
        self.detail = detail

class FastAPI:
    def __init__(self, *args, **kwargs):
        pass

    def post(self, *args, **kwargs):
        def decorator(func):
            return func
        return decorator

class BackgroundTasks:
    pass

fastapi_stub.FastAPI = FastAPI
fastapi_stub.UploadFile = object
fastapi_stub.File = lambda *args, **kwargs: None
fastapi_stub.Body = lambda *args, **kwargs: None
fastapi_stub.HTTPException = HTTPException
fastapi_stub.BackgroundTasks = BackgroundTasks
sys.modules["fastapi"] = fastapi_stub

responses_stub = types.ModuleType("fastapi.responses")
responses_stub.FileResponse = object
sys.modules["fastapi.responses"] = responses_stub

# Stub external dependencies used by llm utilities
dotenv_stub = types.ModuleType("dotenv")
dotenv_stub.load_dotenv = lambda *args, **kwargs: None
sys.modules["dotenv"] = dotenv_stub

sys.modules.setdefault(
    "anthropic", types.SimpleNamespace(Anthropic=lambda *a, **k: None)
)
sys.modules.setdefault(
    "openai",
    types.SimpleNamespace(
        ChatCompletion=types.SimpleNamespace(create=lambda *a, **k: None),
        api_key=None,
    ),
)

# Stub internal app modules to avoid heavy dependencies
app_module = types.ModuleType("app")
services_module = types.ModuleType("app.services")

generator_stub = types.SimpleNamespace(
    transcribe_audio=lambda f: "audio text",
    transcribe_video=lambda f: "video text",
    generate_course=lambda f: {"course": "stub"},
)
services_module.generator = generator_stub
services_module.srs = types.SimpleNamespace()
services_module.concept_map = types.SimpleNamespace(generate_concept_map=lambda text: [])
services_module.exporter = types.SimpleNamespace()
services_module.tts = types.SimpleNamespace()

models_module = types.ModuleType("app.models")
models_module.ReviewInput = object
models_module.ExportInput = object

utils_module = types.ModuleType("app.utils")
llm_module = types.ModuleType("app.utils.llm")
llm_module.ask_llm = lambda prompt: ""
utils_module.llm = llm_module

sys.modules["app"] = app_module
sys.modules["app.services"] = services_module
sys.modules["app.services.generator"] = generator_stub
sys.modules["app.services.srs"] = services_module.srs
sys.modules["app.services.concept_map"] = services_module.concept_map
sys.modules["app.services.exporter"] = services_module.exporter
sys.modules["app.services.tts"] = services_module.tts
sys.modules["app.models"] = models_module
sys.modules["app.utils"] = utils_module
sys.modules["app.utils.llm"] = llm_module

# Ensure backend path is on sys.path and import main
sys.path.append(str(Path(__file__).resolve().parents[1]))
import importlib
import main as main_module
main = importlib.reload(main_module)


class DummyUpload:
    def __init__(self, content_type: str):
        self.filename = "file"
        self.content_type = content_type
        self.file = BytesIO(b"data")


def test_upload_audio_returns_text():
    upload = DummyUpload("audio/wav")
    result = asyncio.run(main.upload_content(upload))
    assert result == {"text": "audio text"}


def test_upload_video_returns_text():
    upload = DummyUpload("video/mp4")
    result = asyncio.run(main.upload_content(upload))
    assert result == {"text": "video text"}
