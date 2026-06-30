---
name: video-assemble
description: >
  Assembles all approved scene clips from a video project into a single final video.
  Reads clips_approved from project.json, applies xfade transitions between clips,
  and handles timeout avoidance by splitting into parts when needed. Use this skill
  when all scenes are approved and the user is ready for the final video: "assemble the
  final video", "assemble", "join the clips", "final video", or when video-scene
  reports all scenes are done.
---

# Video Assemble

Reads `docs/video/project.json`, takes all clips in `clips_approved`, and produces
the final video with smooth crossfade transitions.

## Step 1 — Verify clips

Read project.json. For each clip in `clips_approved`:
```bash
ffprobe -v quiet -show_streams <clip_file> | grep "^duration"
```

Check that:
- Video and audio durations are within 0.5s of each other (if not, flag to user)
- All clips are 1920x1080 H.264 with AAC audio mono
- Channel count is consistent (all mono or all stereo)

Fix any channel mismatch before continuing:
```bash
# Convert stereo to mono
ffmpeg -y -i clip.mp4 -ac 1 clip_fixed.mp4
```

## Step 2 — Get actual durations

Use ffprobe to get the real video stream duration for each clip (not audio — they
can differ). Record these as `v_dur[i]` for each clip i.

## Step 3 — Calculate xfade offsets (CRITICAL)

The most common assembly bug is wrong xfade offsets causing black screens.

**Correct formula:**
```
XFADE_DUR = 0.5  # seconds

For clips [c0, c1, c2, c3, ...] with video durations [v0, v1, v2, v3, ...]:

accumulated = v0
offset[0] = accumulated - XFADE_DUR      # transition into c1

accumulated = accumulated + v1 - XFADE_DUR
offset[1] = accumulated - XFADE_DUR      # transition into c2

accumulated = accumulated + v2 - XFADE_DUR
offset[2] = accumulated - XFADE_DUR      # transition into c3
...
```

In Python:
```python
xfade_dur = 0.5
offsets = []
acc = v_durs[0]
for v_dur in v_durs[1:]:
    offsets.append(acc - xfade_dur)
    acc = acc + v_dur - xfade_dur
```

**Never set offset = accumulated (= end of stream). Always subtract xfade_dur.**

## Step 4 — Assemble (split strategy for long videos)

Re-encoding long videos (>80s) in a single ffmpeg call risks timeout. Use this strategy:

**If total video duration ≤ 80s:** assemble in one ffmpeg call with full xfade chain.

**If total video duration > 80s:** split into parts A and B.
- Part A: first ~half of clips assembled with xfade
- Part B: second ~half assembled with xfade
- Final: `ffmpeg -f concat -c copy` to join parts (stream copy = instant, no timeout)

```bash
# Part assembly (example for 3 clips → part):
ffmpeg -y \
  -i clip_01.mp4 -i clip_02.mp4 -i clip_03.mp4 \
  -filter_complex "
    [0:v][1:v]xfade=transition=fade:duration=0.5:offset={offset0}[v01];
    [v01][2:v]xfade=transition=fade:duration=0.5:offset={offset1}[vout];
    [0:a][1:a][2:a]concat=n=3:v=0:a=1[aout]
  " \
  -map "[vout]" -map "[aout]" \
  -c:v libx264 -c:a aac -pix_fmt yuv420p \
  part_a.mp4

# Final join (stream copy):
printf "file 'part_a.mp4'\nfile 'part_b.mp4'\n" > /tmp/concat.txt
ffmpeg -y -f concat -safe 0 -i /tmp/concat.txt -c copy final.mp4
```

Note: stream copy concat creates hard cuts at part boundaries. This is acceptable —
the smooth xfade transitions happen within each part.

## Step 5 — Verify and present

```bash
ffprobe -v quiet -show_streams final.mp4 | grep "^duration"
```

Check that video and audio durations are within 0.5s of total expected duration.
If there's a significant mismatch (>2s), something went wrong — check which clip
has a duration discrepancy and re-render it.

Update project.json: `final_video: "docs/video/<project_name>_final.mp4"`

Present the file to the user.

## Common issues and fixes

**Black screen after N seconds:**
A xfade offset equals or exceeds the duration of the preceding stream. Recalculate
offsets using the formula above.

**Audio/video out of sync in a clip:**
The clip's video and audio streams have different durations. Re-render that clip
with `-t <audio_duration>` to trim video to match audio.

**Channels mismatch (mono vs stereo) causing concat failure:**
Standardize all clips to mono before assembling:
```bash
for clip in clip_*.mp4; do
  ffmpeg -y -i "$clip" -ac 1 "${clip%.mp4}_mono.mp4"
done
```

**FFmpeg encode timeout on final assembly:**
Split into smaller parts and use stream copy for the final join.
