# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Retail courier customers in the Dominican Republic who buy online from the
United States and have the goods forwarded to a local branch. The primary user
holds an account code (for example `BM-096791`), is assigned to one home branch,
and opens the app on a phone, usually one-handed, to answer a small set of
recurring questions: has my package arrived, what does it cost, where and when
can I pick it up.

A second audience is the courier company itself. Thirty-five brands ship the
same binary under their own identity (`lib/apps/*`, `whitelabel/<slug>.json`),
so every screen must hold up under any brand palette, logo, and typeface.

## Product Purpose

The app is the customer-facing front end of an existing courier back office. It
turns the operator's reception, invoicing, and delivery records into something a
customer can read on a phone: package stages, account statement, pre-alerts,
shipping calculator, branch directory, services, news, and FAQ. Success is a
customer who resolves the question without calling the branch.

## Positioning

One code base, thirty-five courier brands. Identity, enabled modules, and
navigation are configuration (`BrandConfig`, `whitelabel/<slug>.json`) resolved
against what the operator's backend reports for that company (`Empresa`). A
capability is visible only where the local brand permit and the remote module
agree.

## Operating Context

- Data comes from Azure Functions endpoints wrapped by `CourierService`
  (`lib/services/courier_service.dart`), cached through `flutter_cache`.
- Session state lives in `flutter_cache` keys: `sessionId`, `userAccount`,
  `userName`, `userSucursal`, `userEmail`. `CourierService.companyId` carries the
  brand's `empresaId`.
- Navigation is a single `go_router` tree (`lib/navigation/app_router.dart`) with
  five configurable tabs, `home` always centre.
- Localisation is `easy_localization` over `translations/es.json` and
  `translations/en.json`.
- Conversational assistant: a hosted n8n webhook at
  `https://n8n.barolitcloud.dev/webhook/courier/assistant`. It accepts a POST of
  `empresaId`, `sessionId`, `firstName`, `lastName`, `userAccount`, `sucursalId`,
  `question` and answers `{"output": "<markdown>"}`. Measured latency runs from
  three to twenty-two seconds. It has no streaming and no client-visible thread
  id; the server keys its own memory on `sessionId`.

## Capabilities and Constraints

- Confirmed for the assistant: available only to a signed-in customer; the
  conversation is not persisted on the device; answers may offer navigation into
  existing screens but the assistant never performs an action on the customer's
  behalf (no pickup notice, no delivery request, no payment); replies are always
  Spanish, so no `language` field is added to the payload.
- Package data is personal. It must not be logged, cached to disk, or sent
  anywhere the customer's own session does not already reach.
- No streaming transport exists, so the wait is a designed state, not an
  afterthought.
- The app already ships a complete design system (`lib/design_system/*`,
  `lib/theme/brand_tokens.dart`). No screen names a font family or a raw colour.
- `flutter analyze` and `flutter test` are the local gates; `tool/audit_presentation.dart`
  fails the build on brand conditionals or visual literals in presentation code.

## Brand Commitments

Thirty-five brand identities, each defined in `whitelabel/<slug>.json` and
rendered through `BrandTokens`. Nothing in a screen may hard-code a brand's
colour, corner radius, or typeface. Spanish is the primary product language.

## Evidence on Hand

- Live assistant webhook, verified answering branch, service, and package
  questions with the sample payload the product owner supplied.
- Real branch, service, FAQ, and package data through `CourierService`.
- No published claim about the assistant's accuracy exists; none may be invented
  in copy.

## Product Principles

1. Answer the question the customer came with, in the fewest taps.
2. Configuration decides what exists; presentation never asks which brand it is.
3. The customer's package data stays inside the customer's own session.
4. A slow answer is still an answer: every wait has a designed state.
5. The assistant advises and points; the customer stays the one who acts.

## Accessibility & Inclusion

Phone-first, one-handed use. Screens must survive large system text and stay
legible on every brand palette; `BrandTokens.accessibleForeground` exists for
exactly this and is the required path for any accent-coloured foreground.
