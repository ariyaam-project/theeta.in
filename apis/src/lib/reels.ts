import type { Context } from 'hono'
import type { D1Database } from '@cloudflare/workers-types'
import type { AppEnv } from '../types'
import { REEL_STEPS, type ReelStatus } from './constants'
import { newId } from './crypto'

const IG_REEL_PATH_RE = /^\/(?:reel|reels|p|tv)\/([A-Za-z0-9_-]+)(?:\/|$)/i

/** Extract the IG shortcode from a reel/post URL, or null if not an IG URL. */
export function parseShortcode(rawUrl: string): string | null {
  try {
    const url = new URL(rawUrl.trim())
    if (url.protocol !== 'https:') return null
    if (url.hostname !== 'instagram.com' && url.hostname !== 'www.instagram.com') return null
    return IG_REEL_PATH_RE.exec(url.pathname)?.[1] || null
  } catch {
    return null
  }
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

export function triggerFastApiWorker(c: Context<AppEnv>, reelId: string) {
  const baseUrl = c.env.FASTAPI_WORKER_URL?.replace(/\/$/, '')
  if (!baseUrl) return

  const promise = fetch(`${baseUrl}/v1/jobs/trigger`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${c.env.SERVICE_TOKEN}`,
      'content-type': 'application/json'
    },
    body: JSON.stringify({ reelId })
  }).then(async (response) => {
    if (!response.ok) {
      console.error('FastAPI worker trigger failed', {
        reelId,
        status: response.status,
        body: await response.text().catch(() => '')
      })
    }
  }).catch((error) => {
    console.error('FastAPI worker trigger error', { reelId, error: String(error) })
  })

  c.executionCtx.waitUntil(promise)
}
