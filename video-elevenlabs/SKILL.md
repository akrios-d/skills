---
name: video-elevenlabs
description: >
  Sends narration text to the ElevenLabs API and downloads the generated MP3 audio file.
  Supports voice parameterization (voice_id, stability, similarity, style). Use this
  skill whenever the user wants to generate TTS audio for a video scene using ElevenLabs,
  or when video-scene needs to auto-generate audio. Trigger on "generate the audio",
  "send to elevenlabs", "generate the narration", or "TTS this text".
---

# ElevenLabs Audio Generation

Generates a narration MP3 via the ElevenLabs API and saves it to `docs/video/`.

## Required inputs

Get these from the user or from project.json:
- **text** — the narration text to convert
- **api_key** — ElevenLabs API key (ask the user if not in project.json or env)
- **voice_id** — ElevenLabs voice ID (ask the user if not configured; suggest they
  pick a voice at elevenlabs.io/voices first)
- **output_path** — where to save the MP3 (default: `docs/video/audio_XX_name.mp3`)

## Optional voice parameters (use project.json defaults or these values)

- `stability`: 0.5 (0–1, higher = more consistent but less expressive)
- `similarity_boost`: 0.75 (0–1, higher = closer to original voice)
- `style`: 0.0 (0–1, higher = more stylized/dramatic)
- `use_speaker_boost`: true

## API call

```python
import requests, json

url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
headers = {
    "xi-api-key": api_key,
    "Content-Type": "application/json"
}
body = {
    "text": text,
    "model_id": "eleven_multilingual_v2",
    "voice_settings": {
        "stability": stability,
        "similarity_boost": similarity_boost,
        "style": style,
        "use_speaker_boost": use_speaker_boost
    }
}
response = requests.post(url, headers=headers, json=body)
if response.status_code == 200:
    with open(output_path, "wb") as f:
        f.write(response.content)
else:
    raise Exception(f"ElevenLabs error {response.status_code}: {response.text}")
```

Install requests if needed: `pip install requests --break-system-packages`

## After generation

1. Run `ffprobe -v quiet -show_entries format=duration -of csv=p=0 <output_path>` to get
   the actual duration in seconds.
2. Update project.json: set `audio_file` and `audio_duration_sec` for the current scene.
3. Tell the user the duration and ask them to confirm it sounds right before proceeding.

## Error handling

- **401**: Invalid API key — ask the user to check their key
- **422**: Voice ID not found — ask the user to verify the voice ID at elevenlabs.io
- **429**: Rate limit — wait 10s and retry once
- **Quota exceeded**: Tell the user they've hit their ElevenLabs plan limit

## Security note

Never log or display the API key. Store it only in memory or read it from an environment
variable (`ELEVENLABS_API_KEY`). Do not write it to project.json or any file.
