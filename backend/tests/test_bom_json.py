from starlette.testclient import TestClient
from pathlib import Path
import sys

import types

dotenv_stub = types.ModuleType("dotenv")
dotenv_stub.load_dotenv = lambda *args, **kwargs: None
sys.modules["dotenv"] = dotenv_stub

services_module = types.ModuleType("app.services")
services_module.generator = types.SimpleNamespace()
services_module.srs = types.SimpleNamespace()
services_module.concept_map = types.SimpleNamespace(
    generate_concept_map=lambda text: []
)
services_module.exporter = types.SimpleNamespace()
services_module.tts = types.SimpleNamespace()

models_module = types.ModuleType("app.models")
models_module.ReviewInput = object
models_module.ExportInput = object

utils_module = types.ModuleType("app.utils")
llm_module = types.ModuleType("app.utils.llm")
llm_module.ask_llm = lambda prompt: ""
llm_module.generate_items = lambda text: {}
llm_module.make_deep_prompts = lambda text: []
llm_module.build_deep_prompts = lambda provider, *a, **k: []
utils_module.llm = llm_module

sys.modules["app.services"] = services_module
sys.modules["app.services.generator"] = services_module.generator
sys.modules["app.services.srs"] = services_module.srs
sys.modules["app.services.concept_map"] = services_module.concept_map
sys.modules["app.services.exporter"] = services_module.exporter
sys.modules["app.services.tts"] = services_module.tts
sys.modules["app.models"] = models_module
sys.modules["app.utils"] = utils_module
sys.modules["app.utils.llm"] = llm_module

for mod in [
    "fastapi",
    "fastapi.responses",
    "fastapi.middleware",
    "fastapi.middleware.cors",
]:
    sys.modules.pop(mod, None)

sys.path.append(str(Path(__file__).resolve().parents[1]))
import importlib
import main as main_module

main = importlib.reload(main_module)
app = main.app

client = TestClient(app)


def test_accepts_bom_and_charset():
    bom = b"\xef\xbb\xbf"
    body = bom + b'{"prompt":"hola","stream":true,"max_tokens":16}'
    r = client.post(
        "/llm/generate",
        data=body,
        headers={"Content-Type": "application/json; charset=utf-8"},
    )
    # El endpoint puede ser streaming o normal; lo importante es que no falle por 4xx
    assert r.status_code < 400, r.text
