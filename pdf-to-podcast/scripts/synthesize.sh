#!/usr/bin/env bash
# Convert a text file into an mp3 using fully offline TTS (espeak-ng + MBROLA).
# MBROLA diphone voices sound noticeably smoother than espeak-ng's default
# formant synthesis. Usage: synthesize.sh <input.txt> <output.mp3> [voice] [speed_wpm]
#
# Recommended voices: mb-us1 (US female), mb-us2 (US male), mb-en1 (British male).
# Run `espeak-ng --voices=mbrola` to see all installed MBROLA voices.
set -e
INPUT="$1"
OUTPUT="$2"
VOICE="${3:-mb-us1}"
SPEED="${4:-150}"

command -v espeak-ng >/dev/null || { echo "Installing espeak-ng..."; apt-get install -y espeak-ng >/dev/null; }
if [[ "$VOICE" == mb-* ]] && ! command -v mbrola >/dev/null; then
  echo "Installing MBROLA + English voices..."
  apt-get install -y mbrola mbrola-us1 mbrola-us2 mbrola-en1 >/dev/null
fi

WAV="${OUTPUT%.mp3}.wav"
espeak-ng -v "$VOICE" -s "$SPEED" -f "$INPUT" -w "$WAV"
ffmpeg -y -i "$WAV" -codec:a libmp3lame -qscale:a 2 "$OUTPUT" -loglevel error
rm -f "$WAV"
echo "Saved $OUTPUT"
