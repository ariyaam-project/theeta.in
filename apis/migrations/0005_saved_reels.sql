CREATE TABLE IF NOT EXISTS saved_reels (
  user_id TEXT NOT NULL,
  reel_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'saved'
    CHECK (status IN ('saved','processing','processed','failed')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, reel_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (reel_id) REFERENCES reels(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_saved_reels_user ON saved_reels(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_saved_reels_reel ON saved_reels(reel_id);
