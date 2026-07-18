---
name: git-conflict-resolver
description: Resolve Git conflicts automatically via rebase. Use whenever the user hits "CONFLICT" during a merge, rebase, or cherry-pick, mentions merge conflicts, asks to resolve conflicting files, or a git command fails with unmerged paths. Trivial conflicts (formatting, imports, non-overlapping edits) are resolved automatically. Substantive conflicts (logic changes) are resolved automatically too, but only kept if the project's test suite passes afterward — otherwise the conflict is reverted and flagged for the user with both sides explained. Always resolves in the context of a rebase, not a merge commit — if the branch is mid-merge, switch it to a rebase first.
---

# Git Conflict Resolver

Resolve Git conflict markers in a working tree via `git rebase`, verify the result with tests, and report clearly what was done. This skill always uses rebase — it never leaves a merge commit behind.

## Rebase-only policy

- If the repo is currently mid-merge (`git status` mentions unmerged paths from a merge, or `.git/MERGE_HEAD` exists), abort the merge and redo the operation as a rebase instead: `git merge --abort` then `git rebase <target-branch>`.
- If the user just says "resolve this conflict" without specifying merge vs rebase, assume rebase: drive the whole flow with `git rebase --continue` after each commit's conflicts are resolved, not a merge commit.
- "Incoming" always means the commit currently being replayed by the rebase. Prefer that side by default when a substantive conflict is genuinely mutually exclusive, since that's normally the change actively being landed.
- A rebase can hit conflicts on more than one commit in sequence — after each successful `git rebase --continue`, check `git status` again; if it reports a new conflict, repeat the workflow below for it.

## Optional: business-rules repo

Some projects keep business rules in a separate repo (not the one being merged) — a bunch of markdown files documenting domain/business logic, e.g. a "skill-spec" or "domain-docs" repo. If the user has mentioned one, or one is checked out locally, use it to understand intent behind substantive conflicts, not just the code diff.

- If you don't already know where it is, ask the user once for its path (or clone URL) the first time a substantive conflict needs it — don't assume a name or location.
- Once you know it, when a substantive hunk touches a specific module/feature, grep that repo's `.md` files for the relevant terms (module name, function name, feature name) to see if there's a documented rule about how it should behave.
- If the docs clarify which side of the conflict matches the intended business rule, resolve with that side (even overriding the default "prefer the incoming/rebased commit" tie-breaker) and cite which doc justified it in the report.
- If nothing relevant turns up, proceed with the normal classification rules — this lookup is a bonus signal, not a blocker.

## Workflow

1. **Locate conflicts**
   ```
   git status --porcelain | grep '^UU\|^AA\|^DD'
   ```
   For each unmerged file, read it and find `<<<<<<<` / `=======` / `>>>>>>>` blocks.

2. **Classify each conflict hunk**
   - If a business-rules repo is known (see above), check it for anything covering this hunk's module/feature first.
   - **Trivial** — safe to auto-resolve with high confidence:
     - Whitespace/formatting-only differences
     - Import/require ordering, or both sides adding different imports (merge both)
     - Both sides touch different, non-overlapping parts of the same function/block
     - Version bumps in lockfiles/manifests (take the higher version, unless it breaks a stated constraint)
   - **Substantive** — touches actual logic (conditionals, function bodies, return values, config values that affect behavior, overlapping edits to the same lines):
     - Still resolve automatically (see step 3), but treat the result as provisional until tests confirm it.

3. **Resolve each hunk**
   - Read the commit messages/diffs on both sides (`git log --oneline -3` on each ref, or `git show <ref>`) to understand *intent*, not just text.
   - For trivial hunks: merge mechanically (both sides if additive, else keep the non-conflicting logic).
   - For substantive hunks: produce the resolution that preserves the intent of both changes where possible. If the two sides are genuinely mutually exclusive (they can't both be true), default to the incoming commit (the one being replayed by the rebase) — say so explicitly in the report.
   - Remove all conflict markers. Stage the file (`git add`).

4. **Run tests**
   - Detect the test command from the repo (e.g. `package.json` scripts, `pytest.ini`/`pyproject.toml`, `Makefile`, `Gemfile`, `go.mod`). If ambiguous, check for a README/CONTRIBUTING mention. If no test setup is found, say so and skip to step 6 treating this as "untested."
   - Run the full test suite (or, if it's large/slow, at least the tests covering the touched files/modules).

5. **Decide outcome and continue the rebase**
   - **All trivial conflicts**, tests pass or no tests exist → run `git rebase --continue`. If that surfaces another conflict (next commit in the sequence), go back to step 1 for it.
   - **Any substantive conflict involved**:
     - Tests pass → run `git rebase --continue`, proceed to report, but flag which hunks were substantive so the user can spot-check them. Keep looping through `--continue` until the rebase finishes or a new conflict appears.
     - Tests fail → do **not** continue the rebase. Revert just the substantive hunk(s) back to conflict-marker form (trivial hunks already resolved can stay resolved and staged), stop, and ask the user for guidance. Show:
       - The failing test output (trimmed to the relevant failure)
       - Both original sides of the conflicting hunk, in plain terms (not just raw diff) — what each side was trying to do
       - The resolution that was attempted and why it likely broke things

6. **Report**
   Always end with a short summary:
   - Files touched, and for each: how many trivial vs substantive hunks
   - Test result (passed / failed / not run, and why)
   - Rebase outcome: finished cleanly, or stopped waiting for input on a specific commit
   - Do **not** force-push the result — leave that for the user, unless they've explicitly asked you to push.

## Safety rules

- Never use `git checkout --ours` / `--theirs` blindly across a whole file — that silently discards one side's changes even in non-conflicting lines. Resolve conflict blocks individually.
- Never force-push without the user asking.
- Switching a mid-merge state to a rebase (`git merge --abort` then `git rebase`) is part of the normal flow and doesn't need to wait for permission. Running `git rebase --abort` to bail out of a rebase entirely does need the user's OK — if you get stuck beyond what step 5 covers, stop and explain the state instead.
- If a conflict is in a binary file or a lockfile you can't safely hand-merge (e.g. `package-lock.json` with complex dependency trees), regenerate it via the normal tool (`npm install`, `poetry lock`, etc.) instead of hand-editing, and say that's what you did.
- If more than ~10 files or ~30 hunks are conflicted, pause after classifying and give the user a quick heads-up on scope before churning through all of them, in case they'd rather handle it differently (e.g. abort and rebase onto a different base).
