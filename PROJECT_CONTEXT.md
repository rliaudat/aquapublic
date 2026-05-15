# Project Context

This project is an owner-support and administration communication platform for property operations. The final MVP architecture is intentionally simplified after architecture review: build the smallest reliable system that preserves the owner portal, operational auditability, deterministic WhatsApp support, and future extensibility.

## Final MVP Direction

Core MVP components:

- Chatwoot self-hosted on DigitalOcean.
- WhatsApp through Chatwoot.
- Supabase as the canonical operational/business database.
- Supabase Edge Functions as the initial orchestration/BFF layer.
- Next.js owner portal.
- Octavo Piso integration.
- Deterministic WhatsApp flows first.
- AI assist/copilot behavior only.
- Auditability and observability from day one.

The MVP deliberately avoids a large centralized backend at the start. NestJS or another backend can be introduced later if Edge Functions become insufficient, but the first implementation should maximize delivery probability and minimize operational burden.

## Hosting and Operations

Chatwoot is self-hosted on DigitalOcean for the MVP.

Operational expectations:

- Keep the DigitalOcean setup minimal and understandable.
- Configure backups for Chatwoot data and any required volumes/databases.
- Capture logs needed for webhook debugging, message delivery issues, and operator workflow problems.
- Prefer stable, boring operations over platform experimentation.
- Keep Chatwoot deployment assumptions centered on the self-hosted DigitalOcean setup.

Supabase hosts canonical data and Edge Functions. The owner portal is a separate Next.js application that consumes only filtered canonical projections and authorized Edge Function responses.

## System Responsibilities

### Chatwoot

Chatwoot is the operational inbox/workflow layer.

It owns:

- Human operator inboxes.
- Operator assignment.
- Internal notes.
- Conversation handling.
- WhatsApp operational workflow through the configured Chatwoot channel.

It does not own:

- Canonical claims.
- Portal visibility.
- Owner authentication.
- Canonical person/unit relationships.
- Business authorization.

### Supabase

Supabase is the canonical operational/business state.

It owns:

- `administrations`.
- `buildings`.
- `apartments_or_units`.
- `persons`.
- `contact_points`.
- `person_unit_relationships`.
- `portal_accounts` and `portal_sessions`.
- `claims`, `claim_messages`, `claim_channel_links`, and `claim_attachments`.
- `conversation_sessions` for shared phone/session pinning.
- `webhook_events`, `integration_logs`, `sync_outbox`, and `audit_logs`.

### Edge Functions / BFF

Supabase Edge Functions are the preferred MVP orchestration layer.

They own:

- Chatwoot webhook ingestion.
- Deterministic WhatsApp menu orchestration.
- Portal authentication and portal API boundaries.
- Octavo Piso synchronization.
- Provider abstraction boundaries.
- Retryable sync task processing.
- Permission enforcement and audit logging.

### Owner Portal

The owner portal is mandatory for MVP.

It must support:

- OTP login.
- Ticket visibility.
- Ticket creation.
- Ticket replies.
- Owner-visible attachments.
- PDF visibility.

The portal is a filtered projection layer over canonical Supabase state. It must not read raw Chatwoot data, internal Chatwoot notes, or Octavo Piso directly.

### Octavo Piso

Octavo Piso is the administrative source system for initial and recurring imports.

It provides:

- Administration/building/unit context.
- Person and contact source records.
- Person-unit relationship data.

Edge Functions normalize Octavo Piso data into Supabase. Direct portal or frontend access to Octavo Piso is not part of the MVP.

## Simplified Reliability Strategy

The MVP uses a persistence-first and synchronization-second approach.

Required concepts:

- `webhook_events` for raw webhook receipt and idempotent processing.
- `integration_logs` for external API attempts and failures.
- `sync_outbox` for retryable synchronization work.
- `audit_logs` for security-relevant and business-relevant decisions.

This replaces premature Kafka, event bus, BullMQ, microservice, or workflow-engine assumptions. Eventual consistency is acceptable when canonical Supabase data is safely persisted and failed sync tasks are visible and retryable.

## WhatsApp and Provider Strategy

MVP WhatsApp runs through Chatwoot.

Provider abstraction must remain future-ready through simple provider naming and linking patterns:

- `chatwoot`
- `jelou_future`
- `meta_cloud_future`

Rules:

- Do not hard-code canonical business logic to Chatwoot-only assumptions.
- Chatwoot IDs remain external references.
- Canonical claims remain in Supabase.
- Future Jelou or direct Meta Cloud adapters should reuse the same canonical claims, messages, contact points, sessions, webhook logs, and outbox concepts.

## Shared Phone and Session Pinning

Shared WhatsApp numbers are a supported business reality.

MVP handling:

- Use deterministic contact normalization.
- Use `conversation_sessions` with TTL.
- Store active person/unit context after explicit user selection.
- Require explicit selection for ambiguous sensitive actions.
- Deny unknown or ambiguous identities by default when sensitive data or claim access is involved.

## AI Strategy

AI is phased and constrained.

MVP AI may:

- Summarize.
- Classify.
- Extract intent/entities.
- Enrich operator context.
- Suggest responses.
- Prepare drafts.
- Assist operators.

MVP AI must not:

- Autonomously expose sensitive data.
- Autonomously resolve legal or financial disputes.
- Autonomously approve risky operations.
- Autonomously close sensitive claims.
- Hallucinate debt, balance, payment, or legal information.

AI responses must rely on verified tool outputs and deterministic Supabase data access. AI should improve operator productivity without becoming an autonomous authority in Phase 1.

## Explicitly Out of MVP

- VAPI/voice.
- AI autonomous financial actions.
- Autonomous sensitive ticket closure.
- LangGraph.
- Vector databases.
- RAG systems.
- Microservices.
- Kafka/event streaming.
- BullMQ/queue infrastructure.
- Complex orchestration engines.
- Aggressive SaaS multi-tenancy implementation.
- Advanced analytics.
- Long-term AI memory systems.

## Future Extensibility

The architecture intentionally preserves future expansion without paying the complexity cost in Phase 1.

Future expansion paths:

- VAPI/voice as a provider-style webhook integration.
- Jelou as a future WhatsApp provider adapter.
- Direct Meta Cloud WhatsApp adapter if needed.
- Stronger AI agents after deterministic data access and operator workflows are stable.
- SaaS evolution using early `administration_id` or `organization_id` scoping.
- Richer automation after logs, retries, and manual fallback prove reliable.

## Implementation Strategy

Build in incremental vertical slices:

1. Canonical Supabase schema and observability tables.
2. Octavo Piso import into canonical records.
3. Chatwoot webhook ingestion with `webhook_events` and idempotency.
4. Basic deterministic WhatsApp flow with session pinning.
5. Owner portal OTP login and ticket visibility.
6. Portal ticket creation, replies, attachments, and PDFs.
7. `sync_outbox` retries and admin observability views.
8. AI assist only after deterministic workflows are stable.

The first implementation slice should avoid broad schema expansion, speculative integrations, and autonomous AI behavior.
