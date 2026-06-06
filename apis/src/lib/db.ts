import type { Context } from 'hono'
import type { AppEnv } from '../types'
import { apiError } from './http'

export function getDb(c: Context<AppEnv>) {
  const db = c.env.DB
  if (!db) {
    apiError(500, 'Missing D1 binding DB. Configure it in wrangler.toml.')
  }
  return db
}
