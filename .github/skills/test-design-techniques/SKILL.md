---
name: test-design-techniques
description: Apply structured black-box techniques to create efficient, risk-based test coverage for API payloads and asynchronous workflows.
---

# Test design techniques

Use these techniques to derive cases from stated requirements and schemas. Select techniques that fit the rule; do not mechanically generate a huge list without risk rationale.

## Equivalence partitioning

Divide inputs into classes expected to behave alike, including valid and invalid classes. Select representative values from each class. For example, for an integer range 1–100, classes might be below range, in range, above range, and wrong type. Confirm inclusivity and coercion rules from the contract.

## Boundary-value analysis

For ordered limits, include the boundary and adjacent values: `min-1`, `min`, `min+1`, `max-1`, `max`, `max+1`, where representable and safe. Apply to string length, numeric range, collection size, and date windows. Include zero, negative, precision/scale, overflow, and Unicode length semantics when relevant. Do not invent a limit if none is specified.

## Decision tables

For behavior depending on multiple conditions, list conditions and distinct outcomes. Cover each meaningful rule and contradictory/precedence cases. Reduce combinations only with an explicit method (e.g. pairwise) and retain high-risk combinations.

## State-transition testing

Model request lifecycle states (for example: created, published, processing, replied, timed out, retried, failed). Test valid and invalid transitions, late/duplicate events, and recovery. Use only states and transitions supported by the design.

## Schema and type testing

For each field, exercise requiredness, declared type, format, enum, nullability, constraints, nesting, unknown-field policy, and version behavior. Compare against the actual schema validator's documented behavior; JSON Schema keywords and format assertion behavior can vary by dialect/configuration.

## Negative and robustness testing

Test malformed/invalid payloads, wrong content types, unsupported values, and missing metadata according to specified handling. Verify safe, deterministic rejection and no unintended side effect. Keep fuzzing, very large payloads, and malformed bytes within approved test limits.

## Risk and prioritization

Prioritize by impact, likelihood, exposure, and detectability. Cover critical business rules, money/identity fields, message routing, correlation, idempotency, and failure recovery before low-risk permutations. Identify the minimum smoke subset separately.

## Case quality checklist

- One primary purpose/variation per case where practical.
- Preconditions and test data are explicit and repeatable.
- Expected results are specific and observable (payload, destination, properties, status, logs/metrics, or timing).
- Request and response are tied by correlation identifiers where applicable.
- Timeout expectations include a defined duration/window and clock assumptions.
- Each case traces to a requirement or is clearly labeled exploratory/risk-based.
- No expected behavior is invented; uncertainties are marked TBD.
- Cleanup and duplicate/replay safeguards are described.
