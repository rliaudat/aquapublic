# Database Model

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
