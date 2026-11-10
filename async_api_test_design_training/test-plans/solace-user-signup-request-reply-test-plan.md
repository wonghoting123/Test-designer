# Solace User Signup Request/Reply Test Plan

## 1. Scope and assumptions

This example is based on a Solace request/reply flow for user signup processing.

- Request topic: `user/signup/v1`
- Reply topic: `user/signup/reply/v1`
- Request payload contract: `UserSignedUp`
- Response payload contract: `UserSignedUpResponse`
- The request is delivered through a queue bound to the topic subscription.
- The response is expected on the configured reply channel.
- For the runtime behavior specified for this example, an `age` above the signed 32-bit integer maximum (`2147483647`) returns a response with status `FAILED`. This is an implementation/business rule; the request schema itself does not declare an upper bound for `age`.
- The contract defines the request and response payload schemas, but it does not explicitly define correlation headers, JMS `ReplyTo` semantics, timeout values, retry policy, or duplicate-handling behavior.
- Where runtime behavior is not explicit in the contract, the expected outcome should be limited to schema validation and reply-channel routing, or explicitly marked as `TBD`.

## 2. Contract inventory

| Element | Contract |
|---|---|
| AsyncAPI version | `3.0.0` |
| Service | `User Signup Service (Solace Request-Reply)` |
| Request channel | `user/signup/v1` |
| Reply channel | `user/signup/reply/v1` |
| Broker protocol | Solace PubSub+ |
| Request destination type | queue bound to topic subscription |
| Request payload | `UserSignedUp` |
| Response payload | `UserSignedUpResponse` |
| Request required fields | `userId`, `username`, `email`, `age`, `accountTier`, `createdAt` |
| Response required fields | `userId`, `status`, `processedAt` |
| `userId` | string, UUID |
| `username` | string, 3-20 chars |
| `email` | string, email |
| `age` | integer, minimum 18 |
| `age` runtime range | Signed 32-bit maximum `2147483647`; values above it return `FAILED` (runtime rule, not expressed in the schema) |
| `accountTier` | integer, minimum 1, maximum 5 |
| `createdAt` | string, date-time |
| response status | enum `SUCCESS`, `FAILED` |
| correlation contract | not explicitly defined |
| timeout/retry/DLQ | not explicitly defined |

## 3. Runtime topology and async flow

The client publishes a `UserSignedUp` request to the request topic. The broker routes it through the queue `UserSignupQueue`, which is bound to `user/signup/v1`. The consumer reads the request from the queue, validates it, and then publishes a response to the reply channel `user/signup/reply/v1`.

The important contract distinction is that the request and response are routed separately even though they belong to the same business transaction.

The AsyncAPI document does not define whether the broker uses a correlation ID, `JMSCorrelationID`, `JMSReplyTo`, or a static reply destination. Because of that, the test design should assert the reply channel path and payload matching, while treating correlation metadata as contract-TBD unless it is later explicitly specified.

## 4. Coverage matrix

| Area | Coverage | Priority |
|---|---|---|
| Valid request handling | Request accepted and success response returned | P0 |
| Required fields and invalid representations | Missing and null for each required field; empty-string `age` type mismatch | P1 |
| Boundary validation | Username min/max, age minimum, accountTier min/max | P1 |
| Integer runtime boundary | `age` above signed 32-bit maximum returns `FAILED` on the reply channel | P1 |
| Format validation | UUID, email, date-time | P1 |
| Response contract | Success/failed status and required response fields | P0 |
| Reply routing | Response returns on the correct channel | P0 |
| Correlation semantics | Match request and reply by explicit contract; currently TBD | P1 |
| Timeout/retry/duplicate | Not specified in contract; keep as contract-TBD | P2 |

## 5. Prioritized test cases

### ASYNC-USER-SIGNUP-001 — Valid request receives success acknowledgement

- Priority: P0
- Preconditions: broker available; queue and reply channel configured; consumer listening
- Message type: request/response
- Input: valid request payload with `userId`, `username`, `email`, `age`, `accountTier`, and `createdAt`
- Reply expectation: response on `user/signup/reply/v1`, status `SUCCESS`, same `userId`, valid `processedAt`
- Steps:
  1. Publish request to `user/signup/v1`.
  2. Observe queue consumption.
  3. Read reply from `user/signup/reply/v1`.
- Expected result: request accepted; reply schema valid; status `SUCCESS`.
- Observable evidence: queue message count, broker receipt log, response payload.
- Risk: high; valid requests must not be rejected.

### ASYNC-USER-SIGNUP-002 — Missing `username`

- Priority: P1
- Preconditions: valid environment; contract validation configured
- Input: valid payload with `username` omitted
- Expected result: request rejected or result corresponds to documented invalid-request handling; if a response is returned, it must conform to `UserSignedUpResponse` schema.
- Observable evidence: validation error or reply payload showing failure status.
- Risk: medium-high because missing identity data may prevent processing.

### ASYNC-USER-SIGNUP-003 — Null `age`

- Priority: P1
- Preconditions: same as above
- Input: `age: null`
- Expected result: schema validation fails because `age` is present but null; request is not accepted.
- Observable evidence: validator result and any failure response.
- Risk: medium-high; null values can bypass some validation logic.

### ASYNC-USER-SIGNUP-004 — Age below minimum boundary

- Priority: P1
- Preconditions: schema validator or service contract available
- Input: `age: 17`
- Expected result: invalid because minimum is 18.
- Observable evidence: validation error or failed response.
- Risk: high because this is a core business rule.

### ASYNC-USER-SIGNUP-005 — accountTier outside allowed range

- Priority: P1
- Preconditions: same as above
- Input: `accountTier: 0` and `accountTier: 6`
- Expected result: validation failure because range is 1 to 5.
- Observable evidence: validation result, failed response if emitted.
- Risk: medium-high; incorrect tier assignment affects downstream account logic.

### ASYNC-USER-SIGNUP-006 — Invalid email format

- Priority: P1
- Preconditions: schema validator enabled
- Input: `email: "not-an-email"`
- Expected result: invalid email rejected.
- Observable evidence: validation error or failed response.
- Risk: medium.

### ASYNC-USER-SIGNUP-007 — Invalid UUID format for `userId`

- Priority: P1
- Preconditions: same as above
- Input: `userId: "not-a-uuid"`
- Expected result: validation fails because UUID format is invalid.
- Observable evidence: validation error or failed response.
- Risk: medium.

### ASYNC-USER-SIGNUP-008 — Invalid date-time for `createdAt`

- Priority: P1
- Preconditions: same as above
- Input: `createdAt: "not-a-date-time"`
- Expected result: validation fails because date-time format is invalid.
- Observable evidence: validator result and/or failed response.
- Risk: medium.

### ASYNC-USER-SIGNUP-009 — Reply matches the request

- Priority: P0
- Preconditions: valid request, reply channel available
- Input: valid signup request
- Expected result: reply published on `user/signup/reply/v1` and includes the same `userId` as the request.
- Observable evidence: response payload and route metadata.
- Risk: high because incorrect reply routing makes the request/reply flow unusable.

### ASYNC-USER-SIGNUP-010 — Contract gap: correlation semantics

- Priority: P1
- Preconditions: service owner confirms broker semantics
- Input: two concurrent valid requests with distinct `userId` values
- Expected result: if correlation metadata is defined, each response matches the originating request; if not, keep as contract-TBD.
- Observable evidence: correlation metadata in request/response or broker routing logs.
- Risk: high because cross-correlation would break request handling.

### ASYNC-USER-SIGNUP-011 — Age exceeds signed 32-bit integer maximum

- Priority: P1
- Preconditions: broker available; queue and reply channel configured; consumer listening
- Input: otherwise-valid request with `age: 2147483648` (one greater than `2147483647`)
- Steps:
  1. Publish the request to `user/signup/v1`.
  2. Read the response from `user/signup/reply/v1`.
- Expected result: response status is `FAILED`; response contains the same `userId` and a valid `processedAt` date-time.
- Observable evidence: request payload and reply payload, including destination and timestamp.
- Risk: high if integer overflow is silently accepted, coerced, or reported as successful.
- Note: the AsyncAPI payload schema allows integers above this value because it declares no `maximum`; this case verifies the separately agreed runtime behavior.

### ASYNC-USER-SIGNUP-012 — Missing `age`

- Priority: P1
- Preconditions: broker available; queue and reply channel configured; consumer listening
- Input: otherwise-valid request with `age` omitted
- Expected result: schema validation fails because `age` is required; the service follows the documented invalid-request behavior. A specific response status is not asserted unless that behavior is confirmed.
- Observable evidence: validation result and any response received on `user/signup/reply/v1`.
- Risk: medium-high; missing age must not be accepted as a valid signup.

### ASYNC-USER-SIGNUP-013 — Empty-string `age`

- Priority: P1
- Preconditions: broker available; queue and reply channel configured; consumer listening
- Input: otherwise-valid request with `age: ""`
- Expected result: schema validation fails because `age` must be an integer; the service follows the documented invalid-request behavior. A specific response status is not asserted unless that behavior is confirmed.
- Observable evidence: validation result and any response received on `user/signup/reply/v1`.
- Risk: medium; string coercion could result in unintended acceptance.

## 6. Risks and open questions

1. Does the `FAILED` status apply to other invalid request types, or only to cases with explicitly defined failed-response behavior such as an age over the signed 32-bit range?
2. Is a correlation ID or reply-to field required and how is it propagated?
3. Does the service send a reply for every invalid request or only for valid ones?
4. What is the timeout window and what should happen to a late reply?
5. Are duplicate requests or duplicate responses expected, and how are they deduplicated?
6. What is the exact broker-level delivery semantics for queue consumption and reply publication?

## 7. Execution notes

- Validate the contract in a sanctioned non-production environment first.
- Keep request validation and reply-channel verification separate.
- Record queue name, reply topic, payloads, timestamps, and any broker metadata.
- Use synthetic or redacted test data only.
- If correlation semantics are not declared, do not assume them; mark as `TBD` and confirm with the service owner.
