---
name: conventional-commit
description: "Stage and create a git commit with a message that follows the Conventional Commits 1.0.0 spec. Use whenever the user wants to commit changes, write a commit message, or 'make the commit'. Trigger on 'commit', 'make the commit', 'generate the commit message', 'conventional commit', 'commit my changes', or 'create a commit'. The skill inspects the diff, proposes a type(scope): description message (with body and footers when warranted), confirms with the user, then commits. It never pushes."
---

# Conventional Commit Assistant

Reads the staged/unstaged changes, writes a Conventional Commits 1.0.0 message, confirms,
and commits. Mirrors the pull-request skill, but for a single commit. **Never pushes.**

Spec reference: https://www.conventionalcommits.org/en/v1.0.0/

## Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

- **type** — required. One of: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`,
  `test`, `build`, `ci`, `chore`, `revert` (others allowed).
  - `feat` → a new feature (SemVer MINOR). `fix` → a bug fix (SemVer PATCH).
- **scope** — optional noun in parentheses naming the affected area, e.g. `feat(parser):`.
- **description** — required, immediately after `: `. Short, imperative, lowercase,
  no trailing period (e.g. `add ability to parse arrays`).
- **body** — optional, one blank line after the description; free-form, explains *what*
  and *why* (not how).
- **footers** — optional, one blank line after the body. `Token: value` or `Token #value`;
  tokens use `-` instead of spaces (e.g. `Reviewed-by`, `Refs: #123`).

### Breaking changes
Indicate with a `!` before the colon **and/or** a `BREAKING CHANGE:` footer.
- `feat(api)!: send email when product is shipped`
- or footer: `BREAKING CHANGE: <description>` (MUST be uppercase). Correlates with SemVer MAJOR.

## Step 1 — Inspect the changes

```bash
git status --short
git diff --staged          # what's already staged
git diff                   # unstaged changes
```

- If something is **already staged**, commit that set (don't silently add more).
- If **nothing is staged**, ask the user what to stage (specific files vs everything),
  then `git add` accordingly. Don't `git add -A` without confirming.

## Step 2 — Compose the message

From the diff, decide:
- the **type** (use the spec list above; `feat`/`fix` first, else the best fit),
- an optional **scope** (a noun for the touched area/module),
- a concise **description** (imperative, ≤ ~72 chars),
- a **body** if the change needs context,
- **footers** for issue refs / reviewers / breaking changes.

If the staged changes mix unrelated concerns (e.g. a feature **and** an unrelated fix),
recommend splitting into multiple commits — that's the spirit of the spec.

## Step 3 — Confirm, then commit

Show the full proposed message and get the user's OK (or edits). Then commit, using one
`-m` per block so body/footers are separated correctly:

```bash
git commit -m "feat(parser): add ability to parse arrays" \
           -m "Handles nested arrays and trailing commas." \
           -m "Refs: #123"
```

For a breaking change footer, put it in its own `-m`:
```bash
git commit -m "feat(api)!: change auth header format" \
           -m "BREAKING CHANGE: clients must send Bearer tokens in Authorization."
```

Report the result (`git log -1 --oneline`). **Do not push** — leave that to the user.

## Notes

- Casing is not enforced by the spec except `BREAKING CHANGE` (uppercase); be consistent.
- For reverts: use `revert:` with a `Refs:` footer listing the reverted SHAs.
