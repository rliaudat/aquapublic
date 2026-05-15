# Implementation Guardrails

This document prevents AI-assisted overengineering and uncontrolled architecture expansion during the MVP. The goal is to ship a reliable, auditable, owner-facing system first while preserving future expansion paths.

## MVP Guardrails

- The owner portal is mandatory, not a future nice-to-have.
- The portal must support OTP login, ticket visibility, ticket creation, ticket replies, owner-visible attachments, and PDF visibility.
- Deterministic WhatsApp menu flows come before AI-generated behavior.
- Persistence comes before automation: write canonical Supabase records before synchronizing external systems.
- AI assist comes before AI autonomy.
- AI may summarize, classify, extract intent/entities, enrich operator context, suggest responses, and prepare drafts.
- AI must rely on verified tool outputs and deterministic Supabase data access.
- Observability is mandatory from day one through `webhook_events`, `integration_logs`, `sync_outbox`, and `audit_logs`.
- Chatwoot remains the operational inbox/workflow layer.
- Supabase remains the canonical business and owner-visible state.
- Edge Functions remain the MVP orchestration/BFF layer unless a specific operational need justifies a larger backend later.
This document prevents AI-assisted overengineering and uncontrolled architecture expansion during MVP implementation. The platform should be implemented as small, auditable vertical slices that preserve future extensibility without building future complexity early.

## MVP Guardrails

- The owner portal is mandatory in the MVP.
- Deterministic WhatsApp flows come before AI-driven flows.
- Persistence comes before automation or synchronization.
- AI assist comes before AI autonomy.
- Observability is mandatory from day 1.
- Supabase is the canonical operational and business database.
- Chatwoot is the operational inbox/workflow, not the canonical source of truth.
- Chatwoot runs self-hosted on DigitalOcean with minimal operations, backups, and accessible logs.
- Supabase Edge Functions are the preferred MVP orchestration/BFF layer.
- Octavo Piso access must go through the orchestration layer.
- Shared WhatsApp numbers must be supported through explicit context selection and session pinning.

## Forbidden Phase 1 Complexity

- No Kafka.
- No microservices.
- No LangGraph.
- No vector database.
- No RAG system.
- No VAPI implementation.
- No autonomous financial operations.
- No autonomous legal/dispute resolution.
- No autonomous sensitive ticket closure.
- No BullMQ.
- No complex workflow engines.
- No aggressive SaaS multi-tenancy implementation.
- No advanced analytics platform.
- No long-term AI memory system.
- No vector DB.
- No VAPI.
- No autonomous financial operations.
- No BullMQ.
- No complex workflow engines.
- No RAG systems.
- No long-term AI memory.
- No aggressive SaaS multi-tenancy implementation.
- No advanced analytics platform.
- No autonomous sensitive claim closure.

## Development Constraints

- Use small PRs.
- Build incremental vertical slices.
- Do not expand the schema without a direct MVP use case.
- Do not create speculative tables for future AI, VAPI, Jelou, analytics, or workflow engines.
- Do not access Octavo Piso directly outside the orchestration layer.
- Do not let the portal read directly from Chatwoot.
- Do not let the portal read directly from Octavo Piso.
- Do not expose internal Chatwoot notes to owners.
- Do not treat Chatwoot conversation IDs as canonical claim IDs.
- Do not bypass authorization checks with session-pinned context.
- Keep provider abstraction simple and explicit: `chatwoot`, `jelou_future`, and `meta_cloud_future`.

## Operational Constraints

- Logs before automation.
- Retries before advanced orchestration.
- Manual fallback must always be possible.
- Unknown identities are denied by default for sensitive actions.
- Shared WhatsApp numbers require explicit user selection for ambiguous sensitive actions.
- `conversation_sessions` must have TTL and must not replace authorization checks.
- Failed external synchronization must remain visible and retryable through `sync_outbox`.
- Operators must be able to understand what happened from `webhook_events`, `integration_logs`, and `audit_logs` before any dashboard sophistication is added.
- Backups and logs are required for the DigitalOcean Chatwoot deployment.

## Future Expansion Rules

The architecture intentionally preserves future expansion without implementing that complexity in Phase 1.

Future expansion may include:
- Avoid uncontrolled schema expansion.
- Do not add tables unless a concrete MVP flow requires them.
- Do not create a large backend before Edge Functions have been proven insufficient.
- Do not access Octavo Piso directly outside the orchestration layer.
- Do not allow direct portal reads from Chatwoot.
- Do not expose internal Chatwoot notes to owners.
- Do not treat Chatwoot conversation IDs as canonical claim IDs.
- Do not let AI-generated outputs execute sensitive operations without human review.
- Keep provider abstraction minimal and compatible with `chatwoot`, `jelou_future`, and `meta_cloud_future`.

## Operational Constraints

- Logs come before automation.
- Retries come before advanced orchestration.
- Manual fallback must always be possible.
- Unknown identities are denied by default.
- Ambiguous shared-phone contexts require explicit user selection before sensitive actions.
- Webhook payloads should be persisted before business processing.
- Synchronization failures should create retryable `sync_outbox` tasks instead of losing state.
- Sensitive actions must be recorded in `audit_logs`.
- Integration failures must be visible in `integration_logs`.

## Future Expansion Rules

The architecture intentionally preserves future:

- VAPI.
- Jelou.
- Stronger AI agents.
- SaaS evolution.
- Richer automation.

Expansion rules:

- Add future providers through adapter boundaries and `claim_channel_links`, not by changing canonical claim ownership.
- Add stronger AI only after deterministic data access, audit logs, and operator review paths are stable.
- Add SaaS features by building on existing `administration_id` or `organization_id` scoping, not by prematurely rewriting the MVP into a multi-tenant platform.
- Add orchestration infrastructure only when `sync_outbox` retries and manual fallback are proven insufficient.
- Add voice/VAPI only as a provider-style integration after WhatsApp and portal workflows are stable.
Future expansion must satisfy all of the following rules:

- It must preserve Supabase as canonical state unless a deliberate migration plan replaces that boundary.
- It must preserve portal-safe filtered projections.
- It must preserve auditability for identity, permissions, sensitive actions, and AI-assisted recommendations.
- It must use verified tool outputs and deterministic data access for AI-visible sensitive information.
- It must introduce new infrastructure only after a concrete operational need is demonstrated.
- It must remain compatible with the provider abstraction and canonical claim/message model.

Recommended next step:
"Create the actual Supabase schema and Edge Function implementation plan."
