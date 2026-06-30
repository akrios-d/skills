---
name: video-setup
description: >
  Analyzes a code repository or document and generates a structured video production
  script with scenes, then creates a project.json that tracks the entire
  production. Use this whenever the user wants to produce a demo video, hackathon
  submission, product walkthrough, or presentation from a codebase or document — even
  if they don't say "video" explicitly. Trigger on phrases like "make a video of the project", "create a script", "help me record a demo", "make a walkthrough", or
  "presentation video".
---

# Video Setup

Your job: understand the subject, generate a compelling scene-by-scene script, and
create a `project.json` that drives the rest of the production pipeline.

## Step 1 — Understand the subject

If pointed to a repository, read: `CLAUDE.md`, `README.md`, key source files.
If given a document (PDF, MD), read its full content.
If the user describes verbally, ask at most 3 questions:
- What core problem does it solve?
- What are the 2–4 most impressive features to show?
- Who is the audience?

## Step 2 — Generate the script

Write scenes. Each scene has a narrative purpose, narration text, visual type, and
estimated duration (~2.5 words/second is a comfortable narration pace).

**Scene types:**
- `animation` — programmatically generated (no recording needed)
- `recording` — user records screen; specify exactly what to click/show
- `ken_burns` — Ken Burns zoom/pan on a static image
- `slideshow` — sequence of images with crossfade
- `end_card` — static image, ~6s, always last

**Narration rules (critical):**
- Natural spoken language — write how people talk
- Never use "/" — ElevenLabs reads it as "slash". Write "and" or restructure.
- No abbreviations that sound odd when spoken aloud
- Each scene should make sense on its own

**Typical structure (adapt freely):**
1. Hook — the problem (~13s, animation)
2. Solution — what the product is (~13s, recording or animation)
3–5. Feature demos — 2–4 key features (15–30s each, recordings)
6. Architecture — how it's built (~40s, ken_burns + slideshow)
7. End card (~6s)

## Step 3 — Confirm with the user

Show the full script as a numbered list (scene name, type, narration, visual notes).
Ask: "Want to adjust any scene before we start?" Wait for confirmation.

## Step 4 — Create project.json

Save to `docs/video/project.json` (create dir if needed):

```json
{
  "project_name": "short-identifier",
  "output_dir": "docs/video",
  "voice_id": "",
  "scenes": [
    {
      "id": 1,
      "name": "problem",
      "type": "animation",
      "narration": "exact text to send to ElevenLabs",
      "visual_notes": "what to show or generate",
      "estimated_duration_sec": 13,
      "status": "pending",
      "audio_file": null,
      "audio_duration_sec": null,
      "clip_file": null,
      "approved": false
    }
  ],
  "clips_approved": [],
  "final_video": null,
  "created_at": "ISO timestamp"
}
```

After saving, tell the user:
- Scene count and total estimated duration
- Next: run `/video-scene` to start scene 1
- If they have an ElevenLabs API key, add it and set `voice_id` in project.json
