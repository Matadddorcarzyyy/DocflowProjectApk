# n8n Workflows

This document outlines the core workflows and expected webhooks between the API and n8n.

## Base
- n8n URL (local dev): `http://localhost:5678`
- Incoming webhooks base: `http://localhost:5678/webhook/`
- Configure secrets via environment variables, never hardcode tokens.

## 1) Lawyer Login Notification
- Trigger: API POST `/api/hooks/lawyer-login`
- API payload: `{ email: string, timestamp: ISOString }`
- n8n steps:
  1. Webhook (POST) `/webhook/lawyer-login`
  2. Validate payload
  3. Lookup lawyer Telegram chat id
  4. Send Telegram message: "Вход в кабинет: {{email}} {{timestamp}}"

## 2) New Message Notification
- Trigger: API POST `/api/hooks/new-message`
- API payload: `{ chatId: number, sender: 'visitor'|'lawyer'|'ai', text: string, created_at?: ISOString }`
- n8n steps:
  1. Webhook (POST) `/webhook/new-message`
  2. Branch by `sender`
  3. Notify target (email/Telegram) or enqueue tasks

## 3) Order Lifecycle
- Events: created -> payment started -> payment succeeded/failed
- API endpoints:
  - `POST /api/orders` (created)
  - `POST /api/payments/start` (started)
  - `POST /api/payments/webhook/:provider` (result)
- n8n flows:
  - On created: send email/Telegram confirmation
  - On paid: attach receipt, notify lawyer, update CRM

## Webhook URLs (suggested)
- `/webhook/lawyer-login`
- `/webhook/new-message`
- `/webhook/order-created`
- `/webhook/payment-succeeded`
- `/webhook/payment-failed`

## Secrets and Config
- `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ADMIN_CHAT_ID`
- Payment provider secrets (if flows interact)
- Use `N8N_WEBHOOK_URL` in API for forwarding

## Exports and Versioning
- Export workflows JSON regularly and keep in a secure storage
- Use naming: `docflow_*` and add semantic version in workflow metadata
