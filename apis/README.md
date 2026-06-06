# Theta API

V1 backend for Theta.in — **Hono** on **Cloudflare Workers** + **D1** (SQLite). API-only (web is a separate app).
Contract: [docs/api.md](../docs/api.md). Schema: [docs/tech-architecture.md](../docs/tech-architecture.md).

Auth (Google OAuth + sessions) ported from the `mandiboard` base app, extended with a
**bearer-token** path for the Flutter mobile app.

## Run locally

```bash
npm install
cp .dev.vars.example .dev.vars     # fill Google client id/secret for real OAuth
npm run db:migrate:local           # apply migrations/ to local D1
npm run db:seed:local              # load demo restaurant/reel (seeds/seed.sql)
npm run dev                        # wrangler dev → http://localhost:8787
```

Or via Docker (from repo root): `cp .env.example .env && docker compose up --build`, then
`docker compose run --rm api npm run db:seed:local`.
Compose also starts the FastAPI transcription worker at `http://localhost:8000`.
See [docs/docker.md](../docs/docker.md) for local and production compose usage.

Smoke test:
```bash
curl localhost:8787/api/restaurants/al-reem-kuzhi-mandi
curl "localhost:8787/api/restaurants/search?lat=11.25&lng=75.77&radiusKm=10&sort=distance"
curl localhost:8787/api/surprise?city=Kozhikode
```

Requires **Node 22+** (wrangler v4).

## Layout

```
src/
  index.ts          Hono app — mounts routes, error handler (contract shape)
  types.ts          Bindings (DB, MEDIA, CACHE, REEL_QUEUE, env vars)
  lib/              auth crypto db schema google security reels restaurants
                    pagination json text constants http
  routes/           auth me reels restaurants surprise lists saves
migrations/         0001_auth.sql  0002_theta_core.sql   (prod-safe)
seeds/              seed.sql                               (local demo only)
Dockerfile          node:22-slim running `wrangler dev`
```

## Implemented (V1) — all smoke-tested

| Area | Routes |
|---|---|
| Auth | `GET /api/auth/google`, `/google/callback`, `POST /api/auth/google/native`, `POST /api/auth/logout`, `GET/PATCH /api/me` |
| Reels | `POST /api/reels`, `GET /api/reels/:id`, `GET /api/reels/:id/status` |
| Restaurants | `GET /api/restaurants/:slug`, `GET /api/restaurants/search`, `GET /api/surprise` |
| Lists | `GET/POST /api/lists`, `GET/PATCH/DELETE /api/lists/:id`, `POST /api/lists/:id/items`, `DELETE /api/lists/:id/items/:restaurantId` |
| Saves | `GET/POST /api/saves`, `DELETE /api/saves/:restaurantId` |

Auth = cookie (web) **or** `Authorization: Bearer` (mobile) — both resolve to the same
`auth_sessions` row. Errors use `{ statusCode, statusMessage, message }`.

## Reel pipeline

`POST /api/reels` requires a session, saves the reel for the current user, and
dedupes the canonical `reels` row by Instagram shortcode. A queued D1 job is
created only for a new canonical reel. If another user already saved the same
reel, the API reuses that base reel and only adds the current user's
`saved_reels` ref. The FastAPI service in `../worker` claims jobs through
service-token authenticated internal routes, extracts caption/comments, uses
OpenAI for structured location clues, and uses OpenAI-suggested address/lat/lng
as the location. Audio is downloaded and transcribed only when text evidence
does not resolve a confident location.

## Not yet built

- Comment sentiment analysis, trust scoring, and summarization.
- **Foodlists + Visits** — Phase 2 (contract reserved in docs/api.md).
- **Search** uses `LIKE` (not FTS5); **media URLs** are direct `https://media.theta.in/<key>`
  (not R2 signed URLs). Both are noted upgrades.

## Before deploying

1. `wrangler d1 create theta` → paste real `database_id` into `wrangler.toml`.
2. Secrets: `wrangler secret put GOOGLE_CLIENT_ID` (and `GOOGLE_CLIENT_SECRET`,
   `SERVICE_TOKEN`); set `APP_URL` in `[vars]`.
3. `npm run db:migrate:remote` then `npm run deploy`.
