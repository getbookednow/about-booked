# VERIFY — Tarryn Taylor site

Open questions from the Wix → hand-written migration. Everything below is
phrased so it can be sent to Tarryn as-is over WhatsApp and answered directly.

Nothing here has been guessed at in the build. Where an answer is missing, the
page carries a `[VERIFY: ...]` marker or an HTML comment rather than a
plausible-sounding invention.

---

## A. Blockers — the site should not go live until these are answered

**A1. How many years have you been working in the industry?**
The old site said two different things in two different places — "Three decades
within the industry" in the Words by Taylor quote, and "over a decade in the
modelling industry" in the Creative Catalyst section. Neither has been carried
forward. Both spots currently read `[VERIFY: years of experience]`.
→ *One number, and I'll put it in both places.*

**A2. The photographs are compressed re-exports, not originals.**
Every couples image supplied is 827px wide (one is 853px). They look like
WhatsApp exports. The site is built to serve 800 / 1600 / 2400px versions, and
the pipeline refuses to upscale — so right now the 1600 and 2400 slots are
capped at 827px. Wix's compression is the reason for this migration; shipping
these would reproduce the exact problem we are leaving.
→ *Can you send the full-resolution exports straight from Lightroom / your card?*

**A3. Which photographs go on which page?**
22 originals are sitting unsorted in `_source/tarryn/_unsorted/`. They have
UUID filenames, so there is no way to tell model work from commercial work
without you saying so. They have not been used anywhere.
→ *Split them into: model, commercial, hero, and I'll wire them in.*
Slots currently wired: **model 12**, **commercial 12**, **couples 15**.
→ *If you want a different number of images per page, say the number.*

**A4. Your full credits list.**
The credits marquee on the old site scrolled, so the screenshots caught it
mid-scroll. Fully legible: **Topco**, **Topco Kids**, **Hey Judes**. Two more
were cut off — one ending "…0 Management", one starting "D Ma…".
→ *Full list please.* These are labelled **Credits:** on the site — not
"represented by" and not "signed with", per your instruction.

---

## B. Couples & Post-Wedding — a brand new page

This category did not exist on the Wix site, so there is no copy to migrate.
The page structure is built; the words are not written. Nothing on it is
invented marketing copy.

**B1.** What's the intro paragraph for couples sessions? (currently `[VERIFY]`)
**B2.** What does a couples session cost? The brief says priced above your model
rates, but not what the number is. (currently `[VERIFY]`)
**B3.** Should this page say "Couples & Post-Wedding", or something else?

**B4. Alt text for the 15 couples images.**
Every couples image currently carries the same honest but general line:
*"Editorial couples photograph by Tarryn Taylor, shot on location in Cape Town."*
I had per-image descriptions drafted, but spot-checking showed the ordering
couldn't be trusted, and wrong alt text is worse than general alt text for
anyone using a screen reader.
→ *One sentence per image, in slot order 01–15, whenever you have a minute.*

---

## C. Design — derived from the screenshots, please confirm

**C1. Colours.** Sampled directly out of your screenshots, not eyeballed:
- Cream background `#F4F1EB`
- Brand gold `#A7985D`

Both are exact. **But** the gold fails accessibility contrast rules for text:
- gold text on cream = **2.55:1** (needs 4.5:1)
- white text on gold = **2.88:1** (needs 4.5:1)

That means your current gold buttons and gold panels are hard to read for
anyone with low vision, and would fail an accessibility audit. So:
- Text-bearing gold panels and buttons use a deeper gold `#6E6339` (5.3:1).
- Your true brand gold `#A7985D` is kept for rules, borders and hairlines.

→ *Two options — happy with the deeper gold on panels and buttons, or would you
rather keep the exact original gold and switch that text to near-black instead?
Either passes. It's a look preference.*

**C2. Fonts.** Not confidently identifiable from screenshots.
- Headings: **Playfair Display** (your headings are a high-contrast serif — this is close)
- Body: **Figtree** (your body looked like Wix Madefor, which isn't public; Figtree is the nearest)
→ *If you know what the Wix fonts actually were, tell me and I'll swap them in.*

**C3. The Send Message button.** The brief said it was default Wix blue. In the
screenshots it is actually gold `#A7985D` — same as the rest of the palette. So
there was nothing to fix. It is now the deeper accessible gold, like the other
buttons. No blue anywhere on the site.
→ *Flagging only so you know I didn't ignore it.*

**C4. Type scale.** Normalised to clean 1.25 ratios rather than pixel-matched to
the screenshots (which were desktop-only and lossy). Mobile layout was built
from scratch, not inferred. Tested at 375 / 768 / 1440.

---

## D. Contact & practical

**D1. RESOLVED — the form is gone, replaced with WhatsApp.**
Static hosting can't process form submissions, and a form that opens the
visitor's mail app loses people. The contact section is now a WhatsApp block,
plus a floating WhatsApp button on every page (your Wix site had one too).
Email is still listed underneath as the alternative.

Each page sends a different pre-filled message, so you can see which offer the
enquiry came from before you even open the chat:
- Home → "I'd like to ask about a shoot"
- Model Portfolio → "I'd like to book a model portfolio shoot"
- Commercial → "I'd like to talk about a commercial shoot"
- Couples → "I'd like to book a couples session"

**D1a. Confirm the number: +27 68 296 9691.**
→ *This is on every page of your site now — worth double-checking the digits.*
It is not Booked's number, so enquiries come to you directly, not via Luca.

**D2. Is `tarryn.taylor@gmail.com` still the right address?**

**D3. RESOLVED — floating WhatsApp button is back**, on all four pages.
One difference from Wix: it is in your gold, not WhatsApp green. Green fought
with the gold-and-cream palette in exactly the way the old Send Message button
did. → *Say the word if you'd rather have the standard green.*

**D4. Is "Based in Cape Town, South Africa" still accurate?**

**D5. Rates.** Carried over exactly as they appeared: Test Shoot **from R2500**,
Digitals & Polaroids **from R1000**, Creative Direction **Inquire for Rates**.
→ *Still current?*

**D6. Turnaround.** Carried over as "same-day, or within 24–48 hours".
→ *Still accurate?*

---

## E. Image slots with no photograph yet

These are wired with correct `srcset` / `sizes` / dimensions and a flat
placeholder tone. They will fill in the moment the originals land — run
`./scripts/build-images.sh`, no code changes needed.

| Slot | Page | Status |
|---|---|---|
| `hero/tarryn-taylor-hero-home` | index | **empty** — no hero photo chosen |
| `hero/tarryn-taylor-portrait` | index (About) | **empty** — need a portrait of you |
| `model/tarryn-taylor-model-01…12` | model + index door | **empty** — 12 slots |
| `commercial/tarryn-taylor-commercial-01…12` | commercial + index door | **empty** — 12 slots |
| `couples/tarryn-taylor-couples-01…15` | couples + index door | **built**, but see A2 (low resolution) |
| `og/tarryn-taylor-og-home` | index social preview | **empty** |
| `og/tarryn-taylor-og-model` | model social preview | **empty** |
| `og/tarryn-taylor-og-commercial` | commercial social preview | **empty** |
| `og/tarryn-taylor-og-couples` | couples social preview | **empty** |

**E1.** Which photograph should be the hero on the home page?
**E2.** Which photograph of *you* goes in the About section?
**E3.** The OG images are what show as the thumbnail when someone shares a link
on WhatsApp or Instagram. Which photo for each of the four pages?

---

## F. Notes on how this was built — no action needed

- **No photograph of Tarryn's was passed to any AI model** for cropping,
  enhancement, upscaling, selection or alt-text generation. All image processing
  is deterministic ImageMagick: resize, centre-crop, compress.
  One caveat, stated plainly: checking the pages render correctly at 375/768/1440
  meant loading them in a browser, and the couples photographs are on those pages.
  Nothing seen there was used to write alt text, choose crops, or pick images —
  that's why B4 is an open question rather than something filled in.
- **No AI-generated imagery** anywhere in the output. The only non-photographic
  visual elements are CSS rules and the flat placeholder tone.
  Note: `_source/tarryn/_unsorted/OIG3.jpeg` looks like an AI-generated file from
  an unrelated project. It has **not** been used and should probably be removed
  from the folder.
- **Location data stripped** from every output file, then copyright metadata
  embedded (in that order — compression wipes metadata, so it has to go last).
  Verified on output: `IPTC:CopyrightNotice`, `XMP-dc:Creator`,
  `XMP-xmpRights:Marked`, `XMP-xmpRights:UsageTerms` and
  `XMP-plus:DataMining = DMI-PROHIBITED` all survive compression.
- **One deviation from the brief, flagged deliberately:** the brief specified
  `DataMining = DMI-PROHIBITED-AICONTENTGENERATION`. That value does not exist in
  the PLUS controlled vocabulary — exiftool accepts the argument and silently
  writes nothing, which would have looked fine and protected nothing. The real
  token `DMI-PROHIBITED` is used instead; it is the broadest prohibition
  available and matches the wording of the rights statement.
- **WebP files carry XMP but not IPTC** — that is a format limitation, not a
  pipeline bug. The rights reservation is present in XMP on every WebP.
- **robots.txt** is path-scoped and machine-verified: 14 AI-training crawlers are
  denied `/tarryntaylor/` while keeping full access to Booked's own pages;
  Googlebot, Bingbot, OAI-SearchBot, PerplexityBot and Applebot keep full access
  so the work stays findable and citable.
