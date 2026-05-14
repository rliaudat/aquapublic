# OCTAVO_PISO_MOCK_STRATEGY.md

## 1. Purpose

The Octavo Piso mock exists to unblock local, development, and staging work while real Octavo Piso Partner API credentials, building permissions, and production-like API access are pending.

The mock must allow the BFF team to continue implementing and validating the integration without treating mocked behavior as authoritative. The real Octavo Piso API remains the source of truth for contract behavior, permissions, data shape, operational constraints, and production responses.

The mock should specifically support:

- BFF development for the Octavo Piso client, synchronization jobs, error handling, and response normalization.
- Identity resolution flows that map Octavo Piso people, contact points, apartments, tenants, owners, and family or spouse relationships into canonical Supabase entities.
- Portal flows that require known unit access, authorized contacts, unknown contact handling, debt visibility, expense history, and receipt retrieval.
- Chatwoot synchronization flows where canonical Supabase contacts and unit relationships are projected into Chatwoot contacts and metadata.
- Expense, payment, account statement, and PDF receipt flows before real API access is available.

The mock is not intended to replace real Octavo Piso validation. It is a development aid that should keep implementation moving while making all fake data, assumptions, and contract gaps explicit.

## 2. Scope

Mock these endpoints first because they are required for identity resolution, portal account views, Chatwoot contact synchronization, expense/payment validation, and guest visibility:

- `GET /buildings/{building_id}/apartments`
- `GET /buildings/{building_id}/apartments_people`
- `GET /buildings/{building_id}/apartments/{apartment_uf}/current_expense_apartment`
- `GET /buildings/{building_id}/apartments/{apartment_uf}/current_expense_apartment_receipt`
- `GET /buildings/{building_id}/apartments/{apartment_uf}/expense_collections`
- `GET /buildings/{building_id}/apartment_incomes_outcomes`
- `GET /buildings/{building_id}/apartments_guests`

The first mock iteration should prioritize read-only behavior and deterministic fixtures. It should support the BFF sync and portal read flows before any write behavior is considered.

Write endpoints are explicitly excluded from the initial mock scope:

- `POST /apartment_transactions`
- `POST /apartments_guests/{id}/notify`

Excluded write endpoints should return a clear mock error if accidentally called in local or staging validation, such as `501 Not Implemented` or a contract-compatible error response documented as intentionally unsupported by the mock.

## 3. Recommended Implementation Approach

Use a simple local mock server inside the repository. Do not implement it yet as part of this strategy document.

Preferred approach:

- Build a small Node.js/TypeScript mock server.
- Use Express or Fastify for routing.
- Store static JSON fixtures under a clearly named mock fixtures directory.
- Keep fixture data deterministic so tests can assert stable identity, pagination, filtering, debt, payment, and relationship behavior.
- Return a fake PDF payload for receipt endpoints with `Content-Type: application/pdf`.
- Keep all mock fixtures clearly fake and safe for source control.
- Make the BFF switch between mock and real Octavo Piso through environment configuration only.

Recommended environment switching:

```env
# Local/dev/staging mock mode
OCTAVO_MODE=mock
OCTAVO_BASE_URL=http://localhost:4001/api/v1/partners

# Real Octavo Piso mode
OCTAVO_MODE=real
OCTAVO_BASE_URL=https://octavo-piso.com/api/v1/partners
```

The BFF Octavo client should select behavior from configuration, not from code branches hardcoded to a specific URL. Mock mode must not require real Octavo Piso credentials. Real mode must require credentials and should fail fast when credentials are missing.

## 4. Mock Dataset

The mock dataset must be fake, deterministic, and intentionally synthetic. It must not include real resident names, real owner names, real tenant names, real emails, real phone numbers, real Rut/DNI/passport values, real apartment account numbers, or real bank/payment identifiers.

Use obviously fake names, domains, and phone values, for example:

- Fake names from a reserved-style naming pattern such as `Mock Owner Alpha`, `Mock Tenant Beta`, and `Mock Family Gamma`.
- Fake emails under domains such as `example.test`, `mock.invalid`, or `octavo-mock.local`.
- Fake phone numbers in a reserved or clearly artificial range, such as `+56900000001`, `+56900000002`, and `+56900000003`.
- Fake external IDs prefixed with `mock_`, such as `mock_person_001` and `mock_apartment_001`.

Minimum required fake dataset:

### Buildings

At least 2 fake buildings:

1. `mock_building_001`
   - Display name: `Mock Tower Norte`
   - Expected to contain the primary happy-path data.
2. `mock_building_002`
   - Display name: `Mock Tower Sur`
   - Expected to contain cross-building and failure-case data.

### Apartments

At least 5 fake apartments across the two buildings:

1. `101-A` in `mock_building_001`
   - Has current debt.
   - Has current expense data.
   - Has a fake receipt PDF.
   - Has payment history.
2. `102-A` in `mock_building_001`
   - Has no current debt.
   - Has current expense data with a zero or paid balance.
3. `201-B` in `mock_building_001`
   - Has multiple contacts linked to the same apartment.
   - Includes owner, spouse/family member, and tenant-style relationships.
4. `301-C` in `mock_building_001`
   - Has guests.
   - Exercises `apartments_guests` behavior.
5. `401-D` in `mock_building_002`
   - Shares one contact with another apartment to test one contact linked to multiple apartments.
   - Can be used to test cross-building identity boundaries.

### People and Contact Scenarios

The dataset must include:

- One apartment with debt, for example `101-A`.
- One apartment without debt, for example `102-A`.
- One apartment with multiple contacts, for example `201-B`.
- One contact linked to multiple apartments, for example `Mock Owner Shared` linked to `201-B` and `401-D`.
- One tenant, for example `Mock Tenant Beta` linked to `201-B` with a tenant/renter relationship.
- One spouse or family member, for example `Mock Family Gamma` linked to `201-B` with a spouse/family/occupant relationship.
- One unknown phone or email scenario, represented by inbound test identifiers that do not exist in any `apartments_people` fixture and should resolve to an observed/unresolved contact in BFF tests.
- One apartment with guests, for example `301-C`.
- One apartment with payment history, for example `101-A`.

Example fake identities:

| Mock person | Purpose | Fake email | Fake phone | Relationship intent |
| --- | --- | --- | --- | --- |
| `Mock Owner Alpha` | Happy-path owner with debt | `owner.alpha@example.test` | `+56900000001` | Owner of `101-A` |
| `Mock Owner Clear` | Owner without debt | `owner.clear@example.test` | `+56900000002` | Owner of `102-A` |
| `Mock Owner Shared` | Same contact across apartments | `owner.shared@example.test` | `+56900000003` | Owner of `201-B` and `401-D` |
| `Mock Tenant Beta` | Tenant access scenario | `tenant.beta@example.test` | `+56900000004` | Tenant of `201-B` |
| `Mock Family Gamma` | Spouse/family scenario | `family.gamma@example.test` | `+56900000005` | Family or spouse contact for `201-B` |
| `Mock Inactive Delta` | Deleted/inactive person behavior | `inactive.delta@example.test` | `+56900000006` | Inactive historical contact |
| Unknown contact | Unknown identity scenario | `unknown.person@example.test` | `+56900000999` | Not present in Octavo fixtures |

The actual mock fixtures must use the field names, nesting, enum-like values, pagination envelope, and error shapes from `api-1.json` wherever the OpenAPI contract defines them. If `api-1.json` does not define a field or behavior needed by tests, the fixture must mark that behavior as an assumption.

## 5. Mock Response Behavior

The mock server must emulate the Octavo Piso Partner API contract from `api-1.json` as closely as possible while remaining explicitly non-authoritative.

### Pagination

- List endpoints must support pagination.
- Default page size should be 20 records per page.
- If the OpenAPI contract defines explicit pagination parameter names or response metadata, the mock must use those names and shapes.
- Pagination tests should include both a single-page response and a multi-page response once fixtures exceed 20 records.

### Filtering

The mock should support the filters needed by the BFF sync and portal flows:

- `apartment_uf` filtering where the contract exposes or implies apartment/unit filtering.
- `active_only` filtering for people, guests, relationships, or other records that can be active/inactive.
- `updated_after` filtering for incremental synchronization flows.

Filtering rules must be deterministic. If a query parameter is not recognized by the OpenAPI contract, the mock should either ignore it only when explicitly documented as an assumption or return a contract-compatible validation error.

### Deleted or Inactive Person Behavior

The mock must include at least one deleted or inactive person-like record.

Expected behavior:

- With `active_only=true`, inactive/deleted people should be excluded when the contract supports that behavior.
- With `active_only=false` or omitted, behavior should follow `api-1.json`; if the contract is ambiguous, document the assumption in the fixture notes.
- Inactive/deleted contacts must not be treated by the BFF as automatically authorized for portal login.
- Inactive/deleted records should still be useful for testing sync tombstones, stale relationship cleanup, or audit-preserving deactivation behavior.

### Current Expense and Debt Behavior

The current expense endpoint must include:

- A successful debt case for `101-A`.
- A successful no-debt or fully-paid case for `102-A`.
- A missing apartment case returning `404`.
- A malformed apartment identifier case returning `422` when contract-compatible.

The mock should include realistic but fake amount fields, due dates, period labels, payment status, and balance values only if those fields exist in or are safely derived from the OpenAPI contract.

### Receipt PDF Behavior

The receipt endpoint must:

- Return `Content-Type: application/pdf` for successful receipt retrieval.
- Return a fake PDF body, not a real resident receipt.
- Include an obviously fake document marker inside the generated/static PDF, such as `MOCK OCTAVO PISO RECEIPT - NOT VALID FOR PAYMENT`.
- Return `404` when the building/apartment/receipt context does not exist or when no receipt is available.
- Avoid validating production PDF layout, production receipt rendering, or real Octavo Piso document semantics.

### Expense Collections Behavior

The expense collections endpoint must include:

- At least one apartment with payment history, such as `101-A`.
- At least one apartment with no payment history or an empty collection list.
- Multiple historical periods for the payment-history apartment.
- Contract-compatible fields for payment date, amount, status, document/receipt reference, and period when those fields are defined by `api-1.json`.

### Account Statement / Incomes-Outcomes Behavior

`GET /buildings/{building_id}/apartment_incomes_outcomes` must support a variable response shape if the OpenAPI contract permits or documents variability.

Mock behavior should include:

- A standard successful account statement response.
- A response with optional or nullable fields omitted where the contract allows it.
- A response with empty movements for an apartment/building period.
- A contract-compatible error for invalid filters or invalid building IDs.

Tests must not rely on undocumented variable shape behavior unless the test name and fixture note explicitly mark it as an assumption.

### Guests Behavior

`GET /buildings/{building_id}/apartments_guests` must include:

- One apartment with guests, such as `301-C`.
- One apartment without guests.
- Active and inactive/expired guest records when supported by the contract.
- Filtering by apartment and active status when supported by the contract.

### Failure Cases

The mock must include success responses and failure cases. Initial failure behavior should cover:

- `404 Not Found` for unknown building IDs.
- `404 Not Found` for unknown apartment UFs where the endpoint addresses a single apartment.
- `422 Unprocessable Entity` or the contract-defined validation response for malformed IDs, invalid date filters, invalid enum-like values, or invalid pagination parameters.
- `401 Unauthorized` or `403 Forbidden` only when testing real-mode auth behavior is useful; mock mode should not require real credentials.
- `501 Not Implemented` or a documented contract-compatible error for excluded write endpoints.

Timeout simulation may be added later if needed. It should be opt-in through an explicit query parameter, header, fixture mode, or environment flag so normal local tests remain fast and deterministic.

## 6. Contract Safety

The mock must be contract-safe and assumption-aware.

Rules:

- Mock responses must be derived from `api-1.json` wherever the OpenAPI contract defines endpoint paths, methods, parameters, response envelopes, status codes, field names, field types, and content types.
- Any behavior not directly specified by `api-1.json` must be documented as an assumption in fixture notes or mock server documentation.
- Any difference discovered during real Octavo Piso API validation must update the mock fixtures, this strategy, and any downstream validation/test documentation that depended on the previous behavior.
- Tests must not rely on undocumented mock behavior unless the test is explicitly marked as assumption-based.
- The mock must not silently invent production semantics for permissions, debt calculations, receipt availability, rate limits, or identity authorization.
- The BFF should keep raw mock payload snapshots separate from normalized canonical Supabase projections so contract drift is easy to inspect.
- Contract mismatches found against the real API should be treated as validation findings, not as reasons to force the real API to match the mock.

## 7. BFF Configuration Rules

The BFF must be able to switch between mock and real Octavo Piso using configuration.

Configuration rules:

- Never hardcode Octavo Piso URLs in request code.
- Never hardcode Octavo Piso credentials in source code, fixtures, tests, or documentation examples intended for commit.
- Use `OCTAVO_MODE=mock | real` to select mock or real behavior.
- Use `OCTAVO_BASE_URL` to point to either the local mock server or the real Octavo Piso Partner API base URL.
- Mock mode must not require real Octavo Piso credentials.
- Real mode must require credentials and fail fast if they are missing.
- Production must not run against mock mode.
- Production startup should fail if `OCTAVO_MODE=mock` or if the configured `OCTAVO_BASE_URL` points to localhost, a private mock host, or a staging-only mock URL.
- Logs must clearly show whether the BFF is using mock or real Octavo Piso mode.
- Logs must not print credentials, tokens, secrets, or sensitive header values.
- Staging logs should include enough context to debug contract mismatches, such as mode, endpoint, status code, request correlation ID, and fixture scenario name when applicable.

Recommended mode examples:

```env
# Local mock
OCTAVO_MODE=mock
OCTAVO_BASE_URL=http://localhost:4001/api/v1/partners

# Real integration
OCTAVO_MODE=real
OCTAVO_BASE_URL=https://octavo-piso.com/api/v1/partners
OCTAVO_API_TOKEN=required-in-real-mode
```

## 8. Development Sequence

Recommended sequence:

1. Create mock fixtures derived from `api-1.json`.
2. Create the mock server with read-only endpoint coverage.
3. Point the BFF Octavo client to the mock using `OCTAVO_MODE=mock` and `OCTAVO_BASE_URL=http://localhost:4001/api/v1/partners`.
4. Implement sync from mock responses to Supabase canonical entities.
5. Implement identity resolution against mock data, including known owners, tenants, family/spouse contacts, multiple contacts per apartment, one contact across multiple apartments, inactive contacts, and unknown contact observations.
6. Implement expense and PDF tools against mock data, including debt, no-debt, payment history, and fake receipt PDF behavior.
7. Swap to the real API after credentials and building permissions are fixed.
8. Compare mock and real payloads, then update fixtures, docs, and tests for any validated contract differences.

## 9. Explicit Non-Goals

The mock has strict boundaries.

Non-goals:

- The mock is not the source of truth.
- The mock does not validate real Octavo Piso permissions.
- The mock does not validate real Octavo Piso authentication behavior beyond basic BFF configuration branching.
- The mock does not validate real Octavo Piso rate limits.
- The mock does not validate production PDF behavior, PDF layout, receipt legal validity, or payment-document semantics.
- The mock does not replace Octavo Piso validation.
- The mock does not authorize production portal access.
- The mock does not prove that a real building has the same apartments, contacts, guests, debts, payments, or receipts as the fake dataset.
- The mock does not define canonical Supabase schema behavior; it only supplies upstream-like payloads for BFF normalization.
- The mock does not decide Chatwoot operational workflow; it only supports the upstream data needed to sync canonical contacts and metadata.

## 10. Recommended Next Step

Recommended next step:
"Create OCTAVO_PISO_MOCK_SERVER_PLAN.md only."
