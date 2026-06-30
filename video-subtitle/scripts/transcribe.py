"""
transcribe.py — Transcribe a video/audio file straight to a valid .srt using faster-whisper.

Usage:
    python transcribe.py <input_file> <output_srt> <language> [model_size] [device]

Notes:
    - Writes proper SRT timestamps (HH:MM:SS,mmm) directly, so no post-processing
      "fix" step is needed.
    - faster-whisper runs on CTranslate2 (native C++), so this is already the
      performance-critical, optimized part of the pipeline.
"""
import sys
import time
from faster_whisper import WhisperModel


def srt_time(seconds: float) -> str:
    """Format a time in seconds as an SRT timestamp: HH:MM:SS,mmm."""
    if seconds < 0:
        seconds = 0.0
    ms = int(round(seconds * 1000))
    h, ms = divmod(ms, 3_600_000)
    m, ms = divmod(ms, 60_000)
    s, ms = divmod(ms, 1_000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def main() -> None:
    if len(sys.argv) < 4:
        print("Usage: python transcribe.py <input_file> <output_srt> "
              "<language> [model_size] [device]", file=sys.stderr)
        sys.exit(1)

    input_file = sys.argv[1]
    output_srt = sys.argv[2]
    language = sys.argv[3]                              # e.g. "zh", "pt", "en", "auto"
    model_size = sys.argv[4] if len(sys.argv) > 4 else "medium"
    device = sys.argv[5] if len(sys.argv) > 5 else "cpu"

    # "auto" => let Whisper detect the language.
    lang = None if language in ("auto", "", "detect") else language

    print(f"Loading Whisper model '{model_size}' on {device}...")
    start = time.time()
    # int8 on CPU is markedly faster with negligible quality loss; float16 suits GPU.
    compute_type = "float16" if device == "cuda" else "int8"
    model = WhisperModel(model_size, device=device, compute_type=compute_type)

    print(f"Transcribing '{input_file}' (language={language})...")
    # vad_filter skips silence -> fewer segments, faster, fewer hallucinations.
    segments, info = model.transcribe(input_file, language=lang, vad_filter=True)

    detected = getattr(info, "language", lang)
    print(f"Audio duration: {info.duration:.2f}s | language: {detected}")

    count = 0
    with open(output_srt, "w", encoding="utf-8") as f:
        for i, seg in enumerate(segments, 1):
            text = seg.text.strip()
            if not text:
                continue
            f.write(f"{i}\n")
            f.write(f"{srt_time(seg.start)} --> {srt_time(seg.end)}\n")
            f.write(f"{text}\n\n")
            count = i
            print(f"  [{i}] {srt_time(seg.start)} -> {srt_time(seg.end)}: {text}")

    elapsed = time.time() - start
    print(f"Done: {count} segments in {elapsed/60:.2f} min -> {output_srt}")


if __name__ == "__main__":
    main()
