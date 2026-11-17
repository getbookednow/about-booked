#!/usr/bin/env bash
# Candice Kuit page — image pipeline.
#
#   ./make-images.sh <source-folder>      build from Candice's originals
#   ./make-images.sh --placeholders       build labelled stand-ins (draft only)
#
# Source files must be named by slot:
#   hero.jpg  portrait.jpg  bridal-01.jpg … bridal-06.jpg  editorial-01.jpg … editorial-04.jpg
# (.jpg/.jpeg/.png/.tif all accepted)
#
# Her agreement forbids editing, upscaling, extending or AI-altering any image.
# This script ONLY resizes, centre-crops to the slot ratio, compresses and
# converts. It never upscales ("1600x>" only shrinks). Metadata (incl. IPTC
# credit/rights) is kept — do not add -strip.
set -euo pipefail
cd "$(dirname "$0")"
OUT=images
mkdir -p "$OUT"

# slot  ratio(w:h)
SLOTS="hero:4:5 portrait:4:5
bridal-01:3:4 bridal-02:3:4 bridal-03:3:4 bridal-04:3:4 bridal-05:3:4 bridal-06:3:4
editorial-01:3:4 editorial-02:3:4 editorial-03:3:4 editorial-04:3:4"

build() { # $1 src  $2 slot  $3 rw  $4 rh
  local src=$1 slot=$2 rw=$3 rh=$4
  for w in 480 960 1600; do
    local h=$(( w * rh / rw ))
    magick "$src" -auto-orient -resize "${w}x${h}^>" -gravity center -extent "${w}x${h}" \
      -quality 82 -sampling-factor 4:2:0 -interlace JPEG "$OUT/$slot-$w.jpg"
    magick "$OUT/$slot-$w.jpg" -quality 72 "$OUT/$slot-$w.webp"
    magick "$OUT/$slot-$w.jpg" -quality 55 "$OUT/$slot-$w.avif"
  done
}

if [[ "${1:-}" == "--placeholders" ]]; then
  for s in $SLOTS; do
    IFS=: read slot rw rh <<<"$s"
    tmp=$(mktemp -t ph).png
    magick -size 1600x$(( 1600 * rh / rw )) gradient:'#2a2140-#16112a' \
      -gravity center -fill '#C8A96E' -font /System/Library/Fonts/Supplemental/Arial.ttf -pointsize 64 \
      -annotate +0-40 "IMAGE FROM CANDICE" -pointsize 48 -fill '#a98fe0' \
      -annotate +0+50 "$slot" "$tmp"
    build "$tmp" "$slot" "$rw" "$rh"; rm -f "$tmp"
  done
else
  SRC=${1:?usage: ./make-images.sh <source-folder> | --placeholders}
  for s in $SLOTS; do
    IFS=: read slot rw rh <<<"$s"
    f=$(ls "$SRC"/"$slot".{jpg,jpeg,png,tif,JPG,JPEG,PNG} 2>/dev/null | head -1 || true)
    [[ -z "$f" ]] && { echo "missing: $slot"; continue; }
    build "$f" "$slot" "$rw" "$rh"
  done
fi

# Open Graph / Twitter card: 1200x630 crop of the hero (resize + crop only).
magick "$OUT/hero-1600.jpg" -resize '1200x630^' -gravity center -extent 1200x630 -quality 82 "$OUT/og.jpg"
du -ch "$OUT"/*-960.avif "$OUT"/hero-1600.avif | tail -1
