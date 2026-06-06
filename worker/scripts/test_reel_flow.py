#!/usr/bin/env python3
import argparse
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which
from typing import Any

import yt_dlp

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))


def load_env(path: Path) -> None:
    if not path.exists():
        return
    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


def safe_slug(value: str) -> str:
    value = re.sub(r"^https?://", "", value.lower())
    value = re.sub(r"[^a-z0-9]+", "-", value).strip("-")
    return value[:80] or "reel"


def dump_json(label: str, value: Any) -> None:
    print(f"\n=== {label} ===")
    print(json.dumps(value, ensure_ascii=False, indent=2))


def download_video(url: str, output_dir: Path, config: Any) -> Path | None:
    output_template = str(output_dir / "video.%(ext)s")
    options: dict[str, Any] = {
        "format": "best[ext=mp4]/best",
        "outtmpl": output_template,
        "noplaylist": True,
        "quiet": False,
        "no_warnings": True,
        "max_filesize": config.max_download_mb * 1024 * 1024,
    }
    if config.cookies_file:
        options["cookiefile"] = config.cookies_file

    with yt_dlp.YoutubeDL(options) as downloader:
        downloader.download([url])

    matches = sorted(output_dir.glob("video.*"))
    return matches[0] if matches else None


def build_settings(args: argparse.Namespace) -> Any:
    from app.config import Settings

    return Settings(
        service_token=os.getenv("SERVICE_TOKEN", "local-development-token"),
        poll_enabled=False,
        transcription_provider=os.getenv("TRANSCRIPTION_PROVIDER", "openai"),
        openai_transcription_model=os.getenv("OPENAI_TRANSCRIPTION_MODEL", "whisper-1"),
        openai_transcription_language=os.getenv("OPENAI_TRANSCRIPTION_LANGUAGE"),
        openai_transcription_prompt=os.getenv("OPENAI_TRANSCRIPTION_PROMPT"),
        whisper_model=os.getenv("WHISPER_MODEL", "small"),
        whisper_device=os.getenv("WHISPER_DEVICE", "cpu"),
        whisper_compute_type=os.getenv("WHISPER_COMPUTE_TYPE", "int8"),
        max_duration_seconds=int(os.getenv("MAX_DURATION_SECONDS", "180")),
        max_download_mb=int(os.getenv("MAX_DOWNLOAD_MB", "100")),
        cookies_file=os.getenv("COOKIES_FILE"),
        ffmpeg_location=os.getenv("FFMPEG_LOCATION"),
        openai_api_key=os.getenv("OPENAI_API_KEY"),
        openai_location_model=os.getenv("OPENAI_LOCATION_MODEL", "gpt-5.4-mini"),
        location_accept_threshold=float(os.getenv("LOCATION_ACCEPT_THRESHOLD", "0.80")),
        location_margin_threshold=float(os.getenv("LOCATION_MARGIN_THRESHOLD", "0.15")),
        max_location_comments=args.max_comments,
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the reel evidence -> transcript -> AI location diagnostic flow.")
    parser.add_argument("--url", help="Instagram reel URL. If omitted, the script prompts for it.")
    parser.add_argument("--env-file", default=str(ROOT / ".env"), help="Path to env file. Default: worker/.env")
    parser.add_argument("--output-dir", default=str(ROOT / "runs"), help="Directory for downloaded/debug artifacts.")
    parser.add_argument("--max-comments", type=int, default=int(os.getenv("MAX_LOCATION_COMMENTS", "100")))
    parser.add_argument("--skip-video", action="store_true", help="Skip downloading the MP4 video copy.")
    parser.add_argument("--skip-audio", action="store_true", help="Skip audio download/transcription.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    load_env(Path(args.env_file))

    url = args.url or input("Instagram reel link: ").strip()
    if not url:
        print("No reel URL provided.", file=sys.stderr)
        return 2

    config = build_settings(args)
    if not config.openai_api_key:
        print("OPENAI_API_KEY is required. Add it to worker/.env or export it in your shell.", file=sys.stderr)
        return 2

    from app.downloader import download_audio
    from app.instagram_extractor import extract_evidence
    from app.location_extractor import LocationExtractor
    from app.transcriber import transcribe

    run_dir = Path(args.output_dir) / f"{datetime.now().strftime('%Y%m%d-%H%M%S')}-{safe_slug(url)}"
    run_dir.mkdir(parents=True, exist_ok=True)
    print(f"Run directory: {run_dir}")

    print("\n[1/7] Extracting caption/comments...")
    evidence = extract_evidence(url, config)
    (run_dir / "evidence.json").write_text(evidence.model_dump_json(indent=2), encoding="utf-8")
    dump_json(
        "Evidence",
        {
            "caption": evidence.caption,
            "uploader": evidence.uploader,
            "channel": evidence.channel,
            "comments_count": len(evidence.comments),
            "comments": [comment.model_dump() for comment in evidence.comments],
        },
    )

    if not args.skip_video:
        print("\n[2/7] Downloading video copy...")
        video_path = download_video(url, run_dir, config)
        print(f"Video: {video_path}" if video_path else "Video: not created")
    else:
        print("\n[2/7] Skipping video download.")

    extractor = LocationExtractor(config)

    print("\n[3/6] Running OpenAI extraction from caption/comments...")
    text_extraction = extractor.extract(evidence)
    (run_dir / "location_text_only.json").write_text(text_extraction.model_dump_json(indent=2), encoding="utf-8")
    dump_json("Text-only location extraction", text_extraction.model_dump())

    transcript = None
    transcript_extraction = None

    if not args.skip_audio:
        print("\n[4/6] Downloading/extracting audio...")
        if not config.ffmpeg_location and (which("ffmpeg") is None or which("ffprobe") is None):
            print(
                "Audio extraction needs ffmpeg and ffprobe.\n"
                "Install locally with: brew install ffmpeg\n"
                "Or set FFMPEG_LOCATION to the directory containing ffmpeg and ffprobe.\n"
                "Continuing with text-only location output.",
                file=sys.stderr,
            )
            args.skip_audio = True
        else:
            audio_path = download_audio(url, run_dir, config)
            print(f"Audio: {audio_path}")

    if not args.skip_audio:
        print("\n[5/6] Transcribing audio...")
        transcript = transcribe(audio_path, config)
        (run_dir / "transcript.json").write_text(transcript.model_dump_json(indent=2), encoding="utf-8")
        (run_dir / "transcript.txt").write_text(transcript.text, encoding="utf-8")
        dump_json(
            "Transcript",
            {
                "language": transcript.language,
                "modelUsed": transcript.modelUsed,
                "text": transcript.text,
                "segments": [segment.model_dump() for segment in transcript.segments],
            },
        )

        print("\n[6/6] Running OpenAI extraction with transcript...")
        transcript_extraction = extractor.extract(evidence, transcript.text)
        (run_dir / "location_with_transcript.json").write_text(
            transcript_extraction.model_dump_json(indent=2),
            encoding="utf-8",
        )
        dump_json("Transcript-backed location extraction", transcript_extraction.model_dump())
    else:
        print("\n[4/6] Skipping audio download/transcription.")

    final_extraction = transcript_extraction or text_extraction
    has_ai_location = bool(
        final_extraction.restaurant_name
        and final_extraction.suggested_address
        and final_extraction.suggested_lat is not None
        and final_extraction.suggested_lng is not None
    )

    dump_json(
        "Final decision",
        {
            "resolved": has_ai_location,
            "restaurant_name_from_ai": final_extraction.restaurant_name,
            "suggested_address_from_ai": final_extraction.suggested_address,
            "suggested_lat_from_ai": final_extraction.suggested_lat,
            "suggested_lng_from_ai": final_extraction.suggested_lng,
            "suggested_location_confidence_from_ai": final_extraction.suggested_location_confidence,
            "confidence_from_ai": final_extraction.confidence,
            "needs_transcription_from_ai": final_extraction.needs_transcription,
            "artifacts": str(run_dir),
        },
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
