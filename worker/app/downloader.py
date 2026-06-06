from pathlib import Path
from shutil import which

import yt_dlp

from .config import Settings


class DownloadError(RuntimeError):
    pass


def has_ffmpeg(config: Settings) -> bool:
    if config.ffmpeg_location:
        location = Path(config.ffmpeg_location)
        if location.is_dir():
            return (location / "ffmpeg").exists() and (location / "ffprobe").exists()
        return location.exists()
    return which("ffmpeg") is not None and which("ffprobe") is not None


def download_audio(url: str, output_dir: Path, config: Settings) -> Path:
    if not has_ffmpeg(config):
        raise DownloadError(
            "ffmpeg and ffprobe are required to extract audio. Install with `brew install ffmpeg`, "
            "or set FFMPEG_LOCATION to the directory containing ffmpeg and ffprobe."
        )

    output_template = str(output_dir / "audio.%(ext)s")
    options: dict[str, object] = {
        "format": "bestaudio/best",
        "outtmpl": output_template,
        "noplaylist": True,
        "quiet": True,
        "no_warnings": True,
        "max_filesize": config.max_download_mb * 1024 * 1024,
        "match_filter": yt_dlp.utils.match_filter_func(f"duration <= {config.max_duration_seconds}"),
        "postprocessors": [
            {
                "key": "FFmpegExtractAudio",
                "preferredcodec": "wav",
            }
        ],
        "postprocessor_args": ["-ac", "1", "-ar", "16000"],
    }
    if config.cookies_file:
        options["cookiefile"] = config.cookies_file
    if config.ffmpeg_location:
        options["ffmpeg_location"] = config.ffmpeg_location

    try:
        with yt_dlp.YoutubeDL(options) as downloader:
            downloader.download([url])
    except Exception as exc:
        raise DownloadError(f"Unable to download reel audio: {exc}") from exc

    audio_path = output_dir / "audio.wav"
    if not audio_path.exists():
        raise DownloadError("Downloader completed without producing audio")
    return audio_path
