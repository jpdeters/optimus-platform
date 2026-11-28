CREATE TABLE IF NOT EXISTS device_pairings (
  device_code_hash TEXT PRIMARY KEY,
  user_code TEXT NOT NULL UNIQUE,
  user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
  expires_at INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  approved_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_device_pairings_user_code ON device_pairings(user_code);
CREATE INDEX IF NOT EXISTS idx_device_pairings_expires_at ON device_pairings(expires_at);
