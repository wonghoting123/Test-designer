---
name: async-api-test-designer
description: Design traceable, comprehensive test cases for asynchronous APIs using Solace JMS request/reply over topics. Use when given an API contract, schemas, message examples, or business rules and asked to create a test approach or test cases.
---

# Async API test designer (Solace JMS)

## Goal

Produce a test approach and test cases for an asynchronous API in which a requester publishes a message to a request topic and receives a corresponding response through the system's configured reply path (often another topic). Focus on correctness of payloads and on the complete asynchronous request/reply lifecycle.

## Required inputs and uncertainties

First identify what is known and missing:

- Request and response schemas, versions, and content types/encoding.
- Required/optional fields, constraints, enums, formats, and business rules.
- Request topic and reply destination, subscription model, and routing configuration.
- JMS headers/properties in use, including `JMSReplyTo`, `JMSCorrelationID`, message type, expiration/TTL, delivery mode, and priority, if applicable.
- Expected validation/rejection behavior, error response or dead-letter behavior, and whether malformed messages are acknowledged.
- Timeout, retry, duplicate/idempotency, ordering, concurrency, and service-level expectations.
- Authorized environment, test data limits, cleanup requirements, and observability available.

Do not infer that a reply topic is conveyed via `JMSReplyTo`; confirm whether the reply path is configured statically, carried in a header/property, or supplied as a JMS destination. If an expectation is not specified, label it `TBD` and ask a focused question rather than presenting it as a requirement.

## Safe execution boundary

This skill designs tests. Do not connect to a broker or publish messages unless separately instructed and authorized. Restrict destructive, malformed, high-volume, and security tests to an explicitly approved non-production environment. Avoid real customer data and credentials. Do not include secrets in test artifacts or logs.

## Workflow

1. **Extract the contract.** Create a compact inventory of fields, types, requiredness, constraints, enums, examples, and response/error rules. Separate payload rules from JMS metadata and broker behavior.
2. **Map the message flow.** Document producer → request topic → consumer/service → reply destination → requester. Record how replies are correlated and how late, duplicate, unmatched, or missing responses are handled.
3. **State assumptions and questions.** Do not silently fill gaps. List decisions that change expected results (for example, whether unknown properties are allowed or invalid requests receive an error reply).
4. **Build coverage.** Apply applicable techniques from the test-design skill. Include both request validation and reply contract checks.
5. **Prioritize.** Tag cases by risk/priority, noting business impact, likelihood, and any environment dependency. Include a small critical-path smoke set.
6. **Write executable, observable cases.** Each case has a setup, one principal variation, steps, a measurable expected result, correlation/timeout observations, and cleanup.
7. **Review coverage and traceability.** Map each requirement/schema constraint to one or more test IDs. Identify untested constraints and explain exclusions.

## Minimum coverage checklist

### Payload and contract

- Each required field: present, omitted individually, `null` where distinguishable, empty/blank where relevant.
- Optional fields: absent, valid, and invalid when constraints exist.
- Field types: expected type and wrong JSON/JMS representation (string, number, integer, boolean, object, array, null), including coercion-sensitive cases.
- Equivalence partitions and boundaries for lengths, numeric ranges, item counts, dates, and formats.
- Enums: every meaningful allowed class and representative unsupported values; test all values when the set is small and feasible.
- Nested objects/arrays: missing members, empty collections, wrong item types, min/max item counts, and invalid nesting.
- Schema/version compatibility, additional/unknown fields, content type, malformed serialization, and response schema.
- Business-rule combinations using decision tables or pairwise reduction when exhaustive combinations are too large. Preserve critical combinations explicitly.

### Asynchronous messaging

- Valid request produces the expected response on the correct reply path.
- Correlation metadata is unique as required and the response is matched to the originating request.
- Concurrent requests do not receive each other's replies.
- Unmatched, missing, malformed, and duplicate correlation identifiers follow specified behavior.
- No reply, late reply, duplicate reply, and service error behavior (timeout, retry, error response, dead-letter) follow the contract.
- Redelivery, idempotency, ordering, expiration/TTL, and acknowledgement behavior where relevant and specified.
- Subscription/readiness race: verify the requester is ready to receive before publishing if the design requires it.
- Cleanup: temporary destinations, subscriptions, consumers, and test data are removed.

Do not assume that every item is supported by the target application or broker configuration. Mark inapplicable or unspecified items and explain why.

## Output format

Return:

1. **Scope and assumptions** — include the flow and environment boundaries.
2. **Contract inventory** — field/rule table and JMS metadata table.
3. **Coverage matrix** — requirement or rule → test IDs → technique.
4. **Prioritized test cases** — use `templates/test-case-template.md` fields.
5. **Open questions and risks** — expected behavior needed to finalize TBDs.
6. **Execution notes** — setup, safe environment, observability, timing, and cleanup.

Use stable IDs, for example `ASYNC-REQ-001`. Expected results must be observable and must not claim unspecified behavior. State whether a test is design-only, contract-validation, integration, or broker/operational testing.
