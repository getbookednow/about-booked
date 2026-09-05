#!/usr/bin/env bash
#
# build-images.sh — deterministic image pipeline for /tarryntaylor/
#
# Reads full-resolution originals from _source/tarryn/ and writes web-ready
# derivatives into tarryntaylor/images/.
#
# NOTHING IN THIS SCRIPT IS GENERATIVE. Every operation is a deterministic
# ImageMagick transform: resize, centre-crop to a fixed aspect, compress.
# There is no upscaling, no enhancement, no background removal, no generative
# fill, and no model of any kind in the path. Do not add one.
#
# Order of operations matters:
#   1. resize + crop + compress   (ImageMagick -strip drops ALL metadata,
#                                  including GPS shoot coordinates)
#   2. embed copyright metadata   (exiftool, last)
# Compression strips metadata. Embedding before compressing silently wipes it.
#
# Usage:  ./scripts/build-images.sh [--check]
#         --check   report what would be built, write nothing
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/_source/tarryn"
OUT="$ROOT/tarryntaylor/images"
WIDTHS=(800 1600 2400)
Q_HERO=82
Q_GALLERY=78
CHECK=0
if [ "${1:-}" = "--check" ]; then CHECK=1; fi

# ── dependencies ────────────────────────────────────────────────────────────
need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: '$1' not found." >&2
    echo "       brew install imagemagick exiftool" >&2
    exit 1
  }
}
if command -v magick >/dev/null 2>&1; then IM="magick"; else IM="convert"; fi
need "$IM"
need exiftool

# ── expected slots: folder | filename prefix | aspect | quality | count ─────
# Counts match the slots wired into the HTML. A mismatch is reported, not
# silently absorbed — a missing file is a broken <img> on a live page.
SLOTS=(
  "hero|tarryn-taylor-hero|3:2|$Q_HERO|0"
  "model|tarryn-taylor-model|4:5|$Q_GALLERY|12"
  "commercial|tarryn-taylor-commercial|4:5|$Q_GALLERY|9"
  "couples|tarryn-taylor-couples|4:5|$Q_GALLERY|15"
  "og|tarryn-taylor-og|1200:630|$Q_HERO|0"
)

# aspect "W:H" -> geometry for centre-crop at a given width
crop_geom() { # $1=aspect  $2=width
  local aw ah w h
  aw="${1%%:*}"; ah="${1##*:}"; w="$2"
  h=$(( w * ah / aw ))
  echo "${w}x${h}"
}

embed_rights() { # $1=file
  # NOTE: DataMining takes a PLUS controlled-vocabulary token. "DMI-PROHIBITED-
  # AICONTENTGENERATION" is not one of them — exiftool accepts the argument and
  # silently writes nothing. "DMI-PROHIBITED" is the real token and is the
  # broadest prohibition available. Verify with:
  #   exiftool -XMP-plus:DataMining# <file>
  # The trailing "#" writes/reads the raw vocabulary token rather than its
  # human-readable PrintConv description.
  exiftool -q -overwrite_original \
    -IPTC:CopyrightNotice="© Tarryn Taylor. All rights reserved." \
    -IPTC:By-line="Tarryn Taylor" \
    -IPTC:Credit="Tarryn Taylor" \
    -IPTC:Source="bookednow.co.za/tarryntaylor" \
    -XMP-dc:Creator="Tarryn Taylor" \
    -XMP-dc:Rights="© Tarryn Taylor. All rights reserved." \
    -XMP-xmpRights:Marked=True \
    -XMP-xmpRights:WebStatement="https://bookednow.co.za/tarryntaylor/#rights" \
    -XMP-xmpRights:UsageTerms="No licence granted for AI training or generative use." \
    '-XMP-plus:DataMining#=DMI-PROHIBITED' \
    "$1"
}

built=0; missing=0; warned=0; underres=0

for g in "${SLOTS[@]}"; do
  IFS='|' read -r folder prefix aspect quality expected <<< "$g"
  sdir="$SRC/$folder"
  odir="$OUT/$folder"

  if [ ! -d "$sdir" ]; then
    echo "SKIP  $folder/ — no _source/tarryn/$folder/ (expected $expected images)"
    missing=$(( missing + expected )); continue
  fi

  # bash 3.2 (macOS system bash) has no mapfile
  files=()
  while IFS= read -r line; do files+=("$line"); done < <(find "$sdir" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.tif' -o -iname '*.tiff' \) | sort)

  n=${#files[@]}
  if [ "$n" -eq 0 ]; then
    echo "SKIP  $folder/ — empty (expected $expected images)"
    missing=$(( missing + expected )); continue
  fi
  if [ "$expected" -gt 0 ] && [ "$n" -ne "$expected" ]; then
    echo "WARN  $folder/ — $n originals present, HTML wires $expected slots."
    echo "      Fix the folder or the slot count; do not ship a broken <img>."
    warned=$(( warned + 1 ))
  fi

  [ "$CHECK" -eq 0 ] && mkdir -p "$odir"

  i=0
  for f in "${files[@]}"; do
    i=$(( i + 1 ))
    # hero/og keep their source stem; galleries are numbered to match the HTML
    if [ "$folder" = "hero" ] || [ "$folder" = "og" ]; then
      stem="$(basename "${f%.*}")"
    else
      stem="$prefix-$(printf '%02d' "$i")"
    fi

    # Never upscale. Anything smaller than the target width is a compressed
    # re-export, not an original — enlarging it just ships blur at 4x the bytes.
    native_w="$("$IM" identify -format '%w' "$f[0]" 2>/dev/null || echo 0)"

    # og cards are one fixed size; everything else gets the three widths
    if [ "$folder" = "og" ]; then sizes=(""); else sizes=("${WIDTHS[@]}"); fi

    for w in "${sizes[@]}"; do
      if [ -z "$w" ]; then
        geom="1200x630"
      else
        eff="$w"
        if [ "$native_w" -gt 0 ] && [ "$w" -gt "$native_w" ]; then
          # cap at native so the file is honest; keep the name so srcset never 404s
          eff="$native_w"
          underres=$(( underres + 1 ))
          echo "UNDER $(basename "$f") is ${native_w}px wide — ${w}w variant capped, not upscaled."
        fi
        geom="$(crop_geom "$aspect" "$eff")"
      fi
      base="$odir/$stem${w:+-$w}"

      if [ "$CHECK" -eq 1 ]; then
        echo "PLAN  ${base#$ROOT/}.{jpg,webp}  ($geom q$quality)"
        continue
      fi

      # 1 ─ deterministic resize + centre-crop + compress. -strip drops GPS.
      "$IM" "$f" \
        -auto-orient -strip \
        -resize "${geom}^" -gravity center -extent "$geom" \
        -colorspace sRGB -interlace Plane -sampling-factor 4:2:0 \
        -quality "$quality" "$base.jpg"

      "$IM" "$f" \
        -auto-orient -strip \
        -resize "${geom}^" -gravity center -extent "$geom" \
        -colorspace sRGB -define webp:method=6 \
        -quality "$quality" "$base.webp"

      # 2 ─ metadata LAST, after compression, or it is wiped
      embed_rights "$base.jpg"
      embed_rights "$base.webp"

      built=$(( built + 2 ))
      echo "OK    ${base#$ROOT/}.{jpg,webp}"
    done
  done
done

echo
if [ "$CHECK" -eq 1 ]; then
  echo "check only — nothing written."
else
  echo "built $built files."
fi
if [ "$missing" -gt 0 ]; then echo "$missing image slots still have no original. See VERIFY.md."; fi
if [ "$warned" -gt 0 ]; then echo "$warned folder(s) do not match the wired slot count."; fi
if [ "$underres" -gt 0 ]; then
  echo
  echo "BLOCKER  $underres variant(s) were capped because the source is smaller than the"
  echo "         target width. Those files are compressed re-exports, not originals."
  echo "         Wix compression is the reason for this migration — shipping these"
  echo "         reproduces the problem. Get full-resolution exports before launch."
fi

# unsorted originals are a real blocker, not a footnote
if [ -d "$SRC/_unsorted" ]; then
  u=$(find "$SRC/_unsorted" -maxdepth 1 -type f | wc -l | tr -d ' ')
  if [ "$u" -gt 0 ]; then
    echo
    echo "NOTE  $u original(s) sit in _source/tarryn/_unsorted/ and were not processed."
    echo "      They need sorting into hero/ model/ commercial/ couples/ og/ first."
  fi
fi
exit 0
