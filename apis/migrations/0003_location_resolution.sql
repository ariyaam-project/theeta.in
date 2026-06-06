ALTER TABLE reel_entities ADD COLUMN branch_name_raw TEXT;
ALTER TABLE reel_entities ADD COLUMN city_raw TEXT;
ALTER TABLE reel_entities ADD COLUMN state_raw TEXT;
ALTER TABLE reel_entities ADD COLUMN country_raw TEXT;
ALTER TABLE reel_entities ADD COLUMN landmarks TEXT;
ALTER TABLE reel_entities ADD COLUMN evidence TEXT;
ALTER TABLE reel_entities ADD COLUMN confidence REAL;
ALTER TABLE reel_entities ADD COLUMN resolution_status TEXT;

CREATE TABLE IF NOT EXISTS location_candidates (
  id TEXT PRIMARY KEY,
  reel_id TEXT NOT NULL,
  provider TEXT NOT NULL,
  provider_place_id TEXT NOT NULL,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  lat REAL NOT NULL,
  lng REAL NOT NULL,
  score REAL NOT NULL,
  accepted INTEGER NOT NULL DEFAULT 0,
  raw TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (reel_id) REFERENCES reels(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_location_candidates_reel ON location_candidates(reel_id, score DESC);
