@async @acceptance @contract
Feature: Process a user signup request and return an acknowledgement on the reply channel
  As a client of the User Signup Service
  I want to submit a valid signup request and receive a result on the configured reply channel
  So that I know whether the signup request was accepted or rejected

  Background:
    Given the Solace broker is reachable in an authorized test environment
    And the queue "UserSignupQueue" exists and is durable
    And the queue is subscribed to topic "user/signup/v1"
    And the reply channel "user/signup/reply/v1" is available for the consumer
    And the consumer is ready to receive both the request and the reply

  @smoke
  Scenario: A valid signup request is accepted and an acknowledgement is returned
    Given a signup request payload with:
      | userId      | 123e4567-e89b-12d3-a456-426614174000 |
      | username    | alice                               |
      | email       | alice@example.com                   |
      | age         | 28                                  |
      | accountTier | 3                                   |
      | createdAt   | 2026-11-10T12:34:56Z                |
    When the client publishes the request to "user/signup/v1"
    Then the service consumes the request from "UserSignupQueue"
    And the service publishes a valid response on "user/signup/reply/v1"
    And the response payload contains the same userId
    And the response status is "SUCCESS"
    And the processedAt field is a valid date-time value

  @contract @negative
  Scenario Outline: A signup request with a missing required field is rejected
    Given an otherwise valid signup request with <field> omitted
    When the client publishes the request to "user/signup/v1"
    Then the service follows the documented invalid-request outcome
    And the reply follows the response schema if a response is returned
    And the validation result identifies <field> as required

    Examples:
      | field       |
      | userId      |
      | username    |
      | email       |
      | age         |
      | accountTier |
      | createdAt   |

  @contract @negative
  Scenario Outline: A signup request with a required field set to null is rejected
    Given an otherwise valid signup request with <field> set to null
    When the client publishes the request to "user/signup/v1"
    Then the service follows the documented invalid-request outcome
    And the reply follows the response schema if a response is returned
    And the validation result identifies <field> as invalid for a null value

    Examples:
      | field       |
      | userId      |
      | username    |
      | email       |
      | age         |
      | accountTier |
      | createdAt   |

  @contract @negative @type
  Scenario: A signup request with age set to an empty string is invalid
    Given a signup request payload with:
      | userId      | 123e4567-e89b-12d3-a456-426614174000 |
      | username    | alice                               |
      | email       | alice@example.com                   |
      | age         | ""                                  |
      | accountTier | 3                                   |
      | createdAt   | 2026-11-10T12:34:56Z                |
    When the client publishes the request to "user/signup/v1"
    Then the age value fails schema validation because it is not an integer
    And the service follows the documented invalid-request outcome
    And the request does not produce a successful acknowledgement

  @contract @boundary
  Scenario Outline: A signup request with a boundary violation is rejected
    Given a signup request with <field> set to <value>
    When the client publishes the request to "user/signup/v1"
    Then the service follows the documented invalid-request outcome
    And the request does not produce a successful acknowledgement

    Examples:
      | field       | value |
      | username    | al    |
      | age         | 17    |
      | accountTier | 0     |
      | accountTier | 6     |

  @async @boundary @negative
  Scenario: An age above the signed 32-bit integer maximum returns a failed response
    Given a signup request payload with:
      | userId      | 123e4567-e89b-12d3-a456-426614174000 |
      | username    | alice                               |
      | email       | alice@example.com                   |
      | age         | 2147483648                          |
      | accountTier | 3                                   |
      | createdAt   | 2026-11-10T12:34:56Z                |
    When the client publishes the request to "user/signup/v1"
    Then the service publishes a response on "user/signup/reply/v1"
    And the response status is "FAILED"
    And the response payload contains the same userId
    And the processedAt field is a valid date-time value

  @contract @format
  Scenario: A signup request with an invalid email format is rejected
    Given a signup request payload with:
      | userId      | 123e4567-e89b-12d3-a456-426614174000 |
      | username    | alice                               |
      | email       | not-an-email                        |
      | age         | 28                                  |
      | accountTier | 3                                   |
      | createdAt   | 2026-11-10T12:34:56Z                |
    When the client publishes the request to "user/signup/v1"
    Then the service follows the documented invalid-request outcome
    And the reply indicates a validation failure if a failed response is returned

  @contract @format
  Scenario: A signup request with an invalid UUID format is rejected
    Given a signup request payload with:
      | userId      | not-a-uuid                          |
      | username    | alice                               |
      | email       | alice@example.com                   |
      | age         | 28                                  |
      | accountTier | 3                                   |
      | createdAt   | 2026-11-10T12:34:56Z                |
    When the client publishes the request to "user/signup/v1"
    Then the service follows the documented invalid-request outcome
    And the reply indicates a validation failure if a failed response is returned

  @async @reply
  Scenario: The response is received on the configured reply channel and matches the request
    Given a valid signup request is published to "user/signup/v1"
    When the service processes the request
    Then the acknowledgement is returned on "user/signup/reply/v1"
    And the reply contains the same userId as the request
    And the response conforms to the UserSignedUpResponse schema

  @contract @format
  Scenario: A signup request with an invalid date-time value is rejected
    Given a signup request payload with:
      | userId      | 123e4567-e89b-12d3-a456-426614174000 |
      | username    | alice                               |
      | email       | alice@example.com                   |
      | age         | 28                                  |
      | accountTier | 3                                   |
      | createdAt   | not-a-date-time                     |
    When the client publishes the request to "user/signup/v1"
    Then the service follows the documented invalid-request outcome
    And the reply indicates a validation failure if a failed response is returned

# Design notes:
# - This contract is request/reply: the request is published to the queue-bound topic and the
#   response is expected on the reply channel "user/signup/reply/v1".
# - The AsyncAPI does not define a correlation header or a dedicated JMSReplyTo semantics, so
#   the scenarios assert response matching by payload userId and by reply channel routing unless
#   a broker-specific correlation contract is later provided.
# - The request schema does not declare an age maximum; the FAILED outcome for age above the
#   signed 32-bit integer maximum is an additional runtime behavior agreed for this example.
# - Retry, duplicate delivery, timeout, and dead-letter behavior remain contract-TBD until the
#   service owner declares them explicitly.
