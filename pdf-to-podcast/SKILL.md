---
name: pdf-to-podcast
description: >
  Convert a PDF (research paper, article, report) into a narrated podcast-style MP3. Use
  whenever the user asks to "turn this PDF into a podcast", "make an audio version of this
  paper", "read this document to me as a podcast", "generate a podcast from this article", or
  similar — even if they don't say "podcast" explicitly but want an audio narration of a
  document. Runs fully offline, no external TTS or LLM APIs — Claude extracts the text, writes
  the narration script itself, and synthesizes speech locally with espeak-ng and ffmpeg.
---

# PDF to Podcast

Turns an uploaded PDF into a narrated MP3. Everything runs locally — no Groq, no gTTS, no
network calls at synthesis time — because sandboxed environments typically can't reach those
APIs. Speech is synthesized with `espeak-ng` (installed via apt) and encoded with `ffmpeg`.

**Set expectations with the user up front**: `espeak-ng` sounds robotic, not like a human
podcast host. If the user needs natural-sounding voices, tell them this skill can produce the
script and a rough audio draft, but human-quality TTS would require an API key for a service
like ElevenLabs, OpenAI TTS, or PlayHT (not available in this sandbox by default).

## Workflow

1. **Extract text**
   ```bash
   pip install pypdf --break-system-packages   # if not already installed
   python3 scripts/extract_text.py input.pdf /home/claude/paper.txt
   ```

2. **Write the narration script yourself** — do not just read the raw extracted text aloud.
   Read `/home/claude/paper.txt` and write a new, original narration script in your own words:
   spoken, conversational tone, short sentences, an intro that states what the paper is about,
   a walkthrough of the key points/findings, and a short wrap-up. Save it as a plain `.txt` file
   (e.g. `/home/claude/script.txt`). This is a genuine rewrite, not a copy of the source — keep
   normal paraphrasing/citation practice in mind, same as any other summary.
   - For a two-host dialogue style, write alternating lines and synthesize each speaker's lines
     separately with a different `voice` (see step 3), then concatenate the resulting audio
     files with `ffmpeg -f concat`.

3. **Synthesize speech**
   ```bash
   chmod +x scripts/synthesize.sh
   scripts/synthesize.sh /home/claude/script.txt /home/claude/podcast.mp3 en-us 165
   ```
   - `voice`: e.g. `en-us`, `en-gb`, `en-us+f3` (a female-sounding variant). List all with
     `espeak-ng --voices`.
   - `speed_wpm`: words per minute, default 165. Slower (~140) reads clearer for dense material.
   - For long scripts, synthesis is fast and doesn't need chunking — espeak-ng handles full files.

4. **Optional: mix in background music**
   ```bash
   chmod +x scripts/mix_background.sh
   scripts/mix_background.sh /home/claude/podcast.mp3 /path/to/music.mp3 /home/claude/podcast_final.mp3 -18dB
   ```
   Music loops under the narration and is trimmed to the narration's length. Lower `-18dB`
   (e.g. `-24dB`) if the music overpowers the voice.

5. **Deliver the file**
   Copy the final MP3 to `/mnt/user-data/outputs/` and use `present_files` to share it.

## Notes

- If a user uploads a PDF, extract text from the actual uploaded file at
  `/mnt/user-data/uploads/...` — don't fabricate content.
- Keep narration length reasonable; a full paper verbatim makes for a very long, low-quality
  listen. Summarizing to the core contributions is usually the right call unless the user asks
  for full coverage.
- If the user explicitly wants higher-quality voices and has (or is willing to provide) an API
  key for a TTS provider, that's a different workflow — ask before assuming espeak-ng is good
  enough for their use case.
