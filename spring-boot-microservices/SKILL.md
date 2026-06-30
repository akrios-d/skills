---
name: spring-boot-microservices
description: "Apply this skill whenever working on or making structural decisions about Java 17 / Spring Boot 3.x microservices that delegate to a legacy Java EE Core monolith (Strangler Fig pattern). Triggers: any mention of Spring Boot, RestTemplate, jakarta, microservice, Core delegation, strangler fig, or Java service code; and architectural decisions like whether logic belongs here or in Core, creating a new service, adding an abstraction/layer, caching, or messaging. Enforces: jakarta namespace, flat layering (Controller → Service → RestTemplate), custom RestTemplate usage, no Spring Security, no batch in MS, Strangler-phase awareness, build-for-today, and the documented red flags. For generic coding discipline, see the coding-guidelines skill."
---

# Spring Boot Microservices — Strangler Fig Guidelines

## Context

These services front a legacy Java EE 7 EAR (WebLogic). The Core is the source of truth.
Microservices delegate to it via HTTP (`RestTemplate`) and gradually absorb its
responsibilities. Do not replicate everything at once.

> For general coding discipline — think before coding, simplicity first, surgical changes,
> goal-driven execution — follow the **coding-guidelines** skill. This skill covers only
> the Spring Boot / Strangler-Fig–specific rules.

## Stack

| Concern | Decision |
|---|---|
| Runtime | Java 17 |
| Framework | Spring Boot 3.4.5 |
| Namespace | `jakarta.*` — **never** `javax.*` |
| Build | Maven |
| HTTP client | Custom `RestTemplate` bean — inject, don't replace |
| Database | Oracle via Core's REST API (unless the MS owns data directly) |
| Batch | Stays in Core — no batch jobs in these services |
| Security | No Spring Security — auth is handled upstream |

---

## The Strangler Fig contract

These services follow three phases — know which phase each service is in, and don't mix
phases in the same service:

1. **Proxy (now):** receive request → delegate to Core via HTTP → return response. No
   business logic here yet.
2. **Migration (later):** extract logic from Core into the MS. Core becomes thinner.
3. **Target (future):** the MS owns its domain. Core is no longer involved for that
   capability.

### The one question
**"Does this belong here, or does it belong in Core?"** If the logic exists in Core and
you're in proxy phase — call Core, don't replicate it. Two sources of truth diverge.

### Before adding any abstraction
1. Is it used in more than one place **right now**? If no, keep it inline.
2. Is Core already doing this? If yes, call Core.
3. Am I building for today's requirement or a future one? Build for today.

---

## Structural decisions

### When to create a new service
- It has a distinct domain boundary.
- The team explicitly decided to extract it.
- **Not** because a feature "feels different".

### Layering — keep it flat
```
Controller (@RestController)  →  validates input, delegates to Service
Service    (@Service)         →  business logic, calls Core via RestTemplate
Repository (@Repository)      →  only if this MS owns data directly in Oracle
```
No extra layers. No `Facade`, `Orchestrator`, or `Gateway` class on top of Service. This
Controller → Service → RestTemplate is the complete stack for a proxy-phase service.

### Domain model vs. Core DTOs
- **Proxy phase:** use Core's DTOs directly (or a thin copy). Don't build a rich domain model.
- **Migration phase:** build a domain model when the MS owns business logic.

---

## Jakarta namespace (hard rule, zero exceptions)

| ✗ Wrong (Java EE / Spring Boot 2.x) | ✓ Correct (Spring Boot 3.x) |
|---|---|
| `javax.persistence.*` | `jakarta.persistence.*` |
| `javax.validation.*` | `jakarta.validation.*` |
| `javax.servlet.*` | `jakarta.servlet.*` |
| `javax.annotation.*` | `jakarta.annotation.*` |

**Before writing any code:** scan for `javax.*` in the context. If found, flag it as a bug
before proceeding.

## RestTemplate rules

The project uses a **custom `RestTemplate` bean**. Never:
- Replace it with `WebClient` or `RestClient`
- Wrap it in a custom HTTP client abstraction
- Add OpenFeign or any other HTTP client library
- Create a new `RestTemplate` bean — inject the existing one

When calling Core, always:
- Handle `HttpClientErrorException` (4xx) and `HttpServerErrorException` (5xx) explicitly —
  never let them surface as 500s
- Map Core error responses to meaningful domain exceptions before returning to callers
- Respect configured timeouts; if not set on the bean, add them

## Configuration

- All URLs, timeouts, and external values go in `application.yml` — never hardcoded.
- Use `@ConfigurationProperties` for grouped config; `@Value` for single values.
- Never commit credentials — use environment variables or a secrets manager.

---

## What stays in Core — do not touch
- Batch jobs (XML-configured, Java EE 7)
- Oracle schema ownership
- Business rules Core enforces
- Authentication / authorisation

## Red flags — stop and discuss
- A `BaseService` or `AbstractCoreClient` class
- Generic response wrappers (`ApiResponse<T>`) for a 2-endpoint service
- Kafka / RabbitMQ introduced without an explicit scope decision
- A caching layer before there's a measured performance problem
- Replicating Core's full data model in proxy phase
- More than 3 Maven modules in a service that proxies 4 endpoints
