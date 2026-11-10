# References for test design

References were selected to ground the agent in recognized black-box test techniques, messaging behavior, and machine-readable contracts. Prefer standards and official product documentation for normative behavior; tutorials and community articles are supplementary. Always confirm the target service's actual contract and broker configuration.

## Test design techniques

- **ISTQB Foundation Level syllabus, Chapter 4 (Test Analysis and Design):** recognized techniques including equivalence partitioning, boundary value analysis, decision table testing, and state transition testing. Start from the current official ISTQB syllabus and locate the Foundation Level section on test techniques: <https://www.istqb.org/certifications/certified-tester-foundation-level>
- **ASTQB/ISTQB Foundation Level black-box techniques overview:** <https://astqb.org/4-2-black-box-test-techniques/>
- **Practical supplemental examples (not normative):** <https://www.softwaretestinghelp.com/black-box-testing-techniques/>

## Solace JMS and asynchronous request/reply

- **Solace JMS request-reply tutorial and sample:** <https://github.com/SolaceDev/solace-dev-tutorials/blob/master/src/pages/tutorials/jms/request-reply.md>
- **Solace JMS selectors:** <https://docs.solace.com/API/Solace-JMS-API/Selectors.htm>
- **Solace Java API request-reply guide:** <https://docs.solace.com/API/API-Developer-Guide-Java/Java-API-Request-Reply.htm>
- **JMS specification (Jakarta Messaging):** <https://jakarta.ee/specifications/messaging/>

Use these to understand the general mechanics of reply destinations, correlation, and selectors. Verify exact behavior against the JMS API version and Solace client/deployment configuration in use. A fixed reply topic, `JMSReplyTo`, and temporary destinations are different design choices and must not be conflated.

## API schema and contracts

- **JSON Schema specifications:** <https://json-schema.org/specification>
- **JSON Schema validation vocabulary:** <https://json-schema.org/draft/2020-12/json-schema-validation>
- **OpenAPI Specification:** <https://spec.openapis.org/oas/latest.html>
- **Pact documentation (consumer-driven contract testing):** <https://docs.pact.io/>

Check the schema dialect/version and validator configuration. In particular, do not assume every validator treats `format` as an assertion; consult the selected dialect and implementation settings.

## How to apply the references

1. Use the actual API and event schemas as the authority for field rules.
2. Use test-design techniques to derive representative, boundary, combination, and state-transition cases.
3. Use Solace/JMS docs to formulate messaging questions and test metadata, then confirm deployment-specific behavior with the system owner.
4. Record the source/version/date for project-specific contracts and tools. Re-check external documentation when versions change.
5. Do not copy test content or examples as requirements without confirming they apply to the system under test.
