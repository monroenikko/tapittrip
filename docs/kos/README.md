# TapItTrip Knowledge Operating System

The KOS is the small set of repository artifacts that keeps product intent, approved scope, engineering decisions, and verified behavior aligned. It is not a second product plan and it does not authorize work beyond the current milestone.

## Start here

Read only what the task needs, in this order:

1. [`AGENTS.md`](../../AGENTS.md) — non-negotiable repository workflow and safety constraints.
2. [`MASTER_PLAN.md`](../../MASTER_PLAN.md) — product, architecture, milestone order, and acceptance criteria.
3. [`docs/milestone-log.md`](../milestone-log.md) — current approved milestone, completed slices, open issues, and next boundary.
4. [`docs/product-direction.md`](../product-direction.md) and [`docs/features/README.md`](../features/README.md) — staged direction and feature-level behavior/status.
5. [`docs/engineering/application-best-practices.md`](../engineering/application-best-practices.md) — shared Laravel/mobile delivery and quality standards.
6. Accepted records in `docs/decisions/` — decisions and their consequences.
7. [`docs/api/openapi.yaml`](../api/openapi.yaml), migrations, implementation, and tests — detailed implemented contracts.

When sources disagree, do not guess. Prefer the higher source for intent, identify whether the lower source is stale or the implementation exposes a real constraint, and record a decision before making a material change.

## Current state

- Current milestone: **M0 — foundation**, because the milestone log was absent when the KOS was introduced.
- Repository state: Laravel Sail API foundation, health contract, and infrastructure checks exist in `api/`; Flutter mobile shell (`com.tapittrip.app`) is scaffolded and verified in `client/`. See the milestone log for verification and remaining work.
- Product-feature work is not authorized until M0 passes its acceptance gate and the next milestone is explicitly approved.

The milestone log is the live source for progress. Do not maintain a second task-status list here.

## Delivery loop

Every backend or mobile slice follows [`delivery-workflow.md`](delivery-workflow.md):

1. Plan a smallest end-to-end outcome and its acceptance evidence.
2. Develop inside the approved milestone and established boundaries.
3. Test behavior, failure paths, security, accessibility, and offline implications proportionate to the slice.
4. Review the diff against contracts and risks, not only style.
5. Update contracts, decisions, and the milestone log with exact verification results.

For stack-specific work, use:

- `.agents/skills/tapittrip-laravel-api/SKILL.md`
- `.agents/skills/tapittrip-flutter-mobile/SKILL.md`

## Knowledge capture rules

- Create an ADR for durable choices with meaningful alternatives or migration consequences: aggregate boundaries, conflict semantics, authentication/session design, provider choice, encryption/key management, or data-retention behavior.
- Update OpenAPI with externally visible API behavior in the same slice.
- Update the relevant feature document when its flow, behavior, limitations, or delivery direction changes.
- Keep commands and environment requirements in the root README or relevant service README once those files exist.
- Record exact commands and pass/fail results in `docs/milestone-log.md`; never convert an unrun check into a claimed pass.
- Do not place secrets, real PII, booking references, private locations, document contents, or production samples in KOS artifacts.

