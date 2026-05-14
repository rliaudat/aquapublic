# Domain Flows

This document defines the canonical operational flows for the owner portal, Chatwoot synchronization, identity resolution, cross-channel claims/tickets, and incoming/outgoing communications.

The flows prioritize simplicity, deterministic behavior, low operational ambiguity, maintainability, and AI-assisted implementation friendliness. The architecture intentionally avoids event-driven complexity and distributed workflow orchestration unless a later operational requirement clearly justifies it.

## Architectural Rules

- Canonical claim/ticket state lives in Supabase.
- Chatwoot is operational workflow only.
- The portal reads canonical projections only.
- Identity resolution belongs to the BFF/Supabase layer.
- Synchronization must remain deterministic and auditable.
- Avoid direct portal dependency on Chatwoot internals.
- Supabase is the canonical operational layer for normalized persons, contact points, units, relationships, claims, messages, and channel links.
- External system IDs, including Chatwoot contact IDs and conversation IDs, are stored as external references and never become canonical identifiers.

## Simplicity Constraints

- Avoid premature async orchestration.
- Avoid microservices.
- Avoid CQRS/event sourcing complexity.
- Prefer synchronous pragmatic flows initially.
- Optimize for maintainability and AI-assisted implementation.
- Prefer explicit, auditable BFF procedures over implicit side effects.
- Prefer deterministic retries and idempotency keys over distributed workflow engines.

## 1. Octavo Piso Initial Synchronization Flow

### Flow

Octavo Piso → BFF sync process → Supabase canonical entities

1. The BFF runs an explicit Octavo Piso synchronization process.
2. The BFF reads source records from Octavo Piso for:
   - persons
   - contact_points
   - apartments/units
   - person-unit relationships
3. The BFF normalizes each source record into the canonical Supabase shape.
4. The BFF upserts Supabase canonical entities using stable source identifiers and deterministic matching rules.
5. Supabase becomes the canonical operational layer after the sync completes.
6. Chatwoot is synchronized afterward from Supabase, not directly from Octavo Piso.

### Canonical Entities

- `persons` represent humans or organizations that can own, rent, occupy, report, or receive communications.
- `contact_points` represent email addresses, phone numbers, and WhatsApp-capable phone numbers associated with persons.
- `apartments` or `units` represent the physical units used for access control, claims, and ownership/tenant context.
- `person_unit_relationships` represent owner, tenant, occupant, manager, or other access-relevant relationships between persons and units.

### Rules

- Octavo Piso is an upstream source for initial and recurring data import, but Supabase is the operational source of truth after synchronization.
- The synchronization process must be idempotent, deterministic, and auditable.
- Chatwoot synchronization must run from Supabase canonical entities after the Supabase sync is complete.
- The portal must never read Octavo Piso directly for operational claim, ticket, or identity decisions.

## 2. Chatwoot Contact Projection Flow

### Flow

Supabase canonical contacts → Chatwoot contact synchronization

1. The BFF selects canonical persons and verified or operationally approved contact points from Supabase.
2. The BFF creates or updates Chatwoot contacts as operational projections of those canonical records.
3. The BFF stores Chatwoot contact IDs as external references linked to the canonical person/contact context.
4. The BFF updates Chatwoot with display names, email addresses, phone numbers, and relevant metadata derived from Supabase.
5. Chatwoot is used by operators for communication workflow, not as the canonical contact database.

### Rules

- Sync direction is primarily Supabase → Chatwoot.
- Chatwoot contacts are operational projections.
- Chatwoot contact IDs are external references only.
- Supabase canonical contact data wins when Chatwoot and Supabase differ.
- Any Chatwoot-originated contact observation must be normalized into observed contact handling before becoming canonical.

## 3. Incoming Email Flow

### Flow

Incoming email → Chatwoot inbox → Chatwoot webhook → BFF normalization → identity resolution → canonical claim update/create → canonical `claim_messages` creation → portal visibility update

1. An email arrives in the configured Chatwoot email inbox.
2. Chatwoot creates or updates an operational conversation and emits a webhook.
3. The BFF receives the webhook and normalizes the payload into a channel-neutral message shape.
4. The BFF extracts sender email, recipient email, subject, body, attachments, Chatwoot conversation ID, and Chatwoot message ID.
5. The BFF matches the sender email against existing canonical `contact_points`.
6. If a matching verified or authorized contact point exists, the BFF resolves the person and any related unit context.
7. If the email is unknown, the BFF creates an `observed_contacts` record and marks the identity as unresolved or pending review.
8. The BFF links the message to an existing canonical claim when deterministic linking is possible.
9. If no existing claim can be deterministically linked, the BFF creates a new canonical claim.
10. The BFF creates a canonical `claim_messages` record for the email.
11. The BFF updates the owner-visible claim projection when visibility rules allow it.

### Claim Linking Logic

- Multiple emails may belong to the same claim.
- Existing claim linking should prefer explicit channel links, known Chatwoot conversation references, normalized subject/thread references, and deterministic unit/person context.
- If linking is ambiguous, create or route to a reviewable canonical state rather than guessing.
- Unknown emails may create claims, but those claims should remain visibility-restricted until identity and access are resolved.

### Rules

- Email identity matching starts with canonical `contact_points`.
- Unknown emails are recorded as `observed_contacts` and do not automatically become verified contact points.
- Chatwoot conversation IDs are operational references stored through channel-link records.
- Portal visibility is derived from canonical claim state and access rules, never raw Chatwoot state.

## 4. Incoming WhatsApp Flow

### Flow

WhatsApp → Chatwoot → webhook → BFF normalization → identity resolution → canonical claim update/create

1. A WhatsApp message arrives in Chatwoot through the configured WhatsApp inbox/provider.
2. Chatwoot creates or updates an operational conversation and emits a webhook.
3. The BFF receives the webhook and normalizes the payload into a channel-neutral message shape.
4. The BFF extracts the sender phone/WhatsApp number, message body, attachments, Chatwoot conversation ID, and Chatwoot message ID.
5. The BFF normalizes the phone number to a deterministic format before matching.
6. The BFF matches the normalized number against canonical phone or WhatsApp `contact_points`.
7. If a known owner or tenant contact point matches, the BFF resolves person and unit context from canonical relationships.
8. If the number is unknown, the BFF creates an `observed_contacts` record and treats the identity as unresolved or pending review.
9. The BFF links the message to an existing canonical claim when deterministic linking is possible.
10. If no deterministic claim link exists, the BFF creates a new canonical claim.
11. The BFF creates a canonical `claim_messages` record and updates canonical claim state as needed.

### Rules

- Phone matching must use normalized phone numbers.
- WhatsApp matching should treat WhatsApp-capable phone contact points as preferred, then fall back to canonical phone contact points when appropriate.
- Owner and tenant matching is resolved through canonical person-unit relationships.
- Unknown numbers are recorded as observed contacts and do not automatically become verified or authorized contact points.
- Portal visibility is granted only after canonical access rules allow it.

## 5. Portal Login Flow

### Flow

Portal user enters email or WhatsApp/phone → BFF validates against canonical `contact_points` → OTP/magic link delivery → session creation → portal access granted

1. The portal user enters an email address or WhatsApp/phone number.
2. The portal sends the login request to the BFF.
3. The BFF normalizes the submitted identifier.
4. The BFF validates the identifier against canonical `contact_points`.
5. The BFF confirms that the contact point is verified and authorized for portal access.
6. The BFF sends an OTP or magic link through the appropriate delivery channel.
7. The user completes verification.
8. The BFF creates a portal session tied to the canonical person and allowed unit context.
9. The portal grants access only to canonical projections permitted for that person.

### Rules

- Chatwoot authentication is not used.
- Only verified and authorized contact points may authenticate.
- Observed contacts cannot authenticate until promoted through an explicit verification/authorization process.
- Portal sessions are based on canonical identity, not Chatwoot contacts.

## 6. Portal Ticket Creation Flow

### Flow

Portal → BFF → canonical claim creation → canonical `claim_messages` creation → Chatwoot conversation creation → `claim_channel_link` creation

1. A portal user submits a new ticket/claim from an authorized unit context.
2. The portal sends the request to the BFF.
3. The BFF validates the user's session, person, contact point, and unit access from canonical data.
4. The BFF creates the canonical claim in Supabase.
5. The BFF creates the initial canonical `claim_messages` record in Supabase.
6. The BFF creates a Chatwoot conversation for operational handling.
7. The BFF creates a `claim_channel_link` connecting the canonical claim to the Chatwoot conversation.
8. The portal displays the claim using canonical projections.

### Rules

- The claim is canonical.
- The Chatwoot conversation is operational.
- Failure to create the Chatwoot conversation should leave an auditable canonical claim state that can be retried deterministically.
- The portal should not depend on Chatwoot conversation shape, status names, or message internals.

## 7. Operator Response Flow

### Flow

Operator replies in Chatwoot → webhook → BFF normalization → canonical `claim_messages` update → owner-visible projection update

1. An operator replies to a Chatwoot conversation.
2. Chatwoot emits a webhook for the new message or updated conversation.
3. The BFF normalizes the Chatwoot payload into the canonical message shape.
4. The BFF resolves the `claim_channel_link` for the Chatwoot conversation.
5. The BFF creates or updates the corresponding canonical `claim_messages` record.
6. The BFF applies owner-visible filtering rules.
7. The BFF updates the owner-visible projection when the message is visible.

### Rules

- Internal notes remain internal.
- Owner-visible filtering rules apply to every operator-originated message.
- Chatwoot-only internal metadata is not exposed to the portal.
- Message synchronization must be idempotent using stable external message references.

## 8. Claim Visibility Flow

### Visibility Rules

- Owner visibility is derived from canonical person-unit relationships and claim-unit associations.
- A person can view a claim when canonical access rules connect that person to the claim's unit or an explicitly permitted claim participant role.
- Unit-based access is the primary access model for owner portal visibility.
- Tenant access may be narrower than owner access and should be represented explicitly through canonical relationship roles.
- Multiple contacts per unit may have access when their canonical person-unit relationship authorizes it.
- Future family-member access should be modeled as explicit canonical relationships or delegated access records, not by sharing Chatwoot contacts.

### Rules

- The portal never exposes raw Chatwoot data.
- The portal reads canonical claim and message projections only.
- Visibility decisions must be deterministic, auditable, and explainable from Supabase records.
- Unknown or unresolved identities should not gain portal visibility until access is verified.

## 9. Identity Resolution Flow

### Matching Strategy

1. Normalize the inbound identifier by channel.
2. Match email addresses against canonical email `contact_points`.
3. Match phone numbers against canonical phone `contact_points` using deterministic phone normalization.
4. Match WhatsApp numbers against WhatsApp-capable phone contact points first, then appropriate phone contact points.
5. Resolve owner, tenant, occupant, or other roles through canonical person-unit relationships.
6. When no deterministic match exists, create an `observed_contacts` record.
7. Link observed contacts to claims, channel records, and raw external references for later review.
8. Merge identities later through explicit audited operations when evidence supports it.

### Rules

- The same person may use multiple channels.
- Claims aggregate interactions across channels.
- Multi-channel linking happens through canonical person, contact point, observed contact, and claim-channel link records.
- Observed contacts are evidence, not authorization.
- Merging identities must preserve auditability and external references.
- Ambiguous matches should remain unresolved or reviewable rather than being guessed.

## 10. Future Voice/VAPI Flow (High-Level Only)

### High-Level Flow

Voice/VAPI call → voice transcription → BFF normalization → identity matching → claim linking → future AI summaries

1. A future voice provider captures a call and produces call metadata and transcription.
2. The BFF normalizes the voice interaction into the same channel-neutral communication model used for email and WhatsApp.
3. The BFF attempts identity matching from caller phone number and available call metadata.
4. The BFF links the interaction to an existing canonical claim when deterministic linking is possible.
5. If no deterministic link exists, the BFF creates or routes to a canonical claim state appropriate for review.
6. Future AI summaries may assist operators and owners after canonical visibility and review rules are defined.

### Rules

- Do not design implementation details yet.
- Voice/VAPI must follow the same canonical ownership rules as other channels.
- Transcripts and summaries are operational inputs until persisted as canonical visible messages or projections.
- AI summaries must not bypass identity, claim-linking, or visibility rules.

Recommended next step:
"Update API_SURFACE.md for canonical sync and portal APIs."
