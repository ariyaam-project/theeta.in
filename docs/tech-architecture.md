# Theta.in — Technical Architecture (V1)

> Companion to [prd.md](./prd.md). Reflects the **real** stack: built on top of the existing `mandiboard` app (`/Users/sunithvs/entri-vibecoding/mandi.theeta`) — **Nuxt 3 + Cloudflare D1 + Google OAuth**.

---

## 1. Reuse Decision (the existing base)

Theta is built on the existing `mandiboard` Nuxt/Cloudflare app. We **reuse the entire auth + user layer as-is**:

| Reused asset | What it gives us |
|---|---|
| `users` table | Google OAuth identity (`google_sub`, email, display_name, avatar_url) |
| `auth_sessions` table | Cookie session, sha256 token-hash, 30-day TTL |
| Google OAuth flow | `server/api/auth/google/index.get.ts` + `callback.get.ts` |
| Session utils | `auth.ts`, `crypto.ts`, `cookies.ts`, `security.ts`, `db.ts`, `schema.ts` |
| Account routes | `me.get.ts`, `me.patch.ts`, `logout.post.ts` |
| Infra | Nuxt 3 (Nitro `cloudflare-module`), `wrangler.toml`, D1 binding `DB` |

**Dropped (mandi-specific, irrelevant to Theta):** `mandi_sessions` table, `leaderboard.get.ts`, and the `initial_life_expectancy_years` column on `users` (leave it; ignore it).

**New auth helper:** `getCurrentUser()` already returns `null` for anon — reuse it directly for optional-auth reel submits.

---

## 2. Stack

| Layer | Choice | Notes |
|---|---|---|
| Web app | **Nuxt 3** (existing) on Cloudflare Pages/Workers | SSR restaurant pages for SEO |
| Mobile app | **Flutter** (iOS + Android) | Hits same Nuxt server routes (`/api/*`) |
| Server / API | **Nuxt server routes** (Nitro on CF Workers) | Auth, reads/writes, enqueue — same pattern as existing endpoints |
| Database | **Cloudflare D1 (SQLite)** — binding `DB` | Reuse existing DB; extend with Theta tables |
| Queue | **Cloudflare Queues** | Decouple submit → processing |
| Object storage | **Cloudflare R2** | Reel video/audio/thumbnails, OCR frames |
| Cache / KV | **Cloudflare KV** | Hot restaurant JSON, rate limits |
| Heavy worker | **FastAPI** (container: Fly.io / Railway / VPS) | Reel download, transcription, OCR, LLM — can't run on Workers |
| Search | **SQLite FTS5** (name/area) + **Haversine** (geo) | D1 has no PostGIS/trigram; fine at MVP scale |

**Why D1 not Postgres:** the existing base is D1, and reusing auth means staying on it. At MVP scale (PRD: 1k restaurants, 5k reels) FTS5 + Haversine cover search/geo. Revisit Postgres/pgvector at Phase 2 (AI assistant needs vectors).

**Workers vs FastAPI cutoff:** Workers do anything CPU-light and < 30s. FastAPI does anything that downloads media, runs ffmpeg/Whisper/OCR, or calls an LLM with large context.

---

## 3. Architecture

```
┌──────────────┐     ┌──────────────┐
│  Nuxt 3 web  │     │   Flutter    │
│  (CF)        │     │  (iOS/Andrd) │
└──────┬───────┘     └──────┬───────┘
       │   /api/* (cookie/JSON)
       └─────────┬───────────┘
                 ▼
        ┌─────────────────────┐      ┌──────────────┐
        │ Nuxt server routes   │ KV  │ KV (cache/   │
        │ (Nitro on Workers)   │◄───►│ rate/places) │
        │ - reuse auth/session │     └──────────────┘
        │ - reads/writes       │
        │ - enqueue reel jobs  │     ┌──────────────┐
        │ - R2 signed URLs     │────►│  D1 (SQLite) │
        └───┬──────────────┬───┘     │  binding DB  │
   enqueue  │              │ r/w     └──────────────┘
            ▼              ▼
   ┌────────────────┐                ┌──────────────┐
   │ CF Queue       │                │ R2 bucket    │
   └───────┬────────┘                │ video/audio  │
           │ consumer                └──────▲───────┘
           ▼                                │
   ┌──────────────────────────┐             │
   │ FastAPI heavy worker      │─────────────┘
   │ yt-dlp / IG scrape        │   ┌──────────────────┐
   │ Whisper / ffmpeg / OCR    │──►│ OpenAI location  │
   │ LLM entity + sentiment    │   │ IG scrape provider│
   │ trust score + summary     │   │ LLM (Claude/GPT) │
   │ writes D1 over HTTP        │   └──────────────────┘
   └──────────────────────────┘
```

**D1 access from FastAPI:** D1 has no native socket driver for Python. FastAPI writes results back via an **internal Nuxt route** (`/api/internal/jobs/:type`, service-token auth) which does the D1 write — OR via the **D1 REST API** (`/d1/database/.../query`). Recommend the internal-route path: keeps all D1 writes in one place, reuses `ensureSchema`.

---

## 4. Processing Pipeline (PRD Steps 1–6)

| # | Step | Service | Writes |
|---|---|---|---|
| 1 | Save + dedupe canonical reel | Worker route | `saved_reels` per user; `reels` canonical by shortcode → enqueue only once |
| 2 | Extract (caption, thumb, audio, creator) | FastAPI | `reels`, `creators`, R2 |
| 3 | Transcribe audio | FastAPI | `transcripts` |
| 4 | Detect restaurant (caption+transcript+OCR+tags) | FastAPI | `reel_entities` |
| 5 | Resolve place with AI-suggested address/lat/lng | FastAPI | `restaurants`, `restaurant_reels` |
| 6 | Comments + sentiment | FastAPI | `comments`, `comment_analysis` |
| 7 | Trust score + AI summary | FastAPI | `trust_scores`, `ai_summaries`, reel → `complete` |
| 8 | Publish | Nuxt route | invalidate KV restaurant page |

`reels.status` machine: `pending → downloading → transcribing → detecting → resolving → analyzing_comments → summarizing → complete` (any → `failed`). Each step is a `processing_jobs` row with retry/backoff. `saved_reels.status` is the user's ref state: `processing → processed` or `failed`.

---

## 5. Database Schema (D1 / SQLite)

### SQLite conventions (differ from Postgres)
- **IDs:** `TEXT PRIMARY KEY`, value from `crypto.randomUUID()` (matches existing `users`).
- **Timestamps:** `TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP` (ISO-ish), like existing tables.
- **Enums:** no native type → `TEXT` + `CHECK (col IN (...))`.
- **Arrays:** no native type → JSON string (`TEXT`, read with `json_extract`) or junction table.
- **Booleans:** `INTEGER` (0/1).
- **Decimals:** `REAL`.
- **Geo:** `lat`/`lng REAL` + Haversine in SQL (no PostGIS).
- **FKs:** `FOREIGN KEY (...) REFERENCES ... ON DELETE CASCADE`.

New tables ship as migration files `migrations/0003_theta_core.sql` onward, mirrored in `ensureSchema()`.

### 5.1 `users` — **reused, unchanged**
Existing columns: `id, google_sub, email, display_name, avatar_url, initial_life_expectancy_years (ignored), created_at, updated_at, last_login_at`. Theta tables FK to `users(id)`.

### 5.2 `creators`
```sql
CREATE TABLE IF NOT EXISTS creators (
  id TEXT PRIMARY KEY,
  ig_user_id TEXT UNIQUE,
  username TEXT NOT NULL UNIQUE,
  full_name TEXT,
  profile_pic_url TEXT,
  follower_count INTEGER,
  is_verified INTEGER NOT NULL DEFAULT 0,
  credibility_score REAL,                 -- future: PRD creator credibility
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### 5.3 `reels`
```sql
CREATE TABLE IF NOT EXISTS reels (
  id TEXT PRIMARY KEY,
  ig_shortcode TEXT NOT NULL UNIQUE,      -- parsed from URL = dedupe key
  url TEXT NOT NULL,
  caption TEXT,
  thumbnail_url TEXT,                      -- R2 key
  video_r2_key TEXT,
  audio_r2_key TEXT,
  creator_id TEXT,
  location_tag TEXT,
  posted_at TEXT,
  like_count INTEGER,
  comment_count INTEGER,
  view_count INTEGER,
  submitted_by TEXT,                       -- first user who submitted the canonical reel
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','downloading','transcribing','detecting',
                      'resolving','analyzing_comments','summarizing','complete','failed')),
  error TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (creator_id) REFERENCES creators(id) ON DELETE SET NULL,
  FOREIGN KEY (submitted_by) REFERENCES users(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_reels_status ON reels(status);
CREATE INDEX IF NOT EXISTS idx_reels_creator ON reels(creator_id);
```

### 5.4 `transcripts`
```sql
CREATE TABLE IF NOT EXISTS transcripts (
  id TEXT PRIMARY KEY,
  reel_id TEXT NOT NULL UNIQUE,
  language TEXT,
  text TEXT,
  segments TEXT,                           -- JSON: [{start,end,text}]
  model_used TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (reel_id) REFERENCES reels(id) ON DELETE CASCADE
);
```

### 5.5 `restaurants`
```sql
CREATE TABLE IF NOT EXISTS restaurants (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,               -- SEO URL
  google_place_id TEXT UNIQUE,
  address TEXT,
  area TEXT,
  city TEXT,
  lat REAL,
  lng REAL,
  google_maps_url TEXT,
  phone TEXT,
  cuisine TEXT,                            -- JSON array of strings
  price_level INTEGER,                     -- 1..4
  status TEXT NOT NULL DEFAULT 'unverified'
    CHECK (status IN ('unverified','active','closed')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_restaurants_geo ON restaurants(lat, lng);   -- bbox prefilter
CREATE INDEX IF NOT EXISTS idx_restaurants_city_area ON restaurants(city, area);
```

### 5.6 `restaurants_fts` (SQLite FTS5 — name/area/city search)
```sql
CREATE VIRTUAL TABLE IF NOT EXISTS restaurants_fts USING fts5(
  name, area, city,
  restaurant_id UNINDEXED
);
-- keep in sync via triggers on restaurants INSERT/UPDATE/DELETE
```

### 5.7 `restaurant_photos`
```sql
CREATE TABLE IF NOT EXISTS restaurant_photos (
  id TEXT PRIMARY KEY,
  restaurant_id TEXT NOT NULL,
  r2_key TEXT NOT NULL,
  source TEXT CHECK (source IN ('reel','google_places','user')),
  source_reel_id TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
  FOREIGN KEY (source_reel_id) REFERENCES reels(id) ON DELETE SET NULL
);
```

### 5.8 `restaurant_reels` (junction — reel ↔ restaurant)
```sql
CREATE TABLE IF NOT EXISTS restaurant_reels (
  id TEXT PRIMARY KEY,
  restaurant_id TEXT NOT NULL,
  reel_id TEXT NOT NULL,
  confidence REAL,                         -- 0..1 detection confidence
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (restaurant_id, reel_id),
  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
  FOREIGN KEY (reel_id) REFERENCES reels(id) ON DELETE CASCADE
);
```
Powers "reels analysed" + "creators mentioning" counts.

### 5.9 `reel_entities` (raw detection per reel)
```sql
CREATE TABLE IF NOT EXISTS reel_entities (
  id TEXT PRIMARY KEY,
  reel_id TEXT NOT NULL,
  restaurant_name_raw TEXT,                -- pre-resolution
  area_raw TEXT,
  cuisine TEXT,                            -- JSON array
  dishes TEXT,                             -- JSON array
  sources TEXT,                            -- JSON: which signal hit {caption,transcript,ocr,tag}
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (reel_id) REFERENCES reels(id) ON DELETE CASCADE
);
```

### 5.10 `dishes` + `restaurant_dishes`
```sql
CREATE TABLE IF NOT EXISTS dishes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  normalized_name TEXT NOT NULL UNIQUE     -- dedupe, e.g. 'kuzhi mandi'
);
CREATE TABLE IF NOT EXISTS restaurant_dishes (
  restaurant_id TEXT NOT NULL,
  dish_id TEXT NOT NULL,
  mention_count INTEGER NOT NULL DEFAULT 1,
  sentiment_score REAL,
  PRIMARY KEY (restaurant_id, dish_id),
  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
  FOREIGN KEY (dish_id) REFERENCES dishes(id) ON DELETE CASCADE
);
```
Powers "Best dishes" / "Highlights".

### 5.11 `comments` + `comment_analysis`
```sql
CREATE TABLE IF NOT EXISTS comments (
  id TEXT PRIMARY KEY,
  reel_id TEXT NOT NULL,
  ig_comment_id TEXT UNIQUE,
  author_username TEXT,
  text TEXT,
  like_count INTEGER,
  posted_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (reel_id) REFERENCES reels(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_comments_reel ON comments(reel_id);

CREATE TABLE IF NOT EXISTS comment_analysis (
  id TEXT PRIMARY KEY,
  comment_id TEXT NOT NULL UNIQUE,
  sentiment TEXT CHECK (sentiment IN ('positive','negative','neutral')),
  score REAL,
  topics TEXT,                             -- JSON array {price,service,taste}
  is_spam INTEGER NOT NULL DEFAULT 0,
  is_sponsored_flag INTEGER NOT NULL DEFAULT 0,  -- "sponsored review" detector
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE
);
```

### 5.12 `trust_scores` (versioned per restaurant)
```sql
CREATE TABLE IF NOT EXISTS trust_scores (
  id TEXT PRIMARY KEY,
  restaurant_id TEXT NOT NULL,
  score INTEGER NOT NULL,                  -- 0..100
  creator_signal TEXT,                     -- JSON: paid-partnership/sponsored flags
  audience_signal TEXT,                    -- JSON: complaint vs praise ratio
  historical_signal TEXT,                  -- JSON: #creators, sentiment consistency
  computed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_trust_latest ON trust_scores(restaurant_id, computed_at DESC);
```

### 5.13 `ai_summaries` (versioned per restaurant)
```sql
CREATE TABLE IF NOT EXISTS ai_summaries (
  id TEXT PRIMARY KEY,
  restaurant_id TEXT NOT NULL,
  trust_score INTEGER,                     -- snapshot shown
  common_praise TEXT,                      -- JSON array
  common_complaints TEXT,                  -- JSON array
  best_dishes TEXT,                        -- JSON array
  verdict TEXT,
  model_used TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
);
```

### 5.14 `lists` + `list_items` + `list_collaborators`
```sql
CREATE TABLE IF NOT EXISTS lists (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  slug TEXT,
  description TEXT,
  cover_r2_key TEXT,
  is_public INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS list_items (
  id TEXT PRIMARY KEY,
  list_id TEXT NOT NULL,
  restaurant_id TEXT NOT NULL,
  note TEXT,
  position INTEGER,
  added_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (list_id, restaurant_id),
  FOREIGN KEY (list_id) REFERENCES lists(id) ON DELETE CASCADE,
  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
);
-- Phase 2
CREATE TABLE IF NOT EXISTS list_collaborators (
  list_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  role TEXT CHECK (role IN ('owner','editor','viewer')),
  PRIMARY KEY (list_id, user_id),
  FOREIGN KEY (list_id) REFERENCES lists(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### 5.14b `foodlists` — social publishing (Phase 2)
A foodlist = a *published* `list`. No separate table; add publish state + denormalized social counters to `lists`, plus like/save/rate junctions.
```sql
ALTER TABLE lists ADD COLUMN published_at TEXT;             -- non-null = published foodlist
ALTER TABLE lists ADD COLUMN like_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE lists ADD COLUMN save_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE lists ADD COLUMN rating_sum INTEGER NOT NULL DEFAULT 0;   -- avg = rating_sum/rating_count
ALTER TABLE lists ADD COLUMN rating_count INTEGER NOT NULL DEFAULT 0;
CREATE INDEX IF NOT EXISTS idx_lists_feed ON lists(published_at DESC) WHERE published_at IS NOT NULL;

CREATE TABLE IF NOT EXISTS foodlist_likes (
  list_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (list_id, user_id),
  FOREIGN KEY (list_id) REFERENCES lists(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS foodlist_saves (
  list_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (list_id, user_id),
  FOREIGN KEY (list_id) REFERENCES lists(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS foodlist_ratings (
  list_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (list_id, user_id),               -- one rating per user per foodlist (upsert)
  FOREIGN KEY (list_id) REFERENCES lists(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```
Counters (`like_count`, `save_count`, `rating_sum`, `rating_count`) updated transactionally alongside junction insert/delete so feed sorts (`popular`/`top_rated`) need no aggregation. `foodlist_saves` = saved a whole foodlist (vs `saved_restaurants` = saved one restaurant).

### 5.15 `saved_restaurants` (bookmark)
```sql
CREATE TABLE IF NOT EXISTS saved_restaurants (
  user_id TEXT NOT NULL,
  restaurant_id TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, restaurant_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
);
```

### 5.16 `visits` (Phase 2 — community)
```sql
CREATE TABLE IF NOT EXISTS visits (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  restaurant_id TEXT NOT NULL,
  rating INTEGER,                          -- 1..5
  feedback TEXT,
  confirmed_recommendation INTEGER NOT NULL DEFAULT 0,
  visited_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
);
```

### 5.17 `processing_jobs` (queue audit / retry)
```sql
CREATE TABLE IF NOT EXISTS processing_jobs (
  id TEXT PRIMARY KEY,
  reel_id TEXT NOT NULL,
  type TEXT NOT NULL
    CHECK (type IN ('extract','transcribe','ocr','detect','resolve','comments','summary')),
  status TEXT NOT NULL DEFAULT 'queued'
    CHECK (status IN ('queued','running','succeeded','failed','dead')),
  attempts INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL DEFAULT 3,
  payload TEXT,                            -- JSON
  error TEXT,
  started_at TEXT,
  finished_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (reel_id) REFERENCES reels(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_jobs_reel_type ON processing_jobs(reel_id, type);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON processing_jobs(status);
```

### 5.18 `places_cache` (reserved provider cache)
```sql
CREATE TABLE IF NOT EXISTS places_cache (
  google_place_id TEXT PRIMARY KEY,
  raw TEXT,                                -- JSON full response
  fetched_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### 5.19 ER summary
```
users ─< lists ─< list_items >─ restaurants
users ─< saved_restaurants >─ restaurants
users ─< visits >─ restaurants
users ─< reels (submitted_by)
creators ─< reels ─< transcripts
                  ├─< comments ─< comment_analysis
                  ├─< reel_entities
                  ├─< processing_jobs
                  └─< restaurant_reels >─ restaurants
restaurants ─< restaurant_photos
restaurants ─< restaurant_dishes >─ dishes
restaurants ─< trust_scores
restaurants ─< ai_summaries
restaurants ─ restaurants_fts (FTS5 mirror)
```

---

## 6. API Surface (Nuxt server routes)

Same pattern as existing endpoints: `defineEventHandler` + `assertSameOrigin` + `requireCurrentUser`/`getCurrentUser` + `getDb` + `ensureSchema`.

| Method | Route | Auth | Purpose |
|---|---|---|---|
| POST | `/api/reels` | optional (`getCurrentUser`) | Validate + dedupe + enqueue reel |
| GET | `/api/reels/:id/status` | optional | Poll pipeline status |
| GET | `/api/restaurants/:slug` | public | Restaurant page (KV-cached) |
| GET | `/api/restaurants/search` | public | FTS5 name + bbox/Haversine geo + filters |
| GET | `/api/surprise` | public | Random trusted place by location/cuisine/budget |
| POST | `/api/lists` | required | Create list |
| POST | `/api/lists/:id/items` | required | Add restaurant |
| GET | `/api/lists/:id` | public if `is_public` | View list |
| POST | `/api/saves` | required | Bookmark |
| POST | `/api/internal/jobs/:type` | service token | FastAPI → D1 write-back per pipeline step |

Auth = existing cookie session (`mandi_session` cookie; rename to `theta_session` in `constants.ts` if desired). Anon reel submit allowed; claimed on signup via `reels.submitted_by`.

---

## 7. FastAPI Heavy Worker

Internal, service-token auth. One endpoint per pipeline step, **idempotent**, keyed on `(reel_id, type)` in `processing_jobs`.

| Endpoint | Does |
|---|---|
| `POST /jobs/extract` | Download media → R2; upsert `creators`, fill `reels` |
| `POST /jobs/transcribe` | ffmpeg audio → Whisper → `transcripts` |
| `POST /jobs/ocr` | Sample frames → OCR → merge into detection signals |
| `POST /jobs/detect` | LLM entity extraction → `reel_entities` |
| `POST /jobs/resolve` | AI suggested location → `restaurants`, `restaurant_reels` |
| `POST /jobs/comments` | Fetch comments → sentiment → `comments`, `comment_analysis` |
| `POST /jobs/summary` | Compute `trust_scores` + `ai_summaries`; reel → `complete` |

**Writes back to D1** via `/api/internal/jobs/:type` (Nuxt) so all D1 access shares `ensureSchema` + one binding. Media binaries go straight to R2 (S3-compatible).

---

## 8. Trust Score (PRD Trust Engine)

Stored in `trust_scores`, recomputed on each new reel resolving to the restaurant; latest row by `computed_at` is live:
```
score = w1 * audience_positive_ratio
      - w2 * sponsored_penalty        (creator_signal: paid-partnership, #ad)
      + w3 * historical_consistency   (multiple creators, stable sentiment)
      - w4 * complaint_severity
```

---

## 9. Search on D1 (no PostGIS/trigram)

- **Name/text:** `restaurants_fts` (FTS5), synced by triggers. `MATCH` query for name/area/city.
- **Geo radius:** bounding-box prefilter on indexed `(lat,lng)` → Haversine in SQL for exact distance + sort:
  ```sql
  SELECT *, (6371 * acos(
      cos(radians(?lat)) * cos(radians(lat)) * cos(radians(lng) - radians(?lng))
      + sin(radians(?lat)) * sin(radians(lat)))) AS km
  FROM restaurants
  WHERE lat BETWEEN ?minLat AND ?maxLat AND lng BETWEEN ?minLng AND ?maxLng
  ORDER BY km LIMIT ?;
  ```
- **Surprise Me:** filter by city/cuisine/price + min trust score, `ORDER BY RANDOM() LIMIT 1`.

---

## 10. Cross-Cutting

- **Dedupe:** `reels.ig_shortcode` UNIQUE + KV lock during processing → re-submit returns existing.
- **Caching:** restaurant JSON in KV, invalidated on new `ai_summaries`/`trust_scores`.
- **Media:** binaries in R2; D1 stores keys only; Nuxt issues R2 signed URLs.
- **Rate limiting:** per-IP/user submit caps in KV (scrape providers are metered) — reuse the same-origin guard already in `security.ts`.
- **Retries:** `processing_jobs.attempts/max_attempts`, dead-letter on exhaust.
- **Migrations:** add `migrations/0003_theta_core.sql` (+ later), and mirror in `ensureSchema()` so local dev auto-applies — exact pattern the existing app uses.

---

## 11. Open Decisions

1. **IG scrape provider** — yt-dlp (cheap, fragile) vs paid API (Apify/ScrapingDog, metered). Affects extract + comments.
2. **Transcription** — self-host Whisper on FastAPI GPU vs API (Deepgram/OpenAI).
3. **D1 size ceiling** — 10 GB/DB. At 5k reels metadata-only is tiny (media in R2), fine. Re-check before 100k+ reels.
4. **D1 write-back path** — internal Nuxt route (recommended) vs D1 REST API direct from FastAPI.
5. **Cookie/name rebrand** — `mandi_session` → `theta_session`? Cosmetic; reuse works either way.
6. **Phase 2 vectors** — AI assistant + semantic search likely forces pgvector/Vectorize; plan migration path off D1 then.
