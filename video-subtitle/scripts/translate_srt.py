"""
translate_srt.py — Translate the text of an SRT file, preserving indices and timings.

Usage:
    python translate_srt.py <input_srt> <output_srt> <source_lang> <target_lang>

Performance:
    The old version sent one HTTP request per subtitle line — hundreds of
    sequential round-trips for a normal video. This version groups many lines
    into a single request (newline-joined, then split back), cutting the number
    of network calls by ~1-2 orders of magnitude. The network round-trips, not
    Python, are the bottleneck here — so batching is the real speedup, and a
    different language would not help.
"""
import sys
from deep_translator import GoogleTranslator

# Max characters per request (Google's free endpoint caps around 5000).
MAX_CHARS = 4500


def parse_srt(text):
    """Parse SRT into blocks: list of (index, timing, [text_lines])."""
    blocks = []
    for raw in text.strip().split("\n\n"):
        lines = [l for l in raw.splitlines() if l.strip() != ""]
        if len(lines) < 2:
            continue
        index = lines[0].strip()
        timing = lines[1].strip()
        text_lines = lines[2:]
        blocks.append((index, timing, text_lines))
    return blocks


def chunk_texts(texts):
    """Group texts so each newline-joined batch stays under MAX_CHARS."""
    batches, current, size = [], [], 0
    for t in texts:
        add = len(t) + 1
        if current and size + add > MAX_CHARS:
            batches.append(current)
            current, size = [], 0
        current.append(t)
        size += add
    if current:
        batches.append(current)
    return batches


def main():
    if len(sys.argv) < 5:
        print("Usage: python translate_srt.py <input_srt> <output_srt> "
              "<source_lang> <target_lang>", file=sys.stderr)
        sys.exit(1)

    input_srt, output_srt = sys.argv[1], sys.argv[2]
    source_lang, target_lang = sys.argv[3], sys.argv[4]

    with open(input_srt, "r", encoding="utf-8") as f:
        blocks = parse_srt(f.read())

    # One text string per block (multi-line subtitles joined with a space).
    texts = [" ".join(tl).strip() for (_, _, tl) in blocks]
    translator = GoogleTranslator(source=source_lang, target=target_lang)

    translated = []
    n_requests = 0
    for batch in chunk_texts(texts):
        joined = "\n".join(batch)
        result = translator.translate(joined) or ""
        n_requests += 1
        parts = result.split("\n")
        if len(parts) == len(batch):
            translated.extend(p.strip() for p in parts)
        else:
            # Line count drifted — fall back to per-line for this batch only.
            for t in batch:
                translated.append((translator.translate(t) or t).strip())
                n_requests += 1

    with open(output_srt, "w", encoding="utf-8") as f:
        for (index, timing, _), text in zip(blocks, translated):
            f.write(f"{index}\n{timing}\n{text}\n\n")

    print(f"Translated {len(blocks)} segments in {n_requests} request(s) "
          f"({source_lang} -> {target_lang}) -> {output_srt}")


if __name__ == "__main__":
    main()
