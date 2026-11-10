@async @acceptance @contract
Feature: Submit an order and receive its processing outcome
  As an order client
  I want to submit an order to the region and store-specific checkout topic
  So that I receive the processing outcome associated with my request

  Background:
    Given the request and response schemas from the AsyncAPI contract are available to the test suite

  @smoke @reply @correlation @OMS001
  Scenario: A valid order is processed and its success reply matches the request
    Given the service is available in an authorized non-production Solace environment
    And the client is authenticated with an approved test certificate
    And the client is subscribed to the reply channel for its correlation identifier
    And the inbound queue "Acme_Inbound_Orders_Processing_Q" is available
    And the test fixture is prepared to successfully process a valid order
    And the order request uses region "US-EAST" and store "STORE-1234"
    And the request payload is:
      """
      {
        "transactionId": "123e4567-e89b-12d3-a456-426614174000",
        "customerMetadata": {
          "customerId": "CUST-ABC-123456",
          "loyaltyTier": 3
        },
        "orderItems": [
          {
            "sku": "SKU-12345",
            "quantity": 2,
            "unitPrice": 12.50
          }
        ],
        "totalGrossAmount": 25.00,
        "submittedAt": "2026-11-10T12:34:56Z"
      }
      """
    And the Solace correlation header is "223e4567-e89b-12d3-a456-426614174000"
    When the client publishes the request to the matching checkout topic
    Then the request is received through "Acme_Inbound_Orders_Processing_Q"
    And a valid success response is published on the reply channel containing the correlation identifier
    And the response transactionId matches the request transactionId
    And the response status is one of "PROCESSED", "FULFILLED", or "ROUTED_TO_WAREHOUSE"

  @contract @negative @required @OMS002
  Scenario Outline: An order request missing a required property fails schema validation
    Given an otherwise valid order request with <property> omitted
    When the request is validated against the OrderPlacementRequest schema
    Then schema validation fails because <property> is required

    Examples:
      | property                         |
      | transactionId                    |
      | customerMetadata                 |
      | orderItems                       |
      | totalGrossAmount                 |
      | submittedAt                      |
      | customerMetadata.customerId      |
      | customerMetadata.loyaltyTier     |
      | orderItems[0].sku                |
      | orderItems[0].quantity           |
      | orderItems[0].unitPrice          |

  @contract @negative @type @OMS003
  Scenario Outline: A required order property set to null fails schema validation
    Given an otherwise valid order request with <property> set to null
    When the request is validated against the OrderPlacementRequest schema
    Then schema validation fails because <property> does not allow null

    Examples:
      | property                         |
      | transactionId                    |
      | customerMetadata                 |
      | orderItems                       |
      | totalGrossAmount                 |
      | submittedAt                      |
      | customerMetadata.customerId      |
      | customerMetadata.loyaltyTier     |
      | orderItems[0].sku                |
      | orderItems[0].quantity           |
      | orderItems[0].unitPrice          |

  @contract @negative @type @OMS004
  Scenario Outline: An order field with the wrong JSON type fails schema validation
    Given an otherwise valid order request where <property> uses invalid representation <wrong_type>
    When the request is validated against the OrderPlacementRequest schema
    Then schema validation fails for <property>

    Examples:
      | property             | wrong_type |
      | transactionId        | number     |
      | transactionId        | empty string |
      | customerMetadata     | string     |
      | customerMetadata     | empty string |
      | orderItems           | object     |
      | orderItems           | empty string |
      | totalGrossAmount     | string     |
      | totalGrossAmount     | empty string |
      | submittedAt          | boolean    |
      | submittedAt          | empty string |
      | customerId           | array      |
      | loyaltyTier          | string     |
      | loyaltyTier          | empty string |
      | sku                  | number     |
      | quantity             | decimal    |
      | quantity             | empty string |
      | unitPrice            | boolean    |
      | unitPrice            | empty string |

  @contract @boundary @OMS006
  Scenario Outline: Order item and amount values obey their declared boundaries
    Given an otherwise valid order request with <property> set to <value>
    When the request is validated against the OrderPlacementRequest schema
    Then the request is <validation_result>

    Examples:
      | property                   | value     | validation_result |
      | customerMetadata.loyaltyTier | 1       | valid             |
      | customerMetadata.loyaltyTier | 5       | valid             |
      | customerMetadata.loyaltyTier | 0       | invalid           |
      | customerMetadata.loyaltyTier | 6       | invalid           |
      | orderItems[0].quantity       | 1       | valid             |
      | orderItems[0].quantity       | 999     | valid             |
      | orderItems[0].quantity       | 0       | invalid           |
      | orderItems[0].quantity       | 1000    | invalid           |
      | orderItems[0].unitPrice      | 0.01    | valid             |
      | orderItems[0].unitPrice      | 0       | invalid           |
      | totalGrossAmount             | 0.01    | valid             |
      | totalGrossAmount             | 100000  | valid             |
      | totalGrossAmount             | 0       | invalid           |
      | totalGrossAmount             | 100000.01 | invalid         |

  @contract @boundary @OMS006
  Scenario Outline: The order item count obeys its declared boundaries
    Given an otherwise valid order request with <count> order items
    When the request is validated against the OrderPlacementRequest schema
    Then the request is <validation_result>

    Examples:
      | count | validation_result |
      | 0     | invalid           |
      | 1     | valid             |
      | 50    | valid             |
      | 51    | invalid           |

  @contract @format @OMS005 @OMS007
  Scenario Outline: Request identifiers, routing parameters, and timestamps obey their formats
    Given an otherwise valid order request with <field> set to <value>
    When the request or channel parameters are validated against the contract
    Then the value is <validation_result>

    Examples:
      | field              | value                 | validation_result |
      | transactionId      | not-a-uuid            | invalid           |
      | customerId         | CUST-ABC-123456       | valid             |
      | customerId         | CUST-ab-123456        | invalid           |
      | sku                | ABCDEFGH              | valid             |
      | sku                | ABCDEFGHIJKL          | valid             |
      | sku                | ABCDEFG               | invalid           |
      | sku                | ABCDEFGHIJKLM         | invalid           |
      | submittedAt        | not-a-date-time       | invalid           |
      | submittedAt        | ""                    | invalid           |
      | correlationId      | not-a-uuid            | invalid           |
      | correlationId      | ""                    | invalid           |
      | storeId            | STORE-1234            | valid             |
      | storeId            | STORE-0001            | valid             |
      | storeId            | STORE-123              | invalid           |
      | storeId            | STORE-12345           | invalid           |
      | storeId            | STORE-12A4            | invalid           |
      | storeId            | ""                    | invalid           |
      | region             | US-EAST               | valid             |
      | region             | US-WEST               | valid             |
      | region             | EU-WEST               | valid             |
      | region             | APAC-SG               | valid             |
      | region             | APAC                  | invalid           |
      | region             | ""                    | invalid           |

  @contract @boundary @OMS008
  Scenario Outline: An empty or oversized order string fails validation
    Given an otherwise valid order request with <field> set to <value>
    When the request is validated against the OrderPlacementRequest schema
    Then the request is <validation_result>

    Examples:
      | field             | value                 | validation_result |
      | customerId        | ""                    | invalid           |
      | sku               | ""                    | invalid           |
      | sku               | ABCDEFGHIJKLM         | invalid           |

  @async @reply @failure @contract @OMS010
  Scenario: A failure response conforms to the declared failure schema
    Given the service is available in an authorized non-production Solace environment
    And the client is authenticated with an approved test certificate
    And the client is subscribed to the reply channel for its correlation identifier
    And a valid request in a test fixture that produces a declared business failure
    When the service processes the request
    Then a failure response is published on the reply channel identified by the request correlation header
    And the response transactionId matches the request transactionId
    And the response errorCode is one of the declared failure codes
    And the errorMessage contains no more than 256 characters
    And rejectedAt is a valid date-time value

  @contract @response @OMS009
  Scenario Outline: A success response missing a required property fails response-schema validation
    Given an otherwise valid OrderProcessingSuccess response with <property> omitted
    When the response is validated against the OrderProcessingSuccess schema
    Then schema validation fails because <property> is required

    Examples:
      | property      |
      | transactionId |
      | orderId       |
      | status        |
      | allocatedAt   |

  @contract @response @OMS009
  Scenario Outline: A failure response missing a required property fails response-schema validation
    Given an otherwise valid OrderProcessingFailure response with <property> omitted
    When the response is validated against the OrderProcessingFailure schema
    Then schema validation fails because <property> is required

    Examples:
      | property      |
      | transactionId |
      | errorCode     |
      | errorMessage  |
      | rejectedAt    |

  @contract @response @OMS010
  Scenario Outline: Response values conform to their declared enum and pattern
    Given an otherwise valid <message> response with <property> set to <value>
    When the response is validated against its message schema
    Then the response is <validation_result>

    Examples:
      | message                  | property    | value                 | validation_result |
      | OrderProcessingSuccess   | orderId     | ORD-1234567890        | valid             |
      | OrderProcessingSuccess   | orderId     | ORD-123               | invalid           |
      | OrderProcessingSuccess   | status      | PROCESSED             | valid             |
      | OrderProcessingSuccess   | status      | FULFILLED             | valid             |
      | OrderProcessingSuccess   | status      | ROUTED_TO_WAREHOUSE   | valid             |
      | OrderProcessingSuccess   | status      | UNKNOWN               | invalid           |
      | OrderProcessingFailure   | errorCode   | ERR_INSUFFICIENT_STOCK | valid            |
      | OrderProcessingFailure   | errorCode   | ERR_INVALID_SKU       | valid             |
      | OrderProcessingFailure   | errorCode   | ERR_CREDIT_DENIED     | valid             |
      | OrderProcessingFailure   | errorCode   | ERR_GATEWAY_TIMEOUT   | valid             |
      | OrderProcessingFailure   | errorCode   | ERR_UNKNOWN           | invalid           |
      | OrderProcessingSuccess   | transactionId | not-a-uuid          | invalid           |
      | OrderProcessingSuccess   | allocatedAt | not-a-date-time       | invalid           |
      | OrderProcessingFailure   | transactionId | not-a-uuid          | invalid           |
      | OrderProcessingFailure   | rejectedAt  | not-a-date-time       | invalid           |

  @contract @response @boundary @OMS010
  Scenario Outline: A failure response error message obeys its maximum length
    Given an otherwise valid OrderProcessingFailure response with an errorMessage of <length> characters
    When the response is validated against the OrderProcessingFailure schema
    Then the response is <validation_result>

    Examples:
      | length | validation_result |
      | 256    | valid             |
      | 257    | invalid           |

  @contract @negative @response @OMS009
  Scenario Outline: A required response property set to null fails schema validation
    Given an otherwise valid <message> response with <property> set to null
    When the response is validated against its message schema
    Then schema validation fails because <property> does not allow null

    Examples:
      | message                | property      |
      | OrderProcessingSuccess | transactionId |
      | OrderProcessingSuccess | orderId       |
      | OrderProcessingSuccess | status        |
      | OrderProcessingSuccess | allocatedAt   |
      | OrderProcessingFailure | transactionId |
      | OrderProcessingFailure | errorCode     |
      | OrderProcessingFailure | errorMessage  |
      | OrderProcessingFailure | rejectedAt    |

  @contract @negative @type @response @OMS009
  Scenario Outline: A response property with the wrong type fails schema validation
    Given an otherwise valid <message> response with <property> set to a <wrong_type>
    When the response is validated against its message schema
    Then schema validation fails for <property>

    Examples:
      | message                | property      | wrong_type |
      | OrderProcessingSuccess | transactionId | number     |
      | OrderProcessingSuccess | orderId       | number     |
      | OrderProcessingSuccess | status        | number     |
      | OrderProcessingSuccess | allocatedAt   | boolean    |
      | OrderProcessingFailure | transactionId | number     |
      | OrderProcessingFailure | errorCode     | array      |
      | OrderProcessingFailure | errorMessage  | number     |
      | OrderProcessingFailure | rejectedAt    | boolean    |

  @async @reply @correlation @OMS011
  Scenario: Concurrent order replies are routed to their originating correlation addresses
    Given the service is available in an authorized non-production Solace environment
    And the client is authenticated with an approved test certificate
    And the client is subscribed to the reply channels for both correlation identifiers
    And two valid order requests with different transactionIds and Solace correlation identifiers
    When the client publishes both requests to their respective inbound topics
    Then each response is published on the reply address containing its own correlation identifier
    And each response transactionId matches its originating request
    And neither response is associated with the other request

  # Design notes:
  # - Schema-only cases use a contract validator; they do not assert undocumented service
  #   behavior for invalid messages.
  # - The contract defines the Solace correlation header and a reply topic parameter, but the
  #   precise header-to-reply-address propagation must be verified with the service owner.
  # - The contract does not define which business conditions produce each failure code.
  # - No generic int32 limit is inferred for integer fields; test only the bounds explicitly
  #   declared by this schema unless an implementation-specific range is agreed.
  # - Run broker, malformed-input, and failure-path checks only in an authorized non-production
  #   environment with synthetic data.
