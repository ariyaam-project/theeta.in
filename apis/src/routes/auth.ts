import { Hono } from 'hono'
import { getCookie, setCookie, deleteCookie } from 'hono/cookie'
import type { AppEnv } from '../types'
import { OAUTH_STATE_COOKIE } from '../lib/constants'
import { createToken } from '../lib/crypto'
import {
  assertGoogleConfig,
  exchangeGoogleCode,
  fetchGoogleProfile,
  getGoogleRedirectUri,
  verifyGoogleIdToken
} from '../lib/google'
import {
  createAuthSession,
  clearAuthSession,
  createEmailUser,
  findUserByEmail,
  getCurrentUser,
  touchLastLogin,
  upsertGoogleUser
} from '../lib/auth'
import { hashPassword, verifyPassword } from '../lib/crypto'
import { assertSameOrigin } from '../lib/security'
import { apiError } from '../lib/http'

export const authRoutes = new Hono<AppEnv>()

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const MIN_PASSWORD_LENGTH = 8

const getFrontendUrl = (c: { env: AppEnv['Bindings'] }, path: string) => {
  const baseUrl = c.env.FRONTEND_URL || c.env.APP_URL
  return new URL(path, baseUrl).toString()
}

// Web: start OAuth → redirect to Google.
authRoutes.get('/google', (c) => {
  assertGoogleConfig(c)
  const state = createToken(24)
  const params = new URLSearchParams({
    client_id: c.env.GOOGLE_CLIENT_ID,
    redirect_uri: getGoogleRedirectUri(c.env.APP_URL),
    response_type: 'code',
    scope: 'openid email profile',
    state,
    prompt: 'select_account'
  })

  setCookie(c, OAUTH_STATE_COOKIE, state, {
    httpOnly: true,
    sameSite: 'Lax',
    secure: c.env.APP_URL.startsWith('https://'),
    path: '/',
    maxAge: 600
  })

  return c.redirect(`https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`)
})

// Web: OAuth callback → set session cookie → redirect home.
authRoutes.get('/google/callback', async (c) => {
  const state = c.req.query('state') || ''
  const code = c.req.query('code') || ''
  const expectedState = getCookie(c, OAUTH_STATE_COOKIE)
  deleteCookie(c, OAUTH_STATE_COOKIE, { path: '/' })

  if (!state || !expectedState || state !== expectedState || !code) {
    return c.redirect(getFrontendUrl(c, '/?authError=google'))
  }

  const tokens = await exchangeGoogleCode(c, code)
  const profile = await fetchGoogleProfile(tokens.access_token)
  const userId = await upsertGoogleUser(c, profile)
  await createAuthSession(c, userId)
  return c.redirect(getFrontendUrl(c, '/'))
})

// Mobile: exchange a Google ID token for a Theta bearer token.
authRoutes.post('/google/native', async (c) => {
  const body = await c.req.json<{ idToken?: string }>().catch(() => ({}) as any)
  const idToken = typeof body?.idToken === 'string' ? body.idToken.trim() : ''
  if (!idToken) apiError(400, 'idToken is required')

  const profile = await verifyGoogleIdToken(c, idToken)
  const userId = await upsertGoogleUser(c, profile)
  const { token, expiresAt } = await createAuthSession(c, userId)
  const user = await getCurrentUser(c)
  return c.json({ token, expiresAt, user })
})

// Email/password: create an account and return a Theta bearer token.
authRoutes.post('/register', async (c) => {
  const body = await c.req
    .json<{ email?: string; password?: string; name?: string }>()
    .catch(() => ({}) as any)
  const email = typeof body?.email === 'string' ? body.email.trim().toLowerCase() : ''
  const password = typeof body?.password === 'string' ? body.password : ''
  const name = typeof body?.name === 'string' ? body.name.trim() : ''

  if (!EMAIL_RE.test(email)) apiError(400, 'A valid email is required')
  if (password.length < MIN_PASSWORD_LENGTH)
    apiError(400, `Password must be at least ${MIN_PASSWORD_LENGTH} characters`)
  if (!name) apiError(400, 'Name is required')

  const existing = await findUserByEmail(c, email)
  if (existing) apiError(409, 'An account with this email already exists')

  const passwordHash = await hashPassword(password)
  const userId = await createEmailUser(c, { email, name: name.slice(0, 80), passwordHash })
  const { token, expiresAt } = await createAuthSession(c, userId)
  const user = { id: userId, displayName: name.slice(0, 80), avatarUrl: null, email }
  return c.json({ token, expiresAt, user })
})

// Email/password: verify credentials and return a Theta bearer token.
authRoutes.post('/login', async (c) => {
  const body = await c.req
    .json<{ email?: string; password?: string }>()
    .catch(() => ({}) as any)
  const email = typeof body?.email === 'string' ? body.email.trim().toLowerCase() : ''
  const password = typeof body?.password === 'string' ? body.password : ''
  if (!email || !password) apiError(400, 'Email and password are required')

  const row = await findUserByEmail(c, email)
  if (!row || !row.password_hash || !(await verifyPassword(password, row.password_hash))) {
    apiError(401, 'Invalid email or password')
  }

  await touchLastLogin(c, row.id)
  const { token, expiresAt } = await createAuthSession(c, row.id)
  const user = {
    id: row.id,
    displayName: row.display_name,
    avatarUrl: row.avatar_url,
    email: row.email
  }
  return c.json({ token, expiresAt, user })
})

authRoutes.post('/logout', async (c) => {
  assertSameOrigin(c)
  await clearAuthSession(c)
  return c.json({ ok: true })
})
