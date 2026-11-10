@async @acceptance
Feature: Submit an order and receive its processing outcome
  As an ordering client
  I want to submit a valid order and receive the corresponding outcome
  So that I can tell whether that order was accepted for processing

  # Illustrative example only. Confirm destinations, contract, correlation, timing,
  # and invalid-request behavior with the service owner before execution.

  Background:
    Given the order service is available in an authorized test environment
    And the client is ready to receive replies on the configured reply destination

  @smoke
  Scenario: A valid order is accepted and its reply matches the request
    Given the order request has valid customer, amount, currency, and item details
    And the request has a unique correlation identifier
    When the client submits the order to the configured request topic
    Then the client receives an acceptance outcome for that order within the agreed response window
    And the outcome is delivered through the configured reply path
    And the reply is matched to the submitted request

  @contract @negative
  Scenario Outline: An order with an invalid required field is not accepted
    Given an otherwise valid order request with <field> <invalid_condition>
    When the client submits the order to the configured request topic
    Then the order is not accepted
    And the service follows the documented invalid-request outcome

    Examples:
      | field      | invalid_condition |
      | request ID | omitted           |
      | customer   | omitted           |
      | amount     | omitted           |
      | currency   | omitted           |

  @contract @boundary
  Scenario Outline: An order amount follows the documented amount limits
    Given an order request with amount <amount>
    When the client submits the order to the configured request topic
    Then the service handles the order according to the documented amount rule

    Examples:
      | amount             |
      | below minimum      |
      | minimum             |
      | just above minimum  |
      | just below maximum |
      | maximum             |
      | above maximum      |

  @async @correlation
  Scenario: Concurrent order replies are matched to their own requests
    Given two valid orders with different order identifiers and correlation identifiers
    When the client submits both orders while listening on the configured reply path
    Then each received outcome is matched to its originating order
    And neither outcome is associated with the other request

  @async @timeout
  Scenario: The client handles an order with no reply within the agreed window
    Given a valid order request for which the service will not produce a reply in the test fixture
    When the client submits the request and the agreed response window expires
    Then the client follows the documented timeout behavior
    And any later reply is handled according to the documented late-reply behavior

  @async @duplicate
  Scenario: A repeated outcome does not create an unintended duplicate business effect
    Given a valid order has already produced an outcome
    When the same outcome is delivered again in the authorized test environment
    Then the service handles the duplicate according to the documented idempotency behavior

# Design notes:
# - Replace placeholders such as "configured request topic" with contract-backed values only.
# - Define concrete amount boundaries from the approved schema/business rules.
# - The expected rejection, timeout, late-reply, and duplicate outcomes are intentionally
#   left contract-driven; do not turn these examples into executable acceptance criteria
#   until the service owner confirms the behavior.
