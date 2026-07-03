# React / JSX-specific review checklist

Read this when the diff touches `.jsx`/`.tsx` files, React hooks, or a React project (`package.json` has `"react"`). Apply this on top of the general checklist in SKILL.md, not instead of it.

## Hooks

- **Dependency arrays.** Check every changed `useEffect`/`useMemo`/`useCallback`. A dependency listing a whole object/array instead of the primitive fields it actually uses (e.g. `[record]` instead of `[record.name, record.id]`) recomputes on every render unless the upstream value is memoized — check whether it actually is before accepting the pattern. Conversely, a *missing* dependency usually means the effect/memo is reading a stale value.
- **Effect ordering / coordination via refs.** A pattern like "effect A sets `someRef.current = true` before calling `setValue`, effect B checks `someRef.current` to skip its own logic" can work, but only as long as nothing else can trigger effect B in between. Flag this as something to manually test under rapid user interaction or concurrent state updates — it's not necessarily a bug, but it's a fragile spot worth a note.
- **Derived state stored instead of computed.** If a `useState` is set from props/other state and then kept in sync via an effect, ask whether it should just be computed inline or via `useMemo` — synced state is a common source of stale-value bugs, especially across route/prop changes.

## Forms

- **Controlled vs uncontrolled inputs.** Check `value`/`onChange` pairs are complete — a controlled input needs both, and a half-controlled one silently reverts to uncontrolled behavior.
- **react-hook-form specifics (if used).** `watch()` re-renders on every keystroke of that field — not a problem by default. Do check that `setValue` calls use consistent options (`{ shouldDirty, shouldValidate }`) with sibling calls in the same file; inconsistency here is usually accidental, not deliberate.
- **Reset/disable logic changes.** A bugfix that removes a field-disabling condition (e.g. removing a `disabled={!otherField}` check, or removing a blocking overlay) is a real behavior change — confirm it matches the described bug rather than assuming it's correct. Also check whether the same disabling pattern exists elsewhere in the file that the diff *didn't* touch — partial fixes (only one of several near-identical blocked fields gets fixed) are a common miss.

## Data fetching (react-query / SWR / similar)

- Check `enabled` guards on queries that depend on a value that may be null/undefined at mount — a missing guard fires a request with garbage params on first render.
- Check the query key includes every value the query function actually reads — a key missing a param means stale cached data gets served after that param changes elsewhere in the app.
- **Type coercion between API and UI.** A hook that does `typeof x === 'number' ? x : null` silently drops numeric-looking strings from the API response. If the same field is coerced with `Number(x)` + `Number.isInteger(x)` elsewhere in the same diff, that inconsistency is worth flagging — one of the two is probably wrong for the real API response shape, and it can make a new feature silently no-op depending on how the backend serializes that field.

## Lists & rendering

- `key` props on mapped lists: index keys are fine for static lists, risky for lists that reorder or filter.
- Conditional rendering that silently drops a fallback (e.g. a `label` that used to fall back to a secondary description field and no longer does) — confirm this is intentional; it's an easy thing to lose during a refactor and can make previously-populated values render blank.

## General

- Duplicated constants or logic copy-pasted across two page/component files in the same diff — worth calling out as a candidate to extract into a shared module, but not usually a blocker on its own.
- New props threaded through multiple components — check the prop is actually read where it lands, not just passed through and dropped.
- Commented-out code left behind mid-refactor (`//const foo = ...`) — call it out for removal before merge.
