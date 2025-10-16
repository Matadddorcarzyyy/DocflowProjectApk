-- Enable pgvector extension


-- Users and auth
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('visitor','lawyer','admin','owner','partner')),
  full_name TEXT,
  telegram_chat_id TEXT,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS users_role_idx ON users(role);
CREATE INDEX IF NOT EXISTS users_email_idx ON users(email);

-- Documents catalog
CREATE TABLE IF NOT EXISTS documents (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  base_price INTEGER NOT NULL DEFAULT 500
);

-- Chats and messages
CREATE TABLE IF NOT EXISTS chats (
  id SERIAL PRIMARY KEY,
  visitor_id TEXT,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  chat_id INTEGER NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  sender TEXT NOT NULL CHECK (sender IN ('visitor','lawyer','ai')),
  text TEXT NOT NULL,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- Files (optional: can be represented as messages too)
CREATE TABLE IF NOT EXISTS files (
  id SERIAL PRIMARY KEY,
  chat_id INTEGER NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  uploader_role TEXT NOT NULL CHECK (uploader_role IN ('visitor','lawyer')),
  original_name TEXT,
  stored_name TEXT NOT NULL,
  url TEXT NOT NULL,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
  id SERIAL PRIMARY KEY,
  document_id INTEGER NOT NULL REFERENCES documents(id),
  email TEXT NOT NULL,
  price INTEGER NOT NULL,
  payload JSONB,
  status TEXT NOT NULL DEFAULT 'created',
  provider TEXT,
  external_id TEXT,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- Seed basic documents
INSERT INTO documents (title, base_price) VALUES
('Договор дарения', 500),
('Договор купли-продажи автомобиля', 700),
('Договор купли-продажи квартиры', 900),
('Договор аренды квартиры', 600),
('Договор оказания услуг', 650)
ON CONFLICT DO NOTHING;


-- Vacancies
CREATE TABLE IF NOT EXISTS vacancies (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  location TEXT,
  employment_type TEXT,
  salary_min INTEGER,
  salary_max INTEGER,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS vacancies_active_idx ON vacancies(is_active);

-- Settings key/value store (for privacy policy and other texts)
CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT,
  updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- Seed empty privacy policy if missing
INSERT INTO settings(key, value) VALUES ('privacy_policy_html', '<p>Политика конфиденциальности будет размещена здесь.</p>')
ON CONFLICT (key) DO NOTHING;


