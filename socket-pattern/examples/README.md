# Socket Pattern — Backend Examples

Real-world backend implementations of the Socket Pattern across Java, C#, and TypeScript.

Each example uses the same fictional domain: **an e-commerce order processing system**
that receives orders from external sources and persists them.

---

## The Problem (always the same)

You build a system that:
1. Receives data from an external source (webhook, queue, file, polling)
2. Validates and processes it
3. Persists it somewhere
4. Notifies downstream systems

Six months later: the external source changes protocol. Or you swap the database.
Or you add a second notification channel.

**Without Socket Pattern:** you refactor everything.
**With Socket Pattern:** you swap one plug.

---

## Examples

- [`java/`](./java/) — Spring Boot + JPA + RabbitMQ
- [`csharp/`](./csharp/) — ASP.NET Core + EF Core + Azure Service Bus
- [`typescript/`](./typescript/) — Node.js + Prisma + SQS

---

## The Backend Socket Pattern

```
┌─────────────────────────────────────────────────┐
│  INBOUND ADAPTER                                │
│  (polling, webhook, queue consumer, REST)        │
└──────────────────┬──────────────────────────────┘
                   │  IXxxProcessor (interface)
                   ▼
┌─────────────────────────────────────────────────┐
│  DOMAIN / USE CASE                              │
│  No framework imports. No DB imports.            │
│  Pure business logic. Testable with mocks.       │
└───────────┬─────────────────────────────────────┘
            │ IXxxRepository    │ IXxxPublisher
            ▼                   ▼
┌──────────────────┐  ┌─────────────────────────┐
│  INFRASTRUCTURE  │  │  OUTBOUND ADAPTER       │
│  JPA/EF/Prisma   │  │  RabbitMQ/SQS/HTTP      │
└──────────────────┘  └─────────────────────────┘
```

Every arrow is an **interface**. The domain depends on nothing concrete.
