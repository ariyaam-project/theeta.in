import type { D1Database, R2Bucket, KVNamespace, Queue } from '@cloudflare/workers-types'

export type Bindings = {
  DB: D1Database
  MEDIA?: R2Bucket
  CACHE?: KVNamespace
  REEL_QUEUE?: Queue
  APP_URL: string
  FRONTEND_URL?: string
  COOKIE_DOMAIN?: string
  FASTAPI_WORKER_URL?: string
  GOOGLE_CLIENT_ID: string
  GOOGLE_CLIENT_SECRET: string
  SERVICE_TOKEN: string
}

export type AppEnv = { Bindings: Bindings }
