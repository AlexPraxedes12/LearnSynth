import json
import sys
import types
from pathlib import Path

# Create minimal FastAPI stubs so main can be imported without external deps
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
services_module.generator = types.SimpleNamespace()
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
llm_module.make_deep_prompts = lambda text: []
utils_module.llm = llm_module

sys.modules["app"] = app_module
sys.modules["app.services"] = services_module
sys.modules["app.services.generator"] = services_module.generator
sys.modules["app.services.srs"] = services_module.srs
sys.modules["app.services.concept_map"] = services_module.concept_map
sys.modules["app.services.exporter"] = services_module.exporter
sys.modules["app.services.tts"] = services_module.tts
sys.modules["app.models"] = models_module
sys.modules["app.utils"] = utils_module
sys.modules["app.utils.llm"] = llm_module

# Ensure backend path is on sys.path and import main
sys.path.append(str(Path(__file__).resolve().parents[1]))
import main


def test_analyze_text_schema(monkeypatch):
    sample = json.dumps({
        "summary": "Test summary",
        "concept_map": ["A", "B"],
        "flashcards": [{"term": "t", "definition": "d"}],
        "quiz": [{"question": "q", "options": ["a", "b"], "answer": "a"}],
        "spaced_repetition": ["sr"],
        "progress": {"completion": 0.5, "masteryLevel": "medium"}
    })

    def fake_llm(prompt: str) -> str:
        return sample

    monkeypatch.setattr(main, "ask_llm", fake_llm)
    result = main.analyze_text("content")

    assert set(result.keys()) == {
        "summary",
        "concept_map",
        "flashcards",
        "quiz",
        "spaced_repetition",
        "progress",
    }
    assert isinstance(result["concept_map"], list)
    assert all({"term", "definition"} <= set(card.keys()) for card in result["flashcards"])
    assert all(
        {"question", "options", "answer"} <= set(q.keys()) for q in result["quiz"]
    )
    assert isinstance(result["spaced_repetition"], list)
    assert {"completion", "masteryLevel"} <= set(result["progress"].keys())
