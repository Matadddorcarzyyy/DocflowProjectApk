# DocFlow – Technical Document

## Purpose
A end-to-end web application that connects visitors with lawyers to draft legal documents via real-time chat, with AI assistance.

## High-Level Architecture
- Frontend: static site (HTML/CSS/JS) hosted on `hostia.net`
- Backend API: Node.js (Express) running in Docker on `beget.com`
- Database: PostgreSQL 16 with pgvector extension (Docker)
- Automation: n8n (Docker) for notifications and workflows
- Local LLM: Ollama (Docker) for privacy-preserving inference
- External AI: YandexGPT, Yandex Search API, OpenRouter
- Vector storage: pgvector (Postgres)

## Roles and Dashboards
- Visitor: chats, uploads docs, pays, receives drafts
- Lawyer: authenticated via email+password, multiple concurrent chats, uploads, drafts
- Admin: manages lawyers, monitors chats, presence (online/typing), sees uploads
- Owner: global status and controls
- Partner: separate cabinet (not indexed), demo access via Pop-up

## Data Model (simplified)
- documents(id, title, base_price)
- chats(id, visitor_id, created_at)
- messages(id, chat_id, sender[visitor|lawyer|ai], text, created_at)
- orders(id, document_id, email, price, payload, created_at)

## API (initial)
- GET /health
- GET /api/documents
- POST /api/chats/:chatId/messages { sender, text }
- POST /api/orders { document_id, email, price, payload }
- POST /api/payments/start { provider, order_id, amount, description, email }
- POST /api/payments/webhook/:provider

## Authentication & Authorization
- Phase 1: email+password for lawyers/admin/owner/partner
- Sessions via secure cookies or JWT (HttpOnly, SameSite=Lax/Strict)
- RBAC roles: visitor, lawyer, admin, owner, partner

## Realtime Chat
- Phase 1: polling via REST
- Phase 2: WebSocket (Socket.IO) for online/typing indicators
- Message persistence in Postgres

## AI Integration
- Ollama local model for private drafting
- OpenRouter, YandexGPT for augmented generation
- Yandex Search API for retrieval; embeddings to pgvector
- Guardrails: PII redaction and safety filters in n8n/API middleware

## n8n Workflows (planned)
- Lawyer login notification to Telegram
- New message notifications
- Order creation -> payment -> status updates

## Payments
- Unified start endpoint; providers: YooKassa/CloudPayments/Stripe
- Webhooks per provider; verify signatures; update order status

## Security Baseline
- HTTPS everywhere; HSTS on frontend
- CORS allowlist via ALLOWED_ORIGINS
- Parameterized SQL
- Validate payloads; size limits; file scanning for uploads
- Secrets via env; rotated; never committed
- Rate limiting and basic WAF rules

## Deployment
- Frontend: static deploy to `hostia.net`
- Backend: Docker Compose on `beget.com` (api, db, n8n, ollama)
- Backups: Postgres volume snapshots; n8n export flows

## Monitoring & Logs
- API structured logs (JSON)
- Health checks; uptime monitoring

## Roadmap (high level)
1) Auth + role dashboards
2) Payments production provider
3) Realtime chat + presence
4) AI drafting + RAG
5) Partner demo cabinet
6) Mobile APK wrapper (WebView)
