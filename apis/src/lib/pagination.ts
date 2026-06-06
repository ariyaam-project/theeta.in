import type { Context } from 'hono'
import type { AppEnv } from '../types'
import { MAX_PAGE_LIMIT } from './constants'

export function getPage(c: Context<AppEnv>) {
  const page = Math.max(1, Math.floor(Number(c.req.query('page')) || 1))
  const limit = Math.min(MAX_PAGE_LIMIT, Math.max(1, Math.floor(Number(c.req.query('limit')) || 20)))
  return { page, limit, offset: (page - 1) * limit }
}
