---
name: video-subtitle
description: >
  Generates subtitles for a video file using Whisper (local transcription) and
  optionally translates them via Google Translate. Runs a 2-step pipeline:
  transcribe → translate. Outputs a ready-to-use .srt file.
  Use this skill whenever the user wants subtitles, captions, or transcriptions
  from a video or audio file. Trigger on "generate subtitles", "transcribe the video",
  "I want subtitles in English", "subtitle this", "transcribe", "SRT", or any mention
  of adding captions or subtitles to a video.
---

# Video Subtitle Pipeline

Generates a (optionally translated) `.srt` subtitle file from a video in 2 steps:
1. **Transcribe** — faster-whisper extracts speech and writes a valid SRT directly
   (proper `HH:MM:SS,mmm` timestamps — no post-processing needed)
2. **Translate** *(optional)* — Google Translate converts the subtitle text to the
   target language, batching many lines per request for speed

## Step 1 — Collect inputs

Ask the user (or infer from context):
- **video_file**: path to the video/audio file (mp4, mp3, wav, etc.)
- **source_language**: spoken language in the video (e.g. `zh`, `pt`, `en`, `es`, `auto`)
- **target_language**: language for the translated SRT (e.g. `en`, `pt`, `es`).
  Skip translation if source == target or user doesn't want translation.
- **model_size**: Whisper model — `tiny` (fast), `base`, `small`, `medium` (default),
  `large-v3` (most accurate, slowest). Ask if quality vs speed matters.
- **device**: `cpu` (default) or `cuda` (if GPU available)
- **output_dir**: where to save the SRT files (default: same folder as the video)

## Step 2 — Install dependencies

```bash
pip install faster-whisper deep-translator --break-system-packages -q
```

## Step 3 — Run the pipeline

Scripts are in the `scripts/` folder next to this SKILL.md.
Use the SKILL.md directory as the base path for scripts.

```bash
SCRIPTS="<skill_dir>/scripts"
VIDEO="<video_file>"
OUT_DIR="<output_dir>"
BASE="$(basename "$VIDEO" | sed 's/\.[^.]*$//')"

# Step 1: Transcribe → valid SRT (proper timestamps)
python3 "$SCRIPTS/transcribe.py" \
  "$VIDEO" \
  "$OUT_DIR/${BASE}.srt" \
  "<source_language>" \
  "<model_size>" \
  "<device>"

# Step 2: Translate (skip entirely if source == target or no translation wanted)
python3 "$SCRIPTS/translate_srt.py" \
  "$OUT_DIR/${BASE}.srt" \
  "$OUT_DIR/${BASE}_<target_language>.srt" \
  "<source_lang_translate>" \
  "<target_language>"
```

### Language code mapping for Google Translate (source param in translate_srt.py)
| Whisper lang | Google Translate source |
|---|---|
| `zh` | `zh-CN` |
| `pt` | `pt` |
| `en` | `en` |
| `es` | `es` |
| `auto` | `auto` |

## Step 4 — Present results

Tell the user:
- Which SRT file(s) were created and their paths
- How many subtitle segments were generated
- Elapsed time (whisper can be slow on CPU for long videos — set expectations upfront)

If translation was skipped, mention the transcribed SRT is ready to use as-is.

## Tips

- The transcribed SRT is already valid and works in video players and editors —
  there is no separate "fix timestamps" step.
- For long videos (>30 min) on CPU, `tiny` or `base` models are much faster with
  acceptable accuracy for common languages.
- `large-v3` is best for low-quality audio, accents, or rare languages.
- If `cuda` is available (NVIDIA GPU), transcription is 5–10× faster.
- `transcribe.py` enables Whisper's VAD filter to skip silence — faster and fewer
  hallucinated segments. It uses `int8` on CPU / `float16` on GPU for speed.
- `translate_srt.py` batches many lines into each Google Translate request, so it
  stays fast even on long videos. The bottleneck is the network and the Whisper
  model (already native C++ via CTranslate2), not Python.
- For Chinese source: use `zh-CN` (not `zh`) in the Google Translate source param.
