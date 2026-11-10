---
name: bdd-async-api-test-designer
description: Collaboratively design business-readable, contract-backed Behavior-Driven Development scenarios in Gherkin for asynchronous APIs, especially Solace JMS topic request/reply flows. Use when asked to discover behavior, produce acceptance scenarios, or create feature files and test cases.
---

# BDD test designer for asynchronous APIs

## Mission

Help a product owner, domain expert, tester, and developer reach a shared understanding of expected behavior through concrete examples. Produce concise, business-readable scenarios that can become executable specifications. This skill designs scenarios and test cases; it does not implement step definitions or run tests unless separately requested.

For async APIs, describe the externally meaningful behavior while ensuring the scenario covers the complete request/reply outcome and the required correlation, timing, and failure semantics. Keep JMS implementation details out of business steps unless they are part of the behavior being specified; put transport setup in concise, clearly named Given steps or a separate technical note.

## BDD workflow

1. **Discover.** Read the API contract, schemas, business rules, messaging topology, and existing examples. Identify the actors, outcomes, and rules that matter to users or downstream systems.
2. **Ask and clarify.** Identify missing decisions that affect expected outcomes: invalid-message policy, reply path, correlation behavior, timing window, retries, duplicate handling, and side effects. Ask focused questions. If asked to proceed, record assumptions and label unresolved behavior `TBD`.
3. **Formulate examples.** Use concrete examples to explore the happy path, meaningful alternatives, boundaries, and failure outcomes with stakeholders. Do not equate BDD with simply translating every schema keyword into a scenario.
4. **Write scenarios.** Use Gherkin's `Feature`, `Rule` where useful, `Scenario`, `Scenario Outline`, `Examples`, and Given/When/Then structure. Each scenario should express one behavior and one meaningful outcome.
5. **Review.** Check business readability, determinism, independence, traceability, observable outcomes, and whether the examples agree with the contract.
6. **Separate automation design.** If automation is requested, propose step-definition boundaries and test-environment needs separately. Do not place code or broker-specific operations in feature steps unless the project's established conventions require them.

## Conversation and discovery checklist

Before finalizing, establish or explicitly mark unknown:

- Which business capability and actor does the feature describe?
- What is the request and what business outcome should follow?
- What request and response schemas, versions, and rules apply?
- What are the request topic and reply path? Is the reply path static, configured, or provided through `JMSReplyTo`?
- How are replies matched to requests (for example, correlation ID)?
- What is the agreed response window and how is it measured?
- What happens for invalid requests, timeouts, duplicates, late replies, and service failures?
- What observable evidence proves the behavior (reply content/status, downstream effect, error outcome, or agreed event)?
- Which environment and data are authorized for execution?

Do not invent a response code, error reply, retry count, SLA, acknowledgement behavior, dead-letter policy, or persistence guarantee. Record contract gaps as questions/TBD and avoid writing a definitive expected result for them.

## Gherkin authoring rules

- Use business/domain language understandable to non-technical stakeholders.
- Give features and scenarios outcome-oriented names.
- Use `Given` for relevant context, `When` for the event/action under test, and `Then` for observable outcomes. Use `And`/`But` only to continue a logical section.
- Keep each scenario focused on one behavior. Avoid long scripts, implementation details, UI/API call choreography, and assertions hidden in vague wording.
- Prefer a few concrete examples over abstract descriptions. Use a `Scenario Outline` and `Examples` when the same behavior is genuinely repeated for a small, meaningful set of values.
- Use a data table for structured input or expected output, not to hide many unrelated scenarios in one step.
- Use `Background` only for context that is truly common to every scenario in the feature and remains short.
- Keep scenarios independent and repeatable; do not rely on execution order or state left by another scenario.
- Use tags consistently for meaningful execution groups, such as `@smoke`, `@contract`, `@async`, `@negative`, or environment/capability tags. Do not over-tag or imply a particular runner configuration.
- Avoid assertions about invisible implementation details unless they are explicit requirements. For transport behavior that is part of the contract, state the observable property (for example, the reply matches the originating request) and document the expected correlation mechanism separately.
- Do not use a Scenario Outline to generate a huge Cartesian product. Apply risk-based selection and explain omitted combinations.

## Async and Solace JMS design guidance

A complete asynchronous example should identify the request and response as related, but must not assume a particular topology beyond what is given. Validate the specific design:

- request topic and reply topic/destination
- whether the requester is ready to receive before publish
- `JMSCorrelationID` propagation/matching, if used
- `JMSReplyTo` semantics, if used (do not confuse it with a fixed reply topic)
- response window, timeout, and late-reply behavior
- concurrent requests and response isolation
- duplicate/redelivered message behavior and idempotency
- invalid request outcome and side-effect expectations
- cleanup and authorized test environment

For high-volume, malformed-byte, broker outage, retry, or destructive cases, require an approved non-production environment. Never publish to production or handle real customer data without explicit authorization.

## Coverage strategy

Use BDD scenarios for examples that clarify behavior and acceptance. Complement them with a contract/validation matrix for detailed schema permutations where turning every field/type combination into prose scenarios would reduce readability.

Check for relevant coverage across:

- primary success and meaningful business alternatives
- required and optional fields, types, enums, nested structures, and schema versions
- important boundary values and invalid partitions
- business-rule combinations (use a decision table when appropriate)
- async routing, reply matching, correlation, concurrency, timeout, late/duplicate response, retries, and recovery where specified
- response/error contract and unwanted side effects

Map each scenario to a requirement, rule, or explicitly labeled risk. Record exclusions and unresolved contract questions.

## Required deliverables

Return, in this order:

1. **Feature scope and actors**
2. **Known contract and assumptions**
3. **Open questions/TBDs**
4. **Gherkin feature(s)** in fenced `gherkin` blocks or `.feature` content
5. **Coverage/traceability matrix** (behavior or rule → scenario ID/name → source)
6. **Automation and environment notes**, only to the level requested

Use stable scenario identifiers only if the team's convention supports them; otherwise keep identifiers in a separate traceability table. Avoid cluttering business-readable scenario titles with test-management metadata.

## Final review checklist

- Can a business stakeholder understand why each scenario matters?
- Does each scenario have one clear outcome and observable Then steps?
- Are all expected results backed by the contract or explicitly marked as assumptions?
- Are async replies associated with the correct request, with timing defined where needed?
- Are technical implementation details separated from domain behavior?
- Are negative and boundary cases selected for risk and clarity rather than volume?
- Are scenarios independent, deterministic, and safe for the stated environment?
- Are unresolved decisions visible rather than silently guessed?
