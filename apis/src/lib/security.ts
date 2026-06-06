import type { Context } from 'hono'
import type { AppEnv } from '../types'
import { apiError } from './http'

/**
 * Block cross-origin browser requests (CSRF guard for cookie clients).
 * Requests without an Origin header (native mobile, server-to-server) pass —
 * they authenticate with bearer/service tokens, not ambient cookies.
 */
export function assertSameOrigin(c: Context<AppEnv>) {
  const origin = c.req.header('origin')
  if (!origin) return

  const requestOrigin = new URL(c.req.url).origin
  const configuredOrigin = new URL(c.env.APP_URL).origin

  if (origin !== configuredOrigin && origin !== requestOrigin) {
    apiError(403, 'Cross-origin request blocked')
  }
}

/** Guard internal FastAPI → Worker routes with a shared service token. */
export function assertServiceToken(c: Context<AppEnv>) {
  const header = c.req.header('authorization') || ''
  const token = header.startsWith('Bearer ') ? header.slice(7) : ''
  if (!c.env.SERVICE_TOKEN || token !== c.env.SERVICE_TOKEN) {
    apiError(401, 'Invalid service token')
  }
}
