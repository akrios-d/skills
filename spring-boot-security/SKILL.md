---
name: spring-boot-security
description: "Apply this skill when writing or reviewing security-relevant code in Java 17 / Spring Boot 3.x microservices that proxy a legacy Core monolith (no Spring Security in these services). Triggers: validating controller input with jakarta validation, mapping Core errors to client responses, secrets in application.yml, RestTemplate timeouts, logging, or Maven dependency CVE checks. Covers the Spring/Core-specific mechanics; for the universal principles behind them, use the security-guidelines skill."
---

# Spring Boot Security — stack specifics

No Spring Security in these services. That doesn't eliminate the attack surface.

> This skill covers only the **Spring Boot / Core-specific** mechanics. For the universal
> principles (validate input, don't leak internals, secrets out of source, timeouts, safe
> logging, dependency CVEs), follow the **security-guidelines** skill.

## Input validation (jakarta validation)

Validate every controller parameter before the service sees it:

```java
@RestController
@Validated
class OrderController {

    @GetMapping("/{id}")
    ResponseEntity<OrderResponse> getById(
        @PathVariable @NotBlank @Size(max = 50) String id
    ) { ... }

    @PostMapping
    ResponseEntity<OrderResponse> create(
        @RequestBody @Valid CreateOrderRequest request
    ) { ... }
}

record CreateOrderRequest(
    @NotBlank String customerId,
    @NotNull @Positive BigDecimal amount
) {}
```

Add a `@ControllerAdvice` that catches `MethodArgumentNotValidException` and
`ConstraintViolationException` — return `400` with a clean body, never a stack trace.

## Core error mapping

Map Core (upstream) failures to meaningful statuses — never surface internals:

```java
// Wrong
return ResponseEntity.status(500).body(e.getMessage());

// Correct
log.error("Failed to fetch order {} from Core", orderId, e);
return ResponseEntity.status(502).body(new ErrorResponse("Could not retrieve order"));
```

- Core `4xx` → meaningful client error (don't swallow as `500`)
- Core `5xx` → `502 Bad Gateway`
- Core timeout → `504 Gateway Timeout`

## Secrets in application.yml

Nothing sensitive in source or committed `application.yml` — reference env vars:

```yaml
core:
  base-url: ${CORE_BASE_URL}

spring:
  datasource:
    url: ${DB_URL}
    username: ${DB_USER}
    password: ${DB_PASSWORD}
```

## RestTemplate timeouts

Verify the custom bean has explicit timeouts — without them a slow Core response exhausts
the thread pool:

```java
factory.setConnectTimeout(3000);  // 3s — fail fast if Core is unreachable
factory.setReadTimeout(10000);    // 10s — Core may be slow under load
```

## Logging (Spring/Core context)

- Log correlation/request IDs at `INFO`; log Core errors at `ERROR` with context (orderId,
  URL called, HTTP status).
- Never log Oracle result sets, tokens, or PII. Don't use `DEBUG` in production.

## Dependencies

Run `mvn dependency:check` periodically. Flag any transitive dependency at High/Critical CVE.
