# API Surface

This document defines the simplified MVP API surface. The MVP uses Supabase Edge Functions as the preferred orchestration and BFF layer instead of a large centralized NestJS backend. A larger backend can be introduced later only if operational needs justify it.

## API Principles

- Edge Functions orchestrate permissions, webhook ingestion, deterministic automation, integrations, and portal-safe projections.
- Supabase remains the canonical database.
- Chatwoot remains the operational inbox/workflow and is self-hosted on DigitalOcean with minimal operations, backups, and accessible logs.
- Octavo Piso is accessed only through the orchestration layer.
- The portal never reads Chatwoot directly.
- APIs should be small, auditable, idempotent, and implementation-friendly.
- Persistence happens before synchronization.
- Observability endpoints and logs are mandatory from day 1.

## Explicitly Out of MVP API Scope

The Phase 1 API surface must not include:

- Large backend orchestration APIs.
- Microservice boundaries.
- Kafka/event streaming APIs.
- BullMQ management APIs.
- LangGraph or complex agent orchestration APIs.
- Vector search/RAG APIs.
- VAPI/voice endpoints beyond documented future integration points.
- Autonomous financial approval or dispute-resolution endpoints.
- Advanced analytics APIs.

## Edge Function Groups

### Webhook Ingestion Endpoints

Webhook ingestion endpoints receive external events, persist observability records, and then perform deterministic processing.

Required responsibilities:

- Receive Chatwoot webhook events for WhatsApp messages, conversation updates, and operator replies.
- Persist raw envelopes into `webhook_events` before business processing.
- Normalize payloads into channel-neutral shapes.
- Resolve `claim_channel_links` and `conversation_sessions` when available.
- Create or update `claims`, `claim_messages`, `claim_attachments`, and outbox tasks idempotently.
- Record failures in `webhook_events` and `integration_logs`.

Suggested endpoint shapes:

- `POST /functions/v1/webhooks/chatwoot`
- `POST /functions/v1/webhooks/octavo-piso` only if Octavo Piso supports push events later.
- Reserved future paths for `jelou_future` and `meta_cloud_future` adapters.

### Deterministic Automation Endpoints

Automation endpoints should implement small deterministic actions, not complex workflow engines.

Required responsibilities:

- Drive WhatsApp menu steps through Chatwoot for the MVP.
- Create or update `conversation_sessions` with TTL.
- Ask the user to select a person/unit context when a shared WhatsApp number is ambiguous.
- Create claims only after identity and unit context are deterministic enough for the requested action.
- Escalate to an operator when identity, permission, category, or sensitive context is ambiguous.

Suggested endpoint shapes:

- `POST /functions/v1/automation/whatsapp/menu-step`
- `POST /functions/v1/automation/whatsapp/select-context`
- `POST /functions/v1/automation/claims/create-from-session`

### Portal Endpoints

Portal endpoints are mandatory for the MVP and expose owner-safe filtered projections from Supabase.

Required responsibilities:

- OTP or magic-link login using authorized `contact_points`.
- Portal session creation and expiry.
- Ticket/claim visibility by canonical person-unit relationships.
- Ticket creation.
- Ticket replies.
- Owner-visible attachment upload/download.
- Owner-visible PDF visibility.
- Safe claim status projection.

Suggested endpoint shapes:

- `POST /functions/v1/portal/auth/start-otp`
- `POST /functions/v1/portal/auth/verify-otp`
- `POST /functions/v1/portal/auth/logout`
- `GET /functions/v1/portal/claims`
- `GET /functions/v1/portal/claims/:claim_id`
- `POST /functions/v1/portal/claims`
- `POST /functions/v1/portal/claims/:claim_id/messages`
- `GET /functions/v1/portal/claims/:claim_id/attachments`
- `POST /functions/v1/portal/claims/:claim_id/attachments`
- `GET /functions/v1/portal/claims/:claim_id/pdfs/:attachment_id`

### Attachment Endpoints

Attachment endpoints enforce canonical visibility and storage rules.

Required responsibilities:

- Validate portal sessions and claim visibility before upload/download.
- Store attachment metadata in `claim_attachments`.
- Prevent internal Chatwoot-only files and notes from leaking to owners.
- Use signed URLs or equivalent short-lived access patterns.
- Record access and sensitive operations in `audit_logs`.

### Octavo Piso Integration Endpoints

Octavo Piso integration is orchestration-layer-only.

Required responsibilities:

- Import administrations, buildings, units, persons, contact points, and relationships into Supabase.
- Use deterministic upserts and stable external identifiers.
- Record integration operations in `integration_logs`.
- Write retryable follow-up tasks to `sync_outbox` when downstream Chatwoot projection is needed.
- Never let the portal access Octavo Piso directly.

Suggested endpoint shapes:

- `POST /functions/v1/integrations/octavo/sync`
- `GET /functions/v1/integrations/octavo/sync-status/:sync_id`

### Provider Abstraction Endpoints

Provider abstraction must remain small and future-ready.

Required responsibilities:

- Treat Chatwoot as the MVP WhatsApp provider path.
- Keep provider names compatible with `chatwoot`, `jelou_future`, and `meta_cloud_future`.
- Route outbound provider sends through one orchestration boundary.
- Store provider results in `integration_logs` and retryable failures in `sync_outbox`.

Suggested endpoint shapes:

- `POST /functions/v1/providers/messages/send`
- `POST /functions/v1/providers/messages/retry-outbox`

### Observability Endpoints

Observability is mandatory from day 1. The MVP should prioritize logs and debugging over advanced dashboards.

Required responsibilities:

- Inspect recent webhook processing outcomes.
- Inspect integration failures.
- Inspect pending and failed sync outbox tasks.
- Inspect audit records for sensitive actions.
- Support manual retry of safe retryable tasks.

Suggested endpoint shapes:

- `GET /functions/v1/ops/webhook-events`
- `GET /functions/v1/ops/integration-logs`
- `GET /functions/v1/ops/sync-outbox`
- `POST /functions/v1/ops/sync-outbox/:task_id/retry`
- `GET /functions/v1/ops/audit-logs`

## AI Assist API Boundaries

MVP AI behavior is assistive only. AI endpoints, if present, must prepare context and drafts for operators, not execute sensitive operations autonomously.

AI may:

- Summarize.
- Classify.
- Extract intent and entities.
- Enrich operator context.
- Suggest responses.
- Prepare drafts.
- Assist operators.

AI must not:

- Autonomously expose sensitive data.
- Autonomously resolve legal or financial disputes.
- Autonomously approve risky operations.
- Autonomously close sensitive claims.
- Hallucinate debt or payment information.

AI outputs must rely on verified tool outputs and deterministic Supabase data access. Financial, legal, access-control, and sensitive claim operations require human review and auditable approval.

## Future Backend Expansion

A NestJS or larger backend may be introduced later if Edge Functions become insufficient for operational load, developer ergonomics, or integration complexity. That future migration should preserve the same boundaries:

- Supabase canonical state.
- Chatwoot operational workflow.
- Portal filtered projections.
- Octavo Piso orchestration-only access.
- Provider abstraction through small adapter boundaries.
- `webhook_events`, `integration_logs`, `sync_outbox`, and `audit_logs` for observability and reliability.
