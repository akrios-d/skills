---
name: video-render
description: >
  Generates a final video clip for a single scene by combining visuals and audio.
  Handles all visual types: programmatic animations (Python/Pillow), Ken Burns zoom/pan
  on static images, slideshows with crossfade, and screen recordings with speed
  adjustment or timelapse. Always outputs a 1920x1080 H.264 MP4 with AAC audio.
  Use this skill whenever a scene needs to be rendered or re-rendered: "render the scene",
  "generate the clip", "process this recording", "make the animation", "speed this up".
---

# Video Render

Produces `docs/video/clip_XX_name.mp4` for one scene. Read the scene config from
project.json or from the user's instructions.

---

## Visual type: `recording` (screen capture + audio)

The user provides a recording file. Your job: match its duration to the audio.

```
speedup = recording_duration / audio_duration
```

**If speedup ≤ 1.2** (recording is close to audio length):
```bash
ffmpeg -y -i recording.mp4 -i audio.mp3 \
  -c:v libx264 -c:a aac -shortest -pix_fmt yuv420p \
  -vf "scale=1920:1080:force_original_aspect_ratio=decrease,\
pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=#1a1a2e,setsar=1" \
  clip_XX.mp4
```

**If 1.2 < speedup ≤ 2.0** (moderate speedup):
```bash
ffmpeg -y -i recording.mp4 \
  -vf "setpts=PTS/{speedup},scale=1920:1080:force_original_aspect_ratio=decrease,\
pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=#1a1a2e,setsar=1" \
  -af "atempo={speedup}" \
  -c:v libx264 -pix_fmt yuv420p video_sped.mp4

ffmpeg -y -i video_sped.mp4 -i audio.mp3 \
  -c:v copy -c:a aac -shortest clip_XX.mp4
```

**If speedup > 2.0** (timelapse territory — suggest to user first):
Keep the first `audio_duration × 0.3` seconds at normal speed, timelapse the rest:
```bash
NORMAL_END=$(python3 -c "print({audio_dur} * 0.3)")
TIMELAPSE_FACTOR=$(python3 -c "print(({rec_dur} - $NORMAL_END) / ({audio_dur} * 0.7))")

ffmpeg -y -i recording.mp4 -t $NORMAL_END \
  -vf "scale=1920:1080:..." -c:v libx264 normal_part.mp4

ffmpeg -y -i recording.mp4 -ss $NORMAL_END \
  -vf "setpts=PTS/$TIMELAPSE_FACTOR,scale=1920:1080:..." \
  -c:v libx264 timelapse_part.mp4

# Concat then add audio
printf "file 'normal_part.mp4'\nfile 'timelapse_part.mp4'\n" > /tmp/parts.txt
ffmpeg -y -f concat -safe 0 -i /tmp/parts.txt -i audio.mp3 \
  -c:v copy -c:a aac -shortest clip_XX.mp4
```

---

## Visual type: `ken_burns` (zoom/pan on a static image)

Generate a smooth Ken Burns animation using Python + Pillow, then add audio.

```python
from PIL import Image
import subprocess, math

img = Image.open("image.png").convert("RGB")
IW, IH = img.size
W, H = 1920, 1080
FPS = 30
audio_dur = 13.2  # from project.json audio_duration_sec
N = int(audio_dur * FPS)

# Keyframes: (t_sec, zoom, cx_frac, cy_frac)
# zoom=1.0 shows full image (may letterbox); zoom=1.4 zooms in 40%
# cx/cy: center of the view in source image (0.0–1.0 fractions)
KEYFRAMES = [
    (0,          1.0,  0.5, 0.5),  # full view
    (audio_dur * 0.3, 1.35, 0.3, 0.35),  # zoom top-left
    (audio_dur * 0.7, 1.35, 0.7, 0.65),  # pan to right
    (audio_dur,  1.0,  0.5, 0.5),  # back to full
]

def ease(t):
    return (1 - math.cos(t * math.pi)) / 2

def interp(frame):
    t = frame / FPS
    for i in range(len(KEYFRAMES) - 1):
        t0, z0, cx0, cy0 = KEYFRAMES[i]
        t1, z1, cx1, cy1 = KEYFRAMES[i+1]
        if t0 <= t <= t1:
            a = ease((t - t0) / (t1 - t0))
            return z0+(z1-z0)*a, cx0+(cx1-cx0)*a, cy0+(cy1-cy0)*a
    return KEYFRAMES[-1][1:]

def render_frame(zoom, cx, cy):
    # Always maintain output aspect ratio (16:9) in the source crop
    vw = IW / zoom
    vh = vw * (H / W)
    if vh > IH:       # source too short — clamp
        vh = IH; vw = vh * (W / H)
    x0 = max(0.0, min(IW - vw, cx * IW - vw / 2))
    y0 = max(0.0, min(IH - vh, cy * IH - vh / 2))
    crop = img.crop((int(x0), int(y0), int(x0+vw), int(y0+vh)))
    return crop.resize((W, H), Image.BILINEAR)

# Pipe frames to ffmpeg
cmd = ['ffmpeg', '-y', '-f', 'rawvideo', '-vcodec', 'rawvideo',
       '-s', f'{W}x{H}', '-pix_fmt', 'rgb24', '-r', str(FPS), '-i', '-',
       '-c:v', 'libx264', '-pix_fmt', 'yuv420p', 'video_only.mp4']
proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stderr=subprocess.DEVNULL)
for i in range(N):
    z, cx, cy = interp(i)
    proc.stdin.write(render_frame(z, cx, cy).tobytes())
proc.stdin.close(); proc.wait()

# Add audio
subprocess.run(['ffmpeg', '-y', '-i', 'video_only.mp4', '-i', 'audio.mp3',
                '-c:v', 'copy', '-c:a', 'aac', '-t', str(audio_dur), 'clip_XX.mp4'])
```

---

## Visual type: `slideshow` (sequence of images with crossfade)

For N images over `audio_duration` seconds:
- Duration per image: `audio_duration / N` (last one gets a bit more)
- Crossfade: 0.5s between each

**Correct xfade offset formula (critical — wrong offsets cause black screens):**
```
offset_1 = dur_1 - 0.5
v1_dur   = dur_1 + dur_2 - 0.5
offset_2 = v1_dur - 0.5
v2_dur   = v1_dur + dur_3 - 0.5
offset_3 = v2_dur - 0.5
# Pattern: offset_N = (accumulated_duration_so_far) - 0.5
# NEVER set offset_N = accumulated_duration (causes truncation)
```

Generate each image as a static segment first:
```bash
ffmpeg -y -loop 1 -i image_N.png -t {dur} \
  -vf "scale=1920:1080:force_original_aspect_ratio=decrease,\
pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=#1a1a2e,setsar=1" \
  -c:v libx264 -pix_fmt yuv420p -r 30 seg_N.mp4
```

Then join with xfade filter (max 4–5 images per chain to avoid timeout):
```bash
ffmpeg -y -i seg_1.mp4 -i seg_2.mp4 -i seg_3.mp4 \
  -filter_complex "
    [0:v][1:v]xfade=transition=fade:duration=0.5:offset={offset_1}[v01];
    [v01][2:v]xfade=transition=fade:duration=0.5:offset={offset_2}[vout]
  " \
  -map "[vout]" -i audio.mp3 -map "1:a" \
  -c:v libx264 -c:a aac -t {audio_dur} -pix_fmt yuv420p clip_XX.mp4
```

---

## Visual type: `animation` (generated with Python/Pillow)

Use Python to generate frames and pipe to ffmpeg (see ken_burns pattern above).
Common animation patterns:
- **Chaos/problem intro**: random colored cards with glitch/shake effect
- **Title card**: text on dark background with fade-in
- **Diagram build**: progressively reveal components

Always match frame count to `int(audio_duration_sec * 30)` frames.

---

## Visual type: `end_card`

```bash
ffmpeg -y -loop 1 -i end_card.png -t 6 \
  -vf "scale=1920:1080:force_original_aspect_ratio=decrease,\
pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=#1a1a2e,setsar=1,fade=in:0:45" \
  -f lavfi -i anullsrc=r=44100:cl=mono \
  -c:v libx264 -c:a aac -shortest -pix_fmt yuv420p clip_XX_endcard.mp4
```

---

## Blurring sensitive data in screenshots

Before using a screenshot in a slideshow, detect and blur emails, tokens, or
personal data:

```python
import numpy as np
from PIL import Image, ImageFilter

img = Image.open("screenshot.png").convert("RGB")
arr = np.array(img)

# Find text regions (dark pixels) to locate the sensitive column
for x in range(400, img.width - 50, 15):
    strip = arr[row_y:row_y+40, x:x+15, :]
    dark = np.sum(np.mean(strip, axis=2) < 100)
    if dark > 5:
        print(f"text at x={x}")  # identify column boundaries

# Pixelate the region (more reliable than Gaussian blur for text)
blur_box = (x0, y0, x1, y1)
crop = img.crop(blur_box)
small = crop.resize((30, 30), Image.NEAREST)
pixelated = small.resize(crop.size, Image.NEAREST)
img.paste(pixelated, blur_box[:2])
img.save("screenshot_blurred.png")
```

---

## After rendering

1. Verify with ffprobe that video and audio durations are within 0.5s of each other:
   ```bash
   ffprobe -v quiet -show_streams clip_XX.mp4 | grep "^duration"
   ```
2. Update project.json: `clip_file`, `status: "rendered"`
3. Present the clip to the user for approval
