#!/usr/bin/env bash
# macOS-only: synthesize speech using the built-in `say` command.
# Only works when run directly on a Mac - not available in this sandbox.
# Usage: synthesize_macos.sh <input.txt> <output_basename> [voice] [rate_wpm]
#
# List available voices with: say -v '?'
# Good built-in options: Samantha, Alex, Daniel (British), Karen (Australian).
set -e
INPUT="$1"
OUTPUT="$2"
VOICE="${3:-Samantha}"
RATE="${4:-175}"

command -v say >/dev/null || { echo "Error: 'say' is only available on macOS." >&2; exit 1; }

AIFF="${OUTPUT%.*}.aiff"
say -v "$VOICE" -r "$RATE" -f "$INPUT" -o "$AIFF"

if command -v ffmpeg >/dev/null; then
  ffmpeg -y -i "$AIFF" -codec:a libmp3lame -qscale:a 2 "${OUTPUT%.*}.mp3" -loglevel error
  rm -f "$AIFF"
  echo "Saved ${OUTPUT%.*}.mp3"
else
  # macOS's built-in afconvert can't encode mp3 (licensing), but ships with AAC support.
  afconvert -f m4af -d aac "$AIFF" "${OUTPUT%.*}.m4a"
  rm -f "$AIFF"
  echo "Saved ${OUTPUT%.*}.m4a (install ffmpeg via 'brew install ffmpeg' for mp3 output instead)"
fi
