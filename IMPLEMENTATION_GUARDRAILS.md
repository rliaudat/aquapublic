# Implementation Guardrails

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

Future expansion must satisfy all of the following rules:

- It must preserve Supabase as canonical state unless a deliberate migration plan replaces that boundary.
- It must preserve portal-safe filtered projections.
- It must preserve auditability for identity, permissions, sensitive actions, and AI-assisted recommendations.
- It must use verified tool outputs and deterministic data access for AI-visible sensitive information.
- It must introduce new infrastructure only after a concrete operational need is demonstrated.
- It must remain compatible with the provider abstraction and canonical claim/message model.

Recommended next step:
"Create the actual Supabase schema and Edge Function implementation plan."
