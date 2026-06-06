import { Hono } from 'hono'
import type { AppEnv } from '../types'
import { getDb } from '../lib/db'
import { ensureSchema } from '../lib/schema'
import { getPage } from '../lib/pagination'
import { DEFAULT_SEARCH_RADIUS_KM } from '../lib/constants'
import { parseObject, parseStringArray } from '../lib/json'
import { SUMMARY_COLUMNS, mapSummary, mediaUrl, type SummaryRow } from '../lib/restaurants'
import { apiError } from '../lib/http'

export const restaurantRoutes = new Hono<AppEnv>()

function queryAll(c: any, key: string): string[] {
  const v = c.req.queries(key)
  return Array.isArray(v) ? v.filter(Boolean) : []
}

// GET /api/restaurants/search  (registered before :slug)
restaurantRoutes.get('/search', async (c) => {
  const db = getDb(c)
  await ensureSchema(db)
  const { page, limit, offset } = getPage(c)

  const baseWhere: string[] = []
  const baseBind: unknown[] = []

  const text = (c.req.query('q') || '').trim()
  if (text) {
    baseWhere.push('(r.name LIKE ? OR r.area LIKE ? OR r.city LIKE ?)')
    const like = `%${text}%`
    baseBind.push(like, like, like)
  }
  const city = c.req.query('city')
  if (city) {
    baseWhere.push('r.city = ?')
    baseBind.push(city)
  }
  const area = c.req.query('area')
  if (area) {
    baseWhere.push('r.area = ?')
    baseBind.push(area)
  }
  const cuisines = queryAll(c, 'cuisine')
  if (cuisines.length) {
    baseWhere.push('(' + cuisines.map(() => 'r.cuisine LIKE ?').join(' OR ') + ')')
    cuisines.forEach((cu) => baseBind.push(`%"${cu}"%`))
  }
  const priceMax = Number(c.req.query('priceMax'))
  if (Number.isFinite(priceMax)) {
    baseWhere.push('r.price_level <= ?')
    baseBind.push(Math.floor(priceMax))
  }

  const lat = Number(c.req.query('lat'))
  const lng = Number(c.req.query('lng'))
  const hasGeo = Number.isFinite(lat) && Number.isFinite(lng)
  const radiusKm = Number.isFinite(Number(c.req.query('radiusKm')))
    ? Number(c.req.query('radiusKm'))
    : DEFAULT_SEARCH_RADIUS_KM

  let kmSelect = 'NULL AS km'
  if (hasGeo) {
    const dLat = radiusKm / 111
    const dLng = radiusKm / (111 * Math.max(0.01, Math.cos((lat * Math.PI) / 180)))
    baseWhere.push('r.lat BETWEEN ? AND ? AND r.lng BETWEEN ? AND ?')
    baseBind.push(lat - dLat, lat + dLat, lng - dLng, lng + dLng)
    kmSelect = `(6371*acos(min(1.0, cos(radians(?))*cos(radians(r.lat))*cos(radians(r.lng)-radians(?))+sin(radians(?))*sin(radians(r.lat))))) AS km`
  }

  const innerBind = hasGeo ? [lat, lng, lat, ...baseBind] : [...baseBind]
  const whereSql = baseWhere.length ? `WHERE ${baseWhere.join(' AND ')}` : ''
  const inner = `SELECT ${SUMMARY_COLUMNS}, r.created_at AS created_at, ${kmSelect}
                 FROM restaurants r ${whereSql}`

  const outerWhere: string[] = []
  const outerBind: unknown[] = []
  const minTrust = Number(c.req.query('minTrust'))
  if (Number.isFinite(minTrust)) {
    outerWhere.push('trust_score >= ?')
    outerBind.push(Math.floor(minTrust))
  }
  if (hasGeo) {
    outerWhere.push('km <= ?')
    outerBind.push(radiusKm)
  }
  const outerWhereSql = outerWhere.length ? `WHERE ${outerWhere.join(' AND ')}` : ''

  const sortParam = c.req.query('sort')
  const sort =
    sortParam === 'distance' && hasGeo ? 'km ASC' : sortParam === 'recent' ? 'created_at DESC' : 'trust_score DESC'

  const dataSql = `SELECT * FROM (${inner}) sub ${outerWhereSql} ORDER BY ${sort} LIMIT ? OFFSET ?`
  const countSql = `SELECT COUNT(*) AS total FROM (${inner}) sub ${outerWhereSql}`

  const [data, count] = await Promise.all([
    db.prepare(dataSql).bind(...innerBind, ...outerBind, limit, offset).all<SummaryRow>(),
    db.prepare(countSql).bind(...innerBind, ...outerBind).first<{ total: number }>()
  ])

  return c.json({ items: data.results.map(mapSummary), page, limit, total: count?.total || 0 })
})

// GET /api/restaurants/:slug
restaurantRoutes.get('/:slug', async (c) => {
  const slug = c.req.param('slug')
  const db = getDb(c)
  await ensureSchema(db)

  const r = await db
    .prepare(
      `SELECT id, slug, name, address, area, city, lat, lng, google_maps_url, phone, cuisine, price_level
       FROM restaurants WHERE slug = ? LIMIT 1`
    )
    .bind(slug)
    .first<any>()
  if (!r) apiError(404, 'Restaurant not found')

  const [trust, summaryRow, photos, stats, sourceReels] = await Promise.all([
    db.prepare(
      `SELECT score, audience_signal FROM trust_scores WHERE restaurant_id = ?
       ORDER BY computed_at DESC LIMIT 1`
    ).bind(r.id).first<{ score: number; audience_signal: string | null }>(),
    db.prepare(
      `SELECT trust_score, common_praise, common_complaints, best_dishes, verdict
       FROM ai_summaries WHERE restaurant_id = ? ORDER BY created_at DESC LIMIT 1`
    ).bind(r.id).first<any>(),
    db.prepare(
      `SELECT r2_key, source FROM restaurant_photos WHERE restaurant_id = ? ORDER BY created_at ASC`
    ).bind(r.id).all<{ r2_key: string; source: string }>(),
    db.prepare(
      `SELECT
         (SELECT COUNT(*) FROM restaurant_reels rr WHERE rr.restaurant_id = ?) AS reels_analysed,
         (SELECT COUNT(DISTINCT re.creator_id) FROM restaurant_reels rr
            JOIN reels re ON re.id = rr.reel_id WHERE rr.restaurant_id = ?) AS creators_mentioning`
    ).bind(r.id, r.id).first<{ reels_analysed: number; creators_mentioning: number }>(),
    db.prepare(
      `SELECT re.id, re.ig_shortcode, re.thumbnail_url, re.url,
              c.username AS creator_username, c.is_verified AS creator_verified
       FROM restaurant_reels rr
       JOIN reels re ON re.id = rr.reel_id
       LEFT JOIN creators c ON c.id = re.creator_id
       WHERE rr.restaurant_id = ? ORDER BY re.created_at DESC LIMIT 20`
    ).bind(r.id).all<any>()
  ])

  const sentiment = parseObject<{ positive?: number; negative?: number }>(trust?.audience_signal)

  return c.json({
    restaurant: {
      id: r.id,
      slug: r.slug,
      name: r.name,
      address: r.address,
      area: r.area,
      city: r.city,
      lat: r.lat,
      lng: r.lng,
      googleMapsUrl: r.google_maps_url,
      phone: r.phone,
      cuisine: parseStringArray(r.cuisine),
      priceLevel: r.price_level,
      photos: photos.results.map((p) => ({ url: mediaUrl(p.r2_key), source: p.source })),
      trustScore: trust?.score ?? null,
      sentiment: { positive: sentiment.positive ?? 0, negative: sentiment.negative ?? 0 },
      stats: {
        reelsAnalysed: stats?.reels_analysed || 0,
        creatorsMentioning: stats?.creators_mentioning || 0
      },
      summary: summaryRow
        ? {
            verdict: summaryRow.verdict || '',
            commonPraise: parseStringArray(summaryRow.common_praise),
            commonComplaints: parseStringArray(summaryRow.common_complaints),
            bestDishes: parseStringArray(summaryRow.best_dishes)
          }
        : null,
      sourceReels: sourceReels.results.map((s: any) => ({
        id: s.id,
        shortcode: s.ig_shortcode,
        thumbnailUrl: mediaUrl(s.thumbnail_url),
        url: s.url,
        creator: { username: s.creator_username, isVerified: Boolean(s.creator_verified) }
      }))
    }
  })
})
