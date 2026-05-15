# Project Context

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

AI must not:

- Autonomously expose sensitive data.
- Autonomously resolve legal or financial disputes.
- Autonomously approve risky operations.
- Autonomously close sensitive claims.
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
