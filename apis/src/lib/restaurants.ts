import { parseStringArray } from './json'

// Public media base for R2 keys. Swap for signed URLs once R2 is wired.
export const MEDIA_BASE_URL = 'https://media.theta.in'

export function mediaUrl(key: string | null | undefined): string | null {
  if (!key) return null
  if (key.startsWith('http://') || key.startsWith('https://')) return key
  return `${MEDIA_BASE_URL}/${key.replace(/^\//, '')}`
}

export type SummaryRow = {
  id: string
  slug: string
  name: string
  area: string | null
  city: string | null
  cuisine: string | null
  price_level: number | null
  trust_score: number | null
  thumb_key: string | null
  reels_analysed: number | null
  km?: number | null
}

export function mapSummary(row: SummaryRow) {
  const summary: Record<string, unknown> = {
    id: row.id,
    slug: row.slug,
    name: row.name,
    area: row.area,
    city: row.city,
    cuisine: parseStringArray(row.cuisine),
    priceLevel: row.price_level,
    trustScore: row.trust_score,
    thumbnailUrl: mediaUrl(row.thumb_key),
    stats: { reelsAnalysed: row.reels_analysed || 0 }
  }
  if (typeof row.km === 'number' && Number.isFinite(row.km)) {
    summary.distanceKm = Math.round(row.km * 10) / 10
  }
  return summary
}

/** Correlated subqueries shared by summary list/detail SELECTs. */
export const SUMMARY_COLUMNS = `
  r.id, r.slug, r.name, r.area, r.city, r.cuisine, r.price_level,
  (SELECT ts.score FROM trust_scores ts WHERE ts.restaurant_id = r.id
     ORDER BY ts.computed_at DESC LIMIT 1) AS trust_score,
  (SELECT rp.r2_key FROM restaurant_photos rp WHERE rp.restaurant_id = r.id
     ORDER BY rp.created_at ASC LIMIT 1) AS thumb_key,
  (SELECT COUNT(*) FROM restaurant_reels rr WHERE rr.restaurant_id = r.id) AS reels_analysed
`
