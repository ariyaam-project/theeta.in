import { Hono } from 'hono'
import type { AppEnv } from '../types'
import type { ReelStatus } from '../lib/constants'
import { getCurrentUser } from '../lib/auth'
import { newId } from '../lib/crypto'
import { getDb } from '../lib/db'
import { ensureSchema } from '../lib/schema'
import { assertSameOrigin } from '../lib/security'
import { enqueueReel, parseShortcode, stepInfo } from '../lib/reels'
import { apiError } from '../lib/http'

export const reelRoutes = new Hono<AppEnv>()

// POST /api/reels — submit
reelRoutes.post('/', async (c) => {
  assertSameOrigin(c)
  const body = await c.req.json<{ url?: string }>().catch(() => ({}) as any)
  const url = typeof body?.url === 'string' ? body.url.trim() : ''
  const shortcode = url ? parseShortcode(url) : null
  if (!shortcode) apiError(400, 'A valid Instagram reel URL is required')

  const user = await getCurrentUser(c) // optional — anon submit allowed
  const db = getDb(c)
  await ensureSchema(db)

  const existing = await db
    .prepare('SELECT id, ig_shortcode, url, status, created_at FROM reels WHERE ig_shortcode = ? LIMIT 1')
    .bind(shortcode)
    .first<{ id: string; ig_shortcode: string; url: string; status: string; created_at: string }>()

  if (existing) {
    const restaurant = await db
      .prepare(
        `SELECT r.id, r.slug, r.name FROM restaurant_reels rr
         JOIN restaurants r ON r.id = rr.restaurant_id WHERE rr.reel_id = ? LIMIT 1`
      )
      .bind(existing.id)
      .first<{ id: string; slug: string; name: string }>()

    return c.json({
      reel: {
        id: existing.id,
        shortcode: existing.ig_shortcode,
        status: existing.status,
        url: existing.url,
        createdAt: existing.created_at,
        restaurant: restaurant || null
      },
      deduped: true
    })
  }

  const reelId = newId()
  await db
    .prepare(`INSERT INTO reels (id, ig_shortcode, url, submitted_by, status) VALUES (?, ?, ?, ?, 'pending')`)
    .bind(reelId, shortcode, url, user?.id || null)
    .run()
  await enqueueReel(c, db, reelId)

  return c.json(
    {
      reel: { id: reelId, shortcode, status: 'pending', url, createdAt: new Date().toISOString() },
      deduped: false
    },
    202
  )
})

// GET /api/reels/:id/status
reelRoutes.get('/:id/status', async (c) => {
  c.header('cache-control', 'no-store')
  const id = c.req.param('id')
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
  return c.json({
    id: row.id,
    status: row.status,
    step,
    totalSteps,
    restaurantSlug: restaurant?.slug || null,
    error: row.error
  })
})

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

  const restaurant = await db
    .prepare(
      `SELECT r.id, r.slug, r.name FROM restaurant_reels rr
       JOIN restaurants r ON r.id = rr.restaurant_id WHERE rr.reel_id = ? LIMIT 1`
    )
    .bind(id)
    .first<{ id: string; slug: string; name: string }>()

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
      restaurant: restaurant || null
    }
  })
})
