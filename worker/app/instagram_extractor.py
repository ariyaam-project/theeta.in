from typing import Any

import yt_dlp

from .config import Settings
from .models import ReelComment, ReelEvidence


def extract_evidence(url: str, config: Settings) -> ReelEvidence:
    options: dict[str, Any] = {
        "skip_download": True,
        "quiet": True,
        "no_warnings": True,
        "noplaylist": True,
        "getcomments": True,
    }
    if config.cookies_file:
        options["cookiefile"] = config.cookies_file

    with yt_dlp.YoutubeDL(options) as downloader:
        info = downloader.extract_info(url, download=False)

    comments = []
    for item in (info.get("comments") or [])[: config.max_location_comments]:
        text = str(item.get("text") or "").strip()
        if text:
            comments.append(
                ReelComment(
                    id=item.get("id"),
                    author=item.get("author"),
                    text=text,
                    likeCount=item.get("like_count"),
                    timestamp=item.get("timestamp"),
                )
            )
    return ReelEvidence(
        caption=(info.get("description") or "").strip() or None,
        uploader=info.get("uploader"),
        channel=info.get("channel"),
        comments=comments,
    )
