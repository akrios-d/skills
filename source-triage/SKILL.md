---
name: source-triage
description: >
  Use whenever someone needs to find, verify, and triage academic/research sources for a
  dissertation, thesis, essay, or research project — especially when they already have some base
  documents and need to know what else to read and in what order.

  Triggers: "find sources for my dissertation", "triage these links", "I need a reading list",
  "verify these links are active", "what should I read for [topic]?", "research sources for
  [topic]", "can you find academic sources on [topic]?".

  Searches with WebSearch, verifies each link is live, classifies every source relative to what's
  already owned (ESSENTIAL / COMPLEMENTARY / SECONDARY), and produces a landscape .docx + .pdf
  with a clickable triage table and reading order. Always invoke for requests to find and organize
  academic sources — even without explicit dissertation framing.
---

# Source Triage Skill

Given a research topic and a list of documents the student already owns, search for the best
available sources, verify they are live, classify them, and produce a triage document
(landscape .docx + .pdf) with clickable links and a suggested reading order.

---

## Step 1 — Gather inputs

If not already clear from the conversation, confirm:

1. **Topic** — what is the dissertation/essay about? What are the specific case studies or angles?
2. **Base documents** — what does the student already have? (title + brief description is enough)
3. **Language** — what language should the output document be in? (default: English)
4. **Output path** — where to save the files?

---

## Step 2 — Plan source categories

Before searching, map out the source categories needed for the topic. Typical categories:

- **Theoretical framework** — academic explainers of the theory being applied (e.g. Copenhagen School, constructivism, realism)
- **Academic papers** — peer-reviewed articles directly applying the theory to the topic
- **Primary government sources** — official policy documents, reviews, white papers, parliamentary records
- **Case-specific journalistic** — high-quality journalism per case study (The Diplomat, Guardian, FT, BBC)
- **Technical / expert** — agency reports, think tanks, specialist institutions (NCSC, ISS, Chatham House)

Aim for 12–18 sources total. Adjust categories based on the topic.

---

## Step 3 — Search and verify

For each category, run 2–3 WebSearch queries. For each source found:

- Record the **full URL** (not a shortened version)
- Record a **short display label** (domain › path-slug, readable at a glance)
- Confirm it is **live and relevant** — if a search returns the page title and a snippet, that is sufficient confirmation

Immediately flag any source that duplicates something the student already owns — exclude it from the final document entirely.

**Search tips:**
- Use `site:` operator to target quality domains: `site:link.springer.com`, `site:gov.uk`, `site:jstor.org`
- Lords Library: `site:lordslibrary.parliament.uk`
- Commons Library: `site:commonslibrary.parliament.uk`
- NCSC reports: `site:ncsc.gov.uk`
- The Diplomat: `site:thediplomat.com [topic]`
- e-IR: `site:e-ir.info [topic]`

---

## Step 4 — Classify each source

Classify relative to what the student already owns:

| Classification | Meaning |
|---|---|
| **ESSENTIAL** | Fills a critical gap not in any base document. Must read. |
| **COMPLEMENTARY** | Adds depth or extends coverage. Read after ESSENTIALs. |
| **SECONDARY** | Comparative or tangential. Only if broadening scope. |

Ask: *"If the student skips this, will her argument have a hole?"* — if yes, it is ESSENTIAL.

Typical breakdown: 6–9 ESSENTIAL, 3–5 COMPLEMENTARY, 1–3 SECONDARY.

---

## Step 5 — Build the reading order

From ESSENTIAL sources only, define a sequence that flows:
1. Theory / framework first
2. Academic papers applying the framework
3. Primary government sources
4. Case-specific sources (chronological within each case)

---

## Step 6 — Generate the triage document

### Install dependency (once per session)
```bash
mkdir -p /tmp/triage-build && cd /tmp/triage-build && npm init -y && npm install docx 2>&1 | tail -3
```

### Prepare the data JSON at `/tmp/triage_data.json`

```json
{
  "title": "Source Triage — [Short Topic Title]",
  "subtitle": "[Case 1]  ·  [Case 2]  ·  [Case 3]",
  "base_documents": [
    "Title of base doc 1 (already owned)",
    "Title of base doc 2 (already owned)"
  ],
  "date": "Month Year",
  "sources": [
    {
      "number": 1,
      "title": "Full Source Title (Year)\n(Publisher / Journal)",
      "url_label": "domain.com › readable-path-slug",
      "url": "https://full-url.com/exact/path",
      "classification": "ESSENTIAL",
      "note": "One or two sentences explaining the gap this fills and why it matters for the dissertation."
    }
  ],
  "reading_order": [
    { "number": 1, "description": "Source title — reason to read first" }
  ]
}
```

`classification` must be exactly: `"ESSENTIAL"`, `"COMPLEMENTARY"`, or `"SECONDARY"`.

### Run the generator

```bash
node <skill_dir>/scripts/generate_triage_docx.js \
  /tmp/triage_data.json \
  /path/to/output/source_triage.docx
```

### Convert to PDF

Use the LibreOffice wrapper from the docx skill:

```bash
# VM path (bash):
python /sessions/sweet-funny-babbage/mnt/.claude/skills/docx/scripts/office/soffice.py \
  --headless --convert-to pdf /path/to/output/source_triage.docx \
  --outdir /path/to/output/
```

---

## Output document structure

Landscape format (Letter or A4) containing:

1. **Header** — title, subtitle, date, base documents already in hand
2. **Classification key** — colour legend
3. **Triage table** — # | Source | Link (clickable) | Classification | Triage Note
4. **Suggested reading order** — ESSENTIAL sources in recommended sequence

Colour coding (Classification column):
- ESSENTIAL → `C6EFCE` (green)
- COMPLEMENTARY → `FFEB9C` (yellow)
- SECONDARY → `DDEEFF` (light blue)

---

## Quality checks before delivering

- Every URL is the full, exact URL — not truncated or display-only
- Every link confirmed live via WebSearch (title + snippet visible in results)
- No source duplicates something the student already owns
- Reading order covers all ESSENTIAL sources and flows from theory to evidence
- Triage notes name the specific gap filled, not just "useful for the dissertation"
- Both .docx and .pdf saved to the output path and presented to the user
