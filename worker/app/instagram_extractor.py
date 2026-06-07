import logging
from typing import Any

import yt_dlp

from .config import Settings
from .models import ReelComment, ReelEvidence

logger = logging.getLogger(__name__)


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
    evidence = ReelEvidence(
        caption=(info.get("description") or "").strip() or None,
        uploader=info.get("uploader"),
        channel=info.get("channel"),
        comments=comments,
    )
    logger.info(
        "instagram_extractor.evidence url=%s uploader=%r channel=%r total_comments=%s used_comments=%s",
        url,
        evidence.uploader,
        evidence.channel,
        len(info.get("comments") or []),
        len(comments),
    )
    logger.info("instagram_extractor.caption:\n%s", evidence.caption or "(none)")
    for index, comment in enumerate(comments):
        logger.info(
            "instagram_extractor.comment[%s] author=%r likes=%s text=%r",
            index,
            comment.author,
            comment.likeCount,
            comment.text,
        )
    return evidence
