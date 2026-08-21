#!/usr/bin/env bash
#
# go-live.sh — flip /tarryntaylor/ from staged review to public.
#
# Undoes the two deliberate staging decisions:
#   1. noindex, nofollow  ->  index, follow
#   2. re-adds the four /tarryntaylor/ URLs to the root sitemap
#
# Refuses to run while real blockers remain (missing images, placeholder copy).
# Pass --force to override, or --revert to go back to staged.
#
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE="$ROOT/tarryntaylor"
PAGES="index.html model.html commercial.html couples.html"
MODE="${1:-}"

if [ "$MODE" = "--revert" ]; then
  for p in $PAGES; do
    perl -0pi -e 's/<meta name="robots" content="index, follow, max-image-preview:large">/<meta name="robots" content="noindex, nofollow, max-image-preview:large">/' "$SITE/$p"
    perl -0pi -e 's/<meta name="googlebot" content="index, follow">/<meta name="googlebot" content="noindex, nofollow">/' "$SITE/$p"
  done
  perl -0pi -e 's{  <url>\n    <loc>https://bookednow\.co\.za/tarryntaylor/[^<]*</loc>\n  </url>\n}{}g' "$ROOT/sitemap.xml"
  echo "reverted to staged (noindex, sitemap entries removed)."
  exit 0
fi

# ── gate on the blockers go-live cannot itself fix ──────────────────────────
fail=0
for p in $PAGES; do
  n=$(grep -o '\[VERIFY:[^]]*\]' "$SITE/$p" | wc -l | tr -d ' ')
  if [ "$n" -gt 0 ]; then echo "BLOCK  $p still shows $n [VERIFY:...] marker(s)"; fail=1; fi
done
miss=0
for p in $PAGES; do
  while read -r f; do
    [ -f "$SITE/$f" ] || miss=$((miss+1))
  done < <(grep -oE '(src|srcset)="[^"]*"' "$SITE/$p" | sed -E 's/^(src|srcset)="//; s/"$//' \
           | tr ',' '\n' | sed -E 's/^[[:space:]]*//; s/[[:space:]]+[0-9]+w$//' | grep -E '^images/' | sort -u)
done
if [ "$miss" -gt 0 ]; then echo "BLOCK  $miss referenced image file(s) missing — pages would ship broken"; fail=1; fi

if [ "$fail" -ne 0 ] && [ "$MODE" != "--force" ]; then
  echo
  echo "Refusing to go live. Fix the above, or re-run with --force if you mean it."
  exit 1
fi

# ── flip ────────────────────────────────────────────────────────────────────
for p in $PAGES; do
  perl -0pi -e 's/<meta name="robots" content="noindex, nofollow, max-image-preview:large">/<meta name="robots" content="index, follow, max-image-preview:large">/' "$SITE/$p"
  perl -0pi -e 's/<meta name="googlebot" content="noindex, nofollow">/<meta name="googlebot" content="index, follow">/' "$SITE/$p"
  # drop the staging instruction comment
  perl -0pi -e 's/<!-- STAGED FOR CLIENT REVIEW.*?-->\n//s' "$SITE/$p"
  echo "indexable: $p"
done

python3 - "$ROOT/sitemap.xml" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
urls=["https://bookednow.co.za/tarryntaylor/",
      "https://bookednow.co.za/tarryntaylor/model.html",
      "https://bookednow.co.za/tarryntaylor/commercial.html",
      "https://bookednow.co.za/tarryntaylor/couples.html"]
add="".join(f"  <url>\n    <loc>{u}</loc>\n  </url>\n" for u in urls if u not in s)
if add:
    s=s.replace("</urlset>",add+"</urlset>"); open(p,'w').write(s)
    print(f"sitemap: added {add.count('<loc>')} url(s)")
else:
    print("sitemap: already present")
PY

echo
echo "Now re-run: ./scripts/launch-check.sh"
