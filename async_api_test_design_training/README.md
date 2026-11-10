# Async API Test Design Training Materials

This folder organizes the repository's guidance and examples for designing contract-backed asynchronous API tests. It is a reusable knowledge pack for agents and reviewers; it does not train or fine-tune a model by itself.

## Materials by type

- [`guidance/`](./guidance/) — general test-design feedback and workflow.
- [`contracts/`](./contracts/) — AsyncAPI contract used by the Example 2 exercises.
- [`features/`](./features/) — Gherkin examples for publish/subscribe and request/reply flows.
- [`test-plans/`](./test-plans/) — Markdown plans and case inventories.
- [`references/`](./references/) — BDD, messaging, schema, and test-design sources.
- [`templates/`](./templates/) — reusable test-case template.

## Active agent skills

The active Copilot skills remain in VS Code's recognized workspace location:

- [Async API test designer](../.github/skills/async-api-test-designer/SKILL.md)
- [BDD async API test designer](../.github/skills/bdd-async-api-test-designer/SKILL.md)
- [Test design techniques](../.github/skills/test-design-techniques/SKILL.md)

Use the skills to guide the agent's task workflow and this folder as its organized reference and example set. Keep both the feature and plan aligned through the field-by-field coverage reconciliation described in the guidance.
