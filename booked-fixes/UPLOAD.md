# Upload instructions — booked-fixes → getbookednow/about-booked

The GitHub connector on this machine is **read-only** (403 on branch creation), so these
files are staged locally. They were built from the **current live files on `main`**, not
from your local clone.

> **Do not push your local `~/Downloads/about-booked` clone.** It is 39 commits behind
> `origin/main`, and it has `privacy-policy.html` and `terms-of-service.html` deleted —
> both are linked from the live footer. Its `robots.txt` is also missing the entire AI
> crawler allowlist (110b local vs 372b live). Pushing it would break live pages and
> undo the crawler policy.

## Upload order (GitHub web UI)

Two files need a **delete first** because a name is changing.

### 1. og-image — fixes broken WhatsApp/social previews
The file in the repo is `og-image.jpg.png` (a PNG with a double extension). Every meta tag
points at `/og-image.jpg`, which 404s.

1. Delete `og-image.jpg.png`
2. Upload `og-image.jpg` (1200×630 JPEG, 80KB — converted from your existing artwork, design unchanged)

### 2. .well-known — fixes the 404 on the AI plugin manifest
`.well-known` is currently a **file**, not a directory, so `/.well-known/ai-plugin.json`
404s even though robots.txt advertises it.

1. Delete the `.well-known` file
2. Create a new file at path `.well-known/ai-plugin.json` and paste in the staged version
   (typing the `/` in the GitHub filename box creates the directory)

### 3. Straight overwrites
Upload these over the existing files:

- `index.html`
- `robots.txt`
- `sitemap.xml`
- `llms.txt`
- `services.json`
- `contact.json`

## What changed

**index.html**
- Canonical and `og:url` → apex (`bookednow.co.za`). They pointed at `www`, which 301s away.
- All 33 `www.` references → apex, so internal navigation stops paying a redirect hop.
- Four "from" offers converted from `price` to `priceSpecification`/`minPrice`. In
  schema.org a bare `price` means *exact*, so agents were quoting "from R15,000" as a
  fixed R15,000. Affected: Verified Manual Audit, AI Readability Layer, Fix Sprint,
  Portfolio Infrastructure Build.
- Added the **R7,500 Landing Page Build** offer. It appears twice in your visible copy but
  had no entry in the structured data, so machines could not see it at all.

**robots.txt** — `Sitemap:` → apex. Crawler allowlist untouched.

**sitemap.xml** — all URLs → apex (all six previously 301'd); namespace corrected to
`http://www.sitemaps.org/...` (the spec URI); added `/work` and `/legacy/`, which were
live and linked but missing — `/legacy/` being the R50,000 flagship.

**llms.txt** — replaced the stale Tier 0–3 ladder (Signal R5,000 / **Structure R9,000** /
Full Build R15,000) with the live ladder. Also fixed:
- It listed "emerging models" as served, contradicting your NOT FOR section
- Tier 3 included a "maintenance retainer", contradicting infrastructure-not-dependency
- Added an explicit engagement-model section stating no subscriptions or retainers
- Added "prices marked 'from' are starting prices, not fixed quotes"

**services.json** — regenerated from the corrected `index.html` catalogue so the two
cannot drift. Also corrected `paymentAccepted` (was "EFT, Wise, Paddle") and
`currenciesAccepted` (was "ZAR, USD, EUR" — Yoco settles ZAR only).

**.well-known/ai-plugin.json** — rebuilt as a real directory file; stale Tier pricing
replaced; `logo_url` pointed at a non-existent favicon, now the og-image;
`legal_info_url` pointed at `terms-of-service.html`, but the live URL has no `.html`.

**contact.json** — URLs normalised to apex. **Offers left untouched** — see below.

## Still needs your decision

1. **`contact.json` advertises a monthly retainer.** "Roster Intelligence Retainer,
   R12,000–R18,000 per month, EUR 1,200–1,800, 3-month minimum." Also "Roster Visibility
   Scan, from R12,000". Neither appears anywhere on your website, and the retainer
   contradicts infrastructure-not-dependency *and* cannot be charged on Yoco, which has no
   recurring billing. It is live to AI right now. I left it in place — killing a real
   offer is your call, not mine.

2. **`contact.json` declares EUR pricing** (`pricing_currencies: {south_africa: ZAR,
   europe: EUR}`) and is missing Legacy R50,000 entirely.

3. **The R2,500–R7,500 band.** Five offers inside R5,000 of each other. Collapsing to two
   fixed-price products is what unblocks the Yoco checkout — you cannot put a buy button
   on "from R3,500".

## After upload — verify

```bash
curl -sIL https://bookednow.co.za/og-image.jpg | grep -E "HTTP|content-type"
curl -sIL https://bookednow.co.za/.well-known/ai-plugin.json | grep -E "HTTP|content-type"
```

Both should return `200`. Then re-scrape the preview at
<https://developers.facebook.com/tools/debug/> so WhatsApp drops its cached blank card —
it will not refresh on its own.
