import importlib.util
from pathlib import Path
import sys
import types

# Stub optional dependencies required by llm module
dotenv_stub = types.ModuleType("dotenv")
dotenv_stub.load_dotenv = lambda *a, **k: None
sys.modules["dotenv"] = dotenv_stub
sys.modules["anthropic"] = types.SimpleNamespace(Anthropic=lambda *a, **k: None)
openai_stub = types.ModuleType("openai")
openai_stub.OpenAI = lambda *a, **k: None
sys.modules["openai"] = openai_stub
providers_stub = types.ModuleType("providers")
providers_stub.replicate_provider = types.SimpleNamespace()
sys.modules["providers"] = providers_stub
sys.modules["providers.replicate_provider"] = providers_stub.replicate_provider

# Load real module from file to avoid test stubs overriding it
spec = importlib.util.spec_from_file_location(
    "llm_real", Path(__file__).resolve().parents[1] / "app" / "utils" / "llm.py"
)
llm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(llm)  # type: ignore[attr-defined]

def test_parse_cloze_json():
    raw = '[{"sentence": "The cat ___ on the mat", "options": ["sat", "ran"], "answerIndex": 0}]'
    result = llm._parse_cloze_output(raw)
    assert result[0]["sentence"] == "The cat ___ on the mat"
    assert result[0]["options"] == ["sat", "ran"]
    assert result[0]["answerIndex"] == 0

def test_parse_cloze_bullets():
    raw = "- Tom ___ the fence\n- Huck lived in the ___"
    result = llm._parse_cloze_output(raw)
    assert len(result) == 2
    assert result[0]["sentence"].startswith("Tom")
    assert result[0]["options"] == []
    assert result[0]["answerIndex"] == 0
