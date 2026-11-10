# AsyncAPI Test Case Design Guide

This guide summarizes how an agent should turn an AsyncAPI contract and related business rules into useful, traceable test cases. Treat the contract and confirmed stakeholder decisions as the source of expected behavior; do not fill gaps by guessing.

## 1. Understand the contract before designing tests

First identify:

- AsyncAPI version, service, operations, channels, and message direction (`send`/`receive` or publish/subscribe semantics)
- request/event and response/error message schemas, including required and optional properties
- types, formats, enums, patterns, minimums/maximums, lengths, array limits, and nested structures
- server protocol, security requirements, channel parameters, and broker bindings
- whether the flow is event-only or request/reply
- request and reply destinations, correlation metadata, and how replies map to requests
- environment authorization, test data constraints, and cleanup expectations

Separate application payload requirements from transport metadata and broker behavior. Do not treat a topic as a queue, assume `JMSReplyTo` is used, or invent correlation, acknowledgement, retry, timeout, or dead-letter behavior. If a detail is missing, record it as `TBD` and ask a focused question when it affects expected results.

## 2. Design a risk-based test set

Prefer representative, high-value cases over a large list of repetitive tests. Use equivalence partitioning, boundary-value analysis, decision tables, state transitions, and negative testing where appropriate.

### Payload and schema cases

For each applicable field or constraint, consider:

- valid representative value
- required property omitted
- required property present with `null`
- empty string, array, or object where meaningful
- whitespace-only string where meaningful
- wrong JSON type (including integer versus decimal)
- invalid format, pattern, or enum value
- minimum and maximum valid values and the nearest invalid values
- nested object and array item validity, including item counts and item types
- unknown/additional properties, only when their policy is specified or explicitly under investigation

Missing and `null` are different JSON inputs. Track them separately. Apply field-specific tests rather than assuming every string, number, or object shares the same constraints. Do not infer a 32-bit integer maximum unless the contract or a confirmed implementation rule says so.

For response and error schemas, test required fields, types, formats, enums, bounds, and that each response is associated with its originating request as specified.

### Asynchronous and broker-flow cases

Where applicable and contract-backed, include:

- valid message routed to the intended channel, topic, queue, or subscription
- valid response delivered to the defined reply destination
- request/reply correlation and matching
- concurrent requests without cross-association
- timeout, late response, retry, redelivery, duplicate, and idempotency behavior
- invalid requests and whether they cause a response or unwanted side effects
- recovery after consumer restart, broker interruption, or re-subscription
- security/authentication and channel-parameter validation

If these behaviors are not defined, mark them `TBD` instead of asserting an outcome. Keep malformed-message, failure-injection, high-volume, and destructive broker tests in approved non-production environments.

## 3. Make every test case actionable

Each test should have:

- stable test ID and concise title
- priority/risk and objective
- preconditions and authorized environment
- message direction/type and exact input variant
- relevant channel, queue, topic, headers, and correlation data
- clear steps
- a precise expected result supported by the contract or labeled assumption
- observable evidence (for example, validation result, consumed record, response payload, destination, or correlation value)
- failure impact and cleanup notes

One case should focus on one primary variation. Keep schema validation distinct from runtime or broker delivery tests when their expected behavior differs.

## 4. Use readable BDD scenarios

Write Gherkin in business language with one meaningful behavior per scenario. Use `Scenario Outline` for a small, coherent set of similar values; use a test matrix for exhaustive field permutations that would make feature files unreadable. Keep broker setup in concise `Given` steps or technical notes. Do not state undocumented behavior as a `Then`.

## 5. Reconcile coverage before delivery

Build a shared, field-by-field inventory from request, response, and error schemas. For every applicable field and constraint, record:

- the test/scenario IDs that cover it, or
- an explicit exclusion with a reason, or
- a visible `TBD` with the question or decision needed.

When delivering both a feature file and a Markdown plan, cross-check them against the same inventory:

- every planned case maps to a feature scenario or is labeled plan-only
- every feature scenario maps to a contract rule, requirement, or documented risk
- test inputs and expected results agree across artifacts
- missing, `null`, empty, wrong-type, boundary, and format cases are not silently conflated or omitted

Do not finalize while any inventory item is unaccounted for. A generic “invalid request” case does not prove that each field or invalid-value class was tested.

## 6. Recommended plan structure

For a contract-derived test plan, include:

1. Scope, known contract, assumptions, and open questions
2. Contract inventory
3. Runtime topology and message flow
4. Coverage/traceability matrix
5. Prioritized, observable test cases
6. Risks and unresolved behavior
7. Authorized environment and execution/cleanup notes
8. Field-by-field coverage reconciliation

Use the AsyncAPI document, approved business rules, and environment documentation as evidence for expected outcomes. Keep unresolved behavior visible and do not claim guarantees the contract does not make.
