# Theta API

V1 backend for Theta.in — Nuxt 3 server routes on Cloudflare Workers + D1 (SQLite).
Contract: [docs/api.md](../docs/api.md). Schema: [docs/tech-architecture.md](../docs/tech-architecture.md).

Auth layer (Google OAuth, sessions) reused from the `mandiboard` base app, extended
with a **bearer-token** path for the Flutter mobile app.

## Run locally

```bash
npm install
cp .dev.vars.example .dev.vars     # fill Google client id/secret for real OAuth
npm run build                      # nuxt build (nitro cloudflare-module)
npm run db:migrate:local           # apply migrations/ to local D1
npm run db:seed:local              # load demo restaurant/reel (seeds/seed.sql)
npx wrangler dev .output/server/index.mjs --assets .output/public --local --port 8799
```

Then:
```bash
curl localhost:8799/api/restaurants/al-reem-kuzhi-mandi
curl "localhost:8799/api/restaurants/search?lat=11.25&lng=75.77&radiusKm=10&sort=distance"
curl localhost:8799/api/surprise?city=Kozhikode
```

`npm run dev` (plain nuxt dev) does NOT bind D1 — use `wrangler dev` for anything touching the database.

## Layout

```
server/utils/    auth, crypto, db, schema, google, reels, restaurants, pagination, json, text
server/api/      auth/* me reels/* restaurants/* surprise lists/* saves/*
migrations/      0001_auth.sql  0002_theta_core.sql      (prod-safe, applied remotely)
seeds/           seed.sql                                 (local demo data only)
```

## Implemented (V1)

| Area | Routes |
|---|---|
| Auth | `GET /api/auth/google`, `/callback`, `POST /api/auth/google/native`, `POST /api/auth/logout`, `GET/PATCH /api/me` |
| Reels | `POST /api/reels`, `GET /api/reels/:id`, `GET /api/reels/:id/status` |
| Restaurants | `GET /api/restaurants/:slug`, `GET /api/restaurants/search`, `GET /api/surprise` |
| Lists | `GET/POST /api/lists`, `GET/PATCH/DELETE /api/lists/:id`, `POST /api/lists/:id/items`, `DELETE /api/lists/:id/items/:restaurantId` |
| Saves | `GET/POST /api/saves`, `DELETE /api/saves/:restaurantId` |

## Not yet built

- **Reel processing pipeline** — `POST /api/reels` creates a `pending` reel + a `queued` job row; the FastAPI worker that downloads/transcribes/summarizes and the `POST /api/internal/jobs/:type` write-back route are not implemented. Reels stay `pending` until that lands.
- **Foodlists + Visits** — Phase 2 (contract reserved in docs/api.md).
- **Search** uses `LIKE` (not FTS5) and **media URLs** are direct `https://media.theta.in/<key>` (not R2 signed URLs) — both noted as upgrades.

## Before deploying

1. `wrangler d1 create theta` → paste real `database_id` into `wrangler.toml`.
2. Set secrets: `NUXT_PUBLIC_GOOGLE_CLIENT_ID`, `NUXT_GOOGLE_CLIENT_SECRET`, `NUXT_SERVICE_TOKEN`, `NUXT_PUBLIC_APP_URL`.
3. `npm run db:migrate:remote` then `npm run deploy`.
