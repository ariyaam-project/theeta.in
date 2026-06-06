import asyncio
import logging
import secrets
from contextlib import asynccontextmanager, suppress
from pathlib import Path

from fastapi import FastAPI, Header, HTTPException

from .api_client import WorkerApiClient
from .config import settings
from .processor import Processor

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    cookies_status = "not_configured"
    if settings.cookies_file:
        cookies_path = Path(settings.cookies_file)
        if cookies_path.exists() and cookies_path.stat().st_size > 0:
            cookies_status = "configured"
        elif cookies_path.exists():
            cookies_status = "empty"
        else:
            cookies_status = "missing"

    logger.info(
        "worker.start api_base_url=%s poll_enabled=%s poll_interval=%s transcription_provider=%s openai_transcription_model=%s openai_transcription_language=%s openai_transcription_prompt=%s whisper_model=%s whisper_device=%s whisper_compute_type=%s openai_location_model=%s cookies_status=%s cookies_file=%s",
        settings.api_base_url,
        settings.poll_enabled,
        settings.poll_interval_seconds,
        settings.transcription_provider,
        settings.openai_transcription_model,
        settings.openai_transcription_language or "",
        "configured" if settings.openai_transcription_prompt else "",
        settings.whisper_model,
        settings.whisper_device,
        settings.whisper_compute_type,
        settings.openai_location_model,
        cookies_status,
        settings.cookies_file or "",
    )
    api = WorkerApiClient(settings)
    processor = Processor(settings, api)
    app.state.processor = processor
    app.state.trigger_lock = asyncio.Lock()
    task = asyncio.create_task(processor.poll_forever()) if settings.poll_enabled else None
    yield
    logger.info("worker.shutdown")
    if task:
        task.cancel()
        with suppress(asyncio.CancelledError):
            await task
    await api.close()


app = FastAPI(title="Theta Reel Transcription Worker", version="0.1.0", lifespan=lifespan)


@app.get("/health")
async def health() -> dict[str, bool]:
    return {"ok": True}


@app.post("/v1/jobs/run-once")
async def run_once(authorization: str = Header(default="")) -> dict[str, bool]:
    require_service_token(authorization)
    return {"processed": await app.state.processor.run_once()}


@app.post("/v1/jobs/trigger")
async def trigger_job(authorization: str = Header(default="")) -> dict[str, bool]:
    require_service_token(authorization)
    asyncio.create_task(_run_triggered_once())
    logger.info("worker.trigger.accepted")
    return {"accepted": True}


def require_service_token(authorization: str) -> None:
    expected = f"Bearer {settings.service_token}"
    if not secrets.compare_digest(authorization, expected):
        raise HTTPException(status_code=401, detail="Invalid service token")


async def _run_triggered_once() -> None:
    async with app.state.trigger_lock:
        try:
            processed = await app.state.processor.run_once()
            logger.info("worker.trigger.done processed=%s", processed)
        except Exception:
            logger.exception("worker.trigger.failed")
