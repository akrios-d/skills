# Java 25 / modern Java review checklist

Read this when the diff touches `.java` files, or there's a `pom.xml`/`build.gradle` in the repo. Apply this on top of the general checklist in SKILL.md, not instead of it.

This file covers language- and JVM-level correctness. If the project also follows a specific architectural convention (e.g. a Spring Boot microservice with its own layering/framework rules), defer to that project's own conventions for architecture and use this file for the language-level pass only — don't re-litigate layering choices that belong to a different skill or house style.

## Records & data modeling

- New DTOs/value types that are effectively immutable and only hold data → candidate for a `record` instead of a class with manual getters/`equals`/`hashCode`. Flag class-based data holders added in the diff, unless there's a real reason not to (JPA entity, needs mutability, needs inheritance).
- Records with validation: check invariants are enforced in a compact constructor, not validated after construction where it's easy to skip.
- Watch for records used where **identity** semantics matter (e.g. JPA entities). A record's generated `equals`/`hashCode` compares *all* fields, which is usually wrong for an entity with a DB-generated id — two unsaved entities with equal field values would incorrectly compare equal.

## Pattern matching

- New `if (x instanceof Foo) { Foo f = (Foo) x; ... }` chains added in this diff are a candidate for pattern matching (`if (x instanceof Foo f)`); multi-branch `instanceof` chains are a candidate for a `switch` with pattern matching, especially if the type hierarchy is sealed. Suggest it, don't insist — only worth raising if it actually reads clearer than what's there.
- Switch on enums/sealed types: check the new/changed switch is exhaustive. Missing a `default` (or missing a case) on a non-sealed type is a latent bug the moment someone adds a new case later.

## Null-safety & Optional

- `Optional` used as a field type or method **parameter** is a smell — it should generally only be a return type. Flag it if the diff introduces one.
- Chains like `Optional.ofNullable(x).map(...).orElse(null)` unwrap right back to nullable, defeating the point of using `Optional` at all — worth a note.
- New nullable fields/params: check callers actually handle the null case rather than just assuming the added null-check "looks defensive enough."

## Concurrency (virtual threads / structured concurrency, if present)

- **Thread pinning.** `synchronized` blocks around blocking I/O inside a virtual thread pin the carrier thread and defeat the point of using virtual threads. If new code adds `synchronized` around a blocking call in a virtual-thread context, suggest `ReentrantLock` instead.
- **Structured concurrency** (`StructuredTaskScope`): check the scope is properly closed (try-with-resources) and that the join/error-handling policy matches what the surrounding code assumes about partial failure — a scope that doesn't propagate a subtask's exception can silently continue on bad data.
- **Thread-locals with virtual threads.** Flag any new `ThreadLocal` used for per-request state — with virtual threads this can accumulate across a huge number of short-lived threads if not scoped/cleared correctly. `ScopedValue` (finalized in recent JDKs) is usually the better fit for this use case in new code.

## Streams & collections

- Streams with side effects inside `map`/`forEach` (mutating an outer collection, incrementing a shared counter) — flag as fragile even if it happens to work today; suggest `collect`/`reduce` instead.
- A stream pipeline added for what's actually a single pass over a small, fixed collection isn't wrong, but note if a plain loop would be clearer — this is a house-style call, not a correctness issue.
- **Sequenced collections** (`getFirst`/`getLast`/`reversed()` on `List`/`SequencedCollection`): if the diff manually indexes `list.get(0)` / `list.get(list.size() - 1)` or reverses via `Collections.reverse`, the newer methods are more direct. Style note, not a blocker.

## Exceptions & resources

- Catching `Exception` or `RuntimeException` broadly and either swallowing it or re-throwing a generic error loses the original cause/type — check the cause is preserved (`throw new X(msg, e)`) rather than dropped.
- New I/O/connection/lock resources: confirm try-with-resources (or equivalent) is used, not a manual `close()` call that gets skipped on the exception path.
- Checked vs unchecked: if the diff converts a checked exception to unchecked at a boundary (or the reverse), that changes what callers are forced to handle — worth confirming it's intentional rather than incidental.

## Misc

- `var` used where the inferred type isn't obvious from the right-hand side hurts readability at the call site — worth a note (this isn't a blanket objection to `var`).
- Text blocks (`"""..."""`) with indentation that doesn't match the surrounding code — easy to get wrong and produce unwanted leading whitespace; check it renders as intended.
