# Theta.in — API Contract (V1)

> Frozen contract so web (Nuxt), mobile (Flutter), and backend (Nuxt server routes + FastAPI) build in parallel. See [tech-architecture.md](./tech-architecture.md) for the data model and [prd.md](./prd.md) for product intent.

- **Base URL:** `https://theta.in` (dev: `http://localhost:3000`)
- **Prefix:** all endpoints under `/api`
- **Format:** JSON request + response, UTF-8
- **IDs:** opaque strings (UUID v4)
- **Timestamps:** ISO-8601 UTC strings, e.g. `2026-06-06T10:20:30Z`

---

## 1. Auth

Google OAuth only in V1. **Two transports, one session store** — both resolve to the same `auth_sessions` row (token hashed). Web uses the cookie; mobile uses a bearer token.

A request is authenticated if it carries **either**:
- Cookie `theta_session` (web), **or**
- Header `Authorization: Bearer <token>` (mobile).

### Web flow (cookie)
1. Open `GET /api/auth/google` → 302 to Google consent.
2. Google → `GET /api/auth/google/callback` → sets `theta_session` httpOnly cookie → 302 to `appUrl`.
3. Browser sends the cookie automatically on every `/api` call.

### Mobile flow (bearer token — native Google Sign-In)
1. Flutter runs native **Google Sign-In** SDK (`google_sign_in`) on-device → gets a Google **ID token**. No webview, no cookie capture.
2. `POST /api/auth/google/native` with `{ "idToken": "<google_id_token>" }`.
3. Backend verifies the ID token with Google, upserts the user, creates an `auth_sessions` row, returns a **Theta bearer token**.
4. Flutter stores the token in secure storage (`flutter_secure_storage`) and sends `Authorization: Bearer <token>` on every `/api` call.

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/api/auth/google` | none | Web: start OAuth, 302 to Google |
| GET | `/api/auth/google/callback` | none | Web: OAuth return, sets cookie, 302 |
| POST | `/api/auth/google/native` | none | Mobile: exchange Google ID token → Theta bearer token |
| POST | `/api/auth/logout` | session | Revoke current session (cookie or token) |
| GET | `/api/me` | optional | Current user (or `null`) |
| PATCH | `/api/me` | session | Update profile fields |

### `POST /api/auth/google/native`
```json
// request
{ "idToken": "eyJhbGciOi..." }
```
```json
// 200
{
  "token": "tok_3f9a8c...",
  "expiresAt": "2026-07-06T10:20:30Z",
  "user": { "id": "9b1f...", "displayName": "Sunith", "avatarUrl": "https://...", "email": "hello@latelogic.com" }
}
```
Invalid/expired ID token → 401.

**`POST /api/auth/logout`** revokes only the session presented (deletes that `auth_sessions` row + clears cookie if present). Token clients should also drop the token from secure storage.

**Cookie:** `theta_session`, httpOnly, SameSite=Lax, 30-day TTL. **Token:** opaque, same 30-day TTL, same `auth_sessions` store.

### `GET /api/me`
Auth: optional. Returns `null` when not logged in (200, not 401).
```json
{
  "user": {
    "id": "9b1f...",
    "displayName": "Sunith",
    "avatarUrl": "https://lh3.googleusercontent.com/...",
    "email": "hello@latelogic.com"
  }
}
```
Logged out → `{ "user": null }`.

### `PATCH /api/me`
Body (all optional): `{ "displayName": "New Name" }`
Returns updated `{ "user": { ... } }`.

---

## 2. Conventions

### Error shape (h3 default)
Non-2xx responses:
```json
{
  "statusCode": 401,
  "statusMessage": "Authentication required",
  "message": "Authentication required"
}
```
Clients should branch on `statusCode`. Common codes: `400` validation, `401` no session, `403` same-origin/permission, `404` not found, `409` duplicate, `429` rate limit, `500` server.

### Pagination
List endpoints accept `?page=1&limit=20` (limit max 50). Response:
```json
{ "items": [ ... ], "page": 1, "limit": 20, "total": 134 }
```

### Auth column
`none` = public · `optional` = works logged-out, richer logged-in · `session` = 401 without cookie.

---

## 3. Reels (submit + processing)

### `POST /api/reels` — save/submit a reel
Auth: session. Creates a per-user saved-reel ref and reuses the canonical reel if another user already submitted the same Instagram shortcode.
```json
// request
{ "url": "https://www.instagram.com/reel/Cxyz123/" }
```
```json
// 202 Accepted — new canonical reel, or existing reel still processing
{
  "reel": {
    "id": "r_8af2...",
    "shortcode": "Cxyz123",
    "status": "pending",
    "url": "https://www.instagram.com/reel/Cxyz123/",
    "createdAt": "2026-06-06T10:20:30Z"
  },
  "savedReel": {
    "reelId": "r_8af2...",
    "status": "processing"
  },
  "deduped": false
}
```
- If another user already saved the same reel, the existing canonical reel is reused and the current user gets their own `saved_reels` row.
- Already-processed reel → **200** with `"deduped": true`, the existing reel, `savedReel.status: "processed"`, and its `restaurant` if resolved.
- Existing processing reel → **202** with `"deduped": true` and `savedReel.status: "processing"`.
- Invalid/non-reel URL → **400**.
- Missing session → **401**.
- Rate limited → **429**.

Client then **polls** `GET /api/reels/:id/status` until terminal.

### `GET /api/reels/:id/status` — lightweight poll
Auth: optional.
```json
{
  "id": "r_8af2...",
  "status": "summarizing",
  "savedStatus": "processing",
  "savedAt": "2026-06-06T10:20:30Z",
  "step": 7,
  "totalSteps": 8,
  "restaurantSlug": null,
  "error": null
}
```
`status` ∈ `pending · downloading · transcribing · detecting · resolving · analyzing_comments · summarizing · complete · failed`.
When `complete`: `restaurantSlug` is set → navigate to the restaurant page. When `failed`: `error` has a human message.

### `GET /api/reels/saved/list` — current user's saved reels
Auth: session.
```json
{
  "items": [
    {
      "reelId": "r_8af2...",
      "savedStatus": "processed",
      "savedAt": "2026-06-06T10:20:30Z",
      "reel": {
        "id": "r_8af2...",
        "shortcode": "Cxyz123",
        "url": "https://www.instagram.com/reel/Cxyz123/",
        "status": "complete",
        "caption": "Best shawarma in Kozhikode 🌯",
        "thumbnailUrl": "https://media.theta.in/...jpg",
        "createdAt": "2026-06-06T10:20:30Z"
      }
    }
  ]
}
```

### `GET /api/reels/:id` — full reel detail
Auth: optional.
```json
{
  "reel": {
    "id": "r_8af2...",
    "shortcode": "Cxyz123",
    "url": "https://www.instagram.com/reel/Cxyz123/",
    "status": "complete",
    "caption": "Best shawarma in Kozhikode 🌯",
    "thumbnailUrl": "https://media.theta.in/...jpg",
    "postedAt": "2026-05-30T18:00:00Z",
    "likeCount": 12400,
    "commentCount": 318,
    "creator": {
      "id": "c_1...", "username": "kozhikode_foodie",
      "fullName": "Kozhikode Foodie", "profilePicUrl": "https://...",
      "isVerified": false
    },
    "transcript": "This hidden shawarma spot near South Beach...",
    "restaurant": { "id": "rest_5...", "slug": "al-reem-kuzhi-mandi", "name": "Al Reem Kuzhi Mandi" }
  }
}
```

---

## 4. Restaurants

### `GET /api/restaurants/:slug` — restaurant page
Auth: optional. The hero payload for the restaurant page (PRD §Restaurant Page).
```json
{
  "restaurant": {
    "id": "rest_5...",
    "slug": "al-reem-kuzhi-mandi",
    "name": "Al Reem Kuzhi Mandi",
    "address": "South Beach Rd, Kozhikode, Kerala",
    "area": "South Beach",
    "city": "Kozhikode",
    "lat": 11.2519, "lng": 75.7682,
    "googleMapsUrl": "https://maps.google.com/?cid=...",
    "phone": "+91...",
    "cuisine": ["Arabic", "Mandi"],
    "priceLevel": 2,
    "photos": [
      { "url": "https://media.theta.in/...jpg", "source": "reel" }
    ],
    "trustScore": 87,
    "sentiment": { "positive": 0.82, "negative": 0.18 },
    "stats": { "reelsAnalysed": 6, "creatorsMentioning": 4 },
    "summary": {
      "verdict": "Recommended for groups and families.",
      "commonPraise": ["Large portions", "Good value"],
      "commonComplaints": ["Weekend waiting time", "Parking issues"],
      "bestDishes": ["Chicken Kuzhi Mandi", "Mutton Mandi"]
    },
    "sourceReels": [
      {
        "id": "r_8af2...", "shortcode": "Cxyz123",
        "thumbnailUrl": "https://media.theta.in/...jpg",
        "url": "https://www.instagram.com/reel/Cxyz123/",
        "creator": { "username": "kozhikode_foodie", "isVerified": false }
      }
    ]
  }
}
```
Not found → 404.

### `GET /api/restaurants/search` — search + filter
Auth: optional. All query params optional; combine freely.

| Param | Type | Meaning |
|---|---|---|
| `q` | string | FTS5 match on name/area/city |
| `city` | string | exact city |
| `area` | string | exact area |
| `cuisine` | string | repeatable: `?cuisine=Mandi&cuisine=Arabic` |
| `priceMax` | int 1–4 | max price level |
| `lat`,`lng` | float | center for radius search |
| `radiusKm` | float | default 5; requires lat+lng |
| `minTrust` | int 0–100 | min trust score |
| `sort` | enum | `trust` (default) · `distance` (needs lat/lng) · `recent` |
| `page`,`limit` | int | pagination |

Response: paginated `RestaurantSummary[]`:
```json
{
  "items": [
    {
      "id": "rest_5...", "slug": "al-reem-kuzhi-mandi", "name": "Al Reem Kuzhi Mandi",
      "area": "South Beach", "city": "Kozhikode",
      "cuisine": ["Arabic", "Mandi"], "priceLevel": 2,
      "trustScore": 87,
      "thumbnailUrl": "https://media.theta.in/...jpg",
      "distanceKm": 1.2,
      "stats": { "reelsAnalysed": 6 }
    }
  ],
  "page": 1, "limit": 20, "total": 1
}
```
`distanceKm` present only when `lat`/`lng` supplied.

### `GET /api/surprise` — Surprise Me (PRD §Surprise Me)
Auth: optional. Returns one random trusted restaurant matching filters.

| Param | Type |
|---|---|
| `city` | string |
| `area` | string |
| `cuisine` | string (repeatable) |
| `priceMax` | int 1–4 |
| `minTrust` | int, default 70 |

```json
{ "restaurant": { /* RestaurantSummary */ } }
```
No match → 404 `{ "statusMessage": "No matching place found" }`.

---

## 5. Lists (PRD §Saved Lists)

### `GET /api/lists` — my lists
Auth: session.
```json
{
  "items": [
    {
      "id": "l_1...", "name": "Best Shawarmas", "slug": "best-shawarmas",
      "description": null, "isPublic": false, "coverUrl": null,
      "itemCount": 5, "createdAt": "2026-06-01T08:00:00Z"
    }
  ]
}
```

### `POST /api/lists`
Auth: session. Body: `{ "name": "Kozhikode Food Trip", "description": "", "isPublic": false }`
→ 201 `{ "list": { ...as above, itemCount: 0 } }`.

### `GET /api/lists/:id`
Auth: optional — public if `isPublic`, else 403 unless owner/collaborator. Returns list + items:
```json
{
  "list": { "id": "l_1...", "name": "Best Shawarmas", "isPublic": true, "owner": { "displayName": "Sunith" } },
  "items": [
    {
      "restaurant": { /* RestaurantSummary */ },
      "note": "go on weekdays",
      "addedAt": "2026-06-02T09:00:00Z"
    }
  ]
}
```

### `PATCH /api/lists/:id`
Auth: session (owner). Body any of: `{ "name", "description", "isPublic" }` → updated list.

### `DELETE /api/lists/:id`
Auth: session (owner) → 204.

### `POST /api/lists/:id/items`
Auth: session. Body: `{ "restaurantId": "rest_5...", "note": "optional" }` → 201 list item. Duplicate → 409.

### `DELETE /api/lists/:id/items/:restaurantId`
Auth: session → 204.

---

## 6. Saves / Bookmarks

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/api/saves` | session | My bookmarked restaurants (`RestaurantSummary[]`) |
| POST | `/api/saves` | session | Body `{ "restaurantId": "..." }` → 201 |
| DELETE | `/api/saves/:restaurantId` | session | 204 |

---

## 6A. Foodlists — social publishing (Phase 2, contract reserved)

A **foodlist** is a *published* list — a shareable, social playlist of restaurants ("Best Shawarmas in Kozhikode"). Built on the same `lists` table: a private list becomes a foodlist when published. Other users can **like**, **save**, and **rate** it. Counts are denormalized on the list for cheap feeds.

Distinction: `list_items` = restaurants *inside* a list (§5). `foodlist_saves` = users who saved someone else's *whole* foodlist (here).

| Method | Path | Auth | Purpose |
|---|---|---|---|
| POST | `/api/lists/:id/publish` | session (owner) | Publish a private list as a foodlist (sets public + `publishedAt`, enters feed) |
| POST | `/api/lists/:id/unpublish` | session (owner) | Remove from feed (back to private) |
| GET | `/api/foodlists` | optional | Discovery feed of published foodlists |
| GET | `/api/foodlists/:slug` | optional | Full foodlist: meta + restaurants + social counts + viewer state |
| GET | `/api/foodlists/saved` | session | Foodlists the current user saved |
| GET | `/api/users/:id/foodlists` | optional | A user's published foodlists |
| POST | `/api/foodlists/:id/like` | session | Like → 201 |
| DELETE | `/api/foodlists/:id/like` | session | Unlike → 204 |
| POST | `/api/foodlists/:id/save` | session | Save to my saved foodlists → 201 |
| DELETE | `/api/foodlists/:id/save` | session | Unsave → 204 |
| POST | `/api/foodlists/:id/rate` | session | Body `{ "rating": 1..5 }` → upsert my rating |

### `GET /api/foodlists` — discovery feed
Params: `sort` (`popular` default · `recent` · `top_rated`), `q`, `city`, `cuisine` (repeatable), `page`, `limit`.
```json
{
  "items": [
    {
      "id": "l_1...", "slug": "best-shawarmas-kozhikode",
      "name": "Best Shawarmas in Kozhikode", "description": "12 spots, ranked",
      "coverUrl": "https://media.theta.in/...jpg",
      "owner": { "id": "9b1f...", "displayName": "Sunith", "avatarUrl": "https://..." },
      "itemCount": 12,
      "likeCount": 340, "saveCount": 88,
      "ratingAvg": 4.6, "ratingCount": 52,
      "publishedAt": "2026-06-04T08:00:00Z",
      "viewer": { "liked": true, "saved": false, "rating": 5 }
    }
  ],
  "page": 1, "limit": 20, "total": 1
}
```
`viewer` present only when authenticated (else omitted/null).

### `GET /api/foodlists/:slug`
```json
{
  "foodlist": { /* FoodlistSummary as above */ },
  "items": [
    { "restaurant": { /* RestaurantSummary */ }, "note": "best after 7pm", "position": 1 }
  ]
}
```
Private/unpublished + not owner → 404.



| Method | Path | Auth | Purpose |
|---|---|---|---|
| POST | `/api/restaurants/:slug/visits` | session | Mark visited + feedback |
| GET | `/api/restaurants/:slug/visits` | optional | Recent community feedback |

Body: `{ "rating": 4, "feedback": "great mandi", "confirmedRecommendation": true }`. **Not built in V1** — listed so app nav can stub it.

---

## 8. Internal (FastAPI → Nuxt, not for clients)

`POST /api/internal/jobs/:type` — service-token auth (`Authorization: Bearer <SERVICE_TOKEN>`), writes pipeline results to D1. Types: `extract · transcribe · ocr · detect · resolve · comments · summary`. **App devs ignore this section.**

---

## 9. Type Reference

```ts
type ReelStatus =
  | 'pending' | 'downloading' | 'transcribing' | 'detecting'
  | 'resolving' | 'analyzing_comments' | 'summarizing' | 'complete' | 'failed'

interface User { id: string; displayName: string; avatarUrl: string | null; email: string }

interface Creator {
  id: string; username: string; fullName: string | null
  profilePicUrl: string | null; isVerified: boolean
}

interface RestaurantSummary {
  id: string; slug: string; name: string
  area: string | null; city: string | null
  cuisine: string[]; priceLevel: number | null
  trustScore: number | null
  thumbnailUrl: string | null
  distanceKm?: number
  stats: { reelsAnalysed: number }
}

interface RestaurantDetail extends RestaurantSummary {
  address: string | null; lat: number | null; lng: number | null
  googleMapsUrl: string | null; phone: string | null
  photos: { url: string; source: 'reel' | 'google_places' | 'user' }[]
  sentiment: { positive: number; negative: number }
  stats: { reelsAnalysed: number; creatorsMentioning: number }
  summary: {
    verdict: string
    commonPraise: string[]; commonComplaints: string[]; bestDishes: string[]
  } | null
  sourceReels: ReelCard[]
}

interface List {
  id: string; name: string; slug: string | null
  description: string | null; isPublic: boolean
  coverUrl: string | null; itemCount: number; createdAt: string
}

// Phase 2
interface FoodlistSummary {
  id: string; slug: string; name: string; description: string | null
  coverUrl: string | null
  owner: { id: string; displayName: string; avatarUrl: string | null }
  itemCount: number
  likeCount: number; saveCount: number
  ratingAvg: number | null; ratingCount: number
  publishedAt: string
  viewer?: { liked: boolean; saved: boolean; rating: number | null }
}
```

---

## 10. Build-in-parallel notes

- **Mock server:** every endpoint here has a fixed JSON shape — stand up a mock (Prism / Mockoon against these examples) so Flutter + Nuxt UI start before the backend is live.
- **The only async flow** is reel submit: `POST /api/reels` → poll `/status` → navigate on `complete`. Everything else is plain request/response.
- **Trust score** is always `0–100` or `null` (null = not yet computed).
- **Auth in Flutter:** native Google Sign-In SDK → `POST /api/auth/google/native` → store bearer token in `flutter_secure_storage` → send `Authorization: Bearer` on all calls. No cookie/webview needed. No token refresh in V1 (30-day token); re-auth on 401.
- **Auth on web:** cookie via OAuth redirect, sent automatically.
- **Breaking changes** bump to `/api/v2`. V1 shapes above are frozen.
```
