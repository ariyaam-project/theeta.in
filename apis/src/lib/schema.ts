import type { D1Database } from '@cloudflare/workers-types'

let schemaReady = false

/**
 * Idempotent schema bootstrap, mirrored from migrations/*.sql so local dev gets
 * the tables without a separate migrate step. Safe on every request.
 */
export async function ensureSchema(db: D1Database) {
  if (schemaReady) return

  await db.batch([
    // --- Auth ---
    db.prepare(`CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      google_sub TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL,
      display_name TEXT NOT NULL,
      avatar_url TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      last_login_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )`),
    db.prepare(`CREATE TABLE IF NOT EXISTS auth_sessions (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      token_hash TEXT NOT NULL UNIQUE,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      expires_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )`),
    db.prepare('CREATE INDEX IF NOT EXISTS idx_auth_sessions_token_hash ON auth_sessions(token_hash)'),

    // --- Creators / reels ---
    db.prepare(`CREATE TABLE IF NOT EXISTS creators (
      id TEXT PRIMARY KEY,
      ig_user_id TEXT UNIQUE,
      username TEXT NOT NULL UNIQUE,
      full_name TEXT,
      profile_pic_url TEXT,
      follower_count INTEGER,
      is_verified INTEGER NOT NULL DEFAULT 0,
      credibility_score REAL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )`),
    db.prepare(`CREATE TABLE IF NOT EXISTS reels (
      id TEXT PRIMARY KEY,
      ig_shortcode TEXT NOT NULL UNIQUE,
      url TEXT NOT NULL,
      caption TEXT,
      thumbnail_url TEXT,
      video_r2_key TEXT,
      audio_r2_key TEXT,
      creator_id TEXT,
      location_tag TEXT,
      posted_at TEXT,
      like_count INTEGER,
      comment_count INTEGER,
      view_count INTEGER,
      submitted_by TEXT,
      status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending','downloading','transcribing','detecting',
                          'resolving','analyzing_comments','summarizing','complete','failed')),
      error TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (creator_id) REFERENCES creators(id) ON DELETE SET NULL,
      FOREIGN KEY (submitted_by) REFERENCES users(id) ON DELETE SET NULL
    )`),
    db.prepare('CREATE INDEX IF NOT EXISTS idx_reels_status ON reels(status)'),
    db.prepare('CREATE INDEX IF NOT EXISTS idx_reels_creator ON reels(creator_id)'),
    db.prepare(`CREATE TABLE IF NOT EXISTS transcripts (
      id TEXT PRIMARY KEY,
      reel_id TEXT NOT NULL UNIQUE,
      language TEXT,
      text TEXT,
      segments TEXT,
      model_used TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (reel_id) REFERENCES reels(id) ON DELETE CASCADE
    )`),

    // --- Restaurants ---
    db.prepare(`CREATE TABLE IF NOT EXISTS restaurants (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      slug TEXT NOT NULL UNIQUE,
      google_place_id TEXT UNIQUE,
      address TEXT,
      area TEXT,
      city TEXT,
      lat REAL,
      lng REAL,
      google_maps_url TEXT,
      phone TEXT,
      cuisine TEXT,
      price_level INTEGER,
      status TEXT NOT NULL DEFAULT 'unverified'
        CHECK (status IN ('unverified','active','closed')),
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )`),
    db.prepare('CREATE INDEX IF NOT EXISTS idx_restaurants_geo ON restaurants(lat, lng)'),
    db.prepare('CREATE INDEX IF NOT EXISTS idx_restaurants_city_area ON restaurants(city, area)'),
    db.prepare(`CREATE TABLE IF NOT EXISTS restaurant_photos (
      id TEXT PRIMARY KEY,
      restaurant_id TEXT NOT NULL,
      r2_key TEXT NOT NULL,
      source TEXT CHECK (source IN ('reel','google_places','user')),
      source_reel_id TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
      FOREIGN KEY (source_reel_id) REFERENCES reels(id) ON DELETE SET NULL
    )`),
    db.prepare(`CREATE TABLE IF NOT EXISTS restaurant_reels (
      id TEXT PRIMARY KEY,
      restaurant_id TEXT NOT NULL,
      reel_id TEXT NOT NULL,
      confidence REAL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE (restaurant_id, reel_id),
      FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
      FOREIGN KEY (reel_id) REFERENCES reels(id) ON DELETE CASCADE
    )`),
    db.prepare(`CREATE TABLE IF NOT EXISTS reel_entities (
      id TEXT PRIMARY KEY,
      reel_id TEXT NOT NULL,
      restaurant_name_raw TEXT,
      branch_name_raw TEXT,
      area_raw TEXT,
      city_raw TEXT,
      state_raw TEXT,
      country_raw TEXT,
      suggested_address TEXT,
      suggested_lat REAL,
      suggested_lng REAL,
      suggested_location_confidence REAL,
      cuisine TEXT,
      dishes TEXT,
      sources TEXT,
      landmarks TEXT,
      evidence TEXT,
      confidence REAL,
      resolution_status TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (reel_id) REFERENCES reels(id) ON DELETE CASCADE
    )`),
    // --- Dishes ---
    db.prepare(`CREATE TABLE IF NOT EXISTS dishes (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      normalized_name TEXT NOT NULL UNIQUE
    )`),
    db.prepare(`CREATE TABLE IF NOT EXISTS restaurant_dishes (
      restaurant_id TEXT NOT NULL,
      dish_id TEXT NOT NULL,
      mention_count INTEGER NOT NULL DEFAULT 1,
      sentiment_score REAL,
      PRIMARY KEY (restaurant_id, dish_id),
      FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
      FOREIGN KEY (dish_id) REFERENCES dishes(id) ON DELETE CASCADE
    )`),

    // --- Comments ---
    db.prepare(`CREATE TABLE IF NOT EXISTS comments (
      id TEXT PRIMARY KEY,
      reel_id TEXT NOT NULL,
      ig_comment_id TEXT UNIQUE,
      author_username TEXT,
      text TEXT,
      like_count INTEGER,
      posted_at TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (reel_id) REFERENCES reels(id) ON DELETE CASCADE
    )`),
    db.prepare('CREATE INDEX IF NOT EXISTS idx_comments_reel ON comments(reel_id)'),
    db.prepare(`CREATE TABLE IF NOT EXISTS comment_analysis (
      id TEXT PRIMARY KEY,
      comment_id TEXT NOT NULL UNIQUE,
      sentiment TEXT CHECK (sentiment IN ('positive','negative','neutral')),
      score REAL,
      topics TEXT,
      is_spam INTEGER NOT NULL DEFAULT 0,
      is_sponsored_flag INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE
    )`),

    // --- Trust + summary ---
    db.prepare(`CREATE TABLE IF NOT EXISTS trust_scores (
      id TEXT PRIMARY KEY,
      restaurant_id TEXT NOT NULL,
      score INTEGER NOT NULL,
      creator_signal TEXT,
      audience_signal TEXT,
      historical_signal TEXT,
      computed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
    )`),
    db.prepare('CREATE INDEX IF NOT EXISTS idx_trust_latest ON trust_scores(restaurant_id, computed_at DESC)'),
    db.prepare(`CREATE TABLE IF NOT EXISTS ai_summaries (
      id TEXT PRIMARY KEY,
      restaurant_id TEXT NOT NULL,
      trust_score INTEGER,
      common_praise TEXT,
      common_complaints TEXT,
      best_dishes TEXT,
      verdict TEXT,
      model_used TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
    )`),
    db.prepare('CREATE INDEX IF NOT EXISTS idx_summary_latest ON ai_summaries(restaurant_id, created_at DESC)'),

    // --- Lists / saves ---
    db.prepare(`CREATE TABLE IF NOT EXISTS lists (
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
    )`),
    db.prepare('CREATE INDEX IF NOT EXISTS idx_lists_user ON lists(user_id)'),
    db.prepare(`CREATE TABLE IF NOT EXISTS list_items (
      id TEXT PRIMARY KEY,
      list_id TEXT NOT NULL,
      restaurant_id TEXT NOT NULL,
      note TEXT,
      position INTEGER,
      added_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE (list_id, restaurant_id),
      FOREIGN KEY (list_id) REFERENCES lists(id) ON DELETE CASCADE,
      FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
    )`),
    db.prepare(`CREATE TABLE IF NOT EXISTS saved_restaurants (
      user_id TEXT NOT NULL,
      restaurant_id TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (user_id, restaurant_id),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
    )`),
    db.prepare(`CREATE TABLE IF NOT EXISTS saved_reels (
      user_id TEXT NOT NULL,
      reel_id TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'saved'
        CHECK (status IN ('saved','processing','processed','failed')),
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (user_id, reel_id),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (reel_id) REFERENCES reels(id) ON DELETE CASCADE
    )`),
    db.prepare('CREATE INDEX IF NOT EXISTS idx_saved_reels_user ON saved_reels(user_id, created_at DESC)'),
    db.prepare('CREATE INDEX IF NOT EXISTS idx_saved_reels_reel ON saved_reels(reel_id)'),

    // --- Pipeline ---
    db.prepare(`CREATE TABLE IF NOT EXISTS processing_jobs (
      id TEXT PRIMARY KEY,
      reel_id TEXT NOT NULL,
      type TEXT NOT NULL
        CHECK (type IN ('extract','transcribe','ocr','detect','resolve','comments','summary')),
      status TEXT NOT NULL DEFAULT 'queued'
        CHECK (status IN ('queued','running','succeeded','failed','dead')),
      attempts INTEGER NOT NULL DEFAULT 0,
      max_attempts INTEGER NOT NULL DEFAULT 3,
      payload TEXT,
      error TEXT,
      started_at TEXT,
      finished_at TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (reel_id) REFERENCES reels(id) ON DELETE CASCADE
    )`),
    db.prepare('CREATE INDEX IF NOT EXISTS idx_jobs_reel_type ON processing_jobs(reel_id, type)'),
    db.prepare('CREATE INDEX IF NOT EXISTS idx_jobs_status ON processing_jobs(status)'),
    db.prepare(`CREATE TABLE IF NOT EXISTS places_cache (
      google_place_id TEXT PRIMARY KEY,
      raw TEXT,
      fetched_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )`)
  ])

  schemaReady = true
}
