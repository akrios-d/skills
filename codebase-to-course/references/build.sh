#!/bin/bash
# Assembles the course into a single, self-contained index.html.
# styles.css and main.js are inlined so the resulting file is portable —
# open it directly or share/email the one file. (Fonts load from Google
# Fonts when online and fall back to system fonts offline.)
#
# Run from the course directory: bash build.sh
set -e

# Always operate relative to this script's directory.
cd "$(dirname "$0")"

# Guard: modules must exist before assembling.
if ! ls modules/*.html >/dev/null 2>&1; then
  echo "Error: no module files found in modules/. Write the modules first." >&2
  exit 1
fi
for f in _base.html _footer.html styles.css main.js; do
  if [ ! -f "$f" ]; then
    echo "Error: required file '$f' is missing." >&2
    exit 1
  fi
done

{
  # Inline styles.css in place of its <link>, and drop the <script src="main.js">
  # from <head> (the JS is inlined at the end of <body> instead, so it still
  # runs after the DOM is parsed — preserving the original `defer` behavior).
  awk '
    /href="styles.css"/ {
      print "  <style>";
      while ((getline line < "styles.css") > 0) print line;
      close("styles.css");
      print "  </style>";
      next
    }
    /src="main.js"/ { next }
    { print }
  ' _base.html

  cat modules/*.html

  # Inline the JS at the end of the body.
  printf '  <script>\n'
  cat main.js
  printf '\n  </script>\n'

  cat _footer.html
} > index.html

echo "Built self-contained index.html — open it in your browser or share the single file."
