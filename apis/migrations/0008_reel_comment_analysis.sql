-- Reel-level aggregate of the audience comments (PRD Step 5): sentiment split,
-- common praise/complaints, sponsored signal, and a short verdict.
CREATE TABLE IF NOT EXISTS reel_comment_analysis (
  id TEXT PRIMARY KEY,
  reel_id TEXT NOT NULL UNIQUE,
  analyzed_count INTEGER NOT NULL DEFAULT 0,
  positive_count INTEGER NOT NULL DEFAULT 0,
  negative_count INTEGER NOT NULL DEFAULT 0,
  neutral_count INTEGER NOT NULL DEFAULT 0,
  sentiment_score REAL,
  common_praise TEXT,
  common_complaints TEXT,
  sponsored_signal INTEGER NOT NULL DEFAULT 0,
  authenticity_note TEXT,
  verdict TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (reel_id) REFERENCES reels(id) ON DELETE CASCADE
);
