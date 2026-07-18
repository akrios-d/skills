#!/usr/bin/env python3
"""Extract text from a PDF. Usage: extract_text.py <input.pdf> <output.txt>"""
import sys
from pypdf import PdfReader


def main():
    if len(sys.argv) != 3:
        print("Usage: extract_text.py <input.pdf> <output.txt>")
        sys.exit(1)
    reader = PdfReader(sys.argv[1])
    text = "\n".join(page.extract_text() or "" for page in reader.pages)
    with open(sys.argv[2], "w") as f:
        f.write(text)
    print(f"Extracted {len(text)} characters to {sys.argv[2]}")


if __name__ == "__main__":
    main()
