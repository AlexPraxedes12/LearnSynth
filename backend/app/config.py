"""Application configuration and environment loading.

Loads environment variables from a `.env` file located at the project root or
from a path provided via the `ENV_PATH` environment variable.
"""

from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv

# Determine where to load the environment from.
PROJECT_ROOT = Path(__file__).resolve().parents[2]
ENV_FILE = Path(os.getenv("ENV_PATH", PROJECT_ROOT / ".env"))

# Load environment variables. Fall back to default discovery if the file is
# missing so that system environment variables are still respected.
if ENV_FILE.exists():
    load_dotenv(ENV_FILE)
else:  # pragma: no cover - depends on runtime environment
    load_dotenv()

__all__ = ["ENV_FILE"]
