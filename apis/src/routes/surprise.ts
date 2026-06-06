import { Hono } from 'hono'
import type { AppEnv } from '../types'
import { getDb } from '../lib/db'
import { ensureSchema } from '../lib/schema'
import { DEFAULT_SURPRISE_MIN_TRUST } from '../lib/constants'
import { SUMMARY_COLUMNS, mapSummary, type SummaryRow } from '../lib/restaurants'
import { apiError } from '../lib/http'

export const surpriseRoutes = new Hono<AppEnv>()

surpriseRoutes.get('/surprise', async (c) => {
  const db = getDb(c)
  await ensureSchema(db)

  const where: string[] = []
  const bind: unknown[] = []

  const city = c.req.query('city')
  if (city) {
    where.push('r.city = ?')
    bind.push(city)
  }
  const area = c.req.query('area')
  if (area) {
    where.push('r.area = ?')
    bind.push(area)
  }
  const cuisines = c.req.queries('cuisine')?.filter(Boolean) || []
  if (cuisines.length) {
    where.push('(' + cuisines.map(() => 'r.cuisine LIKE ?').join(' OR ') + ')')
    cuisines.forEach((cu) => bind.push(`%"${cu}"%`))
  }
  const priceMax = Number(c.req.query('priceMax'))
  if (Number.isFinite(priceMax)) {
    where.push('r.price_level <= ?')
    bind.push(Math.floor(priceMax))
  }
  const minTrust = Number.isFinite(Number(c.req.query('minTrust')))
    ? Number(c.req.query('minTrust'))
    : DEFAULT_SURPRISE_MIN_TRUST

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : ''
  const sql = `SELECT * FROM (
                 SELECT ${SUMMARY_COLUMNS} FROM restaurants r ${whereSql}
               ) sub WHERE trust_score >= ? ORDER BY RANDOM() LIMIT 1`

  const row = await db.prepare(sql).bind(...bind, Math.floor(minTrust)).first<SummaryRow>()
  if (!row) apiError(404, 'No matching place found')

  return c.json({ restaurant: mapSummary(row) })
})
