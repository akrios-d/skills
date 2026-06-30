## 🔗 Azure DevOps – Work Item(s)
- **Main Work Item:**
  <!-- e.g. https://dev.azure.com/<org>/<project>/_workitems/edit/12345 -->

- **Related Work Items (optional):**
    - <!-- https://dev.azure.com/<org>/<project>/_workitems/edit/XXXXX -->
    - <!-- https://dev.azure.com/<org>/<project>/_workitems/edit/YYYYY -->

---

## 🧾 What changed?

Describe clearly and objectively:
- The problem or requirement described in Azure DevOps
- The reason for the change
- The solution implemented in the Java code

> Example:
> Adjusted the logic in `PaymentService` to fix the balance calculation in the checkout flow.

---

## 📚 Documents

Include relevant project links:
- Functional specification
- Technical / design document
- Diagrams
- Azure DevOps Wiki

<!-- e.g. https://dev.azure.com/<org>/<project>/_wiki -->

---

## 💬 Expected feedback on

Highlight points that need extra attention in code review:
- Business logic
- Performance
- Readability / code standards
- Impact on existing components
- Use of Java-specific APIs, frameworks, or features

---

## ⚠️ Risk areas

Indicate possible risks to consider in testing:
- Changes to business rules
- Impact on critical business processes
- External integrations
- Concurrency / transactions
- Database access
- Version compatibility (Java / Spring)

---

## 🧪 How to test

Steps to validate the change:

1. **Prerequisites:**
    - <!-- e.g. customer data, account state, feature flag -->

2. **Steps:**
    1. <!-- Step 1 -->
    2. <!-- Step 2 -->
    3. <!-- Step 3 -->

3. **Expected result:**
    - <!-- e.g. correct processing with no errors in logs -->

---

## 👨‍💻 Validation performed by the developer

What was run:
- [ ] Manual test
- [ ] Local test
- [ ] Azure DevOps pipeline

**Evidence (if applicable):**
- Screenshots
- Logs
- Azure DevOps build link
- Commands run
  <!-- e.g. mvn clean test / mvn clean install -->

---

## ✅ Unit Tests

- [ ] Unit tests added
- [ ] Not applicable

### Summary:
- Classes and methods tested
- Main flows and error scenarios
- Frameworks used (JUnit 5, Mockito, Spring Test)

---

## 📦 Checklist

- [ ] Code follows project standards
- [ ] Build runs successfully
- [ ] Tests pass locally
- [ ] Azure DevOps Work Item(s) referenced
- [ ] Documentation updated (if needed)
