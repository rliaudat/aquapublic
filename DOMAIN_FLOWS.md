# Domain Flows

This document defines the simplified MVP flows for WhatsApp, Chatwoot, Supabase, the owner portal, and Octavo Piso. The goal is not to redesign the platform; the goal is to reduce operational complexity, improve implementation success probability, preserve future extensibility, and reduce AI-assisted development risk.

## Final MVP Architecture

- Chatwoot is self-hosted on DigitalOcean and acts as the operational inbox and human workflow layer.
- WhatsApp is connected through Chatwoot for the MVP.
- Supabase is the canonical operational/business database.
- Supabase Edge Functions are the preferred MVP orchestration/BFF layer for webhooks, permissions, deterministic automation, integrations, and portal APIs.
- The Next.js owner portal is mandatory and reads filtered canonical projections from Supabase.
- Octavo Piso remains the administrative source system for imported administration, building, unit, person, contact, and relationship data.
- Deterministic WhatsApp flows come before AI automation.
- AI is assistive/copilot-only in the MVP.
- Observability is mandatory from day one through `webhook_events`, `integration_logs`, `sync_outbox`, and `audit_logs`.

## Architectural Rules

- Canonical claim/ticket state lives in Supabase.
- Chatwoot conversation IDs, contact IDs, inbox IDs, and message IDs are external references only.
- Chatwoot internal notes and internal operator metadata must never be exposed directly to the owner portal.
- The portal must never read directly from Chatwoot.
- The portal must never read directly from Octavo Piso.
- Edge Functions validate permissions and orchestrate integrations for the MVP.
- A larger NestJS/backend layer remains a future migration option, not a Phase 1 dependency.
- Core records include `administration_id` or `organization_id` from day one, while MVP operations remain effectively single-tenant.
- Persistence happens before synchronization.
- Synchronization failures are handled through `sync_outbox` retries and operator-visible logs, not Kafka, BullMQ, or workflow engines.

## Explicitly Out of MVP

- VAPI/voice implementation.
- AI autonomous financial actions.
- Autonomous sensitive ticket closure.
- LangGraph.
- Vector databases and RAG systems.
This document defines the simplified MVP domain flows for Chatwoot, WhatsApp, Supabase, the owner portal, Octavo Piso synchronization, and future extensibility. The goal is not to redesign the platform; it is to reduce operational complexity, harden the MVP, and preserve future AI/VAPI/Jelou paths.

## Architecture Principles

- Chatwoot is the operational inbox/workflow for human operators.
- Chatwoot is self-hosted on DigitalOcean with a minimal operational setup, backups, and accessible logs.
- Supabase is the canonical operational and business database.
- Supabase Edge Functions are the preferred MVP orchestration/BFF layer for permissions, webhooks, deterministic automation, and integrations.
- The owner portal is a mandatory filtered projection layer backed by Supabase.
- Octavo Piso is the administrative source system.
- WhatsApp is delivered through Chatwoot in the MVP.
- WhatsApp provider abstraction remains future-ready for `chatwoot`, `jelou_future`, and `meta_cloud_future`.
- Persistence happens before synchronization.
- Observability is mandatory from day 1 through `webhook_events`, `integration_logs`, `sync_outbox`, and `audit_logs`.
- Core entities include `administration_id` or `organization_id` from day 1, while the MVP remains effectively single-tenant operationally.

## Explicitly Out of MVP Flows

The MVP must not introduce flows for:

- VAPI/voice execution.
- AI autonomous financial actions.
- Autonomous sensitive ticket closure.
- LangGraph.
- Vector databases or RAG systems.
- Microservices.
- Kafka/event streaming.
- BullMQ/queue infrastructure.
- Complex orchestration engines.
- Aggressive SaaS multi-tenancy implementation.
- Advanced analytics.
- Long-term AI memory systems.
- Long-term AI memory.

## 1. Octavo Piso Synchronization Flow

### Flow

Octavo Piso → Edge Function sync job → Supabase canonical tables → `sync_outbox` provider tasks

1. An authorized Edge Function runs an explicit Octavo Piso synchronization.
2. The function imports administrations, buildings, units, persons, contact points, and person-unit relationships.
3. The function normalizes source records into canonical Supabase entities.
4. The function upserts records using stable source identifiers and deterministic matching rules.
5. The function writes `integration_logs` and `audit_logs` for sync activity and exceptions.
6. Any required downstream Chatwoot projection is queued in `sync_outbox` after canonical persistence succeeds.

### Rules

- Octavo Piso is the administrative source system, but Supabase is the operational source of truth for claims, portal access, and normalized identity.
- Sync must be idempotent and auditable.
- Direct Octavo Piso access outside the orchestration layer is forbidden.
- The portal never uses Octavo Piso directly for authorization, claim visibility, or ticket state.
Octavo Piso → Supabase Edge Function sync → Supabase canonical entities → `sync_outbox` for downstream projection

1. An operator or scheduled job triggers the Octavo Piso sync Edge Function.
2. The Edge Function reads administrative source data from Octavo Piso.
3. The function normalizes administrations, buildings, units, persons, contact points, and person-unit relationships.
4. The function upserts canonical Supabase records with stable Octavo Piso external references.
5. The function writes `integration_logs` for success/failure details.
6. The function writes `audit_logs` for sensitive or access-relevant changes.
7. Any required Chatwoot projection is written as retryable work in `sync_outbox`.

### Rules

- Octavo Piso is an upstream administrative source, not the portal runtime database.
- The portal must never read Octavo Piso directly.
- Supabase becomes the canonical operational state after synchronization.
- Sync must be idempotent, deterministic, and observable.
- Downstream synchronization is secondary to persistence.

## 2. Chatwoot Contact Projection Flow

### Flow

Supabase canonical contacts → `sync_outbox` → Edge Function worker → Chatwoot contacts

1. Supabase stores canonical persons and verified contact points.
2. A sync task is added to `sync_outbox` when contact projection is needed.
3. An Edge Function worker creates or updates Chatwoot contacts.
4. Chatwoot IDs are stored as external references in minimal linking metadata.
5. `integration_logs` record success, retryable failure, or permanent failure.

### Rules

- Chatwoot contacts are operational projections.
- Supabase canonical contact data wins when systems disagree.
- Chatwoot contact changes may create observations, but they do not automatically authorize portal access.
- No distributed event bus is required for MVP contact sync.

## 3. Deterministic WhatsApp Menu Flow

### Flow

WhatsApp user → Chatwoot conversation → Chatwoot webhook → Edge Function → Supabase → deterministic response or operator escalation

1. A WhatsApp message enters Chatwoot.
2. Chatwoot emits a webhook to a Supabase Edge Function.
3. The function records the raw receipt in `webhook_events` before taking business action.
4. The function normalizes the message and resolves the contact point when possible.
5. The function checks for an active `conversation_sessions` record with a valid TTL.
6. If the person/unit context is unambiguous, the function continues the deterministic menu flow.
7. If the phone number is shared or identity is ambiguous, the function asks the user to select the relevant person/unit before sensitive actions.
8. The function creates or updates canonical `claims`, `claim_messages`, and `claim_channel_links` as needed.
9. Outbound replies or Chatwoot updates are persisted as `sync_outbox` tasks when external delivery is required.
10. The flow escalates to an operator when rules cannot safely proceed.

### Rules

- Shared WhatsApp numbers are supported business reality.
- `conversation_sessions` stores `active_person_context` and related unit context with TTL.
- Ambiguous sensitive actions require explicit user selection.
- Unknown identities are denied by default for sensitive information.
- Deterministic menu behavior ships before AI-generated responses.

## 4. Incoming Chatwoot Webhook Flow

### Flow

Chatwoot webhook → `webhook_events` → idempotency check → canonical update → `sync_outbox` if needed

1. Chatwoot sends a webhook for conversation, message, contact, or status activity.
2. The Edge Function stores the payload in `webhook_events` with provider, event type, and external event ID.
3. The function checks idempotency before applying side effects.
4. The function resolves the `claim_channel_links` record for known conversations.
5. The function updates canonical `claims`, `claim_messages`, and attachments only when visibility and data rules allow it.
6. The function logs processing outcomes in `integration_logs`.
7. Retryable external follow-up work is placed in `sync_outbox`.

### Rules

- Webhook storage is mandatory for day-one debugging.
- Owner-visible state is derived from Supabase rules, not raw Chatwoot status names.
- Internal notes remain internal.
- Failed webhook processing must be inspectable and retryable.

## 5. Portal OTP Login Flow

### Flow

Next.js portal → Edge Function → Supabase contact and relationship validation → OTP delivery → `portal_sessions`

1. The owner enters an email or phone/WhatsApp identifier.
2. The portal calls an Edge Function.
3. The function normalizes the identifier and checks verified `contact_points`.
4. The function confirms the person has an active portal-eligible relationship through `person_unit_relationships`.
5. The function sends an OTP through the configured delivery path.
6. After verification, the function creates `portal_sessions` scoped to the canonical person.
7. Portal screens load only filtered canonical data from Supabase through secure APIs or policies.

### Rules

- Portal login is mandatory for MVP.
- Chatwoot authentication is not used for owners.
- Observed-only contact points cannot authenticate.
- Portal access is based on canonical identity and relationship data.
Supabase canonical contacts → `sync_outbox` → Edge Function worker/retry → Chatwoot contacts

1. Supabase stores canonical persons and contact points.
2. A contact projection task is written to `sync_outbox`.
3. A retry-capable Edge Function processes the task.
4. Chatwoot contacts are created or updated as operational projections.
5. Chatwoot external IDs are stored as external references only.
6. Results and failures are recorded in `integration_logs`.

### Rules

- Supabase canonical contact data wins over Chatwoot contact data.
- Chatwoot contact IDs are external operational references, not canonical identities.
- Projection failures must be retryable and visible.
- No Kafka, event bus, BullMQ, or workflow engine is required for Phase 1.

## 3. Incoming WhatsApp Flow

### Flow

WhatsApp via Chatwoot → Chatwoot webhook → Edge Function → `webhook_events` → identity/session resolution → canonical claim/message update → optional `sync_outbox`

1. A WhatsApp message arrives through Chatwoot.
2. Chatwoot emits a webhook.
3. The webhook Edge Function stores the raw envelope in `webhook_events` before business processing.
4. The function normalizes the payload into a channel-neutral shape.
5. The function checks `conversation_sessions` for active session context and TTL.
6. The function resolves the sender through normalized `contact_points` and canonical person-unit relationships.
7. If the number is shared or ambiguous, the user is asked to explicitly select the person/unit context before sensitive actions proceed.
8. Deterministic menu handling creates or updates canonical `claims` and `claim_messages` when enough verified context exists.
9. Ambiguous, unknown, risky, or sensitive cases are escalated to an operator in Chatwoot.
10. Processing outcomes are recorded in `integration_logs` and, when relevant, `audit_logs`.

### Rules

- Deterministic WhatsApp menu flows come first.
- Shared WhatsApp numbers are supported business reality.
- `conversation_sessions` use TTL and an `active_person_context` when known.
- Unknown identities are denied by default for sensitive actions.
- AI must not guess identity, debt, payments, permissions, or unit access.
- Chatwoot remains the operator workspace; Supabase remains canonical.

## 4. Portal Login Flow

### Flow

Portal login request → Edge Function → canonical contact validation → OTP/magic link → `portal_sessions`

1. A user enters an email address or phone/WhatsApp number.
2. The portal calls the auth Edge Function.
3. The function normalizes the identifier.
4. The function validates the identifier against authorized canonical `contact_points`.
5. The function sends an OTP or magic link through the appropriate delivery path.
6. The user verifies the OTP or magic link.
7. The function creates a `portal_sessions` record tied to the canonical person and allowed access context.
8. The portal reads only filtered Supabase projections.

### Rules

- Portal login is mandatory in the MVP.
- Chatwoot authentication is not used.
- Observed or unknown contacts cannot authenticate until explicitly verified and authorized.
- Session access is based on canonical identity and person-unit relationships.

## 5. Portal Ticket Visibility Flow

### Flow

Portal session → Edge Function/RLS-safe projection → canonical claims/messages/attachments

1. The portal requests visible claims for the authenticated session.
2. The Edge Function validates `portal_sessions`.
3. The function resolves authorized units through `person_unit_relationships`.
4. The function returns owner-visible `claims`, `claim_messages`, and `claim_attachments` only.
5. Internal Chatwoot notes, internal metadata, and non-owner-visible artifacts are excluded.
6. PDF and attachment access is granted only through owner-visible attachment rules.

### Rules

- The portal must not read Chatwoot directly.
- Portal-visible status is a safe canonical projection, not raw Chatwoot lifecycle state.
- Visibility decisions must be deterministic, auditable, and explainable from Supabase records.
- Owner-visible attachments and PDF visibility are mandatory MVP capabilities.

## 6. Portal Ticket Visibility Flow

### Flow

Portal session → Edge Function/RLS-filtered query → canonical claims/messages/attachments

1. The portal requests ticket lists, ticket details, messages, attachments, and PDFs.
2. The request is scoped to the active portal session and canonical person.
3. Visibility is derived from `person_unit_relationships`, claim unit context, claim participants, and explicit owner-visible flags.
4. The portal displays safe `owner_visible_status` values and owner-visible messages only.
5. Attachments and PDFs are shown only when `claim_attachments.owner_visible` is true and the user has claim visibility.

### Rules

- Ticket visibility, creation, replies, owner-visible attachments, and PDF visibility are required MVP portal capabilities.
- Raw Chatwoot data is never exposed to the portal.
- Internal Chatwoot notes are never exposed.
- Unknown identities have no visibility until verified.
Portal → Edge Function → `claims` → `claim_messages` → `claim_attachments` if present → `sync_outbox` → Chatwoot conversation

1. An authenticated portal user creates a claim from an authorized unit context.
2. The Edge Function validates the portal session, person, contact point, and unit access.
3. The function creates the canonical `claims` record and public ticket number in Supabase.
4. The function creates the initial `claim_messages` record.
5. Any uploaded owner-visible files are stored and represented in `claim_attachments`.
6. The function writes a Chatwoot conversation creation task to `sync_outbox`.
7. A retry-capable worker creates or updates the Chatwoot conversation.
8. The worker creates or updates a minimal `claim_channel_links` record for provider `chatwoot`.

### Rules

- The claim exists canonically even if Chatwoot creation fails temporarily.
- Chatwoot conversation IDs remain external references.
- The portal displays canonical Supabase state, not Chatwoot state.
- Synchronization failures must be visible and retryable.

## 7. Portal Ticket Creation and Reply Flow

### Flow

Portal → Edge Function → Supabase canonical write → `sync_outbox` Chatwoot task → portal projection

1. A portal user creates a claim or replies to an existing visible claim.
2. The Edge Function validates the session, person, unit, and claim visibility.
3. The function writes the canonical `claims`, `claim_messages`, and `claim_attachments` records first.
4. The function creates or updates `claim_channel_links` as needed.
5. The function queues Chatwoot creation/reply work in `sync_outbox`.
6. The portal immediately reads the canonical Supabase projection.
7. If Chatwoot synchronization fails, the canonical claim remains visible and the failed task is retryable.

### Rules

- Persistence comes before Chatwoot synchronization.
- Portal users should not lose submitted tickets because Chatwoot is temporarily unavailable.
- Operators must be able to see sync failures and recover manually.

## 8. Operator Escalation Flow

### Flow

Deterministic automation limit → Chatwoot operator workflow → webhook → Supabase projection

1. Deterministic WhatsApp or portal automation detects ambiguity, unknown identity, sensitive content, or policy limits.
2. The conversation is routed to human operators in Chatwoot.
3. Operators use Chatwoot assignment, inboxes, notes, and replies.
4. Chatwoot webhooks synchronize owner-visible operator replies back to canonical Supabase messages.
5. Internal notes stay internal and are used only for operations.

### Rules

- Chatwoot remains the human operational workflow layer.
- Supabase remains the canonical owner-visible projection.
- Sensitive claims are not autonomously closed.
Operator reply in Chatwoot → Chatwoot webhook → Edge Function → `webhook_events` → `claim_channel_links` → `claim_messages`

1. An operator replies in Chatwoot.
2. Chatwoot emits a webhook.
3. The Edge Function persists the webhook in `webhook_events`.
4. The function resolves the canonical claim through `claim_channel_links`.
5. The function stores an owner-visible `claim_messages` record only when the message is safe to expose.
6. Internal notes remain internal and are never exposed to the portal.
7. Results are recorded in `integration_logs` and sensitive decisions in `audit_logs`.

### Rules

- Owner-visible filtering applies to every operator-originated message.
- Internal Chatwoot notes must never appear in the portal.
- Message synchronization must be idempotent using stable external message references.
- Sensitive claim closure requires human/operator-controlled handling.

## 8. Deterministic Automation and Operator Escalation Flow

### Flow

Inbound intent/menu step → deterministic rules → safe action or operator escalation

1. The system evaluates the current message against known deterministic menu steps.
2. The system checks session context, identity, unit access, claim sensitivity, and required data.
3. If all required context is verified, the system performs the safe deterministic action.
4. If anything is ambiguous or sensitive, the system escalates to an operator in Chatwoot.
5. AI may prepare a summary, classification, or draft for the operator but cannot execute sensitive actions.

### Rules

- Deterministic flows are the default automation model.
- Manual fallback must always be possible.
- Unknown or ambiguous identities are denied by default for sensitive actions.
- Logs/debugging are prioritized over advanced dashboards.

## 9. AI Assist Flow

### Flow

Webhook or operator request → verified Supabase context → AI assist → operator-reviewed draft/context

1. An Edge Function gathers verified claim, person, unit, message, and integration context from Supabase.
2. AI may summarize, classify, extract intent/entities, enrich operator context, suggest responses, or prepare drafts.
3. AI outputs are shown as assistive context or drafts for operator review.
4. Any owner-visible response requires deterministic data access and policy-compliant delivery.
5. AI usage and sensitive decisions are logged in `audit_logs` when relevant.

### Rules

- AI is assistive/copilot-only in MVP.
- AI must not autonomously expose sensitive data.
- AI must not resolve legal or financial disputes.
- AI must not approve risky operations.
- AI must not close sensitive claims.
- AI must not hallucinate debt, balance, payment, or legal information.
- AI responses must rely on verified tool outputs and deterministic data access.

## 10. Future Provider Integration Points

### Jelou Future Adapter

- Preserve provider values and linking fields for a future `jelou_future` adapter.
- Do not implement Jelou in MVP unless explicitly approved after the deterministic Chatwoot flow is stable.
- A future adapter should reuse canonical claims, messages, contact points, conversation sessions, webhook logs, and sync outbox.

### Meta Cloud Future Adapter

- Preserve `meta_cloud_future` as a possible direct WhatsApp provider path.
- Do not bypass the provider abstraction by hard-coding Chatwoot assumptions into canonical tables.

### VAPI Future Integration Point

- VAPI/voice is out of MVP.
- Future voice calls can enter through the same pattern: provider webhook, `webhook_events`, deterministic identity resolution, canonical claim/message writes, and `sync_outbox`.
- Do not add voice-specific tables until a real Phase 2 implementation requires them.
Canonical data/tool output → AI assist → operator-visible suggestion/draft → human action if needed

1. The system gathers verified canonical data and tool outputs.
2. AI may summarize, classify, extract intent/entities, enrich operator context, suggest responses, or prepare drafts.
3. AI output is shown as assistive context or a draft.
4. Human operators approve, modify, or ignore AI suggestions.
5. AI-assisted recommendations and sensitive uses are recorded in `audit_logs` when relevant.

### Rules

AI may:

- Summarize.
- Classify.
- Extract intent/entities.
- Enrich operator context.
- Suggest responses.
- Prepare drafts.
- Assist operators.

AI must not:

- Autonomously expose sensitive data.
- Autonomously resolve legal or financial disputes.
- Autonomously approve risky operations.
- Autonomously close sensitive claims.
- Hallucinate debt/payment information.

AI responses must rely on verified tool outputs and deterministic data access.

## 10. Future Jelou Adapter Flow

Jelou is not part of the MVP implementation. The future integration point is the provider abstraction used by `claim_channel_links`, `conversation_sessions`, `webhook_events`, `integration_logs`, and `sync_outbox`.

Future Jelou support must:

- Preserve Supabase canonical claims and messages.
- Preserve owner portal filtering.
- Use provider value `jelou_future` or a deliberate later replacement.
- Avoid bypassing identity, permission, audit, and visibility rules.

## 11. Future VAPI Integration Point

VAPI/voice is explicitly out of MVP. The future integration point is a channel adapter that normalizes calls/transcripts into the same canonical claim/message model.

Future VAPI support must:

- Preserve canonical Supabase claim ownership.
- Treat transcripts and summaries as operational inputs until visibility rules permit exposure.
- Use verified data access for AI summaries.
- Never bypass identity matching, permissions, or owner-visible filtering.

Recommended next step:
"Create the actual Supabase schema and Edge Function implementation plan."
