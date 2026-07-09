---
name: spring-boot-docs
description: "Apply this skill whenever writing or reviewing code documentation — Javadoc, inline comments, naming, or TODOs — in Java 17 / Spring Boot 3.x microservices. Triggers: adding Javadoc to a method, writing or reviewing inline comments, naming variables / URLs / fields, documenting DTO records, or leaving a TODO. Enforces: good names and types are the documentation; Javadoc only on public service methods whose behaviour isn't obvious from the signature (never on getters/setters/trivial constructors); comments explain why, not what; records are self-documenting; TODOs require a ticket reference and a concrete action."
---

# DOCS.md — Code Documentation Guide


## Core Rule

**Good names and types are documentation. Javadoc and comments are for what they cannot express.**

## When to Write Javadoc

Write on **public service methods** when the behaviour isn't obvious from the signature:

```java
/**
 * Fetches the order from Core and maps it to the local response model.
 *
 * Returns empty if Core responds with 404.
 * Throws {@link CoreUnavailableException} on 5xx or timeout.
 */
public Optional<OrderResponse> findById(String orderId) { ... }
```

**Do not** write Javadoc on:
- Getters, setters, constructors that only assign fields
- Methods where name + types make intent obvious
- Private methods (explain inline if non-obvious)

```java
// Unnecessary
/** Gets the order ID. @return the order ID */
public String getOrderId() { return this.orderId; }
```

## When to Write Inline Comments

**Yes — non-obvious business rules:**
```java
// Core returns amounts in cents — divide by 100 before exposing to clients
BigDecimal amount = new BigDecimal(dto.getAmountCents()).movePointLeft(2);
```

**Yes — why a decision was made:**
```java
// POST to /orders/search instead of GET — filter payload exceeds URL length limits.
// This is a Core API constraint, not our choice.
restTemplate.postForEntity(coreUrl + "/orders/search", filter, ...);
```

**Yes — known limitations with a ticket:**
```java
// Core does not support pagination here — we fetch all and slice.
// TODO JIRA-1234: request Core-side pagination once v2 API is available.
```

**No — don't restate the code:**
```java
// Loop through orders and map each one  ← noise
orders.stream().map(this::toResponse).toList();

// Call Core  ← obvious
restTemplate.getForObject(coreUrl + "/orders", ...);
```

## Naming Over Comments

```java
// Wrong
String s = coreBaseUrl + "/orders"; // URL for orders endpoint

// Correct
String coreOrdersUrl = coreBaseUrl + "/orders";
```

## Records for DTOs

Records are self-documenting — no Javadoc needed unless a field has non-obvious constraints:

```java
record CreateOrderRequest(
    @NotBlank String customerId,
    @NotNull @Positive BigDecimal amount  // in euros, not cents
) {}
```

## TODOs

Only with a ticket reference and concrete action:
```java
// TODO JIRA-1234: Remove fallback once Core v2 is in production
```

A `// TODO` with no context is noise — create a ticket first.

## Optional — publish documentation

After the documentation is approved, offer to publish it. Try MCP tools in this order:

- **GitHub MCP** — use `mcp_github_create_or_update_file` to push the generated Markdown to a `docs/` folder in the repository, or to a `gh-pages` branch for GitHub Pages.
- **GitLab MCP** — use `mcp_gitlab_create_file` or `mcp_gitlab_update_file` to push to the repo's `docs/` folder or a GitLab Pages branch.
- **Azure DevOps MCP** — use `mcp_azure_devops_create_wiki_page` to publish directly to the project's Wiki.
- **Fallback** — if no MCP tools are available, output the Markdown for manual paste and inform the user.
