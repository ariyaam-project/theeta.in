# Theta transcription worker

FastAPI service for reel evidence extraction and location resolution:

1. Accept authenticated trigger calls from the Cloudflare Worker, or optionally poll for a queued D1 job.
2. Extract the caption and available comments with `yt-dlp`.
3. Use OpenAI Structured Outputs to identify restaurant/location clues, including AI-suggested address/lat/lng when the place is specific enough.
4. Only if text evidence cannot resolve a confident match, download and transcribe audio with `faster-whisper`, then retry.
5. Write evidence, transcript, and the AI-suggested restaurant/location back through authenticated internal Worker routes.

The service stores media only in a per-job temporary directory and deletes it
after success or failure.

## Local run

The easiest path is from the repository root:

```bash
cp .env.example .env
# Fill OPENAI_API_KEY in .env
docker compose up --build
curl -X POST http://localhost:8787/api/reels \
  -H 'content-type: application/json' \
  -d '{"url":"https://www.instagram.com/reel/SHORTCODE/"}'
curl http://localhost:8787/api/reels/REEL_ID/status
```

Instagram may require a Netscape-format cookies file. Mount it into the
container and set `COOKIES_FILE` when public anonymous access is blocked.

Important environment variables:

| Variable | Default |
|---|---|
| `API_BASE_URL` | `http://localhost:8787` |
| `SERVICE_TOKEN` | `local-development-token` |
| `POLL_ENABLED` | `false` |
| `TRANSCRIPTION_PROVIDER` | `openai` |
| `OPENAI_TRANSCRIPTION_MODEL` | `whisper-1` |
| `OPENAI_TRANSCRIPTION_LANGUAGE` | optional; leave empty for Malayalam because `whisper-1` rejects `ml` |
| `OPENAI_TRANSCRIPTION_PROMPT` | Malayalam/Kerala food reel hint |
| `WHISPER_MODEL` | `medium` |
| `WHISPER_DEVICE` | `cpu` |
| `WHISPER_COMPUTE_TYPE` | `int8` |
| `MAX_DURATION_SECONDS` | `180` |
| `MAX_DOWNLOAD_MB` | `100` |
| `OPENAI_API_KEY` | required |
| `OPENAI_LOCATION_MODEL` | `gpt-5.4-mini` |
| `LOCATION_ACCEPT_THRESHOLD` | `0.85` |
| `LOCATION_MARGIN_THRESHOLD` | `0.20` |
| `MAX_LOCATION_COMMENTS` | `50` |
| `FFMPEG_LOCATION` | optional path to ffmpeg/ffprobe directory |

For production compose usage, see `../docs/docker.md`.

## Tests

Default tests do not call Instagram or OpenAI:

```bash
PYTHONPATH=. python -m unittest discover -s tests -v
```

To run the live sample-reel extraction test:

```bash
RUN_LIVE_AI_EXTRACTION_TEST=1 OPENAI_API_KEY=... \
  PYTHONPATH=. python -m unittest tests.test_location_extractor.LocationExtractorTests.test_live_sample_reel_text_extraction_needs_transcription -v
```

## Manual reel diagnostic

This prompts for a reel URL, downloads the video/audio, extracts caption and
comments, transcribes audio, runs OpenAI location extraction, resolves candidates
from the AI response, and prints every stage:

```bash
cd worker
PYTHONPATH=. python scripts/test_reel_flow.py
```

Or pass the URL directly:

```bash
cd worker
PYTHONPATH=. python scripts/test_reel_flow.py --url "https://www.instagram.com/reel/SHORTCODE/"
```

Outputs are saved under `worker/runs/`, which is git-ignored.

Audio extraction still requires FFmpeg locally because the worker extracts an
audio file before sending it to OpenAI:

```bash
brew install ffmpeg
```

If FFmpeg is installed outside `PATH`, set `FFMPEG_LOCATION` to the directory
that contains `ffmpeg` and `ffprobe`.
