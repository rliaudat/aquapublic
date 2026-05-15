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
