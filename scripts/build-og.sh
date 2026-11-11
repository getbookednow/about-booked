#!/usr/bin/env bash
#
# build-og.sh — 1200x630 link-preview cards for /tarryntaylor/.
#
# Each card is three portrait originals side by side, scaled DOWN to 630px
# tall and trimmed a few pixels at the sides to fit. A single 2:3 portrait
# cropped to 1.9:1 keeps only a slice of the frame (the old home card was the
# top of a head), so cards are built from three frames instead.
# Deterministic ImageMagick only. Sources are the gallery originals in _source.
#
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/_source/tarryn"
OUT="$ROOT/tarryntaylor/images/og"
if command -v magick >/dev/null 2>&1; then IM="magick"; else IM="convert"; fi

card() { # $1=name  $2..$4=source files
  local name="$1"; shift
  local tmp; tmp="$(mktemp -d)"
  local i=0
  for f in "$@"; do
    i=$((i+1))
    "$IM" "$f" -auto-orient -strip -resize 'x630>' -gravity center -extent 396x630 "$tmp/$i.png"
  done
  "$IM" -background '#F4F1EB' "$tmp/1.png" -size 6x630 xc:'#F4F1EB' "$tmp/2.png" \
        -size 6x630 xc:'#F4F1EB' "$tmp/3.png" +append -colorspace sRGB \
        -interlace Plane -sampling-factor 4:2:0 -quality 82 "$OUT/$name.jpg"
  "$IM" "$OUT/$name.jpg" -define webp:method=6 -quality 82 "$OUT/$name.webp"
  for f in "$OUT/$name.jpg" "$OUT/$name.webp"; do
    exiftool -q -overwrite_original \
      -IPTC:CopyrightNotice="© Tarryn Taylor. All rights reserved." \
      -IPTC:By-line="Tarryn Taylor" -IPTC:Credit="Tarryn Taylor" \
      -IPTC:Source="bookednow.co.za/tarryntaylor" \
      -XMP-dc:Creator="Tarryn Taylor" -XMP-dc:Rights="© Tarryn Taylor. All rights reserved." \
      -XMP-xmpRights:Marked=True \
      -XMP-xmpRights:WebStatement="https://bookednow.co.za/tarryntaylor/#rights" \
      -XMP-xmpRights:UsageTerms="No licence granted for AI training or generative use." \
      '-XMP-plus:DataMining#=DMI-PROHIBITED' "$f"
  done
  rm -rf "$tmp"
  echo "OK    images/og/$name.{jpg,webp}"
}

pick() { ls "$SRC/$1"/* | sed -n "${2}p"; }

card tarryn-taylor-og-home      "$(pick model 1)" "$(pick model 2)" "$(pick model 3)"
card tarryn-taylor-og-new-faces "$(ls "$SRC"/hero/tarryn-taylor-new-faces-hero.*)" "$(pick new-faces 1)" "$(pick new-faces 3)"
