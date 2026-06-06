import type { Context } from 'hono'
import type { D1Database } from '@cloudflare/workers-types'
import type { AppEnv } from '../types'
import { REEL_STEPS, type ReelStatus } from './constants'
import { newId } from './crypto'

const IG_REEL_RE = /instagram\.com\/(?:reel|reels|p|tv)\/([A-Za-z0-9_-]+)/i

/** Extract the IG shortcode from a reel/post URL, or null if not an IG URL. */
export function parseShortcode(rawUrl: string): string | null {
  const match = IG_REEL_RE.exec(rawUrl.trim())
  return match ? match[1] : null
}

/** 1-based step number for a status, plus the total. */
export function stepInfo(status: ReelStatus) {
  const idx = REEL_STEPS.indexOf(status as (typeof REEL_STEPS)[number])
  return { step: idx >= 0 ? idx + 1 : 0, totalSteps: REEL_STEPS.length }
}

/**
 * Enqueue the first pipeline job. Records a `queued` processing_jobs row (so the
 * pipeline is observable / the FastAPI worker can poll) and, if the Queue
 * binding exists, pushes a message for the consumer.
 */
export async function enqueueReel(c: Context<AppEnv>, db: D1Database, reelId: string) {
  await db
    .prepare(
      `INSERT INTO processing_jobs (id, reel_id, type, status, payload)
       VALUES (?, ?, 'extract', 'queued', ?)`
    )
    .bind(newId(), reelId, JSON.stringify({ reelId }))
    .run()

  const queue = c.env.REEL_QUEUE
  if (queue) await queue.send({ reelId, type: 'extract' })
}
