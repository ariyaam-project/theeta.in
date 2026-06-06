export const SESSION_COOKIE = 'theta_session'
export const OAUTH_STATE_COOKIE = 'theta_oauth_state'
export const SESSION_TTL_SECONDS = 60 * 60 * 24 * 30 // 30 days

// Reel pipeline order — index = step number (1-based).
export const REEL_STEPS = [
  'pending',
  'downloading',
  'transcribing',
  'detecting',
  'resolving',
  'analyzing_comments',
  'summarizing',
  'complete'
] as const

export type ReelStatus = (typeof REEL_STEPS)[number] | 'failed'

export const DEFAULT_SURPRISE_MIN_TRUST = 70
export const DEFAULT_SEARCH_RADIUS_KM = 5
export const MAX_PAGE_LIMIT = 50
