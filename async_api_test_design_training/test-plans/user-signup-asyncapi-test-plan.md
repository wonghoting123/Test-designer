# User Signup AsyncAPI test plan

## 1. Scope and assumptions

This plan is derived from the supplied AsyncAPI 2.6.0 document for the `User Signup Service`. It covers the `UserSignedUp` JSON event published to the `user/signedup` channel, including schema validation, basic Kafka publication, and consumer-side observation.

- The supplied document is the contract under test; no implementation or runtime configuration was supplied.
- The `publish` operation describes sending an event. There is no reply channel or response message, so this is not a request/reply contract.
- Kafka is the declared protocol. JMS headers and `JMSReplyTo` do not apply; Kafka record metadata such as key, headers, partition, and offset is not specified.
- The environment, authorization, delivery guarantees, retention, expected timing, invalid-message behavior, and side-effect rules are TBD.
- Do not run negative, duplicate, or broker-failure tests against production. Use synthetic data and a sanctioned non-production environment.
- Where the contract does not define runtime behavior, expected outcomes below are limited to schema conformance or are marked TBD; they do not prescribe application behavior.

## 2. Contract inventory

| Element | Contract |
|---|---|
| AsyncAPI version | `2.6.0` |
| Service | `User Signup Service`, version `1.0.0` |
| Server | `production`, protocol `kafka`, URL `://example.com` |
| Channel / operation | `user/signedup`, `publish`, operation ID `sendUserSignedUp` |
| Message | `UserSignedUp`, content type `application/json` |
| Payload | Object with required `userId`, `email`, `age`, and `createdAt` |
| `userId` | String, UUID format |
| `email` | String, email format |
| `age` | Integer, minimum 18; no maximum defined |
| `createdAt` | String, date-time format |
| Optional fields | None declared |
| Additional properties | Policy not declared |
| Reply/error schema | Not defined |

## 3. Runtime topology and async flow

The documented flow is a producer publishing a `UserSignedUp` JSON record to the `user/signedup` channel over Kafka. A consumer, consumer group, acknowledgement/offset policy, keying strategy, and downstream effects are not described. There is no reply destination, correlation mechanism, timeout, retry, or dead-letter contract.

The server URL `://example.com` appears malformed because it has no host preceding the colon-slashes. Also confirm that the channel name maps to a valid Kafka topic in the target implementation: Kafka topic names do not generally allow `/`. These are contract/configuration validation findings, not assumptions about a deployed broker.

## 4. Coverage matrix

| Area | Coverage | Priority |
|---|---|---|
| Valid required payload and event publication | Signup event accepted by the configured test producer and observed on the intended topic | P0 |
| Required fields | Missing-field checks for all four required properties | P1 |
| Types and nulls | JSON type and null conformance for payload properties | P1 |
| Formats | UUID, email, and date-time format checks | P1 |
| Numeric boundary | `age` at 18 and immediately below; no upper bound asserted | P1 |
| JSON/schema robustness | Malformed JSON and undeclared additional property behavior | P2 |
| Kafka routing/configuration | Server URL and channel-to-topic mapping | P0 |
| Delivery/recovery semantics | Duplicate delivery, ordering, retries, DLQ, consumer restart, and timing | TBD pending contract |
| Request/reply | Not applicable; no reply message or channel is defined | — |

## 5. Prioritized test cases

### ASYNC-SIGNUP-001 — Valid signup event

- **Priority / risk:** P0; high impact if valid signup events cannot be published or consumed.
- **Test level / technique:** Integration; schema validation and positive path.
- **Preconditions:** Authorized non-production Kafka environment; resolved bootstrap configuration and confirmed topic name; test consumer subscribed before publishing.
- **Message type / input:** Request/response/error: not applicable. Publish `UserSignedUp` with a syntactically valid UUID, email, integer `age` of 18, and valid date-time `createdAt`.
- **Kafka metadata:** Key, headers, partition, and delivery mode are unspecified; use environment defaults and record actual metadata.
- **Steps:** 1. Start the test consumer. 2. Publish one valid JSON event. 3. Observe producer result and consumed record.
- **Expected result:** Payload conforms to the declared schema and is observed on the configured topic. Delivery-time SLA and producer acknowledgement semantics are TBD.
- **Observable evidence:** Schema validator result, producer acknowledgement/error, topic and partition, offset, and redacted consumed payload.
- **Failure severity:** High if valid events are rejected, misrouted, or not observable.
- **Cleanup:** Remove only test records/resources according to the test environment's policy; do not use real user data.

### ASYNC-SIGNUP-002 — Missing `userId`

- **Priority / risk:** P1; one required identity field omitted.
- **Test level / technique:** Schema; required-field negative test.
- **Preconditions:** Non-production schema-validation or publish path available.
- **Message type / input:** Event with `userId` omitted; all other fields valid.
- **Kafka metadata:** No metadata behavior is defined; use test-environment defaults.
- **Steps:** Validate the payload against the schema, then exercise the sanctioned non-production publish path if runtime rejection behavior is in scope.
- **Expected result:** Schema validation fails because `userId` is required. Runtime rejection, error reporting, and side effects are TBD.
- **Observable evidence:** Validator error identifying `userId`; if published, record producer and consumer observations without asserting undocumented runtime behavior.
- **Failure severity:** High if a required-field omission is treated as schema-valid.
- **Cleanup:** Remove test data per environment policy.

### ASYNC-SIGNUP-003 — Missing `email`

- **Priority / risk:** P1; one required contact field omitted.
- **Test level / technique:** Schema; required-field negative test.
- **Preconditions:** Non-production schema-validation or publish path available.
- **Message type / input:** Event with `email` omitted; all other fields valid.
- **Kafka metadata:** No metadata behavior is defined; use test-environment defaults.
- **Steps:** Validate the payload against the schema, then exercise the sanctioned non-production publish path if runtime rejection behavior is in scope.
- **Expected result:** Schema validation fails because `email` is required. Runtime rejection, error reporting, and side effects are TBD.
- **Observable evidence:** Validator error identifying `email`; record any runtime result without assuming a specific rejection mechanism.
- **Failure severity:** High if a required-field omission is treated as schema-valid.
- **Cleanup:** Remove test data per environment policy.

### ASYNC-SIGNUP-004 — Missing `age`

- **Priority / risk:** P1; one required eligibility-related field omitted.
- **Test level / technique:** Schema; required-field negative test.
- **Preconditions:** Non-production schema-validation or publish path available.
- **Message type / input:** Event with `age` omitted; all other fields valid.
- **Kafka metadata:** No metadata behavior is defined; use test-environment defaults.
- **Steps:** Validate the payload against the schema, then exercise the sanctioned non-production publish path if runtime rejection behavior is in scope.
- **Expected result:** Schema validation fails because `age` is required. Runtime rejection and business effects are TBD.
- **Observable evidence:** Validator error identifying `age`; record any runtime result without assuming a specific rejection mechanism.
- **Failure severity:** High if a required-field omission is treated as schema-valid.
- **Cleanup:** Remove test data per environment policy.

### ASYNC-SIGNUP-005 — Missing `createdAt`

- **Priority / risk:** P1; one required event-timestamp field omitted.
- **Test level / technique:** Schema; required-field negative test.
- **Preconditions:** Non-production schema-validation or publish path available.
- **Message type / input:** Event with `createdAt` omitted; all other fields valid.
- **Kafka metadata:** No metadata behavior is defined; use test-environment defaults.
- **Steps:** Validate the payload against the schema, then exercise the sanctioned non-production publish path if runtime rejection behavior is in scope.
- **Expected result:** Schema validation fails because `createdAt` is required. Runtime rejection and error behavior are TBD.
- **Observable evidence:** Validator error identifying `createdAt`; record any runtime result without assuming a specific rejection mechanism.
- **Failure severity:** High if a required-field omission is treated as schema-valid.
- **Cleanup:** Remove test data per environment policy.

### ASYNC-SIGNUP-006 — Age minimum boundary

- **Priority / risk:** P1; boundary correctness for the explicit minimum.
- **Test level / technique:** Boundary value analysis.
- **Preconditions:** Schema validator available.
- **Message type / input:** Validate two otherwise-valid events: `age: 18` and `age: 17`.
- **Kafka metadata:** Not applicable to schema-only validation; if publishing, use test-environment defaults.
- **Steps:** Validate each payload independently; only publish through the sanctioned non-production path if runtime behavior is being measured.
- **Expected result:** `age: 18` satisfies the declared minimum; `age: 17` violates it. Runtime handling of the invalid event is TBD.
- **Observable evidence:** Separate validator result for each boundary value.
- **Failure severity:** High if the boundary is implemented incorrectly.
- **Cleanup:** Remove any published test records per environment policy.

### ASYNC-SIGNUP-007 — Non-integer `age`

- **Priority / risk:** P1; catches numeric type coercion.
- **Test level / technique:** Type partitioning; negative schema test.
- **Preconditions:** Schema validator available.
- **Message type / input:** Otherwise-valid event with `age: 18.5`.
- **Kafka metadata:** Not applicable to schema-only validation; if publishing, use test-environment defaults.
- **Steps:** Validate the payload and record whether a runtime path coerces or rejects the value in non-production.
- **Expected result:** Payload fails schema validation because `age` must be an integer. Runtime coercion/rejection behavior is TBD.
- **Observable evidence:** Validator result and, if exercised, producer/consumer observation.
- **Failure severity:** Medium; incorrect coercion may undermine the age constraint.
- **Cleanup:** Remove any published test records per environment policy.

### ASYNC-SIGNUP-008 — Invalid `userId` UUID

- **Priority / risk:** P1; identifier format validation.
- **Test level / technique:** Format equivalence partitioning.
- **Preconditions:** Validator's handling of JSON Schema `format` is configured and known.
- **Message type / input:** Otherwise-valid event with `userId: "not-a-uuid"`.
- **Kafka metadata:** Not applicable to schema-only validation; if publishing, use test-environment defaults.
- **Steps:** Validate the event with format assertion enabled; if runtime validation is in scope, publish only in non-production.
- **Expected result:** Invalid UUID is rejected when UUID format assertion is enabled. Note that JSON Schema format enforcement can vary by validator; runtime policy is TBD.
- **Observable evidence:** Validator configuration and result, plus any non-production runtime observation.
- **Failure severity:** Medium; malformed identifiers can break consumers.
- **Cleanup:** Remove any published test records per environment policy.

### ASYNC-SIGNUP-009 — Invalid `email` format

- **Priority / risk:** P1; contact field format validation.
- **Test level / technique:** Format equivalence partitioning.
- **Preconditions:** Validator's handling of JSON Schema `format` is configured and known.
- **Message type / input:** Otherwise-valid event with `email: "not-an-email"`.
- **Kafka metadata:** Not applicable to schema-only validation; if publishing, use test-environment defaults.
- **Steps:** Validate the event with format assertion enabled; if runtime validation is in scope, publish only in non-production.
- **Expected result:** Invalid email is rejected when email format assertion is enabled. Runtime policy is TBD.
- **Observable evidence:** Validator configuration and result, plus any non-production runtime observation.
- **Failure severity:** Medium; malformed email data can affect downstream processing.
- **Cleanup:** Remove any published test records per environment policy.

### ASYNC-SIGNUP-010 — Invalid `createdAt` date-time

- **Priority / risk:** P1; timestamp format validation.
- **Test level / technique:** Format equivalence partitioning.
- **Preconditions:** Validator's handling of JSON Schema `format` is configured and known.
- **Message type / input:** Otherwise-valid event with `createdAt: "yesterday"`.
- **Kafka metadata:** Not applicable to schema-only validation; if publishing, use test-environment defaults.
- **Steps:** Validate the event with format assertion enabled; if runtime validation is in scope, publish only in non-production.
- **Expected result:** Invalid date-time is rejected when date-time format assertion is enabled. Runtime policy is TBD.
- **Observable evidence:** Validator configuration and result, plus any non-production runtime observation.
- **Failure severity:** Medium; invalid timestamps can break ordering or downstream parsing.
- **Cleanup:** Remove any published test records per environment policy.

### ASYNC-SIGNUP-011 — Null required property

- **Priority / risk:** P1; distinguishes absent properties from explicit nulls.
- **Test level / technique:** Negative schema test.
- **Preconditions:** Schema validator available.
- **Message type / input:** Otherwise-valid event with `age: null`.
- **Kafka metadata:** Not applicable to schema-only validation; if publishing, use test-environment defaults.
- **Steps:** Validate the event; optionally exercise runtime validation only in non-production.
- **Expected result:** Payload fails schema validation because `age` is an integer and null is not declared as an allowed type. Runtime behavior is TBD.
- **Observable evidence:** Validator error showing the type mismatch.
- **Failure severity:** Medium.
- **Cleanup:** Remove any published test records per environment policy.

### ASYNC-SIGNUP-012 — Malformed JSON

- **Priority / risk:** P2; parser robustness.
- **Test level / technique:** Negative serialization test.
- **Preconditions:** Sanctioned non-production environment and approved malformed-message test path.
- **Message type / input:** Invalid JSON text, such as a truncated object.
- **Kafka metadata:** Use test-environment defaults; no malformed-record handling is specified.
- **Steps:** Submit the malformed record only through the approved non-production path and inspect producer, consumer, and error/DLQ evidence if configured.
- **Expected result:** JSON parsing cannot produce a payload conforming to the schema. Consumer error, retry, and dead-letter behavior are TBD.
- **Observable evidence:** Parser/validator error and broker/consumer record outcome.
- **Failure severity:** Medium; uncontrolled parser failures may disrupt consumers.
- **Cleanup:** Remove test records and restore consumer state per environment policy.

### ASYNC-SIGNUP-013 — Additional property behavior

- **Priority / risk:** P2; undeclared schema policy can cause producer/consumer incompatibility.
- **Test level / technique:** Schema robustness.
- **Preconditions:** Schema validator available.
- **Message type / input:** Otherwise-valid event with an additional property, for example `"source": "test"`.
- **Kafka metadata:** Not applicable to schema-only validation; if publishing, use test-environment defaults.
- **Steps:** Validate the event and record the result; do not interpret an outcome as contractually correct until the additional-property policy is agreed.
- **Expected result:** TBD because `additionalProperties` is not specified.
- **Observable evidence:** Validator result and configured schema version.
- **Failure severity:** Low to medium, depending on consumer compatibility requirements.
- **Cleanup:** Remove any published test records per environment policy.

### ASYNC-SIGNUP-014 — Server and topic configuration validation

- **Priority / risk:** P0; configuration may prevent connection or publication.
- **Test level / technique:** Contract/configuration validation.
- **Preconditions:** No broker connection is required for static validation; use non-production configuration for any connectivity check.
- **Message type / input:** Supplied server URL `://example.com` and channel `user/signedup`.
- **Kafka metadata:** Not applicable.
- **Steps:** Run an AsyncAPI document validator; confirm the intended Kafka bootstrap/server URL and how the channel maps to a Kafka topic; perform connectivity only after corrected values and authorization are provided.
- **Expected result:** Report the malformed URL for resolution. Confirm whether the slash-containing channel is an abstract AsyncAPI channel or intended Kafka topic name before asserting runtime validity.
- **Observable evidence:** Validator diagnostics, approved server configuration, and resolved topic mapping.
- **Failure severity:** High if unresolved configuration prevents deployment or routes events incorrectly.
- **Cleanup:** No broker resources created by static validation.

## 6. Risks and open questions

1. What is the corrected Kafka server URL, and is `production` intentionally the only server?
2. Is `user/signedup` the literal Kafka topic name, or should the channel map to a Kafka-valid topic name?
3. Should `format` constraints for UUID, email, and date-time be enforced by the runtime validator?
4. Are additional properties allowed, rejected, or ignored?
5. What are the event key, headers, partitioning, delivery/acknowledgement, ordering, and consumer-group expectations?
6. What should happen to invalid or malformed records: reject at producer, skip, retry, log, publish to a DLQ, or another defined action?
7. Are duplicate deliveries expected, and what idempotency behavior is required?
8. What non-production environment, authorization boundaries, timing targets, and cleanup policy should the tests use?
9. No upper bound is defined for `age`; no maximum payload size or string lengths are specified.

## 7. Execution notes

- First validate the AsyncAPI document and resolve the server URL and Kafka topic mapping.
- Keep schema-validation cases separate from broker delivery and consumer behavior.
- Execute malformed-message, duplicate-delivery, retry, or broker-failure tests only in a sanctioned non-production environment.
- Use synthetic identities and redact payloads in evidence.
- Record validator version/configuration, environment, topic, partition/offset, timestamps, producer result, and consumer observation for every integration run.
- Do not assert reply, correlation, timeout, retry, or dead-letter outcomes until those behaviors are specified.
