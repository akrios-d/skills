#!/usr/bin/env bash
# Overlay narration over looped, volume-reduced background music.
# Usage: mix_background.sh <narration.mp3> <music.mp3> <output.mp3> [music_volume_db]
set -e
NARRATION="$1"
MUSIC="$2"
OUTPUT="$3"
VOL="${4:--18dB}"

DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$NARRATION")

ffmpeg -y -i "$NARRATION" -stream_loop -1 -i "$MUSIC" \
  -filter_complex "[1:a]volume=${VOL}[bg];[0:a][bg]amix=inputs=2:duration=first:dropout_transition=2" \
  -t "$DUR" "$OUTPUT" -loglevel error
echo "Saved $OUTPUT"
