# Skills

A collection of skills, grouped by purpose.

## Architecture & coding guidelines

Stack-specific and general coding standards.

| Skill | What it does |
|---|---|
| [angular-vercel](angular-vercel/SKILL.md) | Standards for an Angular 22 PWA + Vercel serverless backend: MVVM, signals, `inject()`, Zod validation on API routes, vanilla CSS. |
| [socket-pattern](socket-pattern/SKILL.md) | Full-stack hexagonal UI architecture where every boundary is an explicit interface contract (IModel/IView/IController, ModelView/ViewController). |
| [spring-boot-microservices](spring-boot-microservices/SKILL.md) | Java 17 / Spring Boot 3.x Strangler Fig microservices: stack rules (jakarta, RestTemplate, flat layering, config) plus architectural decisions (Strangler phases, when to abstract, what stays in Core, red flags). |
| [spring-boot-docs](spring-boot-docs/SKILL.md) | Code documentation guide: Javadoc, inline comments, naming, and TODO conventions. |
| [spring-boot-security](spring-boot-security/SKILL.md) | Spring/Core-specific security mechanics: jakarta validation, Core error mapping, application.yml secrets, RestTemplate timeouts, Maven CVE checks (pairs with security-guidelines). |
| [spring-boot-testing](spring-boot-testing/SKILL.md) | Unit/slice testing guide: JUnit 5, Mockito, MockRestServiceServer, @WebMvcTest, AssertJ. |
| [coding-guidelines](coding-guidelines/SKILL.md) | General coding-behavior guidance to reduce common LLM mistakes: think before coding, simplicity first, surgical changes, goal-driven execution. |
| [security-guidelines](security-guidelines/SKILL.md) | Language-agnostic security principles for any repo: validate input, don't leak internals, secrets out of source, timeouts, safe logging, least privilege, dependency CVEs. |
| [ux-localisation](ux-localisation/SKILL.md) | UX copy & i18n guide for any app: a maintained terminology glossary, a clear product voice, per-language tone adaptation, key parity across locales, changed-keys-only output. |
| [ui-ux-audit](ui-ux-audit/SKILL.md) | UI/UX design audit for any app against its own design system: reads the existing tokens, ranks findings by severity, gives concrete fixes, never reinvents the design. |
| [spring-batch-analysis](spring-batch-analysis/SKILL.md) | Functional documentation of a Java/Spring Batch job from its code: functional description, affected tables, implicit business rules, and a Mermaid flow (optional Confluence publish). |
| [selection-field-analysis](selection-field-analysis/SKILL.md) | Inventories backend-dependent Dropdown/Selection Field form fields from US/EP/Confluence docs into a consolidated per-EP table, with zero-inference rules and cross-EP grouping. |

## Video production

An end-to-end, chained video production pipeline.

| Skill | Stage |
|---|---|
| [video-setup](video-setup/SKILL.md) | Analyzes a repo/document and generates a script + `project.json`. |
| [video-scene](video-scene/SKILL.md) | Scene-by-scene loop (narration → audio → recording → clip). |
| [video-elevenlabs](video-elevenlabs/SKILL.md) | Generates TTS narration audio via ElevenLabs. |
| [video-render](video-render/SKILL.md) | Renders a scene clip (animation, Ken Burns, slideshow, recording) at 1080p. |
| [video-subtitle](video-subtitle/SKILL.md) | Subtitles via Whisper + optional translation, outputs `.srt`. |
| [video-assemble](video-assemble/SKILL.md) | Joins approved clips with xfade transitions into the final video. |

**Flow:** `video-setup` → `video-scene` (→ `video-elevenlabs` / `video-render` per scene) → `video-subtitle` → `video-assemble`.

## Dev workflow

Git and documentation helpers.

| Skill | What it does |
|---|---|
| [pull-request](pull-request/SKILL.md) | Generates a standardized Azure DevOps PR from the current branch's git diff: reads the diff, pre-fills the project template, asks only for missing info, and writes pull_request.md. |
| [conventional-commit](conventional-commit/SKILL.md) | Inspects the git diff and creates a commit following the Conventional Commits 1.0.0 spec (confirms first, never pushes). |
| [requirements-doc](requirements-doc/SKILL.md) | Interviews you for requirements, then generates a Confluence-ready technical/design doc in Markdown (two-phase: ask → write). |
| [azure-devops-workitem](azure-devops-workitem/SKILL.md) | Creates, refines, and validates Azure DevOps work item descriptions (US/Task/Subtask) in a copy-paste-ready format; asks output language (default English); never infers or consolidates by name. |

## Other

Standalone skills.

| Skill | What it does |
|---|---|
| [codebase-to-course](codebase-to-course/SKILL.md) | Turns any codebase into an interactive, self-contained HTML course (scroll-based navigation, animated visualizations, quizzes, and code↔English translations) aimed at non-technical learners. |
