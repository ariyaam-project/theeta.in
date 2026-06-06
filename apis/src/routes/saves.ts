import { Hono } from 'hono'
import type { AppEnv } from '../types'
import { requireCurrentUser } from '../lib/auth'
import { getDb } from '../lib/db'
import { ensureSchema } from '../lib/schema'
import { assertSameOrigin } from '../lib/security'
import { SUMMARY_COLUMNS, mapSummary, type SummaryRow } from '../lib/restaurants'
import { apiError } from '../lib/http'

export const saveRoutes = new Hono<AppEnv>()

// GET /api/saves
saveRoutes.get('/', async (c) => {
  const user = await requireCurrentUser(c)
  const db = getDb(c)
  await ensureSchema(db)
  const rows = await db
    .prepare(
      `SELECT ${SUMMARY_COLUMNS}
       FROM saved_restaurants sr JOIN restaurants r ON r.id = sr.restaurant_id
       WHERE sr.user_id = ? ORDER BY sr.created_at DESC`
    )
    .bind(user.id)
    .all<SummaryRow>()
  return c.json({ items: rows.results.map(mapSummary) })
})

// POST /api/saves
saveRoutes.post('/', async (c) => {
  assertSameOrigin(c)
  const user = await requireCurrentUser(c)
  const body = await c.req.json<{ restaurantId?: string }>().catch(() => ({}) as any)
  const restaurantId = typeof body?.restaurantId === 'string' ? body.restaurantId : ''
  if (!restaurantId) apiError(400, 'restaurantId is required')

  const db = getDb(c)
  await ensureSchema(db)
  const restaurant = await db
    .prepare('SELECT id FROM restaurants WHERE id = ? LIMIT 1')
    .bind(restaurantId)
    .first<{ id: string }>()
  if (!restaurant) apiError(404, 'Restaurant not found')

  await db
    .prepare(
      `INSERT INTO saved_restaurants (user_id, restaurant_id) VALUES (?, ?)
       ON CONFLICT(user_id, restaurant_id) DO NOTHING`
    )
    .bind(user.id, restaurantId)
    .run()
  return c.json({ ok: true }, 201)
})

// DELETE /api/saves/:restaurantId
saveRoutes.delete('/:restaurantId', async (c) => {
  assertSameOrigin(c)
  const user = await requireCurrentUser(c)
  const restaurantId = c.req.param('restaurantId')
  const db = getDb(c)
  await ensureSchema(db)
  await db
    .prepare('DELETE FROM saved_restaurants WHERE user_id = ? AND restaurant_id = ?')
    .bind(user.id, restaurantId)
    .run()
  return c.body(null, 204)
})
