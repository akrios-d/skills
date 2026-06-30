---
name: video-scene
description: >
  Drives the scene-by-scene production loop for a video project. Reads the current
  scene from project.json, walks the user through: reviewing and refining the ElevenLabs
  narration text, receiving the audio, giving screen recording instructions, processing
  the clip, and confirming before moving to the next scene. Use this skill after
  video-setup is done, and re-invoke it for each scene. Trigger on "next scene",
  "let's move to the next", "start scene", or whenever the user wants to
  produce the next scene of their video project.
---

# Video Scene — Scene-by-Scene Production Loop

Read `docs/video/project.json` to find the current scene (first with `status: "pending"`).
If none are pending, all scenes are done — tell the user to run `/video-assemble`.

## For each scene, follow this exact sequence:

### 1. Show current scene info
Tell the user: which scene number, name, type, and narration text.

### 2. Refine the narration text
Review the narration with the user. Suggest improvements for:
- Natural flow when spoken aloud
- Pacing (aim for ~2.5 words/second)
- No "/" characters (ElevenLabs reads as "slash")
- Connecting naturally from the previous scene

Confirm the final text. Update `narration` in project.json if changed.

### 3. Get the audio

**If the project has a voice_id and ElevenLabs API key configured:**
Tell the user: "I can generate the audio automatically — use `/video-elevenlabs` with the
confirmed text."

**Otherwise:**
Tell the user to go to ElevenLabs (elevenlabs.io), paste the confirmed narration,
generate with their chosen voice, and upload the MP3 here.

When the MP3 arrives:
- Note the actual duration with ffprobe
- Save audio_file path and audio_duration_sec to project.json

### 4. Give recording instructions (for `recording` type scenes)

Tell the user exactly what to record:
- Which screen/app to show
- What actions to perform in order
- Target duration: match the audio (~audio_duration × 1.3 buffer for speedup flexibility)

For `animation`, `ken_burns`, `slideshow` types: skip this step, go straight to render.

When the user uploads a recording:
- Check its duration
- If longer than audio: calculate speedup ratio = recording_dur / audio_dur
  - If ratio ≤ 2.0: apply uniform speedup with `/video-render`
  - If ratio > 2.0: suggest keeping first N seconds normal + timelapse the rest

### 5. Render the clip

Call `/video-render` (or do it inline) to produce the final clip for this scene.
The output is `docs/video/clip_XX_name.mp4` with video and audio embedded.

After rendering, update project.json:
- `clip_file`: path to the output mp4
- `status`: "rendered"

### 6. Confirm with the user

Present the clip. Wait for explicit approval ("ok", "perfect", "let's move on",
"good", or similar). 

On approval:
- Set `approved: true` and `status: "approved"` in project.json
- Add clip_file to `clips_approved` list
- Tell the user the next scene and ask if they're ready

On rejection:
- Ask what to fix (audio timing, visual, speed, etc.)
- Re-render with the fix
- Repeat until approved

**Never move to the next scene without explicit approval.**

## project.json update pattern

After each step, write the updated project.json immediately. Don't batch updates —
if the session crashes, the user can resume from the last saved state.
