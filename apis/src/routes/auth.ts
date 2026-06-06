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
import { createAuthSession, clearAuthSession, getCurrentUser, upsertGoogleUser } from '../lib/auth'
import { assertSameOrigin } from '../lib/security'
import { apiError } from '../lib/http'

export const authRoutes = new Hono<AppEnv>()

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

authRoutes.post('/logout', async (c) => {
  assertSameOrigin(c)
  await clearAuthSession(c)
  return c.json({ ok: true })
})
