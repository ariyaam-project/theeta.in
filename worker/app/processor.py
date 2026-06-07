import asyncio
import logging
import tempfile
import time
from pathlib import Path

from .api_client import WorkerApiClient
from .config import Settings
from .downloader import download_audio
from .comment_analyzer import CommentAnalyzer
from .instagram_extractor import extract_evidence
from .location_extractor import LocationExtractor
from .models import ClaimedJob, PipelineResult
from .transcriber import transcribe

logger = logging.getLogger(__name__)


class Processor:
    def __init__(self, config: Settings, api: WorkerApiClient):
        self.config = config
        self.api = api

    async def run_once(self) -> bool:
        logger.debug("processor.run_once.claiming")
        job = await self.api.claim()
        if not job:
            logger.debug("processor.run_once.no_job")
            return False
        logger.info(
            "processor.run_once.claimed job_id=%s reel_id=%s attempt=%s/%s url=%s",
            job.id,
            job.reelId,
            job.attempt,
            job.maxAttempts,
            job.url,
        )
        await self.process(job)
        return True

    async def process(self, job: ClaimedJob) -> None:
        started = time.perf_counter()
        logger.info("processor.job.start job_id=%s reel_id=%s", job.id, job.reelId)
        try:
            evidence = await _timed_thread(
                "extract_evidence",
                extract_evidence,
                str(job.url),
                self.config,
                job_id=job.id,
            )
            logger.info(
                "processor.evidence.done job_id=%s caption_chars=%s comments=%s uploader=%r channel=%r",
                job.id,
                len(evidence.caption or ""),
                len(evidence.comments),
                evidence.uploader,
                evidence.channel,
            )
            extractor = LocationExtractor(self.config)
            await self.api.mark_status(job.id, "detecting")
            extraction = await _timed_thread("ai_extract_text", extractor.extract, evidence, job_id=job.id)
            logger.info(
                "processor.ai_text.done job_id=%s restaurant=%r address=%r lat=%r lng=%r confidence=%s needs_transcription=%s",
                job.id,
                extraction.restaurant_name,
                extraction.suggested_address,
                extraction.suggested_lat,
                extraction.suggested_lng,
                extraction.suggested_location_confidence,
                extraction.needs_transcription,
            )

            # Relevance gate: a non-food reel ends here. Skipping the audio
            # download + Whisper transcription is the main cost saver.
            if not extraction.is_food_related:
                logger.info(
                    "processor.job.not_food job_id=%s reel_id=%s reason=%r",
                    job.id,
                    job.reelId,
                    extraction.rejection_reason,
                )
                await self.api.complete(
                    job.id,
                    PipelineResult(evidence=evidence, extraction=extraction),
                )
                return

            # Food reel: analyse the audience comments once (independent of the
            # transcript path) and attach to whichever completion fires below.
            comment_analysis = None
            if evidence.comments:
                analyzer = CommentAnalyzer(self.config)
                comment_analysis = await _timed_thread(
                    "comment_analysis", analyzer.analyze, evidence, job_id=job.id
                )
                logger.info(
                    "processor.comments.done job_id=%s analyzed=%s pos=%s neg=%s sponsored=%s",
                    job.id,
                    comment_analysis.analyzed_count,
                    comment_analysis.positive_count,
                    comment_analysis.negative_count,
                    comment_analysis.sponsored_signal,
                )

            if _has_ai_location(extraction) and not extraction.needs_transcription:
                logger.info("processor.job.complete_from_text job_id=%s reel_id=%s", job.id, job.reelId)
                await self.api.complete(
                    job.id,
                    PipelineResult(evidence=evidence, extraction=extraction, comment_analysis=comment_analysis),
                )
                return

            with tempfile.TemporaryDirectory(prefix=f"theta-{job.reelId}-") as directory:
                logger.info("processor.audio.required job_id=%s reason=text_location_incomplete", job.id)
                audio = await _timed_thread(
                    "download_audio",
                    download_audio,
                    str(job.url),
                    Path(directory),
                    self.config,
                    job_id=job.id,
                )
                logger.info("processor.audio.downloaded job_id=%s path=%s", job.id, audio)
                await self.api.mark_status(job.id, "transcribing")
                transcript = await _timed_thread("transcribe", transcribe, audio, self.config, job_id=job.id)
                logger.info(
                    "processor.transcript.done job_id=%s language=%r chars=%s segments=%s model=%s preview=%r",
                    job.id,
                    transcript.language,
                    len(transcript.text),
                    len(transcript.segments),
                    transcript.modelUsed,
                    transcript.text[:180],
                )
                await self.api.mark_status(job.id, "detecting")
                extraction = await _timed_thread(
                    "ai_extract_transcript",
                    extractor.extract,
                    evidence,
                    transcript.text,
                    job_id=job.id,
                )
                logger.info(
                    "processor.ai_transcript.done job_id=%s restaurant=%r address=%r lat=%r lng=%r confidence=%s needs_transcription=%s",
                    job.id,
                    extraction.restaurant_name,
                    extraction.suggested_address,
                    extraction.suggested_lat,
                    extraction.suggested_lng,
                    extraction.suggested_location_confidence,
                    extraction.needs_transcription,
                )
                await self.api.complete(
                    job.id,
                    PipelineResult(
                        evidence=evidence,
                        extraction=extraction,
                        transcript=transcript,
                        comment_analysis=comment_analysis,
                    ),
                )
                logger.info(
                    "processor.job.complete job_id=%s reel_id=%s elapsed=%.2fs",
                    job.id,
                    job.reelId,
                    time.perf_counter() - started,
                )
        except Exception as exc:
            retry = job.attempt < job.maxAttempts
            logger.exception(
                "processor.job.failed job_id=%s reel_id=%s retry=%s elapsed=%.2fs",
                job.id,
                job.reelId,
                retry,
                time.perf_counter() - started,
            )
            await self.api.fail(job.id, str(exc), retry=retry)

    async def poll_forever(self) -> None:
        logger.info(
            "processor.poll.start interval_seconds=%s",
            self.config.poll_interval_seconds,
        )
        while True:
            processed = await self.run_once()
            if not processed:
                await asyncio.sleep(self.config.poll_interval_seconds)


def _has_ai_location(extraction: object) -> bool:
    return bool(
        getattr(extraction, "restaurant_name", None)
        and getattr(extraction, "suggested_address", None)
        and getattr(extraction, "suggested_lat", None) is not None
        and getattr(extraction, "suggested_lng", None) is not None
    )


async def _timed_thread(label: str, func, *args, job_id: str):
    started = time.perf_counter()
    logger.info("processor.stage.start job_id=%s stage=%s", job_id, label)
    try:
        result = await asyncio.to_thread(func, *args)
        logger.info("processor.stage.done job_id=%s stage=%s elapsed=%.2fs", job_id, label, time.perf_counter() - started)
        return result
    except Exception:
        logger.exception("processor.stage.failed job_id=%s stage=%s elapsed=%.2fs", job_id, label, time.perf_counter() - started)
        raise
