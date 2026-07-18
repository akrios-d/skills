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
APIs. Speech is synthesized with `espeak-ng` using **MBROLA diphone voices** (installed via
apt) and encoded with `ffmpeg`. MBROLA sounds noticeably smoother than espeak-ng's default
formant synthesis, since it concatenates real recorded speech segments instead of generating
the waveform from scratch.

**Set expectations with the user up front**: this still sounds like a diphone-synthesizer
voice, not a human podcast host — closer to old GPS/phone-system voices than to ElevenLabs
or similar. If the user has an ElevenLabs API key (and the environment can reach the
internet), step 3b below swaps in ElevenLabs for a much more natural voice at the cost of
their API usage. Neural TTS models that run fully offline (e.g. Piper) can't be downloaded
in this sandbox by default, since their voice files are hosted on Hugging Face, which isn't
on the network allowlist — worth checking again in case that changes.

## Workflow

1. **Extract text**
   ```bash
   pip install pypdf --break-system-packages   # if not already installed
   python3 scripts/extract_text.py input.pdf /home/claude/paper.txt
   ```

2. **Write the narration script yourself** — do not just read the raw extracted text aloud,
   and do not over-condense it either. Read `/home/claude/paper.txt` and write a new,
   original narration script in your own words: spoken, conversational tone, short sentences.
   Default to a **thorough** script, not a short one:
   - Cover every major section of the source (background, each key point/method/finding,
     numbers and specifics, caveats, conclusion) — not just a two-line gist of each.
   - As a rough guide, aim for roughly 1 minute of narration (about 150 words) per page of
     source material, unless the user asks for something shorter. A 10-page paper should
     produce a script in the 1,200–1,800 word range, not a 300-word blurb.
   - Only compress heavily if the user explicitly asks for a "quick" or "short" version — the
     default should favor completeness over brevity.
   - Save the script as a plain `.txt` file (e.g. `/home/claude/script.txt`). This is a genuine
     rewrite, not a copy of the source — keep normal paraphrasing/citation practice in mind,
     same as any other summary.
   - For a two-host dialogue style, write alternating lines and synthesize each speaker's lines
     separately with a different `voice` (see step 3), then concatenate the resulting audio
     files with `ffmpeg -f concat`.

3. **Synthesize speech**
   ```bash
   chmod +x scripts/synthesize.sh
   scripts/synthesize.sh /home/claude/script.txt /home/claude/podcast.mp3 mb-us1 150
   ```
   - `voice`: defaults to `mb-us1` (US female, MBROLA). Other good options: `mb-us2` (US
     male), `mb-en1` (British male). List all installed MBROLA voices with
     `espeak-ng --voices=mbrola`. Falling back to plain espeak-ng voices (`en-us`, `en-gb`,
     etc.) is possible but sounds noticeably worse — only do this if MBROLA fails to install.
   - `speed_wpm`: words per minute, default 150 (MBROLA reads a bit slower/clearer than the
     default formant voices). Slower (~130) reads clearer for dense material.
   - For long scripts, synthesis is fast and doesn't need chunking — espeak-ng handles full files.

3b. **Optional: ElevenLabs instead of MBROLA (natural-sounding voice)**
   If the environment has internet access and the user has an ElevenLabs API key, use
   `scripts/synthesize_elevenlabs.sh` instead of step 3 for a much more natural voice:
   ```bash
   export ELEVENLABS_API_KEY="their-key-here"
   chmod +x scripts/synthesize_elevenlabs.sh
   scripts/synthesize_elevenlabs.sh /home/claude/script.txt /home/claude/podcast.mp3
   ```
   - Ask the user for their API key first; never assume one is available. This talks to
     `api.elevenlabs.io`, which is blocked in sandboxes without that domain allowlisted (this
     skill's default sandbox can't reach it — check before promising it will work).
   - Optional args: `voice_id` (default is "Rachel", a stock ElevenLabs voice — browse more
     at https://elevenlabs.io/app/voice-library) and `model_id` (default `eleven_turbo_v2_5`).
   - The script auto-chunks long scripts to stay under ElevenLabs' per-request character
     limit and concatenates the resulting audio.
   - This incurs API usage costs on the user's ElevenLabs account — mention that upfront.

3c. **Optional: native OS voices (Mac/Windows), when running locally on the user's machine**
   These only work if you (or the user) are running this outside a Linux sandbox, directly on
   a Mac or Windows PC. They're offline, free, and sound clearly better than MBROLA, though
   still not neural-quality.
   - **Mac** — uses the built-in `say` command:
     ```bash
     chmod +x scripts/synthesize_macos.sh
     scripts/synthesize_macos.sh script.txt podcast Samantha 175
     ```
     Outputs `podcast.mp3` if `ffmpeg` is installed, otherwise `podcast.m4a`. List voices with
     `say -v '?'`.
   - **Windows** — uses the built-in `System.Speech` API via PowerShell:
     ```powershell
     powershell -File scripts/synthesize_windows.ps1 -InputFile script.txt -OutputFile podcast.wav -Voice "Microsoft Zira Desktop"
     ```
     Outputs WAV (Windows has no built-in mp3 encoder); convert with `ffmpeg` afterwards if
     an mp3 is needed. List voices per the comment at the top of the script.

   If you're Claude running this skill inside your own sandboxed bash tool, you almost
   certainly can't reach these — they only apply when a user runs the scripts themselves, or
   when you're operating directly on their OS (e.g. via a desktop agent).

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
- Keep narration reasonably thorough by default (see the length guidance in step 2) — a
  300-word blurb from a 20-page paper loses too much. Only trim aggressively if the user asks
  for something short or quick.
- If the user explicitly wants higher-quality voices and has (or is willing to provide) an API
  key for a TTS provider, that's a different workflow — ask before assuming espeak-ng is good
  enough for their use case.
