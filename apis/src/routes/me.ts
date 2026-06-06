import { Hono } from 'hono'
import type { AppEnv } from '../types'
import { getCurrentUser, requireCurrentUser } from '../lib/auth'
import { getDb } from '../lib/db'
import { ensureSchema } from '../lib/schema'
import { assertSameOrigin } from '../lib/security'
import { apiError } from '../lib/http'

export const meRoutes = new Hono<AppEnv>()

meRoutes.get('/me', async (c) => {
  c.header('cache-control', 'no-store')
  const user = await getCurrentUser(c)
  return c.json({ user })
})

meRoutes.patch('/me', async (c) => {
  assertSameOrigin(c)
  const user = await requireCurrentUser(c)
  const body = await c.req.json<{ displayName?: string }>().catch(() => ({}) as any)
  const displayName = typeof body?.displayName === 'string' ? body.displayName.trim() : ''
  if (!displayName) apiError(400, 'displayName is required')

  const next = displayName.slice(0, 80)
  const db = getDb(c)
  await ensureSchema(db)
  await db
    .prepare(`UPDATE users SET display_name = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`)
    .bind(next, user.id)
    .run()

  return c.json({ user: { ...user, displayName: next } })
})
