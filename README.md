# Test-designer

A GitHub Copilot skill collection for designing test cases and Behavior-Driven Development (BDD) scenarios for asynchronous APIs using Solace JMS request/reply messaging over topics.

## Skills

- [BDD async API test designer](.github/skills/bdd-async-api-test-designer/SKILL.md) — discover and formulate business-readable Gherkin acceptance scenarios for async APIs.
- [Async API test designer](.github/skills/async-api-test-designer/SKILL.md) — broader test-plan design for payload, schema, JMS correlation, timing, and recovery.
- [Test design techniques](.github/skills/test-design-techniques/SKILL.md) — black-box coverage techniques and risk-based case quality.

## Examples and references

- [BDD Gherkin example](examples/bdd/async-order-request-reply.feature)
- [Solace request/reply signup BDD example](example_1/user-signup-solace.feature)
- [Solace user signup request/reply test plan](example_1/solace-user-signup-request-reply-test-plan.md)
- [Kafka user signup test plan](example_1/user-signup-asyncapi-test-plan.md)
- [Solace JMS async request/reply test-plan example](examples/solace-jms-async-request-reply-test-plan.md)
- [BDD and Gherkin references](references/BDD-REFERENCES.md)
- [Testing and messaging references](references/REFERENCES.md)
- [Reusable test-case template](templates/test-case-template.md)

## Recommended BDD workflow

Use BDD collaboratively: discover behavior with domain stakeholders, formulate concrete examples in Gherkin, then automate agreed scenarios. Provide the agent with the API contract, business rules, request/reply topology, and constraints. It should identify unknowns, ask focused questions, and mark unresolved outcomes as `TBD` rather than inventing acceptance criteria.

Use Gherkin scenarios for important behavioral examples. Pair them with a contract/schema coverage matrix for exhaustive required-field, type, and boundary permutations so feature files remain readable.

For the agent's general workflow and typical async API test coverage, see the [AsyncAPI test case design guide](test_case_design_feedback.md).

## Safety and correctness

- Treat the API contract and stakeholder agreement as sources of expected behavior.
- Distinguish application payload rules from JMS metadata and broker behavior.
- Do not assume a reply topic is conveyed by `JMSReplyTo`; confirm the actual routing design.
- Keep destructive, malformed-message, retry, and high-volume tests in explicitly authorized non-production environments.
- Never put credentials or real customer data in examples.

## References

The skills use official Cucumber documentation for BDD and Gherkin, along with official Solace/JMS and schema references. See the `references/` directory.
