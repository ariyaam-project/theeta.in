import os
import unittest
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch

os.environ["POLL_ENABLED"] = "false"

from app.config import Settings
from app.models import (
    ClaimedJob,
    LocationExtraction,
    ReelEvidence,
    Segment,
    Transcript,
)
from app.processor import Processor


class ProcessorTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.api = AsyncMock()
        self.settings = Settings(poll_enabled=False, openai_api_key="test")
        self.processor = Processor(self.settings, self.api)
        self.job = ClaimedJob(
            id="job-1",
            reelId="reel-1",
            url="https://www.instagram.com/reel/example/",
            attempt=1,
            maxAttempts=3,
        )
        self.evidence = ReelEvidence(caption="Cafe One in Kozhikode")
        self.extraction = LocationExtraction(
            restaurant_name="Cafe One",
            city="Kozhikode",
            suggested_address="Cafe One, Kozhikode, Kerala",
            suggested_lat=11.25,
            suggested_lng=75.77,
            suggested_location_confidence=0.75,
            confidence=0.9,
            needs_transcription=False,
        )

    async def test_run_once_returns_false_without_a_job(self):
        self.api.claim.return_value = None

        self.assertFalse(await self.processor.run_once())

    @patch("app.processor.download_audio")
    @patch("app.processor.LocationExtractor")
    @patch("app.processor.extract_evidence")
    async def test_verified_text_location_skips_transcription(
        self, extract_evidence, location_extractor, download_audio
    ):
        extract_evidence.return_value = self.evidence
        location_extractor.return_value.extract.return_value = self.extraction

        await self.processor.process(self.job)

        download_audio.assert_not_called()
        self.api.complete.assert_awaited_once()
        result = self.api.complete.await_args.args[1]
        self.assertIsNone(result.transcript)
        self.assertEqual(result.extraction.suggested_address, "Cafe One, Kozhikode, Kerala")
        self.api.fail.assert_not_awaited()

    @patch("app.processor.transcribe")
    @patch("app.processor.download_audio")
    @patch("app.processor.LocationExtractor")
    @patch("app.processor.extract_evidence")
    async def test_unresolved_text_falls_back_to_transcription(
        self, extract_evidence, location_extractor, download_audio, transcribe
    ):
        extract_evidence.return_value = self.evidence
        download_audio.return_value = Path("/tmp/audio.wav")
        transcript = Transcript(
            language="en",
            text="Cafe One near Kozhikode beach",
            segments=[Segment(start=0, end=1, text="Cafe One near Kozhikode beach")],
            modelUsed="test",
        )
        transcribe.return_value = transcript
        extractor = MagicMock()
        text_only = LocationExtraction(
            restaurant_name="Cafe One",
            city="Kozhikode",
            confidence=0.5,
            needs_transcription=True,
        )
        extractor.extract.side_effect = [text_only, self.extraction]
        location_extractor.return_value = extractor

        await self.processor.process(self.job)

        download_audio.assert_called_once()
        self.assertEqual(extractor.extract.call_count, 2)
        result = self.api.complete.await_args.args[1]
        self.assertEqual(result.transcript.text, transcript.text)
        self.assertEqual(result.extraction.suggested_address, "Cafe One, Kozhikode, Kerala")
        self.api.fail.assert_not_awaited()

    @patch("app.processor.extract_evidence", side_effect=RuntimeError("extract failed"))
    async def test_process_requeues_retryable_failure(self, _extract_evidence):
        await self.processor.process(self.job)

        self.api.fail.assert_awaited_once_with("job-1", "extract failed", retry=True)


if __name__ == "__main__":
    unittest.main()
