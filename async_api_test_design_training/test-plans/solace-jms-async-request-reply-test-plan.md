# Solace JMS asynchronous request/reply test plan example

This example shows how a test-designer agent should reason about a Solace JMS request/reply API.

## Example scenario

A client publishes a request message to a topic named `demo.orders.request`.
A service consumes the message and publishes the response to `demo.orders.reply`.
The request carries a correlation identifier, and the response is expected to use the same correlation identifier so the client can match the correct reply. The actual contract may use a different destination or a queue; this example is illustrative only.

## Example assumptions

- payload format is JSON
- request message contract is known
- reply message contract is known
- missing required fields should be rejected
- invalid enum values should be rejected
- no response within SLA should trigger defined recovery behavior
- duplicate response handling is expected to be idempotent

## Example request schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "additionalProperties": false,
  "required": ["requestId", "customerId", "amount", "currency", "priority"],
  "properties": {
    "requestId": { "type": "string", "minLength": 1, "maxLength": 64 },
    "customerId": { "type": "string", "minLength": 1, "maxLength": 64 },
    "amount": { "type": "number", "exclusiveMinimum": 0, "maximum": 100000 },
    "currency": { "type": "string", "enum": ["USD", "EUR", "GBP"] },
    "priority": { "type": "string", "enum": ["NORMAL", "HIGH"] }
  }
}
```

## Example response schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "additionalProperties": false,
  "required": ["requestId", "status"],
  "properties": {
    "requestId": { "type": "string", "minLength": 1 },
    "status": { "type": "string", "enum": ["ACCEPTED", "REJECTED"] },
    "message": { "type": "string" }
  }
}
```

## Example test categories

### Mandatory field tests

- request missing `requestId`
- request missing `customerId`
- request missing `amount`
- request missing `currency`
- request missing `priority`
- request with empty `requestId`
- request with blank `currency`

### Boundary tests

- `amount = 0`
- `amount = 0.01`
- `amount = 100000`
- `amount = 100000.01`
- `requestId` max length and max length + 1
- `customerId` empty, short, and max-length edge values

### Invalid data tests

- `amount` as string
- `currency` as array
- `priority` as null
- unsupported enum value
- unknown additional property
- malformed JSON payload
- oversized payload

### Async flow tests

- valid request receives valid response on expected topic
- response uses same correlation ID as request
- request with wrong/missing correlation ID is rejected or ignored
- two concurrent requests do not receive each other's replies
- late reply after timeout is handled correctly
- duplicate reply is handled according to contract

## Example test cases

| ID | Scenario | Expected result |
|---|---|---|
| ASYNC-EX-001 | Valid request with valid correlation ID | Response is received on expected reply topic within SLA and matches schema |
| ASYNC-EX-002 | Missing `requestId` | Request is rejected or error response is emitted; no accepted business effect |
| ASYNC-EX-003 | `amount = 0` | Rejected or treated as invalid according to the contract |
| ASYNC-EX-004 | `amount = 100000.01` | Rejected because above maximum |
| ASYNC-EX-005 | `currency = "JPY"` | Rejected due to enum mismatch |
| ASYNC-EX-006 | `priority = null` | Rejected or schema error returned |
| ASYNC-EX-007 | Response with mismatched correlation ID | Not associated with original request; handled as mismatched/unmatched |
| ASYNC-EX-008 | Duplicate response for same request | Idempotent handling or documented duplicate rejection |
| ASYNC-EX-009 | No response before timeout | Timeout flow triggered according to contract |
| ASYNC-EX-010 | Concurrent valid requests | Each request matches its own response without cross-corruption |

## Key learning point

The test designer must not stop at "happy path" coverage. For async APIs, the most important failure modes are usually:

- correlation mismatch
- missing or late reply
- wrong reply destination
- unexpected validator behavior
- duplicate or out-of-order messages
- timeout/retry handling

A high-quality agent should always design around those realities.
