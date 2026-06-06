import { Hono } from 'hono'
import type { AppEnv } from '../types'
import type { ReelStatus } from '../lib/constants'
import { getCurrentUser, requireCurrentUser } from '../lib/auth'
import { newId } from '../lib/crypto'
import { getDb } from '../lib/db'
import { ensureSchema } from '../lib/schema'
import { assertSameOrigin } from '../lib/security'
import { enqueueReel, parseShortcode, stepInfo, triggerFastApiWorker } from '../lib/reels'
import { apiError } from '../lib/http'

export const reelRoutes = new Hono<AppEnv>()

// POST /api/reels — save/submit a reel for the current user.
reelRoutes.post('/', async (c) => {
  assertSameOrigin(c)
  const body = await c.req.json<{ url?: string }>().catch(() => ({}) as any)
  const url = typeof body?.url === 'string' ? body.url.trim() : ''
  const shortcode = url ? parseShortcode(url) : null
  if (!shortcode) apiError(400, 'A valid Instagram reel URL is required')

  const user = await requireCurrentUser(c)
  const db = getDb(c)
  await ensureSchema(db)

  const existing = await db
    .prepare('SELECT id, ig_shortcode, url, status, created_at FROM reels WHERE ig_shortcode = ? LIMIT 1')
    .bind(shortcode)
    .first<{ id: string; ig_shortcode: string; url: string; status: string; created_at: string }>()

  if (existing) {
    await saveReelForUser(db, user.id, existing.id, statusToSavedStatus(existing.status))
    const restaurant = await getReelRestaurant(db, existing.id)
    if (existing.status !== 'complete' && existing.status !== 'failed') {
      triggerFastApiWorker(c, existing.id)
    }

    return c.json({
      reel: {
        id: existing.id,
        shortcode: existing.ig_shortcode,
        status: existing.status,
        url: existing.url,
        createdAt: existing.created_at,
        restaurant: restaurant || null
      },
      savedReel: {
        reelId: existing.id,
        status: statusToSavedStatus(existing.status)
      },
      deduped: true
    }, existing.status === 'complete' || existing.status === 'failed' ? 200 : 202)
  }

  const reelId = newId()
  await db.batch([
    db
      .prepare(`INSERT INTO reels (id, ig_shortcode, url, submitted_by, status) VALUES (?, ?, ?, ?, 'pending')`)
      .bind(reelId, shortcode, url, user.id),
    db
      .prepare(
        `INSERT INTO saved_reels (user_id, reel_id, status)
         VALUES (?, ?, 'processing')
         ON CONFLICT(user_id, reel_id) DO UPDATE SET status = 'processing', updated_at = CURRENT_TIMESTAMP`
      )
      .bind(user.id, reelId)
  ])
  await enqueueReel(c, db, reelId)
  triggerFastApiWorker(c, reelId)

  return c.json(
    {
      reel: { id: reelId, shortcode, status: 'pending', url, createdAt: new Date().toISOString() },
      savedReel: { reelId, status: 'processing' },
      deduped: false
    },
    202
  )
})

// GET /api/reels/saved — current user's saved reel refs.
reelRoutes.get('/saved/list', async (c) => {
  const user = await requireCurrentUser(c)
  const db = getDb(c)
  await ensureSchema(db)
  const rows = await db
    .prepare(
      `SELECT sr.status AS saved_status, sr.created_at AS saved_at,
              r.id, r.ig_shortcode, r.url, r.status, r.caption, r.thumbnail_url, r.created_at,
              rest.id AS restaurant_id, rest.slug AS restaurant_slug, rest.name AS restaurant_name,
              rest.address AS restaurant_address, rest.area AS restaurant_area, rest.city AS restaurant_city,
              rest.lat AS restaurant_lat, rest.lng AS restaurant_lng, rr.confidence AS restaurant_confidence
       FROM saved_reels sr
       JOIN reels r ON r.id = sr.reel_id
       LEFT JOIN restaurant_reels rr ON rr.reel_id = r.id
       LEFT JOIN restaurants rest ON rest.id = rr.restaurant_id
       WHERE sr.user_id = ?
       ORDER BY sr.created_at DESC`
    )
    .bind(user.id)
    .all<any>()

  return c.json({
    items: rows.results.map((row) => ({
      reelId: row.id,
      savedStatus: row.saved_status,
      savedAt: row.saved_at,
      reel: {
        id: row.id,
        shortcode: row.ig_shortcode,
        url: row.url,
        status: row.status,
        caption: row.caption,
        thumbnailUrl: row.thumbnail_url,
        createdAt: row.created_at,
        restaurant: row.restaurant_id
          ? {
              id: row.restaurant_id,
              slug: row.restaurant_slug,
              name: row.restaurant_name,
              address: row.restaurant_address,
              area: row.restaurant_area,
              city: row.restaurant_city,
              lat: row.restaurant_lat,
              lng: row.restaurant_lng,
              confidence: row.restaurant_confidence
            }
          : null
      }
    }))
  })
})

// GET /api/reels/:id/status
reelRoutes.get('/:id/status', async (c) => {
  c.header('cache-control', 'no-store')
  const id = c.req.param('id')
  const user = await getCurrentUser(c)
  const db = getDb(c)
  await ensureSchema(db)

  const row = await db
    .prepare(`SELECT id, status, error FROM reels WHERE id = ? LIMIT 1`)
    .bind(id)
    .first<{ id: string; status: ReelStatus; error: string | null }>()
  if (!row) apiError(404, 'Reel not found')

  const restaurant = await db
    .prepare(
      `SELECT r.slug FROM restaurant_reels rr JOIN restaurants r ON r.id = rr.restaurant_id
       WHERE rr.reel_id = ? LIMIT 1`
    )
    .bind(id)
    .first<{ slug: string }>()

  const { step, totalSteps } = stepInfo(row.status)
  const savedReel = user
    ? await db
        .prepare(`SELECT status, created_at, updated_at FROM saved_reels WHERE user_id = ? AND reel_id = ? LIMIT 1`)
        .bind(user.id, id)
        .first<{ status: string; created_at: string; updated_at: string }>()
    : null
  return c.json({
    id: row.id,
    status: row.status,
    savedStatus: savedReel?.status || null,
    savedAt: savedReel?.created_at || null,
    step,
    totalSteps,
    restaurantSlug: restaurant?.slug || null,
    error: row.error
  })
})

function statusToSavedStatus(status: string) {
  if (status === 'complete') return 'processed'
  if (status === 'failed') return 'failed'
  return 'processing'
}

async function saveReelForUser(db: ReturnType<typeof getDb>, userId: string, reelId: string, status: string) {
  await db
    .prepare(
      `INSERT INTO saved_reels (user_id, reel_id, status)
       VALUES (?, ?, ?)
       ON CONFLICT(user_id, reel_id) DO UPDATE SET status = excluded.status, updated_at = CURRENT_TIMESTAMP`
    )
    .bind(userId, reelId, status)
    .run()
}

async function getReelRestaurant(db: ReturnType<typeof getDb>, reelId: string) {
  return db
    .prepare(
      `SELECT
         r.id, r.slug, r.name, r.address, r.area, r.city, r.lat, r.lng,
         rr.confidence
       FROM restaurant_reels rr
       JOIN restaurants r ON r.id = rr.restaurant_id WHERE rr.reel_id = ? LIMIT 1`
    )
    .bind(reelId)
    .first<{
      id: string
      slug: string
      name: string
      address: string | null
      area: string | null
      city: string | null
      lat: number | null
      lng: number | null
      confidence: number | null
    }>()
}

// GET /api/reels/:id
reelRoutes.get('/:id', async (c) => {
  const id = c.req.param('id')
  const db = getDb(c)
  await ensureSchema(db)

  const row = await db
    .prepare(
      `SELECT
         re.id, re.ig_shortcode, re.url, re.status, re.caption, re.thumbnail_url,
         re.posted_at, re.like_count, re.comment_count, re.creator_id,
         c.username AS creator_username, c.full_name AS creator_full_name,
         c.profile_pic_url AS creator_pic, c.is_verified AS creator_verified,
         t.text AS transcript
       FROM reels re
       LEFT JOIN creators c ON c.id = re.creator_id
       LEFT JOIN transcripts t ON t.reel_id = re.id
       WHERE re.id = ? LIMIT 1`
    )
    .bind(id)
    .first<any>()
  if (!row) apiError(404, 'Reel not found')

  const restaurant = await getReelRestaurant(db, id)

  const entity = await db
    .prepare(
      `SELECT
         restaurant_name_raw, branch_name_raw, area_raw, city_raw, state_raw, country_raw,
         suggested_address, suggested_lat, suggested_lng, suggested_location_confidence,
         landmarks, evidence, confidence, resolution_status
       FROM reel_entities
       WHERE reel_id = ?
       ORDER BY created_at DESC
       LIMIT 1`
    )
    .bind(id)
    .first<any>()

  return c.json({
    reel: {
      id: row.id,
      shortcode: row.ig_shortcode,
      url: row.url,
      status: row.status,
      caption: row.caption,
      thumbnailUrl: row.thumbnail_url,
      postedAt: row.posted_at,
      likeCount: row.like_count,
      commentCount: row.comment_count,
      creator: row.creator_id
        ? {
            id: row.creator_id,
            username: row.creator_username,
            fullName: row.creator_full_name,
            profilePicUrl: row.creator_pic,
            isVerified: Boolean(row.creator_verified)
          }
        : null,
      transcript: row.transcript,
      restaurant: restaurant || null,
      locationExtraction: entity
        ? {
            restaurantName: entity.restaurant_name_raw,
            branchName: entity.branch_name_raw,
            area: entity.area_raw,
            city: entity.city_raw,
            state: entity.state_raw,
            country: entity.country_raw,
            suggestedAddress: entity.suggested_address,
            suggestedLat: entity.suggested_lat,
            suggestedLng: entity.suggested_lng,
            suggestedLocationConfidence: entity.suggested_location_confidence,
            landmarks: safeJson(entity.landmarks, []),
            evidence: safeJson(entity.evidence, []),
            confidence: entity.confidence,
            resolutionStatus: entity.resolution_status
          }
        : null
    }
  })
})

function safeJson<T>(value: string | null | undefined, fallback: T): T {
  if (!value) return fallback
  try {
    return JSON.parse(value) as T
  } catch {
    return fallback
  }
}
