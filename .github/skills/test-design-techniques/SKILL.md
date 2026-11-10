---
name: test-design-techniques
description: Apply systematic black-box testing methods to create efficient, risk-based test coverage for API payloads and asynchronous request/reply flows.
---

# Test Design Techniques

Use these techniques to turn requirements and schemas into effective tests.

## 1. Equivalence partitioning

Group inputs into classes that should behave similarly:

- valid values
- invalid values
- out-of-range values
- unsupported values
- missing values

Example: a numeric field with allowed range 1–100 should be tested with representative values from:

- below range
- inside range
- above range
- wrong type
- null/empty if allowed

## 2. Boundary value analysis

Apply this to ranges, lengths, counts, and dates. Include values just inside and just outside boundaries.

Examples:

- minimum valid
- minimum invalid
- maximum valid
- maximum invalid
- one below/above boundary
- zero/negative where relevant

## 3. Decision table testing

Use decision tables when behavior depends on multiple business conditions.

For each condition, capture:

- true/false states
- distinct outputs
- rule priority and precedence
- invalid combinations

This works especially well for approval logic, routing rules, and validation rules with multiple flags.

## 4. State transition testing

Use for request/reply and lifecycle state changes such as:

- created
- published
- in progress
- replied
- rejected
- timed out
- retried
- dead-lettered

Test valid transitions, invalid transitions, and duplicate or delayed transitions.

## 5. Schema testing

Apply schema-based validation to:

- required and optional fields
- field types
- enum values
- nested objects
- arrays and counts
- additional properties policy
- format constraints and strictness rules

Do not assume the validator behaves the same across all JSON schema dialects. Check the implementation and version.

## 6. Negative testing

Always include explicit invalid scenarios such as:

- missing required field
- wrong type
- unsupported value
- malformed JSON
- oversized payload
- invalid date or enum value
- malformed correlation metadata
- mismatched replies

Negative tests protect against silent coercion, unsafe defaults, and unexpected system behavior.

## 7. Risk-based prioritization

Sort cases by:

- business criticality
- data sensitivity
- message routing risk
- correlation correctness
- failure severity
- impact of duplicate or delayed message handling

A good plan should include a small smoke subset plus a fuller regression design.

## 8. Coverage checklist

At minimum, verify:

- required fields
- optional fields
- valid values
- invalid values
- boundary values
- nested object behavior
- array behavior
- enums
- type mismatches
- schema violations
- async flow correctness
- correlation correctness
- timeout and retry behavior

## 9. Quality bar for a good test case

A strong test case should have:

- clear objective
- specific setup
- exact input
- precise expected result
- observable evidence
- no hidden assumptions
- clear cleanup or impact notes

If there is uncertainty, label the assumption or ask a targeted question.
