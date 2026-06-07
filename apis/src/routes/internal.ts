import { Hono } from 'hono'
import type { AppEnv } from '../types'
import { newId } from '../lib/crypto'
import { getDb } from '../lib/db'
import { apiError } from '../lib/http'
import { ensureSchema } from '../lib/schema'
import { assertServiceToken } from '../lib/security'

export const internalRoutes = new Hono<AppEnv>()

internalRoutes.use('*', async (c, next) => {
  assertServiceToken(c)
  await ensureSchema(getDb(c))
  await next()
})

// Claim one queued extract job. The conditional update prevents two pollers
// from processing the same job when they race.
internalRoutes.post('/jobs/claim', async (c) => {
  const db = getDb(c)

  // A worker can disappear after claiming a job. Return old leases to the
  // queue; attempts are preserved so repeated crashes eventually dead-letter.
  await db
    .prepare(
      `UPDATE processing_jobs SET status = 'queued', error = 'Worker lease expired'
       WHERE type = 'extract' AND status = 'running'
         AND started_at < datetime('now', '-30 minutes') AND attempts < max_attempts`
    )
    .run()
  await db
    .prepare(
      `UPDATE processing_jobs SET status = 'dead', error = 'Worker lease expired', finished_at = CURRENT_TIMESTAMP
       WHERE type = 'extract' AND status = 'running'
         AND started_at < datetime('now', '-30 minutes') AND attempts >= max_attempts`
    )
    .run()
  await db
    .prepare(
      `UPDATE reels SET status = 'failed', error = 'Worker lease expired', updated_at = CURRENT_TIMESTAMP
       WHERE status != 'complete' AND id IN (
         SELECT reel_id FROM processing_jobs WHERE type = 'extract' AND status = 'dead'
           AND error = 'Worker lease expired'
       )`
    )
    .run()

  for (let attempt = 0; attempt < 3; attempt++) {
    const job = await db
      .prepare(
        `SELECT j.id, j.reel_id, j.attempts, j.max_attempts, r.url
         FROM processing_jobs j
         JOIN reels r ON r.id = j.reel_id
         WHERE j.type = 'extract' AND j.status = 'queued' AND j.attempts < j.max_attempts
         ORDER BY j.created_at ASC LIMIT 1`
      )
      .first<{ id: string; reel_id: string; attempts: number; max_attempts: number; url: string }>()

    if (!job) return c.json({ job: null })

    const result = await db
      .prepare(
        `UPDATE processing_jobs
         SET status = 'running', attempts = attempts + 1, started_at = CURRENT_TIMESTAMP, error = NULL
         WHERE id = ? AND status = 'queued'`
      )
      .bind(job.id)
      .run()

    if ((result.meta.changes || 0) === 1) {
      await db
        .prepare(`UPDATE reels SET status = 'downloading', error = NULL, updated_at = CURRENT_TIMESTAMP WHERE id = ?`)
        .bind(job.reel_id)
        .run()

      return c.json({
        job: {
          id: job.id,
          reelId: job.reel_id,
          url: job.url,
          attempt: job.attempts + 1,
          maxAttempts: job.max_attempts
        }
      })
    }
  }

  return c.json({ job: null })
})

internalRoutes.post('/jobs/:id/status', async (c) => {
  const id = c.req.param('id')
  const body = await c.req.json<{ reelStatus?: string }>().catch(() => ({} as { reelStatus?: string }))
  if (!['transcribing', 'detecting', 'resolving'].includes(body.reelStatus || '')) apiError(400, 'Invalid reel status')

  const db = getDb(c)
  const result = await db
    .prepare(
      `UPDATE reels SET status = ?, error = NULL, updated_at = CURRENT_TIMESTAMP
       WHERE id = (SELECT reel_id FROM processing_jobs WHERE id = ? AND status = 'running')`
    )
    .bind(body.reelStatus, id)
    .run()
  if ((result.meta.changes || 0) !== 1) apiError(404, 'Running job not found')

  return c.json({ ok: true })
})

function slugify(value: string, suffix: string) {
  const base = value.toLowerCase().normalize('NFKD').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
  return `${base || 'restaurant'}-${suffix.toLowerCase().replace(/[^a-z0-9]+/g, '').slice(-8)}`
}

internalRoutes.post('/jobs/:id/result', async (c) => {
  const id = c.req.param('id')
  const body = await c.req.json<any>().catch(() => null)
  const extraction = body?.extraction
  const evidence = body?.evidence
  if (!extraction || !evidence) {
    apiError(400, 'Invalid pipeline result')
  }

  const db = getDb(c)
  const job = await db
    .prepare(`SELECT reel_id, status FROM processing_jobs WHERE id = ? LIMIT 1`)
    .bind(id)
    .first<{ reel_id: string; status: string }>()
  if (!job) apiError(404, 'Job not found')
  if (job.status === 'succeeded') return c.json({ ok: true, reelId: job.reel_id })
  if (job.status !== 'running') apiError(409, 'Job is not running')

  // Relevance gate: a non-food reel terminates here. Mark it complete but
  // is_food=0 so the UI/queries skip it; no restaurant is created.
  if (extraction.is_food_related === false) {
    const reason = typeof extraction.rejection_reason === 'string'
      ? extraction.rejection_reason.slice(0, 500)
      : 'Not a food reel'
    await db.batch([
      db.prepare(
        `UPDATE reels SET caption = ?, status = 'complete', is_food = 0, rejection_reason = ?,
           error = NULL, updated_at = CURRENT_TIMESTAMP WHERE id = ?`
      ).bind(evidence.caption || null, reason, job.reel_id),
      db.prepare(`UPDATE saved_reels SET status = 'processed', updated_at = CURRENT_TIMESTAMP WHERE reel_id = ?`)
        .bind(job.reel_id),
      db.prepare(`DELETE FROM reel_entities WHERE reel_id = ?`).bind(job.reel_id),
      db.prepare(
        `INSERT INTO reel_entities (id, reel_id, confidence, resolution_status)
         VALUES (?, ?, ?, 'not_food')`
      ).bind(newId(), job.reel_id, extraction.confidence || 0),
      db.prepare(`UPDATE processing_jobs SET status = 'succeeded', finished_at = CURRENT_TIMESTAMP WHERE id = ?`).bind(id)
    ])
    return c.json({ ok: true, reelId: job.reel_id, rejected: true })
  }

  // Resolution is best-effort: the AI often returns a name without coordinates,
  // or coordinates without a clean name. Build a spot from whatever we got.
  const aiName =
    (typeof extraction.restaurant_name === 'string' && extraction.restaurant_name.trim()) || null
  const aiLat = typeof extraction.suggested_lat === 'number' ? extraction.suggested_lat : null
  const aiLng = typeof extraction.suggested_lng === 'number' ? extraction.suggested_lng : null
  const aiAddress =
    (typeof extraction.suggested_address === 'string' && extraction.suggested_address.trim()) || null
  const displayName =
    aiName ||
    extraction.area ||
    extraction.city ||
    (aiAddress ? aiAddress.split(',')[0].trim() : null)
  // A spot worth saving needs at least a name/area or a real address/coords.
  const hasLocation = Boolean(displayName || aiAddress || (aiLat !== null && aiLng !== null))
  // "ai_suggested" only when we have a name + pinpoint coords; else needs review.
  const resolutionStatus = aiName && aiLat !== null && aiLng !== null ? 'ai_suggested' : 'needs_review'
  const queries = [
    db.prepare(`UPDATE reels SET caption = ?, status = 'complete', is_food = 1, rejection_reason = NULL, error = NULL, updated_at = CURRENT_TIMESTAMP WHERE id = ?`)
      .bind(evidence.caption || null, job.reel_id),
    db.prepare(`UPDATE saved_reels SET status = 'processed', updated_at = CURRENT_TIMESTAMP WHERE reel_id = ?`)
      .bind(job.reel_id),
    db.prepare(`DELETE FROM comments WHERE reel_id = ?`).bind(job.reel_id),
    db.prepare(`DELETE FROM reel_entities WHERE reel_id = ?`).bind(job.reel_id),
    db.prepare(
      `INSERT INTO reel_entities (
        id, reel_id, restaurant_name_raw, branch_name_raw, area_raw, city_raw, state_raw, country_raw,
        suggested_address, suggested_lat, suggested_lng, suggested_location_confidence,
        sources, landmarks, evidence, confidence, resolution_status
       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(
      newId(), job.reel_id, extraction.restaurant_name || null, extraction.branch_name || null,
      extraction.area || null, extraction.city || null, extraction.state || null, extraction.country || null,
      extraction.suggested_address || null,
      typeof extraction.suggested_lat === 'number' ? extraction.suggested_lat : null,
      typeof extraction.suggested_lng === 'number' ? extraction.suggested_lng : null,
      typeof extraction.suggested_location_confidence === 'number' ? extraction.suggested_location_confidence : 0,
      JSON.stringify((extraction.evidence || []).map((item: any) => item.source)),
      JSON.stringify(extraction.landmarks || []), JSON.stringify(extraction.evidence || []),
      extraction.confidence || 0,
      resolutionStatus
    )
  ]

  for (const comment of evidence.comments || []) {
    if (typeof comment.text !== 'string' || !comment.text.trim()) continue
    queries.push(
      db.prepare(`INSERT INTO comments (id, reel_id, ig_comment_id, author_username, text, like_count) VALUES (?, ?, ?, ?, ?, ?)`)
        .bind(newId(), job.reel_id, comment.id || null, comment.author || null, comment.text.trim(), comment.likeCount || null)
    )
  }
  if (body.transcript?.text) {
    queries.push(
      db.prepare(
        `INSERT INTO transcripts (id, reel_id, language, text, segments, model_used)
         VALUES (?, ?, ?, ?, ?, ?)
         ON CONFLICT(reel_id) DO UPDATE SET language = excluded.language, text = excluded.text,
           segments = excluded.segments, model_used = excluded.model_used`
      ).bind(
        newId(), job.reel_id, body.transcript.language || null, body.transcript.text,
        JSON.stringify(body.transcript.segments || []), body.transcript.modelUsed || null
      )
    )
  }

  let restaurantId: string | null = null
  if (hasLocation) {
    const name = displayName || 'Unnamed spot'
    const existing = await db
      .prepare(`SELECT id FROM restaurants WHERE name = ? AND ifnull(address, '') = ifnull(?, '') LIMIT 1`)
      .bind(name, aiAddress)
      .first<{ id: string }>()
    restaurantId = existing?.id || newId()
    if (!existing) {
      queries.push(
        db.prepare(
          `INSERT INTO restaurants (id, name, slug, google_place_id, address, area, city, lat, lng, status)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')`
        ).bind(
          restaurantId,
          name,
          slugify(name, job.reel_id),
          null,
          aiAddress,
          extraction.area || null,
          extraction.city || null,
          aiLat,
          aiLng
        )
      )
    }
    queries.push(
      db.prepare(`INSERT OR REPLACE INTO restaurant_reels (id, restaurant_id, reel_id, confidence) VALUES (?, ?, ?, ?)`)
        .bind(newId(), restaurantId, job.reel_id, extraction.suggested_location_confidence || extraction.confidence || 0)
    )
  }
  const ca = body.comment_analysis
  if (ca && typeof ca === 'object') {
    queries.push(
      db.prepare(
        `INSERT INTO reel_comment_analysis (
          id, reel_id, analyzed_count, positive_count, negative_count, neutral_count,
          sentiment_score, common_praise, common_complaints, sponsored_signal, authenticity_note, verdict
         ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(reel_id) DO UPDATE SET
           analyzed_count = excluded.analyzed_count, positive_count = excluded.positive_count,
           negative_count = excluded.negative_count, neutral_count = excluded.neutral_count,
           sentiment_score = excluded.sentiment_score, common_praise = excluded.common_praise,
           common_complaints = excluded.common_complaints, sponsored_signal = excluded.sponsored_signal,
           authenticity_note = excluded.authenticity_note, verdict = excluded.verdict`
      ).bind(
        newId(), job.reel_id,
        ca.analyzed_count || 0, ca.positive_count || 0, ca.negative_count || 0, ca.neutral_count || 0,
        typeof ca.sentiment_score === 'number' ? ca.sentiment_score : null,
        JSON.stringify(ca.common_praise || []), JSON.stringify(ca.common_complaints || []),
        ca.sponsored_signal ? 1 : 0, ca.authenticity_note || null, ca.verdict || null
      )
    )
  }
  queries.push(db.prepare(`UPDATE processing_jobs SET status = 'succeeded', finished_at = CURRENT_TIMESTAMP WHERE id = ?`).bind(id))
  await db.batch(queries)

  return c.json({ ok: true, reelId: job.reel_id, restaurantId, resolved: Boolean(hasLocation) })
})

internalRoutes.post('/jobs/:id/transcript', async (c) => {
  const id = c.req.param('id')
  const body = await c.req
    .json<{ language?: string; text?: string; segments?: unknown[]; modelUsed?: string }>()
    .catch(() => ({} as { language?: string; text?: string; segments?: unknown[]; modelUsed?: string }))
  if (typeof body.text !== 'string' || !body.text.trim()) apiError(400, 'Transcript text is required')
  if (body.segments !== undefined && !Array.isArray(body.segments)) apiError(400, 'Segments must be an array')

  const db = getDb(c)
  const job = await db
    .prepare(`SELECT reel_id, status FROM processing_jobs WHERE id = ? LIMIT 1`)
    .bind(id)
    .first<{ reel_id: string; status: string }>()
  if (!job) apiError(404, 'Job not found')
  if (job.status === 'succeeded') return c.json({ ok: true, reelId: job.reel_id })
  if (job.status !== 'running') apiError(409, 'Job is not running')

  await db.batch([
    db
      .prepare(
        `INSERT INTO transcripts (id, reel_id, language, text, segments, model_used)
         VALUES (?, ?, ?, ?, ?, ?)
         ON CONFLICT(reel_id) DO UPDATE SET
           language = excluded.language, text = excluded.text,
           segments = excluded.segments, model_used = excluded.model_used`
      )
      .bind(
        newId(),
        job.reel_id,
        body.language || null,
        body.text.trim(),
        JSON.stringify(body.segments || []),
        body.modelUsed || null
      ),
    db
      .prepare(`UPDATE processing_jobs SET status = 'succeeded', finished_at = CURRENT_TIMESTAMP WHERE id = ?`)
      .bind(id),
    db
      .prepare(`UPDATE reels SET status = 'complete', error = NULL, updated_at = CURRENT_TIMESTAMP WHERE id = ?`)
      .bind(job.reel_id)
  ])

  return c.json({ ok: true, reelId: job.reel_id })
})

internalRoutes.post('/jobs/:id/fail', async (c) => {
  const id = c.req.param('id')
  const body = await c.req
    .json<{ error?: string; retry?: boolean }>()
    .catch(() => ({} as { error?: string; retry?: boolean }))
  const message = typeof body.error === 'string' && body.error.trim() ? body.error.trim().slice(0, 1000) : 'Processing failed'
  const db = getDb(c)
  const job = await db
    .prepare(`SELECT reel_id, attempts, max_attempts FROM processing_jobs WHERE id = ? AND status = 'running' LIMIT 1`)
    .bind(id)
    .first<{ reel_id: string; attempts: number; max_attempts: number }>()
  if (!job) apiError(404, 'Running job not found')

  const retry = body.retry !== false && job.attempts < job.max_attempts
  await db.batch([
    db
      .prepare(
        `UPDATE processing_jobs SET status = ?, error = ?, finished_at = CURRENT_TIMESTAMP WHERE id = ?`
      )
      .bind(retry ? 'queued' : 'dead', message, id),
    db
      .prepare(`UPDATE reels SET status = ?, error = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`)
      .bind(retry ? 'pending' : 'failed', message, job.reel_id)
  ])
  if (!retry) {
    await db
      .prepare(`UPDATE saved_reels SET status = 'failed', updated_at = CURRENT_TIMESTAMP WHERE reel_id = ?`)
      .bind(job.reel_id)
      .run()
  }

  return c.json({ ok: true, retry })
})
