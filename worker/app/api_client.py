import logging

import httpx

from .config import Settings
from .models import ClaimedJob, ClaimResponse, PipelineResult

logger = logging.getLogger(__name__)


class WorkerApiClient:
    def __init__(self, config: Settings):
        self.base_url = config.api_base_url.rstrip("/")
        self._client = httpx.AsyncClient(
            base_url=self.base_url,
            headers={"Authorization": f"Bearer {config.service_token}"},
            timeout=httpx.Timeout(30),
        )
        logger.info("worker_api_client.init base_url=%s", self.base_url)

    async def close(self) -> None:
        await self._client.aclose()

    async def claim(self) -> ClaimedJob | None:
        logger.debug("worker_api_client.claim.request")
        response = await self._client.post("/api/internal/jobs/claim")
        response.raise_for_status()
        job = ClaimResponse.model_validate(response.json()).job
        if job:
            logger.info(
                "worker_api_client.claim.received job_id=%s reel_id=%s attempt=%s/%s",
                job.id,
                job.reelId,
                job.attempt,
                job.maxAttempts,
            )
        else:
            logger.debug("worker_api_client.claim.empty")
        return job

    async def mark_status(self, job_id: str, status: str) -> None:
        logger.info("worker_api_client.status.update job_id=%s status=%s", job_id, status)
        response = await self._client.post(
            f"/api/internal/jobs/{job_id}/status",
            json={"reelStatus": status},
        )
        response.raise_for_status()

    async def complete(self, job_id: str, result: PipelineResult) -> None:
        has_transcript = bool(result.transcript and result.transcript.text)
        extraction = result.extraction
        logger.info(
            "worker_api_client.result.submit job_id=%s has_transcript=%s restaurant=%r address=%r lat=%r lng=%r confidence=%s needs_transcription=%s",
            job_id,
            has_transcript,
            extraction.restaurant_name,
            extraction.suggested_address,
            extraction.suggested_lat,
            extraction.suggested_lng,
            extraction.suggested_location_confidence,
            extraction.needs_transcription,
        )
        response = await self._client.post(
            f"/api/internal/jobs/{job_id}/result",
            json=result.model_dump(),
        )
        response.raise_for_status()
        logger.info("worker_api_client.result.accepted job_id=%s response=%s", job_id, response.text[:500])

    async def fail(self, job_id: str, error: str, retry: bool = True) -> None:
        logger.error("worker_api_client.fail.submit job_id=%s retry=%s error=%s", job_id, retry, error)
        response = await self._client.post(
            f"/api/internal/jobs/{job_id}/fail",
            json={"error": error, "retry": retry},
        )
        response.raise_for_status()
        logger.info("worker_api_client.fail.accepted job_id=%s response=%s", job_id, response.text[:500])
