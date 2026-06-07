-- Food-relevance gate: flag reels the AI classifies as not about a food spot.
-- A rejected reel stays status='complete' (terminal) but is_food=0 so the UI
-- and queries can tell it apart from a resolved food reel.
ALTER TABLE reels ADD COLUMN is_food INTEGER NOT NULL DEFAULT 1;
ALTER TABLE reels ADD COLUMN rejection_reason TEXT;
