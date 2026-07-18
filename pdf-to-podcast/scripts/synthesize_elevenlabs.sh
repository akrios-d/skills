#!/usr/bin/env bash
# Convert a text file into an mp3 using the ElevenLabs TTS API (requires internet + API key).
# This is an OPTIONAL upgrade path over the offline MBROLA voices - use it only when the
# environment can reach api.elevenlabs.io and ELEVENLABS_API_KEY is set.
#
# Usage: synthesize_elevenlabs.sh <input.txt> <output.mp3> [voice_id] [model_id]
#
# Default voice_id is "21m00Tcm4TlvDq8ikWAM" (Rachel, a stock ElevenLabs voice).
# Find more voice IDs at https://elevenlabs.io/app/voice-library or via the /v1/voices endpoint.
set -e
INPUT="$1"
OUTPUT="$2"
VOICE_ID="${3:-21m00Tcm4TlvDq8ikWAM}"
MODEL_ID="${4:-eleven_turbo_v2_5}"

if [[ -z "$ELEVENLABS_API_KEY" ]]; then
  echo "Error: set the ELEVENLABS_API_KEY environment variable first." >&2
  exit 1
fi

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

# ElevenLabs has a per-request character limit, so split the script into
# paragraph-sized chunks (~4000 chars) and synthesize + concatenate each one.
python3 - "$INPUT" "$WORKDIR" << 'PYEOF'
import sys, os
input_path, workdir = sys.argv[1], sys.argv[2]
text = open(input_path).read()
paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]

chunks, current = [], ""
for p in paragraphs:
    if len(current) + len(p) + 2 > 4000:
        chunks.append(current)
        current = p
    else:
        current = f"{current}\n\n{p}" if current else p
if current:
    chunks.append(current)

for i, chunk in enumerate(chunks):
    with open(os.path.join(workdir, f"chunk_{i:03d}.txt"), "w") as f:
        f.write(chunk)
PYEOF

CONCAT_LIST="$WORKDIR/concat.txt"
> "$CONCAT_LIST"

for chunk_file in "$WORKDIR"/chunk_*.txt; do
  idx=$(basename "$chunk_file" .txt)
  mp3_file="$WORKDIR/${idx}.mp3"
  text=$(cat "$chunk_file")

  http_status=$(curl -s -o "$mp3_file" -w "%{http_code}" \
    -X POST "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
    -H "xi-api-key: ${ELEVENLABS_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c 'import json,sys; print(json.dumps({"text": sys.argv[1], "model_id": sys.argv[2]}))' "$text" "$MODEL_ID")")

  if [[ "$http_status" != "200" ]]; then
    echo "ElevenLabs API error (HTTP $http_status) on $chunk_file:" >&2
    cat "$mp3_file" >&2
    exit 1
  fi

  echo "file '$mp3_file'" >> "$CONCAT_LIST"
done

ffmpeg -y -f concat -safe 0 -i "$CONCAT_LIST" -c copy "$OUTPUT" -loglevel error
echo "Saved $OUTPUT"
