import type { Context } from 'hono'
import type { AppEnv } from '../types'
import { apiError } from './http'

type GoogleTokenResponse = {
  access_token: string
  expires_in: number
  scope: string
  token_type: string
  id_token?: string
}

export type GoogleProfile = {
  sub: string
  email: string
  email_verified: boolean
  name: string
  picture?: string
}

export function getGoogleRedirectUri(appUrl: string) {
  return `${appUrl.replace(/\/$/, '')}/api/auth/google/callback`
}

export function assertGoogleConfig(c: Context<AppEnv>) {
  if (!c.env.GOOGLE_CLIENT_ID || !c.env.GOOGLE_CLIENT_SECRET) {
    apiError(500, 'Google OAuth is not configured. Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET.')
  }
}

export async function exchangeGoogleCode(c: Context<AppEnv>, code: string) {
  assertGoogleConfig(c)
  const body = new URLSearchParams({
    code,
    client_id: c.env.GOOGLE_CLIENT_ID,
    client_secret: c.env.GOOGLE_CLIENT_SECRET,
    redirect_uri: getGoogleRedirectUri(c.env.APP_URL),
    grant_type: 'authorization_code'
  })

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body
  })
  if (!response.ok) apiError(401, 'Google token exchange failed')
  return (await response.json()) as GoogleTokenResponse
}

export async function fetchGoogleProfile(accessToken: string) {
  const response = await fetch('https://openidconnect.googleapis.com/v1/userinfo', {
    headers: { authorization: `Bearer ${accessToken}` }
  })
  if (!response.ok) apiError(401, 'Could not read Google profile')

  const profile = (await response.json()) as GoogleProfile
  assertVerifiedProfile(profile)
  return profile
}

/**
 * Verify a Google ID token from the native mobile Sign-In SDK via Google's
 * tokeninfo endpoint, checking the audience matches our client id.
 */
export async function verifyGoogleIdToken(c: Context<AppEnv>, idToken: string): Promise<GoogleProfile> {
  assertGoogleConfig(c)
  const response = await fetch(
    `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`
  )
  if (!response.ok) apiError(401, 'Invalid Google ID token')

  const payload = (await response.json()) as {
    sub: string
    aud: string
    email: string
    email_verified: string | boolean
    name?: string
    picture?: string
  }

  if (payload.aud !== c.env.GOOGLE_CLIENT_ID) {
    apiError(401, 'Google ID token audience mismatch')
  }

  const profile: GoogleProfile = {
    sub: payload.sub,
    email: payload.email,
    email_verified: payload.email_verified === true || payload.email_verified === 'true',
    name: payload.name || payload.email,
    picture: payload.picture
  }
  assertVerifiedProfile(profile)
  return profile
}

function assertVerifiedProfile(profile: GoogleProfile) {
  if (!profile.sub || !profile.email || !profile.email_verified) {
    apiError(401, 'Google account email could not be verified')
  }
}
