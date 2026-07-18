#!/usr/bin/env bash
# Convert a text file into an mp3 using fully offline TTS (espeak-ng).
# Usage: synthesize.sh <input.txt> <output.mp3> [voice] [speed_wpm]
set -e
INPUT="$1"
OUTPUT="$2"
VOICE="${3:-en-us}"
SPEED="${4:-165}"

command -v espeak-ng >/dev/null || { echo "Installing espeak-ng..."; apt-get install -y espeak-ng >/dev/null; }

WAV="${OUTPUT%.mp3}.wav"
espeak-ng -v "$VOICE" -s "$SPEED" -f "$INPUT" -w "$WAV"
ffmpeg -y -i "$WAV" -codec:a libmp3lame -qscale:a 2 "$OUTPUT" -loglevel error
rm -f "$WAV"
echo "Saved $OUTPUT"
