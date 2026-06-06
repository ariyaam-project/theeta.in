from functools import lru_cache
from pathlib import Path
from typing import Any

from openai import BadRequestError, OpenAI

from .config import Settings
from .models import Segment, Transcript


@lru_cache(maxsize=2)
def _load_model(name: str, device: str, compute_type: str) -> Any:
    from faster_whisper import WhisperModel

    return WhisperModel(name, device=device, compute_type=compute_type)


def transcribe(audio_path: Path, config: Settings) -> Transcript:
    if config.transcription_provider == "openai":
        return _transcribe_openai(audio_path, config)
    if config.transcription_provider != "local":
        raise RuntimeError(f"Unsupported TRANSCRIPTION_PROVIDER: {config.transcription_provider}")

    return _transcribe_local(audio_path, config)


def _transcribe_local(audio_path: Path, config: Settings) -> Transcript:
    model = _load_model(config.whisper_model, config.whisper_device, config.whisper_compute_type)
    raw_segments, info = model.transcribe(str(audio_path), vad_filter=True)
    segments = [
        Segment(start=segment.start, end=segment.end, text=segment.text.strip())
        for segment in raw_segments
        if segment.text.strip()
    ]
    text = " ".join(segment.text for segment in segments).strip()
    if not text:
        raise RuntimeError("No speech was detected in the reel")
    return Transcript(
        language=info.language,
        text=text,
        segments=segments,
        modelUsed=f"faster-whisper:{config.whisper_model}",
    )


def _transcribe_openai(audio_path: Path, config: Settings) -> Transcript:
    if not config.openai_api_key:
        raise RuntimeError("OPENAI_API_KEY is required for OpenAI transcription")

    client = OpenAI(api_key=config.openai_api_key)
    with audio_path.open("rb") as audio_file:
        request: dict[str, Any] = {
            "model": config.openai_transcription_model,
            "file": audio_file,
            "response_format": "verbose_json",
        }
        if config.openai_transcription_language:
            request["language"] = config.openai_transcription_language
        if config.openai_transcription_prompt:
            request["prompt"] = config.openai_transcription_prompt
        try:
            response = client.audio.transcriptions.create(**request)
        except BadRequestError as exc:
            if "language" not in request or "unsupported_language" not in str(exc):
                raise
            request.pop("language", None)
            response = client.audio.transcriptions.create(**request)

    text = _get_field(response, "text") or ""
    if not text.strip():
        raise RuntimeError("No speech was detected in the reel")

    raw_segments = _get_field(response, "segments") or []
    segments = [
        Segment(
            start=float(_get_field(segment, "start") or 0),
            end=float(_get_field(segment, "end") or 0),
            text=str(_get_field(segment, "text") or "").strip(),
        )
        for segment in raw_segments
        if str(_get_field(segment, "text") or "").strip()
    ]

    return Transcript(
        language=_get_field(response, "language"),
        text=text.strip(),
        segments=segments,
        modelUsed=f"openai:{config.openai_transcription_model}",
    )


def _get_field(value: Any, field: str) -> Any:
    if isinstance(value, dict):
        return value.get(field)
    return getattr(value, field, None)
