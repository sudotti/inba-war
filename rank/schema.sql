CREATE TABLE IF NOT EXISTS scores (
  player_id TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  score INTEGER NOT NULL,
  character_name TEXT NOT NULL,
  version TEXT NOT NULL,
  achieved_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_scores_rank ON scores (score DESC, achieved_at ASC);
