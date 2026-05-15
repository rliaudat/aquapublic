# API Surface

This document defines the simplified MVP API surface. The MVP uses Supabase Edge Functions as the primary orchestration/BFF layer instead of starting with a large centralized NestJS backend. A larger backend can be introduced later if operational complexity justifies it.

## API Principles

- Edge Functions first for MVP orchestration, permissions, webhooks, deterministic automation, and integrations.
- Supabase is the canonical database for business and owner-visible state.
- Chatwoot is self-hosted on DigitalOcean with minimal operations, backups, and logs, and is the operational inbox/workflow system.
- The owner portal talks to the orchestration layer and canonical Supabase projections, not directly to Chatwoot or Octavo Piso.
- API scope stays small, explicit, auditable, and easy to test.
- All core API operations are scoped by `administration_id` or `organization_id`, even though MVP operations remain effectively single-tenant.
- Persist canonical records first; enqueue external synchronization second through `sync_outbox`.
- Record observability data from day one in `webhook_events`, `integration_logs`, `sync_outbox`, and `audit_logs`.

## Out of MVP API Scope

Do not create Phase 1 APIs for:

- Kafka/event streaming.
- Microservices coordination.
- BullMQ administration.
- LangGraph execution.
- Vector search or RAG memory.
- Autonomous financial operations.
- VAPI/voice operations.
- Advanced analytics dashboards.
- Complex workflow-engine control planes.

## 1. Webhook Ingestion Endpoints

### `POST /functions/v1/webhooks/chatwoot`

Receives Chatwoot webhooks for WhatsApp conversations, messages, contacts, attachments, and status changes.

Responsibilities:

- Authenticate/verify the webhook source.
- Persist the raw event to `webhook_events` before business processing.
- Apply idempotency using provider event IDs or deterministic payload keys.
- Normalize payloads into channel-neutral claim/message concepts.
- Resolve `claim_channel_links` and `conversation_sessions` when applicable.
- Write canonical `claims`, `claim_messages`, and `claim_attachments` updates.
- Add retryable outbound work to `sync_outbox` when needed.
- Write `integration_logs` for processing outcomes.

### `POST /functions/v1/webhooks/provider/:provider`

Future-ready provider webhook entry point for `jelou_future`, `meta_cloud_future`, or `vapi_future` when explicitly added after MVP hardening.

MVP rule:

- Keep the provider abstraction in route design and data model.
- Do not implement non-Chatwoot providers in Phase 1.

## 2. Deterministic Automation Endpoints

### `POST /functions/v1/automation/whatsapp/menu-step`

Advances deterministic WhatsApp menu flows.

Responsibilities:

- Load the relevant `conversation_sessions` record.
- Validate TTL and active person/unit context.
- Ask for explicit person or unit selection when a shared phone number is ambiguous.
- Create or update canonical claims and messages.
- Escalate to Chatwoot operators when identity, authorization, or content is unsafe for automation.

### `POST /functions/v1/automation/escalate`

Escalates a conversation or claim to human operators.

Responsibilities:

- Persist escalation reason in canonical records or `audit_logs`.
- Queue Chatwoot tagging, assignment, note, or reply work in `sync_outbox`.
- Avoid autonomous sensitive closure.

## 3. Owner Portal Authentication Endpoints

### `POST /functions/v1/portal/auth/start-otp`

Starts portal OTP login.

Responsibilities:

- Normalize submitted email or phone/WhatsApp identifier.
- Validate a verified `contact_points` record.
- Validate portal eligibility through `portal_accounts` and `person_unit_relationships`.
- Deny observed-only or unknown identities by default.
- Send OTP through the configured delivery path.
- Log authentication attempts in `audit_logs` where appropriate.

### `POST /functions/v1/portal/auth/verify-otp`

Completes portal OTP login.

Responsibilities:

- Validate OTP.
- Create `portal_sessions`.
- Return only the minimum session/profile context needed by the portal.

### `POST /functions/v1/portal/auth/logout`

Revokes a portal session.

Responsibilities:

- Mark the `portal_sessions` record revoked.
- Write an audit entry for session revocation.

## 4. Owner Portal Claim Endpoints

### `GET /functions/v1/portal/claims`

Lists owner-visible claims.

Responsibilities:

- Validate portal session.
- Filter by canonical person-unit relationships.
- Return public ticket numbers, safe owner-visible statuses, categories, dates, and summaries.
- Never expose raw Chatwoot statuses, internal notes, or operator-only metadata.

### `POST /functions/v1/portal/claims`

Creates a new owner claim.

Responsibilities:

- Validate portal session, person, and unit access.
- Persist the canonical `claims` record first.
- Persist the initial `claim_messages` record and any metadata.
- Queue Chatwoot conversation creation in `sync_outbox`.
- Return the canonical public claim number and owner-visible state.

### `GET /functions/v1/portal/claims/:claim_id`

Returns owner-visible claim detail.

Responsibilities:

- Validate visibility through canonical relationships.
- Return safe claim detail, owner-visible messages, and owner-visible attachments.

### `POST /functions/v1/portal/claims/:claim_id/replies`

Creates an owner reply on an existing visible claim.

Responsibilities:

- Validate session and claim visibility.
- Persist the owner reply in `claim_messages` first.
- Queue Chatwoot reply synchronization in `sync_outbox`.
- Return the canonical message projection.

## 5. Attachment and PDF Endpoints

### `POST /functions/v1/portal/claims/:claim_id/attachments`

Uploads an owner attachment.

Responsibilities:

- Validate portal session and claim visibility.
- Store file metadata in `claim_attachments`.
- Mark owner-visible status explicitly.
- Queue Chatwoot attachment synchronization when required.

### `GET /functions/v1/portal/claims/:claim_id/attachments/:attachment_id`

Returns or signs access to an owner-visible attachment or PDF.

Responsibilities:

- Validate portal session and claim visibility.
- Validate `claim_attachments.owner_visible`.
- Avoid exposing internal Chatwoot files, private notes, or operator-only documents.

## 6. Octavo Piso Integration Endpoints

### `POST /functions/v1/integrations/octavo/sync`

Runs an authorized Octavo Piso synchronization.

Responsibilities:

- Import administrations, buildings, units, persons, contact points, and relationships.
- Upsert canonical Supabase entities idempotently.
- Write `integration_logs` and `audit_logs`.
- Queue downstream Chatwoot projection tasks in `sync_outbox` when needed.

Rules:

- No direct Octavo Piso access from the portal.
- No direct Octavo Piso access from frontend clients.
- Edge Functions own Octavo Piso orchestration in MVP.

## 7. Provider Abstraction Endpoints

### `POST /functions/v1/providers/:provider/send-message`

Internal endpoint or function boundary for sending provider messages.

Supported MVP provider:

- `chatwoot`

Reserved future providers:

- `jelou_future`
- `meta_cloud_future`
- `vapi_future`

Responsibilities:

- Use canonical claim/message data as input.
- Write or consume `sync_outbox` tasks.
- Keep provider-specific IDs in external reference fields and `claim_channel_links`.

## 8. Observability Endpoints

### `GET /functions/v1/admin/observability/webhook-events`

Lists recent webhook processing records for operators/admins.

### `GET /functions/v1/admin/observability/integration-logs`

Lists integration attempts and failures.

### `GET /functions/v1/admin/observability/sync-outbox`

Lists retryable synchronization tasks and failed tasks.

### `POST /functions/v1/admin/observability/sync-outbox/:id/retry`

Manually retries a failed synchronization task.

### `GET /functions/v1/admin/observability/audit-logs`

Lists security-relevant and business-relevant audit entries.

Rules:

- Logs and debugging are prioritized over advanced dashboards in MVP.
- Observability endpoints are administrative and must not be exposed to owners.
- Sensitive payloads should be redacted or access-controlled.

## 9. AI Assist API Boundary

AI assist should be implemented as a controlled internal function boundary, not as autonomous public APIs.

Allowed behavior:

- Summarize claims and conversations.
- Classify messages.
- Extract intent/entities.
- Enrich operator context.
- Suggest responses.
- Prepare drafts for operator review.

Forbidden behavior:

- Autonomously exposing sensitive data.
- Autonomously resolving legal or financial disputes.
- Autonomously approving risky operations.
- Autonomously closing sensitive claims.
- Hallucinating debt, balance, payment, or legal information.

Rules:

- AI must rely on verified tool outputs and deterministic Supabase data access.
- AI outputs that affect owners must be reviewed or constrained by deterministic rules.
- AI use should be logged when it influences operational decisions.
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
