# Enterprise Order Management Service — Test Plan

## 1. Scope and assumptions

This plan is derived from [`example_2.json`](./example_2.json), an AsyncAPI 3.0.0 contract for Solace order processing. It covers the inbound order channel, its queue binding, dynamic channel parameters, request schema, correlation metadata, and the success/failure response schemas.

The companion BDD scenarios are in [`order-management.feature`](./order-management.feature).

- Inbound address: `acme/orders/v2/checkout/{region}/{storeId}`
- Queue: `Acme_Inbound_Orders_Processing_Q`
- Reply address: `acme/orders/v2/replies/{correlationId}`
- Request: `OrderPlacementRequest`
- Responses: `OrderProcessingSuccess` and `OrderProcessingFailure`
- The request message declares a correlation ID in the Solace native header `Solace_Correlation_Id`.
- The request schema does not define upper range for integer fields beyond their individual constraints. No generic 32-bit integer limit is inferred.
- The contract does not state `additionalProperties` behavior, invalid-request handling, mapping between business conditions and failure codes, retry/DLQ policy, or response timing. These remain `TBD`.
- The broker description identifies a production endpoint. Execute tests only with explicit authorization in a sanctioned non-production environment, using test credentials/certificates and synthetic data.

## 2. Contract inventory

| Area | Contract |
|---|---|
| AsyncAPI | `3.0.0` |
| Protocol / security | Solace PubSub+ over `tcps`; client certificate authentication |
| Inbound channel | `acme/orders/v2/checkout/{region}/{storeId}` |
| `region` | Enum: `US-EAST`, `US-WEST`, `EU-WEST`, `APAC-SG` |
| `storeId` | String matching `^STORE-\d{4}$` |
| Queue binding | Durable, exclusive queue `Acme_Inbound_Orders_Processing_Q`; topic subscription `acme/orders/v2/checkout/+/+`; `maxTtl` 86400000 ms |
| Reply address | `acme/orders/v2/replies/{correlationId}` |
| Reply `correlationId` | UUID-formatted string; described as mapping replies to client sessions |
| Request correlation metadata | Read from `$message.header#/Solace_Correlation_Id` |
| Request required fields | `transactionId`, `customerMetadata`, `orderItems`, `totalGrossAmount`, `submittedAt` |
| Nested customer required fields | `customerMetadata.customerId`, `customerMetadata.loyaltyTier` |
| Required item fields | `sku`, `quantity`, `unitPrice` for every item |
| `transactionId` | String, UUID |
| `customerId` | String matching `^CUST-[A-Z]{3}-\d{6}$` |
| `loyaltyTier` | Integer, 1–5 inclusive |
| `orderItems` | Array, 1–50 items |
| `sku` | String, 8–12 characters |
| `quantity` | Integer, greater than 0 and at most 999 |
| `unitPrice` | Number, at least 0.01; no maximum defined |
| `totalGrossAmount` | Number, 0.01–100000 inclusive |
| `submittedAt` | String, date-time |
| Success response | Required `transactionId`, `orderId`, `status`, `allocatedAt`; order ID pattern `^ORD-\d{10}$`; status enum `PROCESSED`, `FULFILLED`, `ROUTED_TO_WAREHOUSE`; date-time |
| Failure response | Required `transactionId`, `errorCode`, `errorMessage`, `rejectedAt`; four declared error codes; error message max 256 characters; date-time |

## 3. Runtime topology and flow

The client publishes an order to a channel address populated with an allowed `region` and matching `storeId`. The Solace binding routes matching topic messages to the durable exclusive inbound queue. The service processes the request and emits either a success or failure response on the dynamic reply address containing the request correlation identifier.

The correlation metadata and reply-address parameter are present in the contract. Verify that the client-supplied `Solace_Correlation_Id` is used consistently for the reply address and that the response `transactionId` matches the request. The response payload schemas themselves do not contain a correlation ID.

The contract does not define which business conditions cause each `errorCode`, whether schema-invalid requests produce a failure response, or how long a response may take. Do not assert those behaviors without clarification.

## 4. Coverage matrix

| Requirement / field | Coverage in feature | Test-plan reference | Status / notes |
|---|---|---|---|
| Valid end-to-end request/reply | Valid order receives correlated success reply | OMS-001 | Covered |
| Routing `region` enum | All four declared values valid; invalid `APAC` and empty value | OMS-007 | Covered |
| Routing `storeId` pattern | Valid `STORE-1234`/`STORE-0001`; invalid short, long, malformed, and empty values | OMS-007 | Covered |
| Queue destination and topic subscription | End-to-end queue receipt | OMS-001 | Covered; broker configuration evidence required |
| Correlation header / reply path | Reply address includes request correlation identifier | OMS-001, OMS-011 | Verify precise propagation with service owner |
| `transactionId` required / null / type / UUID | Missing, null, wrong type, invalid UUID | OMS-002–004, OMS-007 | Covered |
| `customerMetadata` required / null / type | Missing, null, wrong type | OMS-002–004 | Covered |
| `customerId` required / null / type / pattern / empty | Missing, null, wrong type, invalid pattern, empty | OMS-002–005, OMS-007–008 | Covered |
| `loyaltyTier` required / null / type / range | Missing, null, wrong type, 0/1/5/6 | OMS-002–006 | Covered |
| `orderItems` required / null / type / count | Missing, null, wrong type, counts 0/1/50/51 | OMS-002–004, OMS-006 | Covered |
| Item `sku` required / null / type / length / empty | Missing, null, wrong type, lengths 0/7/8/12/13 | OMS-002–005, OMS-007–008 | Covered; min/max valid boundaries should be retained in detailed regression cases |
| Item `quantity` required / null / type / range | Missing, null, wrong type, 0/1/999/1000 | OMS-002–006 | Covered |
| Item `unitPrice` required / null / type / minimum | Missing, null, wrong type, 0/0.01 | OMS-002–006 | Covered; no maximum is declared |
| `totalGrossAmount` required / null / type / bounds | Missing, null, wrong type, 0/0.01/100000/100000.01 | OMS-002–006 | Covered |
| `submittedAt` required / null / type / format | Missing, null, wrong type, invalid date-time | OMS-002–004, OMS-007 | Covered |
| Success response required fields | Omission cases for all four required fields | OMS-009 | Covered |
| Success response `orderId` pattern and status enum | Valid/invalid order ID and status | OMS-010 | Covered |
| Success `transactionId` and `allocatedAt` format/type | Invalid UUID/date-time values and null/wrong-type variants | OMS-009–010 | Covered |
| Failure response required fields | Omission cases for all four required fields | OMS-009 | Covered |
| Failure `errorCode` enum | Valid and unsupported value | OMS-010 | Covered; business-condition mapping is TBD |
| Failure `errorMessage` max length | 256/257-character examples | OMS-010 | Covered |
| Failure `rejectedAt` format/type | Invalid date-time plus null/wrong-type variants | OMS-009–010 | Covered |
| Additional properties | Not specified | — | TBD; do not assume reject/allow |
| Generic 32-bit integer overflow | No general int32 rule in schema | — | Not applicable as a contract assertion; implementation-specific check only if separately agreed |
| Invalid-message reply behavior | Not specified | — | TBD |
| Failure-code business mapping | Not specified | — | TBD; use controlled service fixtures after mapping is agreed |
| TTL, retry, redelivery, DLQ, timeout | Only queue TTL is declared; handling semantics not defined | — | Confirm before runtime assertions |

## 5. Prioritized test cases

### OMS-001 — Valid order receives a correlated success reply

- **Priority:** P0
- **Preconditions:** Authorized non-production broker; approved test certificate; queue and reply subscription ready; controlled fixture known to produce a successful order outcome.
- **Input:** Valid region/store route; UUID `transactionId`; valid customer metadata; 1–50 valid items; amount within limits; valid date-time; UUID in `Solace_Correlation_Id`.
- **Steps:** Publish to the populated inbound address; observe queue receipt; receive the response on the reply address containing the correlation identifier.
- **Expected:** Request is routed through `Acme_Inbound_Orders_Processing_Q`; success response conforms to `OrderProcessingSuccess`; reply address correlation matches the request header; response `transactionId` matches the request.
- **Evidence:** Redacted request/response, route, queue evidence, header and reply address, timestamps.
- **Risk:** High; routing or correlation failure can lose or misassociate order results.

### OMS-002 — Required properties omitted

- **Priority:** P1
- **Input variants:** Omit each required root, nested customer, and item property listed in the coverage matrix.
- **Expected:** Schema validator rejects the payload identifying the required property. Runtime reply behavior is `TBD`.
- **Technique:** One omitted property per test instance; keep all other data valid.

### OMS-003 — Required properties set to null

- **Priority:** P1
- **Input variants:** Set each required property to JSON `null`, including nested/item properties.
- **Expected:** Schema validator rejects the property because null is not declared as an accepted type. Runtime reply behavior is `TBD`.
- **Technique:** Keep this separate from property omission.

### OMS-004 — Wrong JSON types

- **Priority:** P1
- **Input variants:** Wrong types for root and nested properties (e.g. string for `totalGrossAmount`, decimal for integer `quantity`, object for `orderItems`).
- **Expected:** Schema validation fails; do not assume coercion or a runtime failure reply.

### OMS-005 — String format, pattern, and length constraints

- **Priority:** P1
- **Input variants:** Invalid transaction UUID; customer ID not matching pattern; SKU lengths 7 and 13 (and empty); store IDs not matching pattern; invalid timestamp.
- **Expected:** Schema/parameter validation rejects each invalid value. Verify exact lower/upper valid SKU lengths of 8 and 12.
- **Note:** JSON Schema `format` enforcement depends on validator configuration; record whether UUID/date-time assertions are enabled.

### OMS-006 — Numeric and collection boundaries

- **Priority:** P1
- **Input variants:** `loyaltyTier` 0/1/5/6; `quantity` 0/1/999/1000; `unitPrice` 0/0.01; `totalGrossAmount` 0/0.01/100000/100000.01; item count 0/1/50/51.
- **Expected:** Each value validates or fails according to the declared inclusive/exclusive limits.
- **Risk:** Incorrect boundary enforcement can alter pricing, allocations, or order quantities.

### OMS-007 — Dynamic channel parameter validation

- **Priority:** P1
- **Input variants:** Test all four valid `region` values plus unsupported/empty values; test valid store IDs plus short, long, malformed, and empty IDs.
- **Expected:** Valid channel parameters form a matching inbound address; invalid values are rejected by contract validation/routing configuration.
- **Evidence:** Resolved address and binding/subscription configuration.

### OMS-008 — Empty string handling for string fields

- **Priority:** P2
- **Input variants:** Empty `customerId` and item `sku`.
- **Expected:** Pattern and length constraints reject empty strings.
- **Note:** Empty-string cases are distinct from omitted and null properties.

### OMS-009 — Response required-field validation

- **Priority:** P1
- **Input variants:** For success and failure schemas separately, omit each required response property; set each required response property to null; and substitute a wrong JSON type for each required response property.
- **Expected:** Response-schema validation fails for each required-property violation.

### OMS-010 — Response enum, pattern, and length validation

- **Priority:** P1
- **Input variants:** All declared success status values and failure codes; unsupported enum values; invalid UUID/date-time response fields; invalid order ID pattern; error message lengths 256 and 257.
- **Expected:** Declared enum values and valid formats validate; invalid formats, unsupported enum values, and over-limit error messages fail.
- **Note:** The contract does not associate a specific business condition with a particular failure code.

### OMS-011 — Correlation isolation for concurrent requests

- **Priority:** P1
- **Preconditions:** Service owner confirms the exact mapping from the Solace header to reply address.
- **Input:** Two concurrent valid requests with distinct correlation IDs and transaction IDs.
- **Expected:** Each reply is delivered on the address containing its own correlation ID and carries its own transaction ID; no cross-association.
- **Status:** Contract-derived routing intent; confirm implementation mapping before treating as executable acceptance.

## 6. Risks and open questions

1. What validation/runtime outcome is expected when a malformed request reaches the broker? Is a failure response emitted, or is the message rejected/otherwise handled?
2. Is the reply address always built using the exact `Solace_Correlation_Id` header value?
3. Which business conditions map to each failure error code?
4. Is `additionalProperties` allowed or rejected on request and response objects?
5. How do acknowledgement, retry, redelivery, expiration after the declared 24-hour TTL, and DLQ behavior work?
6. What response-time target applies?
7. Are `format` keywords enforced by the production validator, and which JSON Schema dialect/validator configuration is used?
8. Does `totalGrossAmount` need to equal the sum of item quantity × unit price, with what rounding/tolerance? No such invariant is stated in this schema.
9. Is any implementation-specific integer range required for fields typed as `integer`? The schema does not define a universal 32-bit limit.

## 7. Execution notes

- Run broker-level cases only in an authorized non-production environment; never use the production endpoint without explicit approval.
- Use synthetic order/customer data and approved test certificates. Do not store certificate material in the test artifacts.
- Isolate each test's correlation ID, transaction ID, route, and queue evidence.
- Validate the JSON contract separately from broker delivery behavior.
- Capture validator version/configuration, resolved topic, queue name, correlation header, reply address, timestamps, and redacted payloads.
- Clean up only test-owned queues/messages according to environment policy; account for the configured 24-hour message TTL.
