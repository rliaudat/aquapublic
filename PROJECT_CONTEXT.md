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
Aqua Public is an owner communication and claims platform for property administration workflows. The MVP is intentionally simplified after architecture review to reduce operational complexity, maximize implementation success probability, preserve future extensibility, and reduce AI-assisted development risk.

## Final MVP Direction

The MVP consists of:

- Chatwoot self-hosted on DigitalOcean.
- WhatsApp through Chatwoot.
- Supabase as the canonical operational and business database.
- Supabase Edge Functions as the preferred orchestration/BFF layer.
- Next.js owner portal as a mandatory user-facing product surface.
- Octavo Piso integration for administrative source data.
- Deterministic WhatsApp flows first.
- AI assist/copilot behavior only.
- Auditability and observability from day 1.

The MVP does not redesign the platform into a distributed enterprise system. It deliberately avoids large backend orchestration, microservices, queues, event buses, vector systems, and autonomous AI operations until real operational pressure requires them.

## Core Architectural Roles

- Chatwoot is the operational inbox and workflow tool for human operators.
- Supabase is the canonical operational/business state.
- Supabase Edge Functions are the initial orchestration layer for permissions, integrations, webhooks, deterministic automation, and portal-safe projections.
- The owner portal is the filtered projection layer for owners and authorized users.
- Octavo Piso is the administrative source system.
- WhatsApp provider abstraction remains future-ready for `chatwoot`, `jelou_future`, and `meta_cloud_future`.

## Hosting and Operations

Chatwoot is self-hosted on DigitalOcean for the MVP. The setup should remain minimal and operationally understandable:

- Keep the Chatwoot deployment small and documented.
- Configure backups for Chatwoot data and any associated storage.
- Ensure basic logs are accessible for debugging.
- Avoid premature Kubernetes or distributed infrastructure.
- Treat Chatwoot as operational workflow infrastructure, not as the canonical business database.

Supabase hosts canonical state, Edge Functions, auth/session-related data for the portal, storage metadata, and observability tables. The first implementation should favor reliability, traceability, and debuggability over advanced dashboards.

## Mandatory Owner Portal Scope

The owner portal remains a core MVP requirement, not a future phase.

Required MVP portal capabilities:

- OTP or magic-link login.
- Ticket/claim visibility from canonical Supabase projections.
- Ticket/claim creation.
- Ticket replies.
- Owner-visible attachments.
- Owner-visible PDF access.
- Safe filtering that excludes Chatwoot internal notes and internal-only artifacts.

The portal must not read Chatwoot directly. Portal access is determined by canonical persons, contact points, units, and person-unit relationships in Supabase.

## Simplified Flow Strategy

The first implementation should use deterministic vertical slices:

1. Import core Octavo Piso data into Supabase.
2. Project necessary contact data from Supabase into Chatwoot.
3. Receive Chatwoot WhatsApp webhooks into Edge Functions.
4. Persist webhook envelopes and canonical claim/message records before synchronization.
5. Use deterministic WhatsApp menu flows for common actions.
6. Escalate ambiguous or sensitive cases to operators.
7. Show safe owner-visible projections in the portal.
8. Use `sync_outbox` retries for eventual consistency with external systems.

This persistence-first approach avoids Kafka, BullMQ, and complex orchestration engines in Phase 1.

## Shared Phone and Identity Reality

Shared WhatsApp numbers are a supported business reality. The system must not assume every phone number maps to exactly one active person for every action.

The MVP uses short-lived `conversation_sessions` with TTL and an `active_person_context` when known. If a phone number maps to multiple persons, units, or sensitive contexts, the user must explicitly select the relevant identity/context before sensitive actions proceed. Unknown or unresolved identities are denied by default for portal and sensitive claim visibility.

## AI Strategy

The MVP uses AI assist/copilot behavior only.

AI may:

- Summarize.
- Classify.
- Extract intent and entities.
- Enrich operator context.
- Suggest responses.
- Prepare drafts.
- Assist operators.

MVP AI must not:
AI must not:

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
- Hallucinate debt, payment, or account information.

AI outputs must rely on verified tool outputs and deterministic Supabase data access. Stronger AI agents, long-term memory, RAG, and autonomous workflows are future possibilities only after the deterministic MVP is stable and auditable.

## Observability-First Approach

Observability is mandatory from day 1. The MVP should prioritize simple logs and debugging records over advanced analytics.

Required concepts:

- `webhook_events` for raw inbound webhook envelopes, idempotency, and replay/debugging.
- `integration_logs` for Chatwoot, Octavo Piso, WhatsApp provider, and future integration diagnostics.
- `sync_outbox` for retryable synchronization tasks and eventual consistency.
- `audit_logs` for permission decisions, sensitive actions, portal access, and AI-assisted recommendations.

## Future Extensibility Preserved

The simplified MVP intentionally preserves future expansion paths without implementing them early:

- VAPI/voice can later normalize calls into the same claim/message/channel model.
- Jelou can later become a WhatsApp provider adapter through the provider abstraction.
- Stronger AI agents can later use deterministic tools, audited permissions, and verified data access.
- SaaS evolution is supported by early `administration_id` or `organization_id` ownership on core entities.
- Richer automation can later build on `sync_outbox`, webhook events, and canonical claim state.

Future expansion must not bypass the core boundaries: Chatwoot for operations, Supabase for canonical state, Edge Functions/BFF for orchestration and permissions, portal for filtered owner projections, and Octavo Piso as administrative source system.
