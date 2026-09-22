#!/usr/bin/env bash
#
# launch-check.sh — go/no-go gate for /tarryntaylor/
#
# Exits 0 only when the site is genuinely ready to be public. Everything it
# checks is something that would embarrass the client or break a page.
#
# BLOCKERS  must be fixed before launch (exit 1)
# WARNINGS  worth knowing, do not block
#
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE="$ROOT/tarryntaylor"
B=0; W=0
blk(){ printf '  BLOCK  %s\n' "$1"; B=$((B+1)); }
wrn(){ printf '  warn   %s\n' "$1"; W=$((W+1)); }
sec(){ printf '\n== %s\n' "$1"; }
PAGES="index.html model.html commercial.html couples.html about.html contact.html"

sec "Placeholder copy"
for p in $PAGES; do
  n=$(grep -o '\[VERIFY:[^]]*\]' "$SITE/$p" 2>/dev/null | wc -l | tr -d ' ')
  [ "$n" -gt 0 ] && blk "$p has $n visible [VERIFY:...] marker(s) in rendered copy"
done
n=$(grep -o '__TITLE__\|__DESC__\|__SLUG__\|__OGN__' $SITE/*.html 2>/dev/null | wc -l | tr -d ' ')
[ "$n" -gt 0 ] && blk "unreplaced template placeholder(s) in output: $n"

sec "Indexing"
for p in $PAGES; do
  grep -q 'name="robots" content="noindex' "$SITE/$p" && blk "$p is still noindex"
done
for u in "" model.html commercial.html couples.html about.html contact.html; do
  grep -q "tarryntaylor/$u<" "$ROOT/sitemap.xml" || blk "sitemap.xml missing /tarryntaylor/$u"
done

sec "Image slots"
missing=0
# every src and srcset target must exist on disk
for p in $PAGES; do
  grep -oE '(src|srcset)="[^"]*"' "$SITE/$p" \
   | sed -E 's/^(src|srcset)="//; s/"$//' | tr ',' '\n' \
   | sed -E 's/^[[:space:]]*//; s/[[:space:]]+[0-9]+w$//' \
   | grep -E '^images/' | sort -u | while read -r f; do
      [ -f "$SITE/$f" ] || echo "$p -> $f"
   done
done > /tmp/_tt_missing.txt
missing=$(wc -l < /tmp/_tt_missing.txt | tr -d ' ')
if [ "$missing" -gt 0 ]; then
  blk "$missing referenced image file(s) do not exist — broken <img> on live pages"
  sed -n '1,6p' /tmp/_tt_missing.txt | sed 's/^/           /'
  [ "$missing" -gt 6 ] && echo "           … and $((missing-6)) more"
fi

sec "Image quality"
if command -v magick >/dev/null 2>&1 || command -v identify >/dev/null 2>&1; then
  IDENT=$(command -v magick >/dev/null 2>&1 && echo "magick identify" || echo identify)
  under=0
  while IFS= read -r f; do
    want="${f##*-}"; want="${want%%.*}"
    case "$want" in ''|*[!0-9]*) continue;; esac
    got=$($IDENT -format '%w' "$f" 2>/dev/null || echo 0)
    [ "$got" -lt "$want" ] && under=$((under+1))
  done < <(find "$SITE/images" -name '*.jpg' 2>/dev/null)
  [ "$under" -gt 0 ] && blk "$under image(s) are below their advertised width — compressed re-exports, not originals"
else
  wrn "ImageMagick absent; cannot verify image resolution"
fi

sec "Rights metadata"
if command -v exiftool >/dev/null 2>&1; then
  bad=0; tot=0
  while IFS= read -r f; do
    tot=$((tot+1))
    exiftool -q -s3 -XMP-plus:DataMining# "$f" 2>/dev/null | grep -q 'DMI-PROHIBITED' || bad=$((bad+1))
  done < <(find "$SITE/images" -type f \( -name '*.jpg' -o -name '*.webp' \) 2>/dev/null)
  [ "$tot" -gt 0 ] && [ "$bad" -gt 0 ] && blk "$bad/$tot image(s) missing XMP-plus:DataMining"
  leak=$(exiftool -q -if '$gpslatitude' -p '$filename' "$SITE/images" -r 2>/dev/null | wc -l | tr -d ' ')
  [ "$leak" -gt 0 ] && blk "$leak output image(s) still carry GPS coordinates"
else
  wrn "exiftool absent; cannot verify embedded rights"
fi

sec "Accessibility"
for p in $PAGES; do
  h1=$(grep -c '<h1' "$SITE/$p"); [ "$h1" -ne 1 ] && blk "$p has $h1 <h1> (want exactly 1)"
  ea=$(grep -o 'alt=""' "$SITE/$p" | wc -l | tr -d ' '); [ "$ea" -gt 0 ] && blk "$p has $ea empty alt attribute(s)"
  nd=$(grep -o '<img [^>]*>' "$SITE/$p" | grep -vc 'width=' || true)
  [ "$nd" -gt 0 ] && blk "$p has $nd <img> without explicit width/height"
  grep -q 'class="skip"' "$SITE/$p" || blk "$p missing skip link"
done
generic=$(grep -ho 'alt="[^"]*"' $SITE/*.html | sort | uniq -c | awk '$1>3{s+=$1} END{print s+0}')
[ "$generic" -gt 0 ] && wrn "$generic <img> share a repeated generic alt string — per-image descriptions still owed"

sec "Trust layer"
for p in $PAGES; do
  for t in 'noai, noimageai' 'tdm-reservation' 'rel="license"' 'og:image' 'rel="canonical"'; do
    grep -q "$t" "$SITE/$p" || blk "$p missing $t"
  done
done
grep -q 'id="rights"' "$SITE/index.html" || blk "index.html missing #rights anchor"
[ -f "$SITE/llms.txt" ] || blk "llms.txt missing"

sec "Links"
: > /tmp/_tt_links.txt
for p in $PAGES; do
  for h in $(grep -oE 'href="/tarryntaylor/[^"#]*"' "$SITE/$p" | sed 's/href="//; s/"//' | sort -u); do
    rel="${h#/tarryntaylor/}"; [ -z "$rel" ] && rel="index.html"
    [ -e "$SITE/$rel" ] || echo "$p -> dead internal link $h" >> /tmp/_tt_links.txt
  done
done
dead=$(wc -l < /tmp/_tt_links.txt | tr -d ' ')
if [ "$dead" -gt 0 ]; then
  while IFS= read -r l; do blk "$l"; done < /tmp/_tt_links.txt
else
  echo "  ok     all internal links resolve"
fi

sec "Robots"
python3 - "$ROOT/robots.txt" <<'PY' || true
import sys,urllib.robotparser as rp
p=rp.RobotFileParser(); p.parse(open(sys.argv[1]).read().splitlines())
T='/tarryntaylor/'
train=['GPTBot','ClaudeBot','Google-Extended','CCBot','Bytespider','Applebot-Extended','Amazonbot','anthropic-ai','Claude-Web','Meta-ExternalAgent','cohere-ai','Diffbot','omgili','ImagesiftBot']
srch=['Googlebot','Googlebot-Image','Bingbot','DuckDuckBot','OAI-SearchBot','PerplexityBot','ChatGPT-User','Applebot']
bad=[a for a in train if p.can_fetch(a,T)]+[a for a in srch if not p.can_fetch(a,T)]
bad+=[a for a in train if not p.can_fetch(a,'/')]
print("  BLOCK  robots.txt wrong for: "+", ".join(bad) if bad else "  ok     14 training denied / 8 search+citing allowed / Booked unaffected")
PY

printf '\n%s\n' "──────────────────────────────────────────────"
if [ "$B" -eq 0 ]; then
  echo "READY TO LAUNCH — 0 blockers, $W warning(s)."
  exit 0
fi
echo "NOT READY — $B blocker(s), $W warning(s)."
exit 1
