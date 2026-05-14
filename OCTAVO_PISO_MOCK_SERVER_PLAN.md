# Octavo Piso Mock Server Implementation Plan

## Purpose

This plan defines a simple local mock server for the Octavo Piso Partner API so the team can continue BFF, portal, identity resolution, receipt, debt, and Chatwoot synchronization development while real Octavo Piso credentials and building permissions are pending.

The mock server is a development aid only. It is not production infrastructure, not an authorization authority, and not a replacement for validation against the real Octavo Piso API. The implementation should remain deterministic, small, easy to inspect, easy for AI-assisted coding tools to modify, and easy to remove or replace once real API access is available.

Inputs used for this plan:

- `OCTAVO_PISO_MOCK_STRATEGY.md`
- `DOMAIN_FLOWS.md`
- Expected Octavo Piso API contract concepts referenced by the project documents, including `api-1.json`, `API_SURFACE.md`, `DATABASE_MODEL.md`, and `PROJECT_CONTEXT.md`

> Note: endpoint names, response fields, query parameters, and response envelopes must be finalized from the actual OpenAPI contract before implementation. Where the contract is ambiguous or unavailable during implementation, record the behavior as an explicit mock assumption in fixture notes.

## 1. Recommended Technology Stack

Use the smallest practical Node.js stack:

- **Runtime:** Node.js.
- **Language:** TypeScript.
- **HTTP framework:** Express or Fastify.
  - Express is acceptable if the team wants maximum familiarity and minimal structure.
  - Fastify is acceptable if the team wants built-in schema validation and better request logging.
- **Data source:** Static JSON fixtures committed to the repository.
- **Receipt source:** Local PDF fixture files committed under a mock-only sample PDF directory.
- **Configuration:** Environment variables only.
- **Testing:** Lightweight endpoint tests that assert deterministic fixture behavior and status codes.

Initial implementation should require **no database**. Filesystem fixtures are preferred because they are easy to review in pull requests, easy for AI tools to edit safely, and simple to replace after real Octavo Piso payloads are validated.

The mock should not attempt to implement production-grade persistence, authentication, permissions, rate limiting, background jobs, or administrative tooling. It should only return deterministic upstream-like payloads for the BFF Octavo client.

## 2. Recommended Repository Structure

Proposed structure:

```text
mock-octavo-piso/
  README.md
  package.json
  tsconfig.json
  .env.example
  src/
    server.ts
    app.ts
    config/
      env.ts
      routes.ts
    middleware/
      requestLogger.ts
      errorHandler.ts
      mockScenario.ts
    routes/
      apartments.ts
      apartmentsPeople.ts
      currentExpenseApartment.ts
      currentExpenseApartmentReceipt.ts
      expenseCollections.ts
      apartmentIncomesOutcomes.ts
      apartmentsGuests.ts
      unsupportedWrites.ts
    fixtures/
      README.md
      buildings.json
      apartments.json
      apartments_people.json
      current_expense_apartment.json
      expense_collections.json
      apartment_incomes_outcomes.json
      apartments_guests.json
      errors.json
      fixture_notes.md
    sample_pdfs/
      mock_receipt_101_a.pdf
      mock_receipt_empty.pdf
```

Implementation guidelines for this structure:

- `src/server.ts` should only start the local process.
- `src/app.ts` should compose middleware and route modules so endpoint tests can import the app without opening a port.
- `src/config/env.ts` should centralize port, base path, and optional scenario flags.
- `src/routes/` should contain one small route module per endpoint family.
- `src/fixtures/` should contain static, fake, deterministic JSON only.
- `src/fixtures/fixture_notes.md` should document every assumption not proven by the real OpenAPI contract.
- `src/sample_pdfs/` should contain obviously fake PDFs with a visible marker such as `MOCK OCTAVO PISO RECEIPT - NOT VALID FOR PAYMENT`.
- `README.md` should explain how to run the mock, which endpoints are supported, which fixtures drive each endpoint, and how to switch the BFF between mock and real modes.

This is a proposed structure only. Do not create implementation code until the team approves this plan.

## 3. Environment Configuration

The BFF and mock integration should use the following variables:

```env
OCTAVO_MODE=mock|real
OCTAVO_BASE_URL=http://localhost:4001/api/v1/partners
OCTAVO_USERNAME=
OCTAVO_PASSWORD=
```

Required behavior:

- `OCTAVO_MODE=mock`
  - Points the BFF to the local mock URL.
  - Must not require `OCTAVO_USERNAME` or `OCTAVO_PASSWORD`.
  - Must not require real Octavo Piso credentials, tokens, cookies, or permissions.
  - Should log clearly that the BFF is using mock Octavo Piso mode.
- `OCTAVO_MODE=real`
  - Points the BFF to the real Octavo Piso Partner API URL.
  - Must fail fast at startup when `OCTAVO_USERNAME` or `OCTAVO_PASSWORD` is missing, if those are the required credentials for the real integration.
  - Must not silently fall back to mock behavior.
  - Must not run with localhost, private mock hosts, or mock fixture URLs in production.
- `OCTAVO_BASE_URL`
  - Must be the only source of the upstream base URL.
  - Should include the expected base path, for example `http://localhost:4001/api/v1/partners` for local development.
- `OCTAVO_USERNAME` and `OCTAVO_PASSWORD`
  - Required only in real mode.
  - Must never be committed in source code, fixtures, tests, or docs.

The mock server itself may also use local-only variables such as `PORT=4001` or `MOCK_SCENARIO=default`, but these should not leak into BFF business logic.

## 4. Initial Mock Endpoints

Implement read-only endpoints first in this order:

1. `GET /buildings/{building_id}/apartments`
   - Foundation for unit synchronization and unit-level portal access.
   - Should return fake apartments for known fake buildings.
2. `GET /buildings/{building_id}/apartments_people`
   - Foundation for identity resolution, owner/tenant relationships, contact points, and Chatwoot contact projection.
   - Should include active and inactive people and relationship scenarios.
3. `GET /buildings/{building_id}/apartments/{apartment_uf}/current_expense_apartment`
   - Supports current debt and no-debt portal account views.
   - Should return deterministic debt status for known apartments.
4. `GET /buildings/{building_id}/apartments/{apartment_uf}/current_expense_apartment_receipt`
   - Supports receipt retrieval and PDF handling.
   - Should return a local fake PDF for supported apartment contexts.
5. `GET /buildings/{building_id}/apartments/{apartment_uf}/expense_collections`
   - Supports payment history and expense collection views.
   - Should include both non-empty and empty history cases.
6. `GET /buildings/{building_id}/apartment_incomes_outcomes`
   - Supports account statement style reads and variable-shape response validation where contract-compatible.
   - Should include standard, empty, and optional-field scenarios.
7. `GET /buildings/{building_id}/apartments_guests`
   - Supports guest visibility and active/inactive guest tests.
   - Should include at least one apartment with guests and one without guests.

Prioritize read-only flows before write behavior. Excluded write endpoints, such as apartment transaction creation or guest notification, should not be implemented initially. If they are accidentally called, return `501 Not Implemented` or a contract-compatible mock error that clearly states the endpoint is intentionally unsupported by the local mock.

## 5. Fixture Design

Fixtures must be fake, deterministic, safe for source control, and built to exercise identity resolution and portal-read behavior.

Required fixture categories:

- **Fake buildings**
  - `mock_building_001` / `Mock Tower Norte` for primary happy-path data.
  - `mock_building_002` / `Mock Tower Sur` for cross-building and edge-case data.
- **Fake apartments**
  - `101-A`: current debt, current expense data, fake receipt PDF, and payment history.
  - `102-A`: no current debt or fully paid balance.
  - `201-B`: multiple contacts on one unit, including owner, spouse/family, and tenant-style relationships.
  - `301-C`: guest records.
  - `401-D`: cross-building or multi-apartment identity scenario.
- **Fake contacts**
  - Use names such as `Mock Owner Alpha`, `Mock Tenant Beta`, and `Mock Spouse Gamma`.
  - Use emails under fake domains such as `example.test`, `mock.invalid`, or `octavo-mock.local`.
  - Use artificial phone values such as `+56900000001` through `+56900000099`.
  - Use external IDs prefixed with `mock_`, such as `mock_person_001`.
- **Fake debts**
  - Include deterministic current balance, due date, period, status, and apartment references when fields exist in the real contract.
  - Include one debt-positive case and one no-debt/paid case.
- **Fake payment history**
  - Include multiple historical periods for `101-A`.
  - Include an empty collection list for at least one apartment.
  - Include deterministic payment dates, amounts, statuses, receipt/document references, and periods when contract-compatible.
- **Fake receipts**
  - Include at least one local PDF fixture for `101-A`.
  - Include at least one missing-receipt case returning `404`.
  - PDF content must be visibly fake and not valid for payment.
- **Fake guest entries**
  - Include active and inactive/expired guests when supported by the contract.
  - Include guests linked to `301-C`.
  - Include an apartment with no guests.

Fixture relationships must support identity resolution testing. Every person, contact point, apartment, building, relationship, debt, payment, receipt, and guest should have stable identifiers so the BFF can deterministically map source records into canonical Supabase entities and later into Chatwoot metadata.

Recommended fixture relationship rules:

- Do not use random IDs, random dates, or generated timestamps in committed fixtures.
- Use fixed `updated_at` values to test incremental synchronization.
- Keep building IDs and apartment UFs stable across all fixture files.
- Store contact points in a way that allows matching by normalized email and normalized phone.
- Keep inactive/deleted records present in fixtures so sync cleanup and portal-auth denial paths can be tested.

## 6. Identity Resolution Test Cases

The fixture dataset should explicitly support these identity resolution scenarios:

1. **Owner with multiple emails**
   - One owner has two email contact points.
   - Expected result: both emails map to the same canonical person; only verified/authorized emails can authenticate.
2. **Tenant with WhatsApp only**
   - One tenant has no email but has a WhatsApp-capable phone number.
   - Expected result: WhatsApp matching resolves the tenant through normalized phone matching.
3. **Spouse sharing apartment**
   - A spouse/family member shares `201-B` with an owner.
   - Expected result: the spouse resolves to a distinct person with an explicit relationship to the same unit, not as a duplicate owner.
4. **Same phone reused**
   - One phone number appears in more than one source context.
   - Expected result: the BFF detects ambiguity and avoids unsafe automatic authorization unless the canonical relationship is deterministic.
5. **Unknown inbound email**
   - An email not present in Octavo-derived contact points sends a message.
   - Expected result: create an observed contact or unresolved inbound identity, not a verified contact point.
6. **Unknown WhatsApp number**
   - A WhatsApp number not present in contact points sends a message.
   - Expected result: create an observed contact and deny portal access until explicitly verified.
7. **Inactive resident**
   - An inactive or deleted resident remains in fixture data.
   - Expected result: sync can preserve or deactivate canonical records, but portal authentication and authorization are denied.
8. **Multiple apartments per person**
   - One person is linked to more than one apartment, including a cross-building case if needed.
   - Expected result: the BFF creates one canonical person with multiple person-unit relationships and exposes only authorized unit contexts.

Each test case should be documented in fixture notes with the exact source IDs, apartments, contact values, and expected canonical outcome.

## 7. Error Simulation

Initial deterministic error behavior should include:

- **404 Not Found**
  - Unknown building ID.
  - Unknown apartment UF for single-apartment endpoints.
  - Missing receipt for a valid apartment without receipt data.
- **401 Unauthorized**
  - Optional mock scenario for testing BFF real-mode auth handling.
  - Mock mode should not require credentials by default.
- **422 Unprocessable Entity**
  - Malformed building IDs.
  - Malformed apartment UFs.
  - Invalid date filters.
  - Invalid pagination/filter parameters where the real contract supports validation errors.
- **Empty datasets**
  - Known building with zero matching records for filters.
  - Known apartment with no payment history.
  - Known apartment with no guests.
- **Inactive apartments**
  - Apartment returned or excluded according to contract-compatible `active_only` behavior.
  - Portal access must not be granted solely because an inactive apartment appears in raw source data.
- **Malformed data**
  - Opt-in scenario only, used to test BFF defensive normalization.
  - Must not be part of the default happy-path fixture responses.
- **Timeout simulation later**
  - Add only after the default endpoints are stable.
  - Must be opt-in through an explicit query parameter, header, environment flag, or named scenario.
  - Must not make normal local tests slow or flaky.

Error responses should match the real OpenAPI contract where defined. If the contract does not define an error shape, use one documented mock error envelope and label it as an assumption.

## 8. BFF Integration Rules

The BFF must not know whether the upstream API is mock or real beyond configuration.

Rules:

- The same Octavo client contract should work for both mock and real APIs.
- Business services must not contain mock-specific branches, fake IDs, fixture names, or scenario checks.
- Mock-vs-real selection must happen through `OCTAVO_MODE` and `OCTAVO_BASE_URL` only.
- The BFF should normalize Octavo responses into canonical Supabase models the same way in mock and real modes.
- Identity resolution should operate against canonical records created from Octavo responses, not directly against mock fixture internals.
- Portal services should read canonical projections only and should not consume raw Octavo payloads directly.
- Chatwoot synchronization should use canonical persons, contact points, unit relationships, and external references, not mock-specific payload assumptions.
- Logs may include mode, endpoint, status code, request correlation ID, and mock scenario name when applicable.
- Logs must never print credentials, passwords, tokens, secret headers, or sensitive production contact data.

If a real payload differs from the mock, update the Octavo client normalization and fixtures rather than adding mock-only conditions to business services.

## 9. Transition to Real API

When real Octavo Piso credentials and permissions become available:

1. Point a non-production BFF environment to the real Octavo Piso base URL with `OCTAVO_MODE=real`.
2. Capture representative real responses for the supported endpoints, respecting privacy and secret-handling rules.
3. Compare real payloads to mock payloads for:
   - path structure
   - query parameters
   - response envelope
   - field names
   - field types
   - nullability
   - pagination
   - filtering
   - error response shapes
   - PDF content type and receipt behavior
4. Validate assumptions documented in fixture notes.
5. Update fixtures to reflect confirmed real behavior while keeping fake data.
6. Update endpoint tests that relied on incorrect assumptions.
7. Maintain a small compatibility layer in the Octavo client if the real API requires normalization that differs from the ideal canonical shape.
8. Remove or deprecate mock-only assumptions once the real contract is confirmed.

The goal is not to force the real API to match the mock. The goal is to use the mock to unblock development, then adjust it to mirror the real API as closely as needed for safe local development.

## 10. Explicit Simplicity Constraints

The initial mock server must follow these constraints:

- No database.
- No Docker initially.
- No Kubernetes.
- No event bus.
- No async orchestration.
- No auth system inside the mock.
- No admin UI.
- No production deployment requirement.
- No background synchronization jobs inside the mock.
- No writes or persistent mutations initially.
- No generated random fixture data at runtime.
- No dependency on real Octavo Piso credentials.
- No dependency on Chatwoot, Supabase, or portal services to start the mock.

The mock should be a small local HTTP server backed by static JSON and local PDF fixtures.

## 11. Recommended Next Step

Recommended next step:
"Create API_SURFACE.md updates for Octavo, Portal and Chatwoot canonical APIs."
