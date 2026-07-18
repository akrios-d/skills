# pdf-to-podcast

Turns a PDF (research paper, article, report) into a narrated podcast-style MP3.

`SKILL.md` is the instruction file Claude reads to run this workflow. This README is for
humans browsing the repo.

## How it works

1. **Extract text** from the PDF (`scripts/extract_text.py`, uses `pypdf`).
2. **Write a narration script** — Claude reads the extracted text and writes an original,
   spoken-style script itself (no external LLM call needed).
3. **Synthesize speech** — several options, from fully offline/free to paid/natural-sounding:

| Script | Voice quality | Requires | Platform |
|---|---|---|---|
| `synthesize.sh` | Robotic-but-clear (MBROLA diphone) | Nothing (apt-installed) | Linux |
| `synthesize_elevenlabs.sh` | Natural (neural) | Internet + ElevenLabs API key | Any |
| `synthesize_macos.sh` | Decent (OS built-in) | Nothing | macOS only |
| `synthesize_windows.ps1` | Decent (OS built-in) | Nothing | Windows only |

4. **Optional:** mix in background music (`scripts/mix_background.sh`).
5. Deliver the final MP3.

## Requirements

- Python 3 + `pypdf` (`pip install pypdf`)
- `espeak-ng` + `mbrola` + `mbrola-us1`/`mbrola-us2`/`mbrola-en1` (Linux path, via `apt`)
- `ffmpeg`
- For the ElevenLabs path: an `ELEVENLABS_API_KEY` and internet access
- For the Mac/Windows paths: nothing extra — they use each OS's built-in TTS

## Notes

- The default Linux/MBROLA path sounds like a diphone synthesizer, not a human — set that
  expectation with users before they listen.
- The ElevenLabs and native-OS paths sound noticeably better; use them when available.
- See `SKILL.md` for the full step-by-step instructions Claude follows, including exact
  commands and flags for each option.
