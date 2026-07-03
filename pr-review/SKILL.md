---
name: pr-review
description: Use this skill whenever the user asks to review a pull request or merge request, review a diff/branch before merging, do a code review, or asks things like "review this PR", "any issues with this branch/PR", "code review this", "check these changes before I open the PR", "any issues with this diff". Trigger it even when the user doesn't say "review" explicitly but is clearly asking for a second pair of eyes on a set of code changes, in any language. Works for any language or stack — it automatically pulls in React-specific checks (references/react.md) or Java 25-specific checks (references/java25.md) when the diff touches those stacks, on top of the general checklist.
---

# PR Review

Review a set of code changes (a PR/MR, a branch diff, or a pasted diff) and report problems and suggestions — the same way a careful senior engineer would read a diff before approving it.

## 1. Get the diff

Try these in order, and stop at the first that works:

1. **User pasted a diff directly** — use it as-is.
2. **`gh` CLI available and remote is GitHub** — `gh pr list` to find the PR, then `gh pr diff <number>`.
3. **Local git repo, no GitHub/gh** — figure out the base branch (usually `main`/`master`/`develop`, check `git remote show origin` or just try the common names) and run something like:
   ```
   git diff <base>...<current-branch> -- ':!*.lock' ':!package-lock.json' ':!*.min.js'
   ```
   Prefer three-dot (`...`, diff against the merge-base) over two-dot — it shows only what the branch actually adds, not unrelated drift on the base branch.
4. **Nothing obvious** — ask the user which branch, PR link, or diff to look at. Don't guess at a base branch or silently review the wrong thing.

If the diff is huge (property of hobby/monorepo changes, generated files, lockfiles), exclude generated/vendored paths so you're reading signal, not noise.

## 2. Read beyond the diff

Diff hunks hide context. Before judging whether a dependency array is right, whether a removed check was truly redundant, or whether a precedence swap is a bug — open the full file(s) around the change, not just the ± lines.

If there's a PR description, ticket, or commit messages available, skim them for the *stated* intent. You're checking whether the diff matches that intent, and calling out anything that goes beyond it.

## 3. Detect the stack and load the matching reference

- Diff touches `.jsx`/`.tsx` files, React hooks (`useEffect`, `useState`, etc.), or `package.json` has `"react"` → read `references/react.md` before writing the review.
- Diff touches `.java` files, or there's a `pom.xml`/`build.gradle` → read `references/java25.md` before writing the review.
- Neither → just use the general checklist below.
- Both can apply in a full-stack PR — read both reference files in that case.

## 4. General checklist (apply regardless of stack)

- **Correctness** — does the change do what it claims? Watch for things easy to skim past: an operator swap, a precedence change between two data sources (e.g. `a || b` silently becoming `b || a`), an off-by-one, wrong null/undefined handling.
- **Unexplained behavior changes** — any line that changes behavior in a way not obviously tied to the PR's stated purpose. Flag it as a question ("was this intentional?"), not an accusation — you often can't tell from the diff alone whether it's a fix bundled in or a stray edit.
- **Consistency** — does new code follow the patterns already used nearby (naming, coercion style, error handling)? If the same PR validates or coerces the same kind of value two different ways in two places it touched, that's almost always worth a note — one of the two is probably wrong for the real data shape.
- **Dead code / leftovers** — commented-out code, debug `console.log`/`print`, unused imports or variables introduced by this diff. Don't flag pre-existing dead code the PR didn't touch.
- **Error handling** — silently swallowed errors, unguarded external/network calls, missing null checks on newly-added fields.
- **Security basics** — input validation, injection risk, hardcoded secrets, missing auth checks on new endpoints.
- **Scope** — is the diff doing more than the stated task needs (refactoring unrelated code, renaming things, widening permissions/behavior beyond the described bug)? Call this out as a question, since scope creep is sometimes intentional and just needs confirming.
- **Fragile coordination** — cross-effect/cross-function coordination via mutable flags, refs, shared/global state, or anything relying on execution order that isn't structurally guaranteed. Worth flagging as "needs a manual test of this specific race," not necessarily as a bug.

## 5. Write the review

- Group findings by concern, in prose — not one bullet per changed line, and not a bullet for every file whether or not it has an issue.
- For each finding: say what changed, why it matters, and if you can't tell intent from the diff alone, ask rather than assert it's wrong.
- Don't restate the whole diff back to the user — they can already see it.
- Close by separating what's actually blocking from what's a question or nice-to-have, so the user knows what needs a decision before merging.
- Reply in the same language the user used.
- If a file or section is clean, say nothing about it — don't manufacture a finding to look thorough.

## Notes

- If you can't get a diff at all (no repo, no `gh`, nothing pasted, and the user hasn't clarified), say so and ask for a diff or a repo/branch to look at instead of guessing.
- This skill is about reading and reporting, not fixing. Only make edits if the user explicitly asks you to apply a fix after the review.
