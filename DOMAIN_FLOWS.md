# DOMAIN_FLOWS.md

This document defines the final simplified MVP operational flows after architecture simplification.

The MVP intentionally prioritizes deterministic flows, operational simplicity, auditability, observability, implementation velocity, and future extensibility. The goal is not enterprise orchestration. The goal is a realistic AI-assisted operational MVP.

## 1. High-Level System Flow

### System Roles

- **Chatwoot** is the operational inbox. Operators use it to receive WhatsApp messages, manage conversations, reply to owners, add internal notes, and coordinate day-to-day service work.
- **Supabase** is the canonical business state. Owner identity, normalized contact points, claims, claim visibility, session context, operational snapshots, audit records, webhook receipts, integration logs, and synchronization state are persisted there first.
- **Supabase Edge Functions** are the orchestration layer. They receive webhooks, normalize input, enforce permissions, run deterministic menu flows, call integrations, write audit records, and enqueue retryable sync work.
- **Next.js owner portal** is the owner-facing projection. It displays filtered, permission-checked views of canonical Supabase state and allows owners to create and follow claims.
- **Octavo Piso** is the administrative source system. It remains authoritative for administration data such as buildings, units, owners, debts, coupons, and payment-related administrative records.

### Flow Principles

1. External events enter through Chatwoot, the portal, scheduled syncs, or explicit operator actions.
2. Edge Functions persist the received event or command before attempting downstream synchronization.
3. Supabase stores canonical operational state and operational snapshots.
4. Chatwoot, portal screens, and outbound messages are updated from persisted state.
5. Synchronization occurs after persistence and may be retried.
6. Eventual consistency is acceptable when the system can show stale-data warnings, retry failures, and preserve auditability.

### MVP Architecture Rules

- Persistence comes before synchronization.
- Synchronization comes before optimization.
- Failed downstream delivery must not erase the canonical business event.
- The portal never reads directly from Chatwoot or Octavo Piso.
- Chatwoot remains operational; Supabase remains canonical; Octavo Piso remains administrative.
- Edge Functions keep orchestration simple and explicit for Phase 1.

## 2. WhatsApp Deterministic Menu Flows

Phase 1 WhatsApp flows are deterministic menu and webhook flows. They do not require autonomous AI reasoning for closed, rule-defined operations.

### Standard Entry Flow

1. A WhatsApp message arrives in Chatwoot.
2. Chatwoot sends an inbound webhook to an Edge Function.
3. The Edge Function records the webhook receipt.
4. The Edge Function normalizes the sender and message.
5. The Edge Function resolves identity and active session context.
6. The Edge Function presents or continues a deterministic menu.
7. The Edge Function either completes the closed flow, creates a canonical record, or escalates to an operator.

### Phase 1 Menu Options

- **Request expense coupon**: verifies identity and apartment context, checks available administrative snapshot data, and returns a permitted coupon link, file, or stale-data message.
- **Request debt balance**: verifies identity and apartment context, reads the latest permitted debt snapshot, and states freshness clearly.
- **Create claim**: collects claim category, description, apartment/common-area context, attachments when available, and creates a canonical claim.
- **Ask operator assistance**: routes the conversation to a human operator in Chatwoot with relevant context.
- **Request payment proof**: verifies identity and apartment context, collects or retrieves permitted proof information, and escalates if the data is disputed or unavailable.
- **Generic information**: provides non-sensitive information such as office hours, building contact channels, high-level process explanations, or portal access instructions.

### Deterministic Flow Rules

- Closed flows must prefer buttons, numbered options, and explicit confirmation prompts.
- Sensitive flows require verified identity and selected apartment context.
- Unknown or ambiguous identities may receive generic information only.
- No autonomous AI reasoning is required to complete deterministic Phase 1 flows.
- Any flow that cannot safely complete deterministically escalates to a human operator.

## 3. Identity Resolution Flow

Identity resolution protects private information and ensures that sensitive actions are tied to the correct person and apartment.

### Flow

1. An incoming WhatsApp message arrives through Chatwoot.
2. The Edge Function normalizes the contact point, including phone formatting, country code handling, and channel metadata.
3. The normalized contact point is looked up in Supabase canonical identity records.
4. The system checks whether the contact point maps to one verified person, multiple possible people, or no known person.
5. The system checks whether there is an active session with a pinned `active_person_context` and valid TTL.
6. If the person has access to multiple apartments, the system requests apartment selection before sensitive actions.
7. If the number is ambiguous or shared, the system asks the user to select the correct person and apartment context.
8. If identity cannot be verified, private data is denied by default.
9. Generic information may still be shown to unknown or unverified users.

### Access Rules

- Private data requires verified access.
- Sensitive actions require an explicit person and apartment context.
- Unknown identities are denied by default for private information, balances, coupons, payment records, claim details, and owner-only documents.
- AI must not infer or guess identity from conversational hints.
- Operators may manually review ambiguous cases in Chatwoot and update canonical identity records only through approved operational procedures.

## 4. Shared Phone / Session Pinning

Shared WhatsApp numbers are expected in family, household, caretaker, and administrator scenarios. The MVP must support this without exposing private data incorrectly.

### Flow

1. A message arrives from a phone number associated with more than one person or apartment relationship.
2. The deterministic menu asks who is using the number or which apartment the request concerns.
3. The user selects the person and, when needed, the apartment.
4. The system stores the selected `active_person_context` and apartment context for the conversation session.
5. The session remains valid only until its TTL expires.
6. The user may explicitly switch active person or apartment context.
7. Sensitive actions restart context confirmation when the session is missing, expired, or inconsistent with the requested action.

### Auditability Requirements

- Every context selection must be auditable.
- Every context switch must record who or what was selected, the channel, the timestamp, and the triggering conversation.
- Sensitive actions must be traceable to the active person and apartment context used at the time.
- Session pinning is a convenience, not proof of permanent identity.

## 5. Claim / Ticket Lifecycle

Claims are canonical business records in Supabase. Chatwoot conversations are operational workspaces used to communicate and coordinate.

### Creation Paths

- **Portal-created claims**: an authenticated owner creates a claim from the portal, optionally adds attachments, and sees the claim immediately in their filtered view.
- **WhatsApp-created claims**: a verified WhatsApp user completes a deterministic claim creation flow and the system creates a canonical claim.
- **Operator-created claims**: an operator identifies a service issue in Chatwoot and creates or links a canonical claim from the operational conversation.

### Lifecycle Flow

1. A claim is created in Supabase with source channel, requester, apartment or common-area context, category, description, visibility rules, and initial status.
2. Any related Chatwoot conversation is linked as an operational reference.
3. Attachments and messages are stored or referenced according to visibility and permission rules.
4. The claim is enriched with deterministic metadata such as category, urgency, source, building, unit, and related administrative context.
5. The claim is assigned to an operator or queue.
6. Operators reply through Chatwoot or approved portal messaging paths.
7. Owner-visible replies are synchronized into canonical claim messages.
8. Internal Chatwoot notes remain internal and are never exposed in the portal.
9. Owners see claim status, permitted messages, and permitted attachments in the portal.
10. Operators may close claims after completing the necessary review.
11. Owners or operators may reopen claims when new information appears or the issue persists.

### MVP Safety Rules

- No autonomous sensitive claim closure is allowed in the MVP.
- AI may suggest closure language, but a human must approve sensitive closures.
- Chatwoot status is not the canonical claim status unless explicitly synchronized through approved rules.
- Owner visibility is filtered by identity, apartment relationship, claim visibility, and attachment visibility.

## 6. Portal Flows

The portal remains mandatory in the MVP. It is the owner-facing projection layer, not the source system.

### OTP Login

1. The owner enters a phone number or email.
2. The portal sends the login request to an Edge Function.
3. The Edge Function normalizes the contact point.
4. Supabase verifies that the contact point belongs to an eligible person with an active owner or authorized relationship.
5. An OTP is sent through the configured delivery channel.
6. The owner submits the OTP.
7. The portal session is established for the verified person.

### Owner Dashboard

- Shows apartments or relationships available to the authenticated person.
- Shows claim summaries visible to that person.
- Shows permitted debt, coupon, payment, or document snapshots when available.
- Clearly labels stale or last-synced administrative data.

### Claim Visibility and Creation

- Owners can create claims from the portal.
- Owners can attach files or images when allowed.
- Owners can see only their permitted claims and permitted messages.
- Owners can reply to claims through approved message flows.
- Owners can view PDFs only when identity, apartment relationship, document type, and visibility rules allow it.

### Portal Rules

- The portal reads filtered Supabase projections only.
- The portal does not expose raw Chatwoot conversations.
- The portal does not expose Chatwoot internal notes.
- The portal does not query Octavo Piso directly.
- Portal visibility is filtered by authenticated person, apartment relationship, document permissions, and claim visibility.

## 7. AI Assist Flows

AI is assistive and copilot-only in the MVP. Deterministic flows remain the default for closed operations.

### AI May

- Summarize long conversations for operators.
- Classify claim category or urgency for review.
- Extract structured intent from owner messages.
- Suggest operator responses.
- Enrich operator context with permission-checked summaries.
- Prepare drafts for human approval.
- Identify when a conversation should be escalated.

### AI Must Not

- Autonomously expose sensitive data.
- Autonomously resolve legal disputes.
- Autonomously approve risky operations.
- Hallucinate balances, debts, payment status, coupon availability, or administrative facts.
- Autonomously close sensitive claims.
- Guess identity, ownership, apartment access, or relationship status.

### AI Access Rules

- AI uses permission-checked tools only.
- AI never directly accesses Octavo Piso.
- AI never directly accesses the database.
- AI receives only scoped, filtered context prepared by Edge Functions or approved backend APIs.
- AI output is treated as a draft or recommendation unless a deterministic rule explicitly allows a safe non-sensitive response.

## 8. Human Escalation Flows

Human fallback always exists. The MVP is operator-centric and must make escalation easy.

### Escalation Triggers

- Ambiguous identity.
- Shared phone context cannot be safely selected.
- Payment disputes.
- Legal claims or legal threats.
- Angry, abusive, or distressed users.
- Unknown ownership or unclear apartment relationship.
- Confidence too low for classification or intent extraction.
- Operator requested by the user.
- Stale administrative data that affects a sensitive answer.
- Missing attachment or unreadable proof.
- Any deterministic flow reaches an unsupported branch.

### Escalation Flow

1. The system stops the sensitive automated flow.
2. The conversation remains or is assigned in Chatwoot.
3. The operator receives available context, identity status, selected apartment context, recent messages, and reason for escalation.
4. The operator replies, requests clarification, or updates canonical records through approved procedures.
5. The final resolution is recorded in canonical state when it affects a claim or owner-visible record.

## 9. Octavo Piso Synchronization Flows

Octavo Piso remains authoritative for administrative source data. Supabase stores operational snapshots needed for fast, auditable owner service.

### Daily Sync

1. A scheduled Edge Function runs a daily synchronization.
2. The function retrieves relevant administrative data from Octavo Piso.
3. Supabase stores normalized operational snapshots and external references.
4. The function records success, failures, counts, and timestamps in integration logs.
5. Sensitive or access-relevant changes are auditable.

### Webhook-Triggered or Operator-Triggered Refreshes

- A specific owner, apartment, debt, coupon, payment, or document snapshot may be refreshed when a user requests it or an operator triggers it.
- The refresh updates Supabase snapshots before the result is shown or sent.
- If refresh fails, the system uses the last known snapshot only with a clear stale-data warning or escalates to an operator.

### Stale Data Handling

- Owner-facing financial or administrative data must show last-synced timing when relevant.
- Stale snapshots are acceptable when clearly labeled and operationally useful.
- If stale data could create financial, legal, or trust risk, the system escalates instead of pretending the data is current.

### Authority Rules

- Supabase stores operational snapshots only for Octavo-managed administrative data.
- Octavo Piso remains authoritative for the underlying administrative facts.
- Supabase remains authoritative for operational claims, sessions, audit records, and portal-facing workflow state.

## 10. Chatwoot Synchronization Flows

Chatwoot synchronization stays simple in Phase 1. The MVP does not need Kafka, an event bus, BullMQ, or a workflow engine.

### Inbound Webhook Flow

1. Chatwoot emits a webhook for an inbound message, outgoing message, conversation update, contact update, or assignment change.
2. The Edge Function persists the raw webhook event before business processing.
3. The function applies idempotency checks.
4. The function maps Chatwoot external references to canonical Supabase records.
5. The function updates claims, messages, attachments, or operational links when allowed.
6. The function logs processing outcomes and errors.

### Outbound Synchronization Flow

1. Supabase persists the canonical business action first.
2. The required Chatwoot or WhatsApp side effect is written as a `sync_outbox` task.
3. A retry-capable Edge Function processes the outbox task.
4. Success or failure is recorded in integration logs.
5. Failed tasks remain inspectable and retryable.

### Rules

- Persistence-first is mandatory.
- `sync_outbox` handles retryable external work.
- Retries are preferred before introducing orchestration engines.
- Chatwoot IDs are external operational references, not canonical identities.
- Eventual consistency is acceptable when failures are visible and recoverable.

## 11. Observability Flows

Observability is mandatory from day 1. Debugging visibility is prioritized over polished dashboards.

### Required Operational Records

- **`webhook_events`**: stores inbound webhook receipts, provider names, event types, external IDs, raw payload references, idempotency status, and processing state.
- **`integration_logs`**: stores integration attempts, request/response summaries, success/failure status, error messages, retry counts, and affected external systems.
- **`sync_outbox`**: stores pending, successful, failed, and retryable outbound synchronization tasks.
- **`audit_logs`**: stores security-relevant and business-relevant changes such as identity selections, context switches, permission-sensitive access, claim status changes, and operator actions.

### Observability Flow

1. Every inbound webhook is recorded before processing.
2. Every external integration attempt is logged.
3. Every retryable outbound task has a visible state.
4. Every sensitive or permission-relevant action has an audit trail.
5. Operators and developers can inspect what happened without reconstructing state from provider dashboards.

### MVP Observability Rules

- Debugging visibility is more important than advanced dashboards.
- Logs must help answer: what happened, when, for whom, through which channel, and what failed.
- Silent failure is not acceptable.
- Auditability is part of the product, not an afterthought.

## 12. Future Expansion Points

The architecture intentionally preserves future extensibility while deferring complexity.

### Future-Ready Integration Points

- **VAPI**: voice intake, outbound calls, and AI-assisted call summaries can later use the same identity, claim, audit, and permission boundaries.
- **Jelou**: alternative or complementary WhatsApp automation can later integrate through the same canonical persistence and synchronization patterns.
- **Stronger AI agents**: future agents can operate with stricter tool permissions, richer context, and human approval workflows.
- **Richer automation**: more deterministic workflows can be added after Phase 1 proves operational reliability.
- **SaaS evolution**: administration and organization boundaries can mature into stronger multi-tenant capabilities when the product requires it.

### Expansion Rules

- Future systems integrate through canonical persistence and audited tools.
- Future complexity must not bypass identity, visibility, or audit controls.
- The MVP defers orchestration complexity intentionally, not accidentally.

## 13. Explicit Phase 1 Non-Goals

Phase 1 explicitly excludes:

- VAPI implementation.
- LangGraph.
- Vector databases.
- RAG.
- Kafka.
- BullMQ.
- Microservices.
- Autonomous financial actions.
- Autonomous legal decisions.
- Advanced workflow engines.
- Aggressive multi-tenant orchestration.
- Direct AI access to Octavo Piso.
- Direct AI access to the database.
- Autonomous sensitive claim closure.
- Enterprise-grade orchestration.

## 14. Final MVP Philosophy

The final MVP is intentionally operational, deterministic, and auditable.

- Deterministic before autonomous.
- Persistence before orchestration.
- Observability before optimization.
- Human operators before autonomous resolution.
- AI assist before AI agency.
- Owner visibility through filtered projections.
- Extensibility without overengineering.

This approach keeps the MVP realistic: Chatwoot handles operational communication, Supabase preserves canonical business state, Edge Functions coordinate simple workflows, the portal gives owners a trustworthy projection, Octavo Piso remains authoritative for administrative data, and AI helps humans without replacing critical judgment.
