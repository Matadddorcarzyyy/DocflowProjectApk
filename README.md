# DocFlow – Backend and Frontend (local dev)

## Prerequisites
- Docker + Docker Compose

## Stack
- Frontend: static HTML in project root (to be deployed on `hostia.net`)
- API: Node.js (Express) under `server/` (to be deployed on `beget.com` in Docker)
- DB: PostgreSQL 16 + pgvector (vector extension)
- n8n: workflow automation
- Ollama: local LLM runtime

## Run locally
1. Create env file:
```
cp server/.env.example server/.env
```
2. Start services:
```
docker compose up -d --build
```
3. API: http://localhost:8080/health
4. n8n: http://localhost:5678
5. Ollama: http://localhost:11434

## API (basic)
- GET `/api/documents` — list documents
- POST `/api/chats/:chatId/messages` — add message { sender, text }
- POST `/api/orders` — create order { document_id, email, price, payload }
- POST `/api/payments/start` — init payment (stub: YooKassa/CloudPayments/Stripe)
- POST `/api/payments/webhook/:provider` — provider webhooks (stubs)

## Database
- Auto-initialized from `server/db/init/*.sql`
- Uses `pgvector` extension for embeddings

## Environments and Deployment
- Frontend:
  - Host: `hostia.net`
  - Deploy: upload `*.html`, assets, and sitemap excluding `cooperation.html`
- Backend:
  - Host: `beget.com`
  - Deploy: Docker Compose stack from repo root (services: api, db, n8n, ollama)
  - Configure `server/.env` with secrets and provider keys
  - Minimal required env:
    - `PORT=8080`
    - `DATABASE_URL=postgres://docflow:docflow_password@db:5432/docflow`
    - `SESSION_SECRET=...`
    - `ALLOWED_ORIGINS=https://your-frontend-hostia.net`
    - `ADMIN_EMAIL=owner@example.com`
    - `ADMIN_PASSWORD=StrongPassword123!`
    - optional: `ADMIN_FULL_NAME=Owner`

### Beget (пример)
1. Скопировать проект на сервер
2. Создать/задать `.env` по `server/env.template`
3. Выполнить `docker compose up -d --build`
4. Проксировать 8080 на внешний порт/домен (через панель/NGINX)

## Security
- CORS allow-list via `ALLOWED_ORIGINS`
- Parameterized SQL and input validation
- Secrets only via env, never committed
- HTTPS termination at hosting; enable HSTS on frontend
- Rate limiting and payload size limits (to add)

## Payments
- Single `/api/payments/start` entrypoint; plug provider SDKs later
- Webhooks per provider with signature verification (to implement)

## AI Integrations (planned)
- Ollama: local inference for private drafting
- YandexGPT + Yandex Search API for Russian-language generation and retrieval
- OpenRouter for alternative chat models
- Vector search via pgvector (embeddings to be generated and stored)

## n8n Workflows (planned)
- Telegram: lawyer login notification
- New message notifications
- Order lifecycle: created -> paid -> delivered

## Pages
- `index.html`, `cooperation.html`, `vacancies.html`, `privacy.html`, `consent.html`, `404.html`, `admin.html`, `owner.html`, `lawyer.html`, `partner.html`
- `cooperation.html` is marked `noindex, nofollow` and must be excluded from sitemap

## Next steps
- Add authentication and role-based dashboards
- Integrate a production payment provider
- Hook n8n for notifications (email/Telegram) and order workflows
- Connect Ollama/OpenRouter/Yandex APIs for drafting
