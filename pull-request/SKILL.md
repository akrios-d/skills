---
name: pull-request
description: "Generate a standardized Azure DevOps pull request from the current branch's git diff for a Java project. Use whenever the user wants to write, prepare, or fill in a PR / pull request description. Trigger on 'generate a PR', 'create a pull request', 'fill in the PR', 'build the PR description', 'prepare my pull request', or any request to turn a branch diff into a PR description. The skill reads the diff itself, pre-fills the project's PR template, asks only for what it cannot infer (one question at a time), and outputs the final PR text plus a pull_request.md file. PR output is written in English."
---

# Pull Request Assistant

Turns the current branch's `git diff` into a standardized, pre-filled pull request for
a Java project, using the project's PR template. Adapted to run the diff and fill the
template directly — no copy-pasting into a separate chat.

**Output language: English.** The generated PR text and `pull_request.md` match the
template. Keep a professional, clear, direct tone.

## Step 1 — Get the diff

Determine the base branch (default `main`; ask only if the repo clearly uses another,
e.g. `develop`/`master`). Then read the diff and the list of changed files:

```bash
git diff main...HEAD            # full diff of the branch
git diff --stat main...HEAD     # changed-file overview
```

If there are no commits/changes versus the base, tell the user and stop.

## Step 2 — Analyze (be conservative)

You **may** infer, from the diff alone:
- what changed technically (classes, methods, packages, control flow, validations,
  external calls, transactions),
- probable impacts and risk areas,
- a technical testing strategy.

You **must not** infer:
- functional context not visible in the code,
- implicit business rules or functional decisions,
- Azure DevOps / documentation links that weren't provided.

Use only information provided or clearly inferable from the changed code. When in doubt,
ask — don't guess.

## Step 3 — Pre-fill the template

Read `references/pr-template.md` and fill every technical section you can from the
analysis:
- **What changed?** — problem/requirement, motive, solution implemented in the Java code.
- **Expected feedback / Risk areas** — derive from what the diff touches (business
  logic, integrations, concurrency, DB access, version compatibility).
- **Unit Tests** — note added/changed test classes found in the diff.
- Leave checkboxes unchecked unless the diff proves them.

## Step 4 — Ask only for what's missing (one question at a time)

For each section still incomplete, ask a single, objective question — **one question per
section, never bundled** — and wait for the answer before moving on. Typical gaps:
- Azure DevOps Work Item link(s)
- Specification / design / wiki links
- Manual test steps and evidence (build, logs, screenshots)

If the user answers "doesn't exist" / "not applicable" / "none", mark that section as
**"Not applicable"** or omit it per the template. Don't ask about things the diff already
answers.

## Step 5 — Generate (only when authorized)

Do **not** produce the final PR until the user explicitly says something like
"no more information" or "you can generate the PR".

When authorized, output, in English:
1. A section titled `### PULL REQUEST TEXT` — the description to paste into the PR.
2. A section titled `### pull_request.md` — the full filled template in a separate
   Markdown block, and also write it to a `pull_request.md` file as a deliverable.

## Notes

- This does not access Azure DevOps and does not replace code review.
- The clearer the diff and commit messages, the better the generated PR.
- Review the content before submitting.
