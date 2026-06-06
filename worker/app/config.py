import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


_WORKER_DIR = Path(__file__).resolve().parents[1]
_REPO_DIR = _WORKER_DIR.parent

# Local convenience: allow `uvicorn app.main:app ...` from the worker folder
# without manually sourcing env files. Existing process env still wins.
load_dotenv(_REPO_DIR / ".env", override=False)
load_dotenv(_WORKER_DIR / ".env", override=False)


def _bool_env(name: str, default: bool) -> bool:
    value = os.getenv(name)
    return default if value is None else value.lower() in {"1", "true", "yes", "on"}


@dataclass(frozen=True)
class Settings:
    api_base_url: str = os.getenv("API_BASE_URL", "http://localhost:8787")
    service_token: str = os.getenv("SERVICE_TOKEN", "local-development-token")
    poll_enabled: bool = _bool_env("POLL_ENABLED", True)
    poll_interval_seconds: float = float(os.getenv("POLL_INTERVAL_SECONDS", "5"))
    transcription_provider: str = os.getenv("TRANSCRIPTION_PROVIDER", "openai")
    openai_transcription_model: str = os.getenv("OPENAI_TRANSCRIPTION_MODEL", "whisper-1")
    openai_transcription_language: str | None = os.getenv("OPENAI_TRANSCRIPTION_LANGUAGE")
    openai_transcription_prompt: str | None = os.getenv("OPENAI_TRANSCRIPTION_PROMPT")
    whisper_model: str = os.getenv("WHISPER_MODEL", "small")
    whisper_device: str = os.getenv("WHISPER_DEVICE", "cpu")
    whisper_compute_type: str = os.getenv("WHISPER_COMPUTE_TYPE", "int8")
    max_duration_seconds: int = int(os.getenv("MAX_DURATION_SECONDS", "180"))
    max_download_mb: int = int(os.getenv("MAX_DOWNLOAD_MB", "100"))
    cookies_file: str | None = os.getenv("COOKIES_FILE")
    ffmpeg_location: str | None = os.getenv("FFMPEG_LOCATION")
    openai_api_key: str | None = os.getenv("OPENAI_API_KEY")
    openai_location_model: str = os.getenv("OPENAI_LOCATION_MODEL", "gpt-5.4-mini")
    location_accept_threshold: float = float(os.getenv("LOCATION_ACCEPT_THRESHOLD", "0.80"))
    location_margin_threshold: float = float(os.getenv("LOCATION_MARGIN_THRESHOLD", "0.15"))
    max_location_comments: int = int(os.getenv("MAX_LOCATION_COMMENTS", "30"))


settings = Settings()
