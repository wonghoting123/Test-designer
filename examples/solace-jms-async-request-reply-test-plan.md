# Worked example: Solace JMS asynchronous request/reply test plan

> **Illustrative only.** This example demonstrates test design, not a claim about a particular service or Solace deployment. The schema, limits, rejection behavior, destinations, and timing below are example assumptions. Replace them with the real contract before execution. Use an authorized non-production environment.

## 1. Scenario and assumptions

A requester publishes an order request to `demo/orders/request`. A service processes it and publishes a reply to `demo/orders/reply`. The requester matches the response by `JMSCorrelationID`.

Example assumptions to validate with the system owner:

- The requester is subscribed and ready before publishing.
- Both endpoints are topics; the reply topic is configured for the test rather than inferred from `JMSReplyTo`.
- The request and response carry JSON.
- `requestId` is required and unique per request. The response echoes it.
- `JMSCorrelationID` is set on the request and copied to the response.
- Invalid requests produce a defined validation error response. If the real system instead rejects, acknowledges, or dead-letters messages, change those expected results.
- Example constraints: `amount` is greater than 0 and at most 100000.00; `currency` is one of `USD`, `EUR`, `GBP`; `priority` is `NORMAL` or `HIGH`; `quantity` is an integer from 1 through 999.
- Illustrative response target: within 5 seconds in the designated test environment. Replace with an agreed SLA and measurement method.

## 2. Example request contract (JSON Schema 2020-12)

This compact schema is for demonstrating case design. A production schema should define its actual policies, including unknown fields and formats.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "OrderRequest",
  "type": "object",
  "additionalProperties": false,
  "required": ["requestId", "customerId", "orderId", "amount", "currency", "priority", "payload"],
  "properties": {
    "requestId": { "type": "string", "minLength": 1, "maxLength": 64 },
    "customerId": { "type": "string", "minLength": 1, "maxLength": 64 },
    "orderId": { "type": "string", "minLength": 1, "maxLength": 64 },
    "amount": { "type": "number", "exclusiveMinimum": 0, "maximum": 100000, "multipleOf": 0.01 },
    "currency": { "type": "string", "enum": ["USD", "EUR", "GBP"] },
    "priority": { "type": "string", "enum": ["NORMAL", "HIGH"] },
    "payload": {
      "type": "object",
      "additionalProperties": false,
      "required": ["itemCode", "quantity"],
      "properties": {
        "itemCode": { "type": "string", "minLength": 1, "maxLength": 32 },
        "quantity": { "type": "integer", "minimum": 1, "maximum": 999 }
      }
    }
  }
}
```

## 3. Example response contract

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "additionalProperties": false,
  "required": ["requestId", "status", "orderId"],
  "properties": {
    "requestId": { "type": "string", "minLength": 1 },
    "status": { "type": "string", "enum": ["ACCEPTED", "REJECTED"] },
    "orderId": { "type": "string", "minLength": 1 },
    "acceptedAmount": { "type": "number", "minimum": 0 },
    "currency": { "type": "string", "enum": ["USD", "EUR", "GBP"] },
    "message": { "type": "string" }
  }
}
```

The schema alone does not determine all business semantics. For example, whether an error reply includes `orderId`, or whether a rejected request is represented by a response or a broker-level error, must come from the API contract.

## 4. Example test data

Valid request:

```json
{
  "requestId": "REQ-1001",
  "customerId": "CUST-001",
  "orderId": "ORD-88321",
  "amount": 1250.50,
  "currency": "USD",
  "priority": "HIGH",
  "payload": { "itemCode": "SKU-123", "quantity": 2 }
}
```

JMS metadata example: request has `JMSCorrelationID = "corr-REQ-1001"`; the response is expected to carry the same value. Destination and property setup must follow the actual service contract.

## 5. Sample cases

| ID | Priority | Test variation | Expected result (under stated assumptions) |
|---|---|---|---|
| ASYNC-REQ-001 | P1 | Valid request; valid correlation ID | One accepted response on configured reply topic within agreed window; response schema valid; correlation ID and request identity match. |
| ASYNC-REQ-002 | P1 | Omit each required top-level field, one case per field | Validation outcome matches documented invalid-request policy; no accepted response or unintended order side effect. |
| ASYNC-REQ-003 | P1 | Omit `payload.quantity` | Validation outcome matches policy; no accepted order side effect. |
| ASYNC-REQ-004 | P1 | `amount`: `0`, `-0.01`, `0.01`, `100000`, `100000.01` | Respect exclusive minimum, precision, and inclusive maximum; positive values in range accepted, outside invalid. |
| ASYNC-REQ-005 | P1 | `quantity`: `0`, `1`, `999`, `1000` | Respect inclusive range; only 1 through 999 valid. |
| ASYNC-REQ-006 | P1 | Wrong types: amount as string, quantity as decimal, currency as array, payload as null | Reject according to validation contract; no silent type coercion unless explicitly specified. |
| ASYNC-REQ-007 | P1 | `currency` and `priority` outside enum; each allowed enum value | Allowed values accepted; unsupported values handled as invalid. |
| ASYNC-REQ-008 | P2 | String lengths at 0, 1, 64, 65 for `requestId`; 32/33 for `itemCode` | Enforce the specified min/max lengths, with no undocumented truncation. |
| ASYNC-REQ-009 | P2 | Null, empty, whitespace-only for string fields | Validate nullability/blank semantics from contract; do not assume empty and whitespace are equivalent. |
| ASYNC-REQ-010 | P2 | Unknown top-level and nested properties | Reject because this example schema sets `additionalProperties: false`; revise if actual schema permits extensions. |
| ASYNC-REQ-011 | P1 | Malformed JSON and empty body | Follow documented parser/error handling; verify no accepted business side effect and inspect approved error observability. |
| ASYNC-REQ-012 | P1 | Response missing required `status`, unknown status, wrong field type | Response consumer flags contract violation; capture the response and correlation details safely. |
| ASYNC-REQ-013 | P1 | Two concurrent requests with distinct correlation IDs and distinguishable order IDs | Each requester receives only its own response; no cross-correlation. |
| ASYNC-REQ-014 | P1 | Response with unmatched correlation ID | Do not associate it to an in-flight request; verify documented unmatched-message handling. |
| ASYNC-REQ-015 | P2 | Duplicate request or duplicate response | Verify documented idempotency/deduplication behavior; no unapproved duplicate business effect. |
| ASYNC-REQ-016 | P1 | No response within timeout; then late response | Verify configured timeout/retry behavior and that late replies are handled without corrupting another request. |
| ASYNC-REQ-017 | P2 | Reply destination/subscription unavailable or requester not yet subscribed | Verify the actual routing/readiness design and recovery behavior; avoid assuming a topic retains messages. |
| ASYNC-REQ-018 | P2 | Expired message / TTL at configured boundary | Verify expiry behavior and observability according to broker and application configuration. |

Cases involving invalid payloads, retries, duplicate delivery, or broker failure require an isolated authorized test environment and safe test data. Do not run them against production by default.

## 6. Example coverage map

| Contract/risk | Cases | Technique |
|---|---|---|
| Required request fields | 002–003 | Requirement-based, negative testing |
| Numeric and collection boundaries | 004–005, 008 | Boundary-value analysis |
| Types, nullability, enum, additional properties | 006–010 | Equivalence partitioning, schema testing |
| Response contract | 012 | Schema/contract testing |
| Routing and correlation | 001, 013–014, 017 | Integration, state-transition/concurrency testing |
| Failure timing, duplication, expiration | 015–016, 018 | State-transition, negative, resilience testing |

## 7. Execution and reporting notes

For each integration case, capture test ID, environment, request ID, correlation ID, publish timestamp, reply timestamp, destination, relevant JMS properties, payload validation result, and cleanup result. Redact credentials and sensitive payload data. Define timeout measurement, retry policy, and allowed clock skew before execution. Record actual behavior separately from expected behavior; raise a contract question if the documented policy is missing.
