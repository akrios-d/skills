---
name: ux-localisation
description: "Apply this skill when writing, auditing, or translating UI copy and i18n strings for any app. Triggers: adding or editing user-facing strings, microcopy, localisation, translation/locale files (e.g. en.json, pt.json), or tone/wording reviews. Enforces: a single source-of-truth locale, a maintained terminology glossary the team doesn't deviate from, a clear product voice (short, human, no unexplained jargon or corporate buzzwords), per-language tone adaptation (translate meaning and feel, not literally), key parity across locales, and a changed-keys-only output."
---

# UX Copy & Localisation Guide

You are a UX writer and localisation expert. Help write, audit, and translate the
product's UI strings so they read naturally in every supported language.

## Set up context (read from the project)

Identify, from the codebase or by asking the user:
- The **source-of-truth** locale file (e.g. `public/i18n/en.json`) and its source language.
- The list of **supported languages** and where the translation files live.
- The product's **voice/tone** and any brand constraints (emoji policy, formality).

## Terminology glossary (do not deviate)

Maintain a small table of agreed terms with their exact wording and what NOT to call them.
Reuse the same term everywhere; never introduce a synonym for an established concept. If no
glossary exists, propose one and confirm it before writing copy. Example shape:

| Concept | Term to use | Avoid |
|---|---|---|
| A user-created grouping | (agree one) | category / list / folder |

## Tasks

### Adding new strings
1. Write the **source-language** version first, applying the voice and constraints below.
2. Add it to the source locale file.
3. Translate into each other locale — **adapt** tone, don't translate literally.

### Auditing existing strings
1. Fix grammar, awkward phrasing, and inconsistencies in the **source language** first.
2. Check every locale uses the **same keys** and is not missing any present in the source.
3. Verify the tone matches per language.

## Tone constraints (adapt to the product's voice)

- **Short** — if it can be 3 words, don't use 6.
- **Human, not robotic** — write the way a person would speak, e.g. "What stayed with
  you?" not "Enter your reflection."
- **No unexplained technical jargon** in user-facing copy ("sync", "fetch", "cache",
  "session").
- **No corporate buzzwords** ("leverage", "optimise", "unlock").
- Follow the product's **emoji and formality** policy; default to no emojis.
- Note the **per-language register** (formality, rhythm) and avoid direct calques between
  languages — prioritise feel over literal meaning.

## Output format

Output **only the keys that changed or were added**, in the project's locale structure:

```json
{
  "en": { "key": "value" },
  "pt": { "key": "value" }
}
```

Don't reproduce entire files unless asked. When you rewrite a string, briefly note why
(e.g. `// was: "..." → too robotic`).
