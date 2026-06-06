import { Hono } from 'hono'
import type { AppEnv } from '../types'
import { requireCurrentUser, getCurrentUser } from '../lib/auth'
import { newId } from '../lib/crypto'
import { getDb } from '../lib/db'
import { ensureSchema } from '../lib/schema'
import { assertSameOrigin } from '../lib/security'
import { slugify } from '../lib/text'
import { SUMMARY_COLUMNS, mapSummary, mediaUrl, type SummaryRow } from '../lib/restaurants'
import { apiError } from '../lib/http'

export const listRoutes = new Hono<AppEnv>()

// GET /api/lists — my lists
listRoutes.get('/', async (c) => {
  const user = await requireCurrentUser(c)
  const db = getDb(c)
  await ensureSchema(db)
  const rows = await db
    .prepare(
      `SELECT l.id, l.name, l.slug, l.description, l.is_public, l.cover_r2_key, l.created_at,
              (SELECT COUNT(*) FROM list_items li WHERE li.list_id = l.id) AS item_count
       FROM lists l WHERE l.user_id = ? ORDER BY l.created_at DESC`
    )
    .bind(user.id)
    .all<any>()

  return c.json({
    items: rows.results.map((l: any) => ({
      id: l.id,
      name: l.name,
      slug: l.slug,
      description: l.description,
      isPublic: Boolean(l.is_public),
      coverUrl: mediaUrl(l.cover_r2_key),
      itemCount: l.item_count,
      createdAt: l.created_at
    }))
  })
})

// POST /api/lists
listRoutes.post('/', async (c) => {
  assertSameOrigin(c)
  const user = await requireCurrentUser(c)
  const body = await c.req.json<{ name?: string; description?: string; isPublic?: boolean }>().catch(() => ({}) as any)
  const name = typeof body?.name === 'string' ? body.name.trim() : ''
  if (!name) apiError(400, 'List name is required')

  const db = getDb(c)
  await ensureSchema(db)
  const id = newId()
  const slug = `${slugify(name) || 'list'}-${id.slice(0, 6)}`
  const description = typeof body?.description === 'string' ? body.description.trim() || null : null
  const isPublic = body?.isPublic ? 1 : 0

  await db
    .prepare(`INSERT INTO lists (id, user_id, name, slug, description, is_public) VALUES (?, ?, ?, ?, ?, ?)`)
    .bind(id, user.id, name.slice(0, 120), slug, description, isPublic)
    .run()

  return c.json(
    {
      list: {
        id,
        name: name.slice(0, 120),
        slug,
        description,
        isPublic: Boolean(isPublic),
        coverUrl: null,
        itemCount: 0,
        createdAt: new Date().toISOString()
      }
    },
    201
  )
})

// GET /api/lists/:id
listRoutes.get('/:id', async (c) => {
  const id = c.req.param('id')
  const db = getDb(c)
  await ensureSchema(db)

  const list = await db
    .prepare(
      `SELECT l.*, u.display_name AS owner_name, u.avatar_url AS owner_avatar
       FROM lists l JOIN users u ON u.id = l.user_id WHERE l.id = ? LIMIT 1`
    )
    .bind(id)
    .first<any>()
  if (!list) apiError(404, 'List not found')

  if (!list.is_public) {
    const user = await getCurrentUser(c)
    if (!user || user.id !== list.user_id) apiError(403, 'This list is private')
  }

  const items = await db
    .prepare(
      `SELECT ${SUMMARY_COLUMNS}, li.note AS note, li.added_at AS added_at, li.position AS position
       FROM list_items li JOIN restaurants r ON r.id = li.restaurant_id
       WHERE li.list_id = ? ORDER BY li.position ASC, li.added_at ASC`
    )
    .bind(id)
    .all<SummaryRow & { note: string | null; added_at: string }>()

  return c.json({
    list: {
      id: list.id,
      name: list.name,
      slug: list.slug,
      description: list.description,
      isPublic: Boolean(list.is_public),
      coverUrl: mediaUrl(list.cover_r2_key),
      createdAt: list.created_at,
      owner: { displayName: list.owner_name, avatarUrl: list.owner_avatar }
    },
    items: items.results.map((row: any) => ({
      restaurant: mapSummary(row),
      note: row.note,
      addedAt: row.added_at
    }))
  })
})

// PATCH /api/lists/:id
listRoutes.patch('/:id', async (c) => {
  assertSameOrigin(c)
  const user = await requireCurrentUser(c)
  const id = c.req.param('id')
  const body = await c.req.json<{ name?: string; description?: string; isPublic?: boolean }>().catch(() => ({}) as any)

  const db = getDb(c)
  await ensureSchema(db)
  const owned = await db
    .prepare('SELECT id FROM lists WHERE id = ? AND user_id = ? LIMIT 1')
    .bind(id, user.id)
    .first<{ id: string }>()
  if (!owned) apiError(404, 'List not found')

  const sets: string[] = []
  const bind: unknown[] = []
  if (typeof body?.name === 'string' && body.name.trim()) {
    sets.push('name = ?')
    bind.push(body.name.trim().slice(0, 120))
  }
  if (typeof body?.description === 'string') {
    sets.push('description = ?')
    bind.push(body.description.trim() || null)
  }
  if (typeof body?.isPublic === 'boolean') {
    sets.push('is_public = ?')
    bind.push(body.isPublic ? 1 : 0)
  }
  if (!sets.length) apiError(400, 'Nothing to update')
  sets.push('updated_at = CURRENT_TIMESTAMP')

  await db.prepare(`UPDATE lists SET ${sets.join(', ')} WHERE id = ?`).bind(...bind, id).run()

  const row = await db
    .prepare(
      `SELECT id, name, slug, description, is_public, created_at,
              (SELECT COUNT(*) FROM list_items li WHERE li.list_id = lists.id) AS item_count
       FROM lists WHERE id = ?`
    )
    .bind(id)
    .first<any>()

  return c.json({
    list: {
      id: row.id,
      name: row.name,
      slug: row.slug,
      description: row.description,
      isPublic: Boolean(row.is_public),
      coverUrl: null,
      itemCount: row.item_count,
      createdAt: row.created_at
    }
  })
})

// DELETE /api/lists/:id
listRoutes.delete('/:id', async (c) => {
  assertSameOrigin(c)
  const user = await requireCurrentUser(c)
  const id = c.req.param('id')
  const db = getDb(c)
  await ensureSchema(db)

  const result = await db.prepare('DELETE FROM lists WHERE id = ? AND user_id = ?').bind(id, user.id).run()
  if (!result.meta.changes) apiError(404, 'List not found')
  return c.body(null, 204)
})

// POST /api/lists/:id/items
listRoutes.post('/:id/items', async (c) => {
  assertSameOrigin(c)
  const user = await requireCurrentUser(c)
  const listId = c.req.param('id')
  const body = await c.req.json<{ restaurantId?: string; note?: string }>().catch(() => ({}) as any)
  const restaurantId = typeof body?.restaurantId === 'string' ? body.restaurantId : ''
  if (!restaurantId) apiError(400, 'restaurantId is required')

  const db = getDb(c)
  await ensureSchema(db)

  const owned = await db
    .prepare('SELECT id FROM lists WHERE id = ? AND user_id = ? LIMIT 1')
    .bind(listId, user.id)
    .first<{ id: string }>()
  if (!owned) apiError(404, 'List not found')

  const restaurant = await db
    .prepare('SELECT id FROM restaurants WHERE id = ? LIMIT 1')
    .bind(restaurantId)
    .first<{ id: string }>()
  if (!restaurant) apiError(404, 'Restaurant not found')

  const dupe = await db
    .prepare('SELECT id FROM list_items WHERE list_id = ? AND restaurant_id = ? LIMIT 1')
    .bind(listId, restaurantId)
    .first<{ id: string }>()
  if (dupe) apiError(409, 'Already in this list')

  const id = newId()
  const note = typeof body?.note === 'string' ? body.note.trim() || null : null
  await db
    .prepare(
      `INSERT INTO list_items (id, list_id, restaurant_id, note, position)
       VALUES (?, ?, ?, ?, (SELECT COALESCE(MAX(position), 0) + 1 FROM list_items WHERE list_id = ?))`
    )
    .bind(id, listId, restaurantId, note, listId)
    .run()

  return c.json({ item: { id, listId, restaurantId, note } }, 201)
})

// DELETE /api/lists/:id/items/:restaurantId
listRoutes.delete('/:id/items/:restaurantId', async (c) => {
  assertSameOrigin(c)
  const user = await requireCurrentUser(c)
  const listId = c.req.param('id')
  const restaurantId = c.req.param('restaurantId')
  const db = getDb(c)
  await ensureSchema(db)

  const owned = await db
    .prepare('SELECT id FROM lists WHERE id = ? AND user_id = ? LIMIT 1')
    .bind(listId, user.id)
    .first<{ id: string }>()
  if (!owned) apiError(404, 'List not found')

  await db
    .prepare('DELETE FROM list_items WHERE list_id = ? AND restaurant_id = ?')
    .bind(listId, restaurantId)
    .run()
  return c.body(null, 204)
})
