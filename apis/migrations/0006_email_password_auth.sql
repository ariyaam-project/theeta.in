-- Email/password auth: store a password hash and enforce one account per email.
-- google_sub stays NOT NULL UNIQUE; email/password users get a synthetic
-- `pwd:<id>` marker (mirrors the `dev:<email>` marker used by the dev login).
ALTER TABLE users ADD COLUMN password_hash TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(lower(email));
