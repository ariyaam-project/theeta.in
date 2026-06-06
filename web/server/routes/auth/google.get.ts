import { sendRedirect } from 'h3'

// Same-origin entry point for Google OAuth. Redirects to the Theta API worker
// using the runtime API base (no build-time bake), so login always targets the
// correct host even if the client bundle was built with a stale value.
export default defineEventHandler((event) => {
  const config = useRuntimeConfig()
  const base = String(config.thetaApiBase).replace(/\/$/, '')
  return sendRedirect(event, `${base}/api/auth/google`, 302)
})
