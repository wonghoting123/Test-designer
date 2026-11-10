# Test-designer

Private for now: a GitHub Copilot skill collection for designing test cases for asynchronous APIs that use Solace JMS topics for request/reply messaging.

## What’s here

- [` .github/skills/async-api-test-designer/SKILL.md`](.github/skills/async-api-test-designer/SKILL.md) — end-to-end test-design skill for asynchronous request/reply APIs.
- [`.github/skills/test-design-techniques/SKILL.md`](.github/skills/test-design-techniques/SKILL.md) — systematic case-design methods and coverage checklist.
- [`examples/solace-jms-async-request-reply-test-plan.md`](examples/solace-jms-async-request-reply-test-plan.md) — worked example with assumptions, sample schemas, and illustrative cases.
- [`references/REFERENCES.md`](references/REFERENCES.md) — online references, with official specifications and Solace documentation prioritized.
- [`templates/test-case-template.md`](templates/test-case-template.md) — reusable test-case format.

## Use the skills

Copy the `.github/skills/` directories into a repository where Copilot can use them. Provide the agent with the API contract, business rules, expected messaging topology, and test environment constraints. Ask it to produce a test plan and traceable cases; do not ask it to publish test messages unless that is explicitly authorized and the target is a designated test environment.

## Important design principles

- Treat the supplied API contract and business rules as the source of truth. Mark unknown behavior as an assumption or question; do not invent expected outcomes.
- Distinguish application payload validation from JMS headers, properties, delivery semantics, broker configuration, and operational behavior.
- A request topic and a reply topic are not necessarily equivalent to a JMS `JMSReplyTo` destination. Confirm the actual contract and routing design.
- Include positive, negative, boundary, schema, asynchronous, correlation, timeout, concurrency, and recovery coverage where applicable.
- Never use production messaging destinations for negative, load, malformed-message, or destructive tests without explicit authorization.

## References

See [references/REFERENCES.md](references/REFERENCES.md). External references inform the approach; they do not replace the target API contract or environment-specific rules.
