# Test-designer

A private GitHub repository for a Copilot-style test-case designer focused on asynchronous API testing with Solace JMS request/reply messaging over topics.

## Purpose

This repo contains reusable skill files and examples for designing high-quality test cases for APIs that use:

- request topic publish
- asynchronous processing
- reply topic consumption
- correlation by JMS headers/properties
- contract validation, negative testing, and boundary coverage

## Included assets

- `.github/skills/async-api-test-designer/SKILL.md` — the main skill for async API testing design
- `.github/skills/test-design-techniques/SKILL.md` — the supporting test-design methodology
- `examples/solace-jms-async-request-reply-test-plan.md` — illustrative test plan with realistic examples
- `references/REFERENCES.md` — research references and quality sources
- `templates/test-case-template.md` — reusable case format

## Recommended use

Use these files when you want the agent to:

- design a complete async API test strategy
- derive negative and boundary cases from request/response schemas
- reason about JMS correlation, selectors, retries, and timeout behavior
- produce a traceable test matrix instead of ad hoc examples

## Best-practice prompt pattern

Ask the agent with a prompt like this:

"Design a comprehensive async API test plan for a Solace JMS request/reply flow. The requester publishes to topic A and expects a reply on topic B. Use the attached schema, business rules, and expected correlation behavior. Generate mandatory field tests, boundary tests, invalid type tests, schema tests, negative tests, and async flow tests. Return a prioritized matrix with test IDs, steps, expected results, and follow-up risks."

## Important guardrails

- Treat the API contract as the main source of truth.
- Distinguish JMS metadata from payload schema.
- Do not assume behavior unless the contract clearly states it.
- Non-production environment only for malformed payloads, timeout tests, replay tests, and broker-level negative cases.
- Capture unknowns explicitly as `TBD` and ask targeted questions rather than guessing.
