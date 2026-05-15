# Database Model

This document defines the simplified MVP database model for the Aqua owner-support platform. The model is intentionally small, auditable, and implementation-friendly while preserving the future option to add richer AI, Jelou, VAPI, and SaaS capabilities.

## MVP Database Principles

- Supabase is the canonical operational and business database.
- Chatwoot is self-hosted on DigitalOcean with minimal operations, backups, and logs, and acts as an operational inbox/workflow system rather than the source of truth for claims, persons, units, portal access, or owner-visible state.
- Supabase Edge Functions are the preferred MVP orchestration layer for permissions, webhooks, deterministic automation, and integrations.
- A larger backend such as NestJS may be introduced later only when operational load or complexity justifies it.
- Every core entity includes `administration_id` or `organization_id` from day one to preserve SaaS evolution, while the MVP remains effectively single-tenant operationally.
- Persistence happens before synchronization: write the canonical Supabase record first, then synchronize to Chatwoot, Octavo Piso, or other providers through retryable tasks.
- Observability is mandatory from day one through `webhook_events`, `integration_logs`, `sync_outbox`, and `audit_logs`.
- The schema should not include Kafka-style event streams, workflow-engine state, vector databases, long-term AI memory, LangGraph state, or advanced analytics tables in the MVP.

## Canonical MVP Tables

### administrations

Represents the administration/operator context for the MVP.

Purpose:

- Provide an early boundary for future SaaS or multi-administration support.
- Scope buildings, units, persons, claims, logs, and integrations.
- Keep MVP operations effectively single-tenant without blocking future expansion.

Recommended fields:

- `id`
- `name`
- `status`
- `timezone`
- `created_at`
- `updated_at`

### buildings

Represents buildings, barrios, consorcios, or equivalent groups synchronized from Octavo Piso or configured directly.

Purpose:

- Group units and claims under an administration.
- Support owner portal filtering and operator context.
- Preserve a simple future reporting boundary without adding enterprise tenant hierarchy.

Recommended fields:

- `id`
- `administration_id`
- `name`
- `external_source_system`
- `external_source_id`
- `active`
- `created_at`
- `updated_at`

### apartments_or_units

Represents apartments, units, lots, or other owner-visible property units.

Purpose:

- Provide the canonical access-control and claim-context unit.
- Normalize Octavo Piso property concepts into one simple MVP table.
- Support owner-visible ticket filtering.

Recommended fields:

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

Represents a human or organization that can own, occupy, report, reply, or receive communications.

Purpose:

- Canonical identity record for portal access, claim authorship, and contact resolution.
- Avoid duplicating people across WhatsApp, email, Chatwoot, Octavo Piso, or the portal.
- Preserve future AI compatibility by giving AI tools deterministic person context instead of relying on chat history.

Recommended fields:

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

Represents email addresses, phone numbers, and WhatsApp-capable identifiers linked to persons.

Purpose:

- Resolve inbound WhatsApp and portal login identities deterministically.
- Support OTP delivery and future provider changes.
- Distinguish verified authorization data from observed inbound data.

Recommended fields:

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

- Verified contact points may authorize portal access when relationship rules allow it.
- Observed-only contact points do not authorize access until explicitly verified.
- Shared WhatsApp numbers are supported by combining contact matching with session pinning and explicit person selection for sensitive actions.

### person_unit_relationships

Represents access-relevant relationships between persons and units.

Purpose:

- Drive owner portal visibility.
- Represent owners, tenants, residents, authorized contacts, and other roles without overloading the `persons` table.
- Provide deterministic context for WhatsApp menu flows and operator escalation.

Recommended fields:

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

- Support mandatory Next.js owner portal access.
- Bind portal login to verified canonical persons and contact points.
- Keep portal authentication independent from Chatwoot accounts.

Recommended fields:

- `id`
- `administration_id`
- `person_id`
- `primary_contact_point_id`
- `status`
- `last_login_at`
- `created_at`
- `updated_at`

### portal_sessions

Represents active owner portal sessions or session references.

Purpose:

- Support OTP login and scoped owner portal access.
- Preserve an audit trail of access without exposing Chatwoot internals.
- Enforce expiration and revocation.

Recommended fields:

- `id`
- `administration_id`
- `portal_account_id`
- `person_id`
- `expires_at`
- `revoked_at`
- `created_at`
- `last_seen_at`

### claims

Represents the canonical ticket/claim record.

Purpose:

- Store the owner-visible and business-canonical claim state.
- Generate public ticket numbers independently from Chatwoot conversation IDs.
- Link property context, requester context, portal visibility, and operational status.

Recommended fields:

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
- `created_at`
- `updated_at`
- `closed_at`

Rules:

- `claims` are canonical.
- Chatwoot conversation IDs are external references, never canonical identifiers.
- Sensitive or ambiguous claims must escalate to operators rather than being autonomously closed.

### claim_messages

Represents canonical messages attached to claims.

Purpose:

- Provide owner-visible conversation history in the portal.
- Store normalized messages from portal, WhatsApp, Chatwoot, and future channels.
- Apply explicit visibility filtering before exposing anything to owners.

Recommended fields:

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
- AI-generated drafts may be stored only when clearly marked as assistive context or when sent by an approved operator action.

### claim_channel_links

Minimal external-channel linking table.

Purpose:

- Link one canonical claim to operational Chatwoot conversations and future provider threads.
- Preserve provider abstraction without over-modeling channel-specific state.
- Support future values such as `jelou_future`, `meta_cloud_future`, and voice references without redesigning claims.

Recommended fields:

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
- Use stable provider references for idempotent synchronization.

### claim_attachments

Represents owner-visible and operational attachments associated with claims or messages.

Purpose:

- Support owner portal attachments and PDF visibility.
- Store metadata for files uploaded from portal, WhatsApp, Chatwoot, or imported systems.
- Control owner visibility explicitly.

Recommended fields:

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

- The portal displays only attachments marked owner-visible.
- PDFs are supported as first-class owner-visible attachments when access rules allow it.

### conversation_sessions

Represents temporary conversational context for shared phone numbers and deterministic WhatsApp flows.

Purpose:

- Support shared WhatsApp numbers as a normal business reality.
- Pin the active person/unit context for a short TTL after explicit selection.
- Avoid guessing identity for ambiguous or sensitive actions.

Recommended fields:

- `id`
- `administration_id`
- `provider`
- `external_conversation_id`
- `contact_point_id`
- `active_person_id`
- `active_unit_id`
- `state`
- `expires_at`
- `created_at`
- `updated_at`

Rules:

- Ambiguous sensitive actions require explicit user selection.
- Expired sessions must re-confirm context.
- Session context helps deterministic automation; it is not a replacement for authorization checks.

### webhook_events

Stores raw and normalized inbound webhook receipts.

Purpose:

- Provide mandatory day-one observability.
- Make webhook ingestion idempotent and debuggable.
- Preserve source payload evidence without turning webhooks into an event-streaming architecture.

Recommended fields:

- `id`
- `administration_id`
- `provider`
- `event_type`
- `external_event_id`
- `payload`
- `received_at`
- `processed_at`
- `processing_status`
- `error_message`

### integration_logs

Stores integration attempts and outcomes.

Purpose:

- Debug Chatwoot, Octavo Piso, OTP, attachment, and future provider operations.
- Prioritize logs and traceability over advanced dashboards.

Recommended fields:

- `id`
- `administration_id`
- `integration_name`
- `operation`
- `related_entity_type`
- `related_entity_id`
- `request_summary`
- `response_summary`
- `status`
- `error_message`
- `created_at`

### sync_outbox

Simplified reliability table for retryable synchronization tasks.

Purpose:

- Implement persistence-first, synchronization-second flows.
- Retry Chatwoot, Octavo Piso, attachment, notification, and future provider operations without Kafka, BullMQ, or workflow engines.
- Provide eventual consistency with manual fallback.

Recommended fields:

- `id`
- `administration_id`
- `task_type`
- `target_system`
- `payload`
- `idempotency_key`
- `status`
- `attempt_count`
- `next_attempt_at`
- `last_error`
- `created_at`
- `updated_at`

Rules:

- Failed external sync must not erase canonical Supabase records.
- Retries must be idempotent.
- Operators should be able to inspect and manually recover failed tasks.

### audit_logs

Stores security-relevant and business-relevant actions.

Purpose:

- Preserve accountability for portal access, claim changes, identity decisions, operator-sensitive actions, AI assist usage, and integration recovery.
- Support debugging and compliance without advanced analytics infrastructure.

Recommended fields:

- `id`
- `administration_id`
- `actor_type`
- `actor_id`
- `action`
- `entity_type`
- `entity_id`
- `metadata`
- `created_at`

## AI Compatibility Without AI Over-Modeling

The MVP should not add vector databases, RAG tables, LangGraph state, autonomous-agent memory, or complex AI workflow entities. AI assist features can use verified Supabase records, recent claim messages, and integration outputs as deterministic context.

AI may summarize, classify, extract intent/entities, enrich operator context, suggest responses, prepare drafts, and assist operators. AI must not autonomously expose sensitive data, resolve legal or financial disputes, approve risky operations, close sensitive claims, or invent debt/payment data. AI outputs must rely on verified tool outputs and deterministic data access.

## Provider Abstraction

The MVP starts with WhatsApp through Chatwoot. The provider abstraction is preserved through simple provider fields and `claim_channel_links` values:

- `chatwoot`
- `jelou_future`
- `meta_cloud_future`
- `vapi_future`

Do not implement Jelou, Meta Cloud direct integration, or VAPI in Phase 1. Keep table shapes ready for them without adding their operational complexity.
This document defines the simplified MVP data model for Aqua Public. The goal is to maximize implementation success probability while preserving future extensibility for AI, Jelou, VAPI, and SaaS evolution.

## MVP Database Principles

- Supabase is the canonical database for operational and business state.
- Chatwoot is the operational inbox/workflow and must not become the canonical database.
- Chatwoot is self-hosted on DigitalOcean with a minimal setup, basic backups, and accessible logs.
- Octavo Piso is the administrative source system and upstream integration source.
- Supabase Edge Functions are the preferred MVP orchestration layer for permissions, webhooks, deterministic automation, and integrations.
- The Next.js owner portal reads filtered Supabase projections only.
- Persistence happens before synchronization or automation.
- Observability is mandatory from day 1 through simple tables and logs before advanced dashboards.
- The MVP remains effectively single-tenant operationally, but core records include `administration_id` or `organization_id` from day 1 so the schema can evolve toward SaaS later.

## Explicitly Out of the MVP Data Model

The MVP schema must not introduce premature distributed-system or enterprise abstractions for:

- Kafka or event-streaming infrastructure.
- BullMQ or queue infrastructure.
- Microservices.
- LangGraph.
- Vector databases.
- RAG systems.
- Long-term AI memory.
- Complex workflow engines.
- Autonomous AI financial operations.
- Autonomous sensitive claim closure.
- Aggressive SaaS multi-tenancy beyond early IDs and clear ownership boundaries.

## Required Core Entities

### `administrations`

Represents the administration/management context. In the MVP this is likely one operational administration, but the table establishes a clean boundary for future multi-administration or SaaS use.

Minimum responsibilities:

- Owns buildings, persons, units, claims, integration logs, and audit logs.
- Stores display name and basic operational settings.
- Provides the default `administration_id` for all canonical records.

### `buildings`

Represents buildings administered through the platform.

Minimum responsibilities:

- Belongs to `administrations`.
- Stores Octavo Piso external references when available.
- Groups units and claims.

### `apartments_or_units`

Represents apartments, units, parking spaces, storage units, or other access-relevant managed units.

Minimum responsibilities:

- Belongs to `administrations` and usually to `buildings`.
- Stores canonical unit labels and Octavo Piso external references.
- Provides the main visibility boundary for owner portal access.

### `persons`

Represents humans or organizations that can own, rent, occupy, report, or receive communications.

Minimum responsibilities:

- Belongs to `administrations`.
- Stores canonical identity fields and Octavo Piso external references.
- Does not store channel-specific operational workflow state from Chatwoot.

### `contact_points`

Represents emails, phone numbers, and WhatsApp-capable phone numbers associated with persons.

Minimum responsibilities:

- Belongs to `administrations` and a `person`.
- Stores normalized identifiers for deterministic matching.
- Tracks verification and portal authorization state.
- Supports shared WhatsApp numbers by not assuming one phone number always maps to one active person in all contexts.

### `person_unit_relationships`

Represents access-relevant relationships between persons and units.

Minimum responsibilities:

- Belongs to `administrations`.
- Links `persons` to `apartments_or_units`.
- Stores relationship role such as owner, tenant, occupant, administrator, or authorized representative.
- Drives owner portal visibility rules.

### `portal_accounts`

Represents portal login eligibility and preferences for canonical persons.

Minimum responsibilities:

- Belongs to `administrations` and `persons`.
- Supports OTP or magic-link login through authorized `contact_points`.
- Does not authenticate against Chatwoot.

### `portal_sessions`

Represents authenticated portal sessions.

Minimum responsibilities:

- Belongs to `administrations`, `portal_accounts`, and `persons`.
- Stores session lifecycle metadata and expiry.
- Stores enough context to evaluate unit-scoped access without exposing Chatwoot internals.

### `claims`

Represents canonical tickets/claims.

Minimum responsibilities:

- Belongs to `administrations` and usually to a building/unit.
- Stores canonical public ticket number, owner-visible status, claim category, reporter context, and lifecycle timestamps.
- Remains canonical even when Chatwoot conversation creation or synchronization fails.
- Stores sensitive-state flags when claims require manual handling.

### `claim_messages`

Represents canonical messages associated with claims.

Minimum responsibilities:

- Belongs to `administrations` and `claims`.
- Stores channel-neutral message content and direction.
- Stores owner-visible filtering state.
- Excludes Chatwoot internal notes from owner-visible projections.
- Uses stable external message references for idempotent webhook processing.

### `claim_channel_links`

Minimal, future-ready mapping between canonical claims and external channel objects.

Minimum responsibilities:

- Belongs to `administrations` and `claims`.
- Stores provider type such as `chatwoot`, `jelou_future`, or `meta_cloud_future`.
- Stores external IDs such as Chatwoot conversation IDs and message/thread references.
- Keeps Chatwoot IDs as external references only; they never become canonical claim IDs.
- Allows future WhatsApp provider migration without changing canonical claim ownership.

### `claim_attachments`

Represents attachments associated with claims and messages.

Minimum responsibilities:

- Belongs to `administrations`, `claims`, and optionally `claim_messages`.
- Stores safe file metadata, storage references, visibility, and source channel.
- Supports owner-visible attachments and PDF visibility in the portal.
- Prevents raw internal Chatwoot-only artifacts from being exposed by default.

### `conversation_sessions`

Represents short-lived channel context, especially for shared WhatsApp numbers and deterministic menu flows.

Minimum responsibilities:

- Belongs to `administrations`.
- Stores provider, external conversation/contact references, normalized channel identifier, and `active_person_context` when known.
- Has a TTL/expiry so stale identity context is not reused indefinitely.
- Requires explicit user selection when a shared phone number maps to multiple possible persons for sensitive actions.

### `webhook_events`

Stores raw inbound webhook envelopes for observability and idempotency.

Minimum responsibilities:

- Belongs to `administrations` when resolvable.
- Stores provider, event type, external event ID, received timestamp, payload hash, processing status, and error summary.
- Enables replay/debugging without introducing Kafka or event-streaming infrastructure.

### `integration_logs`

Stores lightweight integration diagnostics for Octavo Piso, Chatwoot, WhatsApp provider adapters, and future integrations.

Minimum responsibilities:

- Belongs to `administrations`.
- Stores integration name, operation, request/response metadata, result, duration, and error summary.
- Prioritizes operational debugging over advanced analytics.

### `sync_outbox`

Stores retryable synchronization tasks for simple eventual consistency.

Minimum responsibilities:

- Belongs to `administrations`.
- Stores task type, target provider, target external reference, payload, idempotency key, status, retry count, next attempt time, and last error.
- Implements persistence first, synchronization second.
- Replaces Phase 1 needs for Kafka, event buses, BullMQ, or complex orchestration engines.

### `audit_logs`

Stores security- and business-relevant audit events.

Minimum responsibilities:

- Belongs to `administrations`.
- Records actor type, actor ID, action, target table/entity, before/after summaries when appropriate, timestamp, and source channel.
- Tracks sensitive actions, portal access, identity decisions, permission decisions, and AI-assisted recommendations.

## Provider Abstraction

WhatsApp provider support must remain future-ready without adding Phase 1 complexity.

Required provider values:

- `chatwoot` for the MVP path.
- `jelou_future` as a reserved future adapter path.
- `meta_cloud_future` as a reserved direct Meta Cloud API adapter path.

Provider abstraction belongs in channel links, conversation sessions, webhook events, integration logs, and sync outbox tasks. The MVP should not create separate provider-specific canonical claim tables.

## AI Compatibility Without Over-Modeling

The MVP supports AI assist/copilot behavior, not AI autonomy. AI-related data should be captured through existing messages, audit logs, integration logs, and optional metadata fields only when needed.

AI may:

- Summarize conversations.
- Classify claims.
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

AI responses must rely on verified tool outputs and deterministic Supabase data access. Any AI-visible context must respect the same identity, portal visibility, and sensitive-claim rules as human-facing surfaces.

## Implementation Notes

- Use idempotency keys for webhook processing and sync outbox tasks.
- Keep first schema slices small and tied to vertical flows.
- Prefer nullable future-facing fields over new tables until a concrete Phase 1 flow requires them.
- Do not let the portal read Chatwoot directly.
- Do not let Chatwoot conversation status become the canonical owner-visible status without explicit mapping.
- Do not create advanced analytics tables in Phase 1; use logs and audit records first.
