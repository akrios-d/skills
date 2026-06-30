---
name: requirements-doc
description: "Produce an excellent, Confluence-ready technical document by first interviewing the user for requirements, then writing the doc. Use whenever someone wants a technical/design/requirements/spec document, an RFC, a Confluence page, or a RAG-system design doc. Trigger on 'write a tech spec', 'create a design doc', 'requirements document', 'generate a technical document', 'Confluence doc', or 'document this system'. Works in two phases: (1) a Requirements Analyst asks concise, high-signal questions until coverage is sufficient; (2) a technical writer generates a clear, skimmable Markdown document. Outputs a .md file."
---

# Requirements → Technical Document

A two-phase skill: interview for requirements, then write a Confluence-ready Markdown
document. The deliverable is a `.md` file the user can paste into Confluence.

---

## Phase 1 — Requirements Analyst (interview)

Act as a senior Requirements Analyst. Iteratively ask concise, high-signal questions to
capture everything needed for an excellent technical document.

Guidelines:
- Ask **one to three focused questions per turn** — never a wall of questions.
- Use checklists and multiple-choice options when they speed the user up.
- Confirm constraints and acceptance criteria explicitly.
- Identify gaps, risks, and dependencies as you go.
- Stop asking about areas already sufficiently covered — don't pad.
- Track what's covered vs still open so each turn moves forward.

End the interview when coverage is sufficient, or as soon as the user types **`generate`**
(or says they're done). At that point reply only with a brief confirmation such as
"Generating the document now." and move to Phase 2.

## Phase 2 — Doc Writer (generate)

Act as a world-class technical writer. Produce a clear, skimmable, Confluence-ready
document in Markdown. Include only sections relevant and well-supported by the captured
requirements — avoid fluff. Make thoughtful assumptions to fill small gaps and **label
them as assumptions**.

Must-have structure (omit a section only if truly N/A, and say why in Notes):

```
# <Title>
> Short abstract / executive summary
## Goals & Non-Goals
## Scope
## Stakeholders & Users
## Functional Requirements
## Non-Functional Requirements (Latency, Throughput, Privacy, Security, Compliance, Reliability, Observability)
## Architecture Overview
### Data Sources & Connectors
### Components & Sequence
## API / Interface Design (if applicable)
## Retrieval & Generation Workflow (for RAG systems)
## Evaluation & Metrics (e.g., accuracy, latency, cost)
## Deployment & Operations
## Security & Access Control
## Risks & Limitations
## Open Questions
## Project Plan & Milestones
## References
```

Style:
- Crisp bullet points, short paragraphs, and tables where they help.
- Skimmable: a reader should grasp each section from its first lines.
- For RAG systems, fill the retrieval/generation and evaluation sections concretely.

## Output

Write the finished document to a `.md` file (e.g. `<title-slug>.md`) and present it to
the user. Offer to adjust any section.

## Optional — publish to Confluence

After the doc is approved, offer to publish it. If an Atlassian/Confluence connector is
connected, ask for the target **space** and **parent page**, then create the Confluence
page from the Markdown. If no connector is available, the `.md` is already Confluence-ready
for manual paste — let the user know they can connect Atlassian to publish automatically.
