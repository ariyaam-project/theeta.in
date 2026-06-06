import type { Context } from 'hono'
import { getCookie, setCookie, deleteCookie } from 'hono/cookie'
import type { AppEnv } from '../types'
import { SESSION_COOKIE, SESSION_TTL_SECONDS } from './constants'
import { createToken, newId, sha256 } from './crypto'
import { getDb } from './db'
import { ensureSchema } from './schema'
import { apiError } from './http'
import type { GoogleProfile } from './google'

export type UserRow = {
  id: string
  google_sub: string
  email: string
  display_name: string
  avatar_url: string | null
  password_hash: string | null
  created_at: string
  updated_at: string
  last_login_at: string
}

export type AuthUser = {
  id: string
  displayName: string
  avatarUrl: string | null
  email: string
}

function secureCookies(c: Context<AppEnv>) {
  return c.env.APP_URL.startsWith('https://')
}

/**
 * Create a session row. Returns the raw token + expiry. Web callers also get
 * the cookie; mobile callers use the returned token as a bearer credential.
 */
export async function createAuthSession(c: Context<AppEnv>, userId: string) {
  const db = getDb(c)
  await ensureSchema(db)
  const token = createToken()
  const tokenHash = await sha256(token)
  const sessionId = newId()
  const expiresAt = new Date(Date.now() + SESSION_TTL_SECONDS * 1000).toISOString()

  await db
    .prepare(`INSERT INTO auth_sessions (id, user_id, token_hash, expires_at) VALUES (?, ?, ?, ?)`)
    .bind(sessionId, userId, tokenHash, expiresAt)
    .run()

  setCookie(c, SESSION_COOKIE, token, {
    httpOnly: true,
    sameSite: 'Lax',
    secure: secureCookies(c),
    path: '/',
    maxAge: SESSION_TTL_SECONDS
  })

  return { token, expiresAt }
}

/** Upsert a user from a verified Google profile. Shared by web + native flows. */
export async function upsertGoogleUser(c: Context<AppEnv>, profile: GoogleProfile) {
  const db = getDb(c)
  await ensureSchema(db)
  const existing = await db
    .prepare('SELECT id FROM users WHERE google_sub = ? LIMIT 1')
    .bind(profile.sub)
    .first<{ id: string }>()

  const userId = existing?.id || newId()

  await db
    .prepare(
      `INSERT INTO users (id, google_sub, email, display_name, avatar_url, last_login_at)
       VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
       ON CONFLICT(google_sub) DO UPDATE SET
         email = excluded.email,
         display_name = excluded.display_name,
         avatar_url = excluded.avatar_url,
         updated_at = CURRENT_TIMESTAMP,
         last_login_at = CURRENT_TIMESTAMP`
    )
    .bind(userId, profile.sub, profile.email, profile.name, profile.picture || null)
    .run()

  return userId
}

/** Look up a user by email (case-insensitive). Includes password_hash. */
export async function findUserByEmail(c: Context<AppEnv>, email: string) {
  const db = getDb(c)
  await ensureSchema(db)
  return db
    .prepare('SELECT * FROM users WHERE lower(email) = lower(?) LIMIT 1')
    .bind(email)
    .first<UserRow>()
}

/**
 * Create an email/password user. google_sub is NOT NULL UNIQUE, so we store a
 * synthetic `pwd:<id>` marker (same pattern dev login uses with `dev:<email>`).
 */
export async function createEmailUser(
  c: Context<AppEnv>,
  params: { email: string; name: string; passwordHash: string }
) {
  const db = getDb(c)
  await ensureSchema(db)
  const userId = newId()
  await db
    .prepare(
      `INSERT INTO users (id, google_sub, email, display_name, password_hash, last_login_at)
       VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)`
    )
    .bind(userId, `pwd:${userId}`, params.email, params.name, params.passwordHash)
    .run()
  return userId
}

/** Bump last_login_at after a successful password login. */
export async function touchLastLogin(c: Context<AppEnv>, userId: string) {
  const db = getDb(c)
  await db
    .prepare('UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = ?')
    .bind(userId)
    .run()
}

/** Token from `Authorization: Bearer` (mobile) or the session cookie (web). */
function getSessionToken(c: Context<AppEnv>) {
  const header = c.req.header('authorization') || ''
  if (header.startsWith('Bearer ')) return header.slice(7).trim()
  return getCookie(c, SESSION_COOKIE) || null
}

export async function getCurrentUser(c: Context<AppEnv>): Promise<AuthUser | null> {
  if (!c.env.DB) return null

  const token = getSessionToken(c)
  if (!token) return null

  const db = getDb(c)
  await ensureSchema(db)
  const tokenHash = await sha256(token)
  const row = await db
    .prepare(
      `SELECT users.*
       FROM auth_sessions
       INNER JOIN users ON users.id = auth_sessions.user_id
       WHERE auth_sessions.token_hash = ?
         AND auth_sessions.expires_at > datetime('now')
       LIMIT 1`
    )
    .bind(tokenHash)
    .first<UserRow>()

  if (!row) {
    if (getCookie(c, SESSION_COOKIE)) deleteCookie(c, SESSION_COOKIE, { path: '/' })
    return null
  }

  return mapUser(row)
}

export async function requireCurrentUser(c: Context<AppEnv>) {
  const user = await getCurrentUser(c)
  if (!user) apiError(401, 'Authentication required')
  return user
}

/** Revoke only the presented session (cookie or bearer token). */
export async function clearAuthSession(c: Context<AppEnv>) {
  const token = getSessionToken(c)
  if (token) {
    const tokenHash = await sha256(token)
    const db = getDb(c)
    await ensureSchema(db)
    await db.prepare('DELETE FROM auth_sessions WHERE token_hash = ?').bind(tokenHash).run()
  }
  if (getCookie(c, SESSION_COOKIE)) deleteCookie(c, SESSION_COOKIE, { path: '/' })
}

function mapUser(row: UserRow): AuthUser {
  return {
    id: row.id,
    displayName: row.display_name,
    avatarUrl: row.avatar_url,
    email: row.email
  }
}
