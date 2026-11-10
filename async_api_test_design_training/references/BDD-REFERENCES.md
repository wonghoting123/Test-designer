# Official BDD and Gherkin references

These sources were reviewed for the BDD-oriented test-designer skill. Cucumber's official documentation is the primary reference for its BDD workflow and Gherkin syntax. Use the actual API contract and stakeholder agreement as the source of truth for system behavior.

## Cucumber: BDD workflow

- [Behaviour-Driven Development (BDD)](https://cucumber.io/docs/bdd/) — collaboration through discovery, formulation, and automation using concrete examples.
- [Cucumber documentation](https://cucumber.io/docs/) — overview of Cucumber and executable specifications.

## Cucumber: Gherkin

- [Gherkin Reference](https://cucumber.io/docs/gherkin/reference/) — keywords and syntax, including Feature, Rule, Scenario, Scenario Outline, Examples, Given/When/Then, Background, tags, and data tables.
- [Gherkin best practices](https://cucumber.io/docs/gherkin/best-practices/) — guidance for writing understandable, focused scenarios.
- [Cucumber tag expressions](https://cucumber.io/docs/cucumber/api/#tag-expressions) — tag expression documentation; details may depend on the Cucumber implementation/language.

## How the skill applies these sources

1. Use BDD as a collaborative discovery and specification process, not merely a Gherkin formatting exercise.
2. Write concrete, outcome-focused examples in domain language.
3. Keep Gherkin syntax valid and concise; use outlines/tables only when they make examples clearer.
4. Keep business behavior separate from implementation-specific automation.
5. Confirm the system's actual asynchronous behavior, Solace JMS topology, and contract with project sources; Cucumber documentation does not define those service-specific expectations.
6. Use a complementary contract/schema matrix for detailed payload permutations rather than making feature files unreadably exhaustive.

## Related repository references

- See [`REFERENCES.md`](REFERENCES.md) for black-box test design, Solace JMS, JSON Schema, and API contract references.
- See [`../test-plans/solace-jms-async-request-reply-test-plan.md`](../test-plans/solace-jms-async-request-reply-test-plan.md) for an illustrative async test plan.
