# Database Model

This document defines the final simplified MVP database model for Aqua Public after architecture review. The goal is to maximize implementation success probability while preserving future extensibility for SaaS, AI, VAPI, Jelou, direct Meta Cloud API, and richer automation in later phases.

The MVP is intentionally pragmatic:

- Chatwoot is self-hosted on DigitalOcean and used as the operational inbox for WhatsApp and human support work.
- Supabase is the canonical operational and business database.
- Supabase Edge Functions are the preferred orchestration layer for MVP webhooks, permissions, deterministic flows, and integrations.
- The Next.js owner portal reads filtered Supabase data only.
- Octavo Piso remains the key administrative integration source.
- WhatsApp flows should be deterministic first.
- AI is assistive/copilot only in the MVP.

## MVP Database Principles

- Keep the model simple enough to implement reliably.
- Preserve future extensibility through stable IDs, provider fields, external references, and clear ownership boundaries.
- Avoid enterprise overengineering, distributed-system assumptions, complex workflow state, and premature AI-specific tables.
- Supabase is the source of truth for persons, units, claims, owner-visible messages, portal access, audit records, and integration state.
- Chatwoot is an operational artifact and workflow surface; it is not the canonical database.
- Chatwoot conversation IDs are external references only.
- `claim_channel_links` is the abstraction layer between canonical claims and external channel/provider objects.
- Write canonical Supabase records before synchronizing to Chatwoot, Octavo Piso, WhatsApp providers, or other external systems.
- Use lightweight observability from day one: `webhook_events`, `integration_logs`, `sync_outbox`, and `audit_logs`.
- Use retryable persistence tables instead of Kafka, event buses, BullMQ, or complex workflow engines.
- MVP operations are effectively single-tenant, but `administration_id` exists from day one in core entities to support future SaaS and multi-administration isolation.

## Core Stack Responsibilities

### Supabase

Supabase stores canonical operational data and owner-visible state. Tables in this document should be designed for clear authorization checks, deterministic lookups, idempotent webhook processing, and reliable synchronization.

### Supabase Edge Functions

Supabase Edge Functions are the MVP orchestration layer. They should handle webhook ingestion, Chatwoot synchronization, Octavo Piso integration calls, portal authorization checks, deterministic WhatsApp flow decisions, sync outbox workers, and AI-assist tool boundaries.

A larger backend can be introduced later if operational load or complexity justifies it. The MVP should not assume a large backend, microservice architecture, or separate workflow platform.

### Chatwoot

Chatwoot is the MVP operational provider for WhatsApp support. It provides the inbox, assignment, operator workflow, and WhatsApp conversation handling. Chatwoot does not own canonical claims, persons, units, portal access, owner-visible statuses, or audit history.

### Next.js Owner Portal

The owner portal reads and writes through Supabase and/or Supabase Edge Functions. It must not depend on Chatwoot as an authorization source or canonical ticket database.

### Octavo Piso

Octavo Piso integration provides administrative context and external references for buildings, units, persons, relationships, and possibly claim-related operational data. Supabase normalizes the data needed for MVP flows.

## Required Core Entities

### administrations

Represents the administration/operator boundary.

Purpose:

- Provide future SaaS compatibility and organizational isolation.
- Scope buildings, units, persons, portal access, claims, webhooks, integrations, outbox tasks, and audit records.
- Keep the MVP operationally single-tenant while making future multi-administration support possible.

Relationships:

- One `administrations` record owns many `buildings`, `apartments_or_units`, `persons`, `contact_points`, `person_unit_relationships`, `portal_accounts`, `claims`, `webhook_events`, `integration_logs`, `sync_outbox` tasks, and `audit_logs`.
- Core entities must include `administration_id` from day one, even if the first production deployment has only one administration.

Suggested fields:

- `id`
- `name`
- `status`
- `timezone`
- `created_at`
- `updated_at`

### buildings

Represents buildings, barrios, consorcios, or equivalent managed groups.

Purpose:

- Group units and claims under an administration.
- Store Octavo Piso or manually configured building references.
- Provide a practical filtering boundary for operators and the owner portal.

Relationships:

- Belongs to `administrations`.
- Has many `apartments_or_units`.
- Can be referenced by many `claims`.

Suggested fields:

- `id`
- `administration_id`
- `name`
- `external_source_system`
- `external_source_id`
- `active`
- `created_at`
- `updated_at`

### apartments_or_units

Represents apartments, units, parking spaces, storage units, lots, or other access-relevant property units.

Purpose:

- Provide the main owner-portal visibility boundary.
- Normalize Octavo Piso unit concepts into one MVP table.
- Attach claims to the property context owners understand.

Relationships:

- Belongs to `administrations`.
- Usually belongs to `buildings`.
- Has many `person_unit_relationships`.
- Can be referenced by many `claims`.

Suggested fields:

- `id`
- `administration_id`
- `building_id`
- `unit_code`
- `display_name`
- `external_source_system`
- `external_source_id`
- `active`
- `created_at`
- `updated_at`

### persons

Represents humans or organizations that can own, rent, occupy, report, reply, or receive communications.

Purpose:

- Provide canonical identity for portal access, claim authorship, and contact resolution.
- Avoid duplicating people across WhatsApp, email, Chatwoot, Octavo Piso, and the portal.
- Give deterministic context to flows and future AI tools without relying on chat history.

Relationships:

- Belongs to `administrations`.
- Has many `contact_points`.
- Has many `person_unit_relationships`.
- Can own `portal_accounts`.
- Can author or be the primary requester for `claims` and `claim_messages`.

Suggested fields:

- `id`
- `administration_id`
- `full_name`
- `preferred_name`
- `status`
- `external_source_system`
- `external_source_id`
- `created_at`
- `updated_at`

### contact_points

Represents emails, phone numbers, and WhatsApp-capable identifiers linked to persons.

Purpose:

- Resolve inbound WhatsApp and portal login identities deterministically.
- Support OTP delivery and future provider changes.
- Distinguish verified contact data from observed inbound contact data.
- Support shared family WhatsApp numbers without assuming a phone number always maps to one active person.

Relationships:

- Belongs to `administrations`.
- Belongs to `persons` when the contact has been associated with a person.
- Can be referenced by `portal_accounts` as an authorized login/contact method.
- Can be referenced by `conversation_sessions` for session pinning.

Suggested fields:

- `id`
- `administration_id`
- `person_id`
- `type` (`email`, `phone`, `whatsapp`)
- `normalized_value`
- `raw_value`
- `verified`
- `observed_only`
- `primary_contact`
- `active`
- `external_source_system`
- `external_source_id`
- `created_at`
- `updated_at`

Rules:

- Verified contact points may support portal access when relationship rules allow it.
- Observed-only contact points do not authorize access until explicitly verified.
- Shared WhatsApp numbers require session context and explicit person selection before sensitive actions.

### person_unit_relationships

Represents access-relevant relationships between persons and units.

Purpose:

- Drive owner portal visibility.
- Represent owners, tenants, residents, authorized contacts, administrators, and other access roles.
- Provide deterministic person/unit context for WhatsApp menu flows and operator escalation.

Relationships:

- Belongs to `administrations`.
- Links one `person` to one `apartments_or_units` record.
- Used by `claims`, `portal_sessions`, and deterministic flows to evaluate access.

Suggested fields:

- `id`
- `administration_id`
- `person_id`
- `unit_id`
- `relationship_type`
- `status`
- `can_view_claims`
- `can_create_claims`
- `can_reply_to_claims`
- `valid_from`
- `valid_until`
- `external_source_system`
- `external_source_id`
- `created_at`
- `updated_at`

### portal_accounts

Represents owner portal authentication eligibility.

Purpose:

- Support Next.js owner portal access.
- Bind portal login to verified canonical persons and contact points.
- Keep portal authentication independent from Chatwoot accounts.

Relationships:

- Belongs to `administrations`.
- Belongs to `persons`.
- Usually references a primary verified `contact_points` record.
- Has many `portal_sessions`.

Suggested fields:

- `id`
- `administration_id`
- `person_id`
- `primary_contact_point_id`
- `status`
- `last_login_at`
- `created_at`
- `updated_at`

### portal_sessions

Represents authenticated owner portal sessions or session references.

Purpose:

- Support OTP or magic-link login and scoped owner portal access.
- Preserve an audit trail of portal access.
- Enforce expiration and revocation without exposing Chatwoot internals.

Relationships:

- Belongs to `administrations`.
- Belongs to `portal_accounts`.
- Belongs to `persons`.
- Produces `audit_logs` for sensitive access and permission decisions.

Suggested fields:

- `id`
- `administration_id`
- `portal_account_id`
- `person_id`
- `expires_at`
- `revoked_at`
- `created_at`
- `last_seen_at`

### claims

Represents the canonical business ticket/claim record.

Purpose:

- Store the owner-visible and business-canonical claim state.
- Generate public ticket numbers independently from Chatwoot conversation IDs.
- Link property context, requester context, portal visibility, and operational status.
- Remain valid even when Chatwoot synchronization fails or is delayed.

Relationships:

- Belongs to `administrations`.
- Usually belongs to `buildings` and `apartments_or_units`.
- References a primary `persons` requester when known.
- Has many `claim_messages`, `claim_channel_links`, and `claim_attachments`.

Suggested fields:

- `id`
- `administration_id`
- `public_claim_number`
- `building_id`
- `unit_id`
- `primary_person_id`
- `title`
- `description`
- `category`
- `priority`
- `status`
- `owner_visible_status`
- `source_channel`
- `created_by_person_id`
- `requires_manual_review`
- `created_at`
- `updated_at`
- `closed_at`

Rules:

- `claims` are the canonical business tickets.
- Chatwoot conversations are operational artifacts only.
- Chatwoot conversation IDs remain external references.
- `claim_channel_links` is the required abstraction layer between claims and Chatwoot or future providers.
- Sensitive, ambiguous, legal, financial, or identity-dependent claims must escalate to operators rather than being autonomously resolved.

### claim_messages

Represents canonical messages attached to claims.

Purpose:

- Provide owner-visible conversation history in the portal.
- Store normalized messages from portal, WhatsApp, Chatwoot, system actions, and future channels.
- Apply explicit visibility filtering before exposing anything to owners.

Relationships:

- Belongs to `administrations`.
- Belongs to `claims`.
- Can reference an author `person` when applicable.
- Can have many `claim_attachments`.

Suggested fields:

- `id`
- `administration_id`
- `claim_id`
- `author_person_id`
- `author_type` (`owner`, `operator`, `system`, `ai_assist`)
- `source_channel`
- `body`
- `owner_visible`
- `external_message_id`
- `created_at`

Rules:

- Internal Chatwoot notes must not be copied into owner-visible messages.
- AI-generated drafts may be stored only when clearly marked as assistive context or sent through an approved operator action.

### claim_channel_links

Represents the minimal mapping between canonical claims and external channel/provider objects.

Purpose:

- Link one canonical claim to operational Chatwoot conversations and future provider threads.
- Preserve provider abstraction without over-modeling channel-specific lifecycle state.
- Support future migration to Jelou or direct Meta Cloud API without changing canonical claims.

Relationships:

- Belongs to `administrations`.
- Belongs to `claims`.
- References external provider IDs only; it does not own claim state.

Suggested fields:

- `id`
- `administration_id`
- `claim_id`
- `provider` (`chatwoot`, `jelou_future`, `meta_cloud_future`, `vapi_future`)
- `external_conversation_id`
- `external_contact_id`
- `external_inbox_id`
- `active`
- `created_at`
- `updated_at`

Rules:

- Keep this table minimal.
- Do not mirror Chatwoot's full conversation lifecycle.
- Use stable provider references and idempotency keys for synchronization.
- Chatwoot IDs never become claim IDs, portal IDs, or authorization IDs.

### claim_attachments

Represents lightweight attachments associated with claims or claim messages.

Purpose:

- Support owner-visible attachments in the portal.
- Support PDFs, WhatsApp media, uploaded images, and future documents.
- Store file metadata and visibility without introducing a complex document-management system.

Relationships:

- Belongs to `administrations`.
- Belongs to `claims`.
- Optionally belongs to `claim_messages`.

Suggested fields:

- `id`
- `administration_id`
- `claim_id`
- `claim_message_id`
- `storage_path`
- `file_name`
- `content_type`
- `size_bytes`
- `owner_visible`
- `source_channel`
- `external_attachment_id`
- `created_at`

Rules:

- The owner portal displays only attachments explicitly marked owner-visible.
- PDFs are supported as first-class owner-visible attachments when access rules allow it.
- Raw internal or operator-only artifacts are private by default.

### conversation_sessions

Represents short-lived conversational context for deterministic WhatsApp flows, especially shared family numbers.

Purpose:

- Support shared WhatsApp numbers as a normal business reality.
- Pin the active person context after explicit person selection.
- Store a TTL so stale identity context is not reused indefinitely.
- Avoid guessing identity for ambiguous or sensitive actions.

Relationships:

- Belongs to `administrations`.
- Can reference `contact_points`.
- Can reference the currently selected `persons` and `apartments_or_units` records.
- Can be linked operationally to Chatwoot or future provider conversations through external references.

Suggested fields:

- `id`
- `administration_id`
- `provider`
- `external_conversation_id`
- `contact_point_id`
- `current_person_id`
- `active_unit_id`
- `source_channel`
- `state`
- `last_interaction_at`
- `expires_at`
- `created_at`
- `updated_at`

Rules:

- `current_person_id` represents the active person context for the pinned session.
- Sensitive actions require explicit person selection when a contact point maps to multiple people.
- Expired sessions must re-confirm person context.
- Session context assists deterministic automation; it does not replace authorization checks against `person_unit_relationships`.

### webhook_events

Stores inbound webhook metadata and payloads.

Purpose:

- Provide day-one debugging and replay analysis.
- Retain raw payloads or safe raw-payload references for incident review.
- Make webhook ingestion idempotent and traceable.
- Support troubleshooting without introducing Kafka or event-streaming infrastructure.

Relationships:

- Belongs to `administrations` when resolvable.
- May be associated with claims, messages, channel links, or sync tasks through metadata or related IDs.

Suggested fields:

- `id`
- `administration_id`
- `provider`
- `event_type`
- `external_event_id`
- `payload`
- `payload_hash`
- `received_at`
- `processed_at`
- `processing_status`
- `error_message`

### integration_logs

Stores external API call diagnostics.

Purpose:

- Log calls to Chatwoot, Octavo Piso, OTP/message providers, storage/attachment services, and future providers.
- Capture latency, success/failure, request/response summaries, and troubleshooting context.
- Provide practical observability before advanced dashboards.

Relationships:

- Belongs to `administrations`.
- Can reference related canonical entities such as claims, persons, units, or outbox tasks.

Suggested fields:

- `id`
- `administration_id`
- `integration_name`
- `operation`
- `related_entity_type`
- `related_entity_id`
- `request_summary`
- `response_summary`
- `status`
- `latency_ms`
- `error_message`
- `created_at`

### sync_outbox

Stores retryable synchronization tasks for eventual consistency.

Purpose:

- Implement persistence-first synchronization.
- Retry Chatwoot, Octavo Piso, attachment, notification, and future-provider operations.
- Preserve a recoverable task record when an external service is unavailable.
- Avoid Kafka, event bus, BullMQ, and complex workflow-engine complexity in the MVP.

Relationships:

- Belongs to `administrations`.
- Can reference claims, messages, channel links, attachments, persons, units, or integration records through payload or related IDs.
- Produces `integration_logs` as external calls are attempted.

Suggested fields:

- `id`
- `administration_id`
- `task_type`
- `target_system`
- `related_entity_type`
- `related_entity_id`
- `payload`
- `idempotency_key`
- `status`
- `attempt_count`
- `next_attempt_at`
- `last_error`
- `created_at`
- `updated_at`

Rules:

- Failed external synchronization must not erase canonical Supabase records.
- Retries must be idempotent.
- Operators should be able to inspect and manually recover failed tasks.

### audit_logs

Stores security-relevant and business-relevant audit events.

Purpose:

- Track private data access and owner data access.
- Record sensitive actions, portal access, identity decisions, permission decisions, claim changes, operator actions, AI-assist usage, and integration recovery.
- Support security tracing and accountability without advanced analytics infrastructure.

Relationships:

- Belongs to `administrations`.
- Can reference any canonical entity through `entity_type` and `entity_id`.
- Can reference actors such as owners, operators, system processes, Edge Functions, or AI-assist tools.

Suggested fields:

- `id`
- `administration_id`
- `actor_type`
- `actor_id`
- `action`
- `entity_type`
- `entity_id`
- `metadata`
- `source_channel`
- `created_at`

## Claims Are Canonical

Claims are the canonical business tickets in the Aqua Public system. All owner-visible ticket numbers, statuses, claim categories, requester context, property context, and portal-visible history should derive from Supabase claim records.

Chatwoot conversations are operational artifacts. They help operators receive WhatsApp messages, triage issues, assign work, and reply to owners, but they do not define canonical claim identity or authorization.

The required boundary is:

- `claims` stores business truth.
- `claim_messages` stores canonical owner-visible or system-visible message history.
- `claim_attachments` stores canonical attachment metadata and visibility.
- `claim_channel_links` maps canonical claims to Chatwoot conversations and future provider threads.
- Chatwoot IDs remain external references.

## Shared Phone Numbers and Session Pinning

Shared family WhatsApp numbers are expected. The model must not assume one phone number always equals one person.

MVP behavior:

- Match inbound WhatsApp contacts through `contact_points`.
- If a phone number maps to multiple possible persons, require explicit person selection before sensitive actions.
- Store short-lived active context in `conversation_sessions.current_person_id`.
- Track `last_interaction_at`, `expires_at`, and `source_channel` for TTL-based session pinning.
- Reconfirm person context after session expiry.
- Always re-check authorization through `person_unit_relationships` before showing private unit or claim information.

This keeps deterministic flows safe while avoiding a complex identity engine.

## AI Scope

MVP AI is assistive/copilot only. The database should not introduce autonomous-agent tables, vector databases, RAG indexes, LangGraph state, long-term AI memory, or AI workflow engines.

AI may:

- Summarize conversations.
- Classify claims.
- Extract intent and entities.
- Enrich operator context.
- Suggest replies.
- Prepare drafts.
- Assist human operators.

AI must not:

- Autonomously expose private owner data.
- Autonomously approve legal, financial, identity-sensitive, or operationally risky actions.
- Autonomously close sensitive claims.
- Invent debt, payment, building, unit, or account information.
- Treat chat history as authorization.

Future AI extensibility is preserved by clean canonical data, explicit audit logs, stable claim/message/attachment records, and provider-neutral channel links.

## WhatsApp Provider Abstraction

Chatwoot remains the MVP operational WhatsApp provider.

Future provider abstraction is preserved through provider fields in `claim_channel_links`, `conversation_sessions`, `webhook_events`, `integration_logs`, and `sync_outbox`.

Reserved provider values:

- `chatwoot` for the MVP path.
- `jelou_future` for a possible Jelou provider path.
- `meta_cloud_future` for a possible direct Meta Cloud API provider path.
- `vapi_future` for future voice workflows, outside Phase 1.

Do not create provider-specific canonical claim tables in the MVP.

## Explicit Phase 1 Non-Goals

The Phase 1 MVP data model must not include:

- VAPI implementation.
- LangGraph.
- Vector databases.
- RAG systems.
- Long-term AI memory.
- Autonomous AI operations.
- Autonomous sensitive claim closure.
- Microservices.
- Kafka.
- Event buses.
- BullMQ.
- Complex workflow engines.
- Advanced analytics tables.
- Enterprise tenant hierarchies beyond `administrations` and `administration_id`.

## Implementation Notes

- Do not generate SQL from this document without a separate implementation task.
- Keep first schema slices tied to vertical MVP flows: identify person, identify unit, create claim, sync to Chatwoot, display claim in portal, attach files, audit access.
- Prefer nullable future-facing fields over new tables until a concrete MVP flow requires additional structure.
- Do not let the portal read Chatwoot directly.
- Do not let Chatwoot conversation status become the canonical owner-visible status without explicit mapping.
- Use `webhook_events` for inbound debugging and replay analysis.
- Use `integration_logs` for external API diagnostics and latency tracking.
- Use `sync_outbox` for retryable eventual consistency.
- Use `audit_logs` for private data access and security tracing.

## Final MVP Philosophy

The MVP should favor deterministic flows first, persistence before automation, and observability before autonomy.

Human operators remain central in Phase 1. AI assists operators; it does not replace authorization, judgment, or sensitive decision-making.

The architecture remains intentionally simple while preserving the extension points needed for future SaaS, AI, VAPI, Jelou, direct Meta Cloud API, and richer automation phases.
