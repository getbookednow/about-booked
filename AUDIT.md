# Booked. — Repository Audit

Branch: `repo-audit` · Audited against `origin/main` @ `85f6af7` · 29 July 2026

Every finding below was verified against the actual files and, where it concerns
serving behaviour, against the live site over HTTP. Nothing here is inferred.

---

## 0. Read this first — the local checkout is not the live site

**`[needs decision]`** — highest priority, and the reason this audit was run against `origin/main`.

The working copy at `~/Downloads/about-booked` is **5 commits ahead and 39 commits
behind** `origin/main`. The two diverged at `3b08e8f`.

```
git rev-list --left-right --count main...origin/main
5	39
```

`origin/main` is what GitHub Pages serves. The local `main` is a stale fork of it that
is missing `work.html`, `booked-case-study-001.html`, `services.json`, `og-image.jpg.png`,
`.well-known`, and the entire `andemafenuka/` client site. It also has uncommitted
working-tree changes that **delete** `privacy-policy.html` and `terms-of-service.html`.

Five local commits exist only on the local `main` and are not on the remote:

| Commit | Subject |
|---|---|
| `3afd66f` | Call the proxy's actual allowed model directly, skip broken sonnet-5 path |
| `0ac1b27` | Distinguish origin-lock failures from proxy-busy in portfolio preview |
| `8416a65` | Replace Make.com capture with WhatsApp auto-handoff on portfolio preview |
| `57e4f78` | Add contact.json and update llms.txt for AI agent discoverability |
| `df9c2d2` | Wire Formspree capture to scan and portfoliopreview forms |

Those five commits touch `portfoliopreview/` and `scan/` behaviour. Whether they are
superseded by later web-UI edits on the remote, or are genuinely unshipped work, is a
call only you can make. **Do not merge or rebase local `main` onto `origin/main`
without checking** — a fast-forward in the wrong direction would revert 39 commits of
live site, including a client portfolio.

`repo-audit` was branched from `origin/main`, so it is clean of all of this.

---

## Phase 1 — Findings, by user-visible impact

### 1. The founder page downloaded instead of rendering `[shipped]`

`founder` was committed as an extensionless file containing 191KB of HTML.

```
GET https://bookednow.co.za/founder
200  Content-Type: application/octet-stream  191461 bytes
```

`application/octet-stream` means the browser **downloads the file** rather than
rendering it. Anyone clicking through to the founder page got a mystery file in their
downloads folder. The page has been effectively invisible for as long as it has been live.

Fixed by renaming to `founder.html`. GitHub Pages resolves extensionless request paths
to `.html` files — verified independently, `/work` already serves `work.html` this way
— so the public URL `/founder` keeps working and now returns `text/html`.

### 2. Every social share preview was broken `[shipped]`

The committed image was `og-image.jpg.png`. Every reference on the site pointed at
`og-image.jpg`, which did not exist:

```
GET https://bookednow.co.za/og-image.jpg   →  404
```

Five references were affected: `index.html`, `scan/index.html` (×2),
`infrastructure/index.html`, `README.md`. Nothing referenced the actual file. So every
link shared to WhatsApp, LinkedIn, Slack or X rendered with no image at all.

The file was also a 832KB PNG at 2396×1254, while `scan/index.html` declared
`og:image:width 1200` / `og:image:height 630`.

Fixed by replacing it with a real JPEG at exactly 1200×630, quality 90, **98KB (−88%)**.
Naming it `og-image.jpg` makes all five existing references resolve without editing any
HTML, and the extension now matches the actual format.

### 3. `.well-known` was a file, and returned 404 `[shipped]`

`.well-known` was committed as a file containing an AI-plugin manifest. Both plausible
URLs 404'd:

```
GET https://bookednow.co.za/.well-known                  →  404
GET https://bookednow.co.za/.well-known/ai-plugin.json   →  404
```

Two separate causes: `.well-known` is a protocol-reserved *directory*, and Jekyll (which
GitHub Pages runs by default) excludes dotfile paths from the published site entirely.

Fixed by moving it to `.well-known/ai-plugin.json` — the exact path `robots.txt` already
advertises — and adding `.nojekyll` so dotfile paths are published. The site is plain
HTML with no build step, so bypassing Jekyll changes nothing else.

### 4. Canonical tags pointed at redirects and 404s `[shipped]`

Two distinct problems, both of which suppress indexing.

**Host split.** `CNAME` is `bookednow.co.za`, and `www` 301s to it. But `index.html`,
`scan/index.html` and `booked-case-study-001.html` declared canonicals, `og:url`s and
schema `@id`s on `www.bookednow.co.za`, while `work.html` and the policy pages used the
apex. 53 URLs normalised to the apex.

**Canonicals pointing at 404s.**

| Page | Claimed canonical | Status | Now |
|---|---|---|---|
| `booked-case-study-001.html` | `/case-studies/001/` | **404** | `/booked-case-study-001` |
| `privacy-policy.html` | `/privacy-policy/` | **404** | `/privacy-policy` |
| `scan/privacy-policy.html` | `/privacy-policy/` | **404** | `/privacy-policy` |

A self-referencing canonical pointing at a 404 is a strong signal not to index the page.
The case study — the strongest proof asset on the site — was telling Google to ignore it.

Fixing the privacy canonical also correctly resolves the duplicate: `privacy-policy.html`
and `scan/privacy-policy.html` are **byte-identical**, and both now canonicalise to the
root copy.

### 5. Three pages had no meta layer at all `[shipped]`

| Page | description | canonical | og:* | twitter:* |
|---|---|---|---|---|
| `founder` | missing | missing | missing | missing |
| `terms-of-service.html` | missing | missing | missing | missing |
| `scan/fanie-nel-case-study.html` | missing | missing | missing | missing |

And three more declared `twitter:card` but had no `og:image`, so the card had no image
to show: `work.html`, `booked-case-study-001.html`, both `privacy-policy` copies.

`booked-case-study-001.html` audits *other people's sites* for missing `og:image` and
Twitter card tags while missing its own.

All filled in. **Every description is drawn from copy already on the page** — no new
positioning, claims or numbers. They are listed in Phase 3 below so you can review the
wording, since meta descriptions are user-visible in search results.

`lang="en"` and `viewport` were present and correct on all nine in-scope pages. No page
had a truncated or duplicated title. Titles ranged 14–65 characters — all within limits.

### 6. Structured data `[shipped]` / `[proposed]`

What existed on `origin/main`:

| Page | JSON-LD |
|---|---|
| `index.html` | `WebSite`, `WebPage`, `Person`, `OfferCatalog` + 8 `Offer`, `FAQPage` + 9 Q&A |
| `work.html` | `CollectionPage`, `Organization` |
| `scan/index.html` | `WebApplication`, `Offer`, `Person` |
| `booked-case-study-001.html` | **none** |
| `founder` | **none** |
| policy pages | none |

`index.html` is genuinely well marked up. Added `Article` + `BreadcrumbList` to the case
study and `ProfilePage`/`Person` to the founder page, built only from facts already on
those pages (the "June 2026" audit date and 21/100 score are both stated in the copy).

Still absent, and **`[proposed]`** rather than shipped because it needs a decision on
which service catalogue is true: a site-wide `Organization` / `ProfessionalService`
node. `services.json` contains a complete `ProfessionalService` graph, but it describes
a different set of services from the ones on the homepage — see §8.

### 7. Link integrity `[shipped]` / `[needs decision]`

All 11 internal relative links resolve. **No `http://` links anywhere** on in-scope
pages — everything is already HTTPS.

Broken links found:

| Source | Target | Status | Disposition |
|---|---|---|---|
| `founder` nav → "About" | `luca.html` | **404** | `[needs decision]` |
| `founder` nav → "Structure" | `getbookednow.github.io/booked-demo` | **404** | `[needs decision]` |
| `index.html` | `/favicon.ico` | **404** | `[needs decision]` |
| `index.html` | `/apple-touch-icon.png` | **404** | `[needs decision]` |

**Two of the four nav items on the founder page are dead.** I have not guessed at
replacements: there is no `luca.html` anywhere in the repo, and the founder page *is*
the Luca page, so a self-link is one reading among several. `booked-demo` is a repo that
either was never published or has been removed. Both need you to say what they should
point at. See Phase 3.

The missing `favicon.ico` also matters beyond the browser tab: `.well-known/ai-plugin.json`
declares it as `logo_url`.

Links into out-of-scope folders (all resolve 200, left untouched):
`index.html` → `/portfoliopreview/`, `/legacy/`, `/infrastructure/`.

External hosts in use: `wa.me` (200), `tally.so/r/68rPoe` (200), `fonts.googleapis.com`,
`fonts.gstatic.com`.

### 8. Content drift — three sources describe three different businesses `[needs decision]`

This is the most consequential finding that I did not ship, and the single thing most
worth your attention this week.

`index.html` is self-consistent: its visible copy and its `OfferCatalog` JSON-LD agree
on seven services. `contact.json` roughly agrees with it. `llms.txt`, `services.json`
and `.well-known/ai-plugin.json` describe **an entirely different catalogue** — different
service names, and two price points that appear nowhere else on the site.

| Service (index.html, live) | index.html | contact.json | llms.txt / services.json / ai-plugin |
|---|---|---|---|
| Visibility Scan | Free · audit from R2,500 | Free · from R2,500 | "Free AI Readability Scan" |
| Portfolio Audit | R4,000 | R4,000 | — |
| Landing Page Preview | Free · builds from R7,500 | R7,500 | — |
| Fix Sprint | From R4,500 | From R4,500 | — |
| AI Readability Layer | From R3,500 | From R3,500 | — |
| Portfolio Infrastructure Build | From R15,000 | From R15,000 | "Tier 3 — Full Build", from R15,000 |
| **Legacy** | **R50,000** | *absent* | *absent* |
| — | — | Roster Visibility Scan, from R12,000 | "Agency Roster Intelligence", POA |
| — | — | Roster Intelligence Retainer, R12,000–18,000/mo | — |
| — | *absent* | *absent* | **Tier 0 — Audit, R2,500** |
| — | *absent* | *absent* | **Tier 1 — Signal, R5,000** |
| — | *absent* | *absent* | **Tier 2 — Structure, R9,000** |

Concretely:

- **R5,000 and R9,000 are prices no page on the site offers.** An AI agent reading
  `llms.txt` or `services.json` will quote them.
- **Legacy at R50,000 — the highest-value offer on the site — is missing from every
  machine-readable file.** An agent asked "what's the most comprehensive thing Booked
  does?" will answer "Tier 3, from R15,000."
- The **"Tier 0/1/2/3 — Signal/Structure/Full Build"** naming exists only in the machine
  layer. No human visitor ever sees those names.
- Positioning differs three ways: "AI readability infrastructure company" (`llms.txt`),
  "Discoverability infrastructure for fashion creatives" (`contact.json`), "Portfolio
  audits, visibility scans… " (`index.html` meta description).
- `llms.txt` says "Last updated: June 2026" and describes markets as Cape Town, Milan,
  Shanghai; `contact.json` adds Hong Kong, Seoul, Bali. `index.html` lists Cape Town,
  Milan, Shanghai, Hong Kong, Seoul, Mumbai, Istanbul, Bali.
- `.well-known/ai-plugin.json` declares `"api": {"type": "openapi", "url": ".../services.json"}`
  but `services.json` is schema.org JSON-LD, not an OpenAPI document.
- Contact details are the one thing that is **fully consistent**: `+27637549122` /
  `wa.me/27637549122` / `luca@bookednow.co.za` everywhere. `@bookedofficialsa` (contact.json)
  vs `instagram.com/lucaboldcpt` (index.html JSON-LD) are different accounts but not
  contradictory — one is the brand, one is personal.

I normalised the `www` URLs inside `contact.json` `[shipped]` but changed **no** service
name, price or description in any of these files. Which catalogue is true is a pricing
decision, not a mechanical one.

### 9. Duplicate content across repos `[needs decision]`

| URL | Status | Canonical it declares | Problem |
|---|---|---|---|
| `bookednow.co.za/scan/` | 200 | `bookednow.co.za/scan/` | — (correct) |
| `getbookednow.github.io/scan/` | 200 | **itself** | Competing copy on a second host |
| `getbookednow.github.io/blog/` | 200 | **itself** | Orphaned — see below |
| `getbookednow.github.io/booked-founder/` | 404 | — | Not published |
| `getbookednow.github.io/about-booked/` | 200 | redirects → `bookednow.co.za/` | Correctly handled |

Two live duplicates, neither pointing at the main domain:

- **`getbookednow.github.io/scan/`** serves a separate copy of the scan tool with
  `<title>scan</title>` (a placeholder) and a self-canonical. It competes with
  `bookednow.co.za/scan/` instead of deferring to it.
- **`getbookednow.github.io/blog/`** is a real, indexable blog — "Booked. — Notes on
  getting found." — with `robots: index, follow` and a self-canonical. It is **not
  linked from bookednow.co.za, and not in the sitemap.** Every piece of content on it
  builds authority for `github.io`, not for your domain.

Both live in other repos, so neither can be fixed from this branch.

### 10. `sitemap.xml` `[shipped]`

Three separate defects in 559 bytes.

- `xmlns` was `https://www.sitemaps.org/schemas/sitemap/0.9`. The sitemap protocol
  namespace is literally **`http://`** — strict parsers reject the `https` variant as an
  unknown namespace.
- Every `<loc>` used the `www` host, which 301s. Sitemaps listing redirecting URLs are discounted.
- Five live public pages were missing entirely:

| Missing URL | Status |
|---|---|
| `/work` | 200 |
| `/booked-case-study-001` | 200 |
| `/founder` | 200 |
| `/privacy-policy` | 200 |
| `/terms-of-service` | 200 |

All added; URLs now match each page's canonical exactly. Now 11 URLs.

`/legacy/` is linked from `index.html` as a live R50,000 product page but is still not
in the sitemap — it is an out-of-scope directory, so I left it out rather than decide
for you. **`[needs decision]`**

### 11. `robots.txt` `[shipped]`

The four `Allow:` lines for the machine-readable layer sat *after* the
`User-agent: Meta-ExternalAgent` group. Under robots.txt grouping rules they therefore
applied **only to Meta's crawler** — not to `*`, and not to GPTBot, ClaudeBot or
PerplexityBot. Moved into the `User-agent: *` group. The `Sitemap:` directive also
pointed at the redirecting `www` host.

Low practical impact, since `Allow: /` already permits everything — but the file did not
express what it was written to express.

### 12. Accessibility and performance `[shipped]` / `[proposed]`

**Heading order** — three pages skipped a level:

| Page | Before | After |
|---|---|---|
| `index.html` | h1 → **h3** → h2 | h1 → h2 → h2 ✅ |
| `founder` | h1 → **h3** ×3 → h2 | h1 → h2 ×4 ✅ |
| `scan/fanie-nel-case-study.html` | h1 → **h3**, h2 → **h4** ×8 | h2 → h3 fixed; h1 → h3 remains |

Each fix renamed the tag **and its class-scoped CSS selector together**
(`.diagnosis-copy h3` → `h2`, `.what-item h3` → `h2`, `.blocker`/`.offer-card h4` → `h3`).
None of these files has a bare `h2`/`h3` rule that could take over, so computed styles
are provably unchanged.

The one remaining skip, on the scan case study, is the decorative "01 / 08" eyebrow
label. That file *does* have a bare `h2 { font-size: clamp(32px, 7vw, 62px) }` rule, so
retagging it would visibly change the page. It belongs in Phase 3. **`[proposed]`**

**Other a11y/perf checks:**

- **Images** — only one `<img>` exists across all in-scope pages (in `founder`, an
  inlined base64 data URI). It **has** alt text: "Luca — founder of Booked." No missing
  alt anywhere. It lacks `width`/`height`, but as a base64 data URI with CSS-controlled
  dimensions, adding them risks layout change for no network benefit — left alone.
  Worth noting: that single inlined image is most of the page's 191KB, and its data URI
  is declared `data:image/png` while the payload is actually JPEG. **`[proposed]`**
- **Duplicate IDs** — none, on any page.
- **HTML validity** — all nine pages pass a tag-balance and duplicate-attribute check.
  (`tidy` on this machine is the 2006 Apple build and flags `<nav>`, `<main>` and
  `<section>` as unrecognised — all false positives from a pre-HTML5 validator.)
- **Render-blocking** — every page loads Google Fonts via a blocking `<link>` in `<head>`,
  already mitigated with `preconnect` and `display=swap`. No JS frameworks, no analytics,
  no trackers. CSS is fully inlined. Genuinely fast.
- **Link text** — no "click here" / "read more" anywhere. Link text is descriptive
  throughout; `index.html` nav links carry full descriptive labels.

### 13. Mobile at 390px `[proposed]`

Checked in a real browser at 390×844.

- **No horizontal overflow on any page.** `scrollWidth === clientWidth === 390`. No
  element extends past the viewport. All pages carry media queries (1–5 each).
- **Tap targets under 44px** — 6 on `/`, 8 on `/work`:

| Element | Size | Page |
|---|---|---|
| "CHAT" button | 76×41 | both |
| "BOOKED." logo | 94×29 | both |
| ALL / BUILDS / SCANS filters | 119×18 | `/work` |
| "Run the visibility scan →" | 162×20 | `/` |
| "WORK WITH BOOKED" | 154×19 | both |
| PRIVACY POLICY / TERMS | 108×18, 128×18 | both |

The filter controls on `/work` at 18px tall are the most likely to be genuinely
mis-tapped. The rest are footer/text links where a smaller target is conventional.

- **Text under 14px** — present on every page (8px–13px). These are uppercase,
  letter-spaced eyebrow and label styles, i.e. a deliberate typographic choice, not an
  oversight. Raising them would change the design.

Both of these are design decisions, so neither was shipped.

---

## Phase 2 — What shipped

Nine commits on `repo-audit`, one per category. No out-of-scope directory was touched.

| Commit | What |
|---|---|
| `b4efe4b` | `founder` → `founder.html` — stop the page downloading as `octet-stream` |
| `e96fab3` | `.well-known` → `.well-known/ai-plugin.json` + `.nojekyll` — fix the 404 |
| `cdfda9d` | `og-image.jpg.png` → real `og-image.jpg`, 1200×630, 832KB → 98KB |
| `1bc643c` | 53 `www` URLs → apex; 3 canonicals repointed off 404s |
| `da1527e` | `sitemap.xml` namespace + host + 5 missing URLs; `robots.txt` grouping |
| `ba7bdb3` | Descriptions, canonicals, OG and Twitter cards on 6 pages |
| `9dc4b0e` | `Article` + `BreadcrumbList` on the case study; `ProfilePage` on founder |
| `7b392ff` | Heading-order fixes with matching CSS selector renames |
| `c5f7dc9` | `contact.json` URLs → apex host |

Verification performed: all 9 pages pass tag-balance/duplicate-attribute validation; all
JSON-LD blocks parse; `sitemap.xml` parses with the correct namespace; `contact.json` and
`ai-plugin.json` are valid JSON; internal link check re-run clean; `founder.html` and
`index.html` confirmed rendering in-browser off a local server with no console errors.

---

## Phase 3 — Proposed, not shipped

### Copy and positioning

| File | Current string | Proposed replacement | Reason |
|---|---|---|---|
| `llms.txt` | "Tier 0 — AI Readability Audit — R2,500 / Tier 1 — Signal — R5,000 / Tier 2 — Structure — R9,000 / Tier 3 — Full Build — from R15,000" | The 7 services named on `index.html` | R5,000 and R9,000 are offered nowhere on the site; agents are quoting prices you don't sell |
| `services.json` | Same Tier 0–3 `OfferCatalog` | Mirror `index.html`'s 8-offer `OfferCatalog` verbatim | One catalogue, one source of truth |
| `.well-known/ai-plugin.json` | "Paid tiers range from R2,500 (Tier 0 Audit) to R15,000+ (Tier 3 Full Build)" | Range ending at R50,000 (Legacy) | Understates your top offer by R35,000 |
| `llms.txt`, `services.json`, `contact.json` | *(Legacy absent)* | Add Legacy — R50,000 | Highest-value offer is invisible to every AI system |
| `llms.txt` | "BOOKED. is an AI readability infrastructure company" | Match `index.html`'s positioning | Three files, three different descriptions of the business |
| `contact.json` | `"tagline": "Discoverability infrastructure for fashion creatives."` | Align with homepage h1 framing | Same |
| `llms.txt` | "Last updated: June 2026" | Bump on next edit | Staleness signal to crawlers |
| `.well-known/ai-plugin.json` | `"api": {"type": "openapi", ...}` | `"type"` reflecting schema.org JSON-LD | `services.json` is not an OpenAPI document |

### Broken links needing a target decision

| File | Current string | Proposed replacement | Reason |
|---|---|---|---|
| `founder.html` | `href="luca.html"` (nav "About") | `/founder` (self) or remove the item | 404; no `luca.html` exists in any repo |
| `founder.html` | `href="https://getbookednow.github.io/booked-demo"` (nav "Structure") | `/work` or `/infrastructure/` | 404; repo unpublished or removed |
| `index.html` | `href="/favicon.ico"` | Add a real `favicon.ico` | 404; also `logo_url` in the AI manifest |
| `index.html` | `href="/apple-touch-icon.png"` | Add the asset or drop the tag | 404 |

### Design and IA

| File | Current string | Proposed replacement | Reason |
|---|---|---|---|
| `scan/fanie-nel-case-study.html` | `<h3 style="font-size:10px;…">01 / 08</h3>` | `<p class="slide-num">` | Decorative label as a heading breaks the outline; can't retag without restyling |
| `work.html` | Filter chips at 119×18px | ≥44px tap height | Below the touch-target minimum on the page's primary control |
| all pages | Label text at 8–13px | ≥14px, or leave as-is | Deliberate typographic style; flagging, not recommending |
| `founder.html` | `data:image/png;base64,/9j/4AAQ…` | External `.jpg` with `width`/`height` | Payload is JPEG mislabelled as PNG; inlining it is most of the page's 191KB |
| `sitemap.xml` | *(no `/legacy/` entry)* | Add if `/legacy/` is a live product page | Linked from the homepage as R50,000 but not in the sitemap |
| — | `getbookednow.github.io/scan/` self-canonical | `rel=canonical` → `bookednow.co.za/scan/` | Duplicate competing with your own domain (other repo) |
| — | `getbookednow.github.io/blog/` self-canonical | Move to `bookednow.co.za/blog/` or canonicalise | Orphaned blog building authority for `github.io` (other repo) |

### Meta descriptions written from on-page copy — please review the wording

These shipped because the pages had none at all, but they are user-visible in search
results, so the wording is yours to approve:

| File | Description written |
|---|---|
| `founder.html` | "The person behind Booked. A decade working as an international model across South Africa, Asia, and Europe — now building the digital infrastructure that makes fashion creatives findable and legible." |
| `terms-of-service.html` | "Terms of Service for Booked. — Luca Bold, trading as Booked., a South African sole proprietorship. Effective 1 June 2026. Governing law: Republic of South Africa." |
| `scan/fanie-nel-case-study.html` | "A full discoverability audit of the Fanie Nel / Discovered ecosystem — 4 accounts across Instagram, LinkedIn, website and Google. Overall score 5 / 20." |

---

## The three things to decide this week

**1. Which service catalogue is real — and reconcile the machine layer to it.**
`llms.txt`, `services.json` and `.well-known/ai-plugin.json` are selling "Tier 1 —
Signal, R5,000" and "Tier 2 — Structure, R9,000", which you do not offer, while omitting
Legacy at R50,000, which you do. Every AI system that reads your site — the exact
audience this business is built to serve — is currently quoting the wrong catalogue.
This is the finding with the widest gap between what it costs to fix and what it costs
to leave. Nothing else on this list is close.

**2. Sort out the local checkout before you commit anything else.**
`~/Downloads/about-booked` is 39 commits behind the live site and holds 5 commits that
never shipped, plus uncommitted deletions of both policy pages. Decide whether those 5
commits are wanted; then reset the checkout to `origin/main`. Until then, any commit
made there risks reverting live content, including the Ande Mafenuka client site.

**3. Where the founder page's two dead nav links should point — and whether the blog
moves onto your domain.**
Two of four nav items on the founder page 404. Separately,
`getbookednow.github.io/blog/` is a live, indexable blog that no page on your domain
links to; every post builds authority for `github.io` instead of `bookednow.co.za`.
Both are cheap to fix once you decide the targets.
