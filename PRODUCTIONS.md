# BOOKED. Productions v1

## Result and scope

Website release has been approved and is being published from `codex/productions-v1`. The enquiry receiver is separately deployed with user approval. `/productions` follows the existing directory/index.html convention and redirects to `/productions/` on directory-based hosting.

Three services, Cape Town as the initial destination, future destinations clearly unlaunched, homepage introduction, core navigation links and a validated project-brief builder. Typography, colour tokens, mobile menu and buttons follow the existing brand. Decorative type and CSS graphics avoid using client photographs or unlicensed images.

## Existing architecture

- Plain HTML with page-local CSS and browser JavaScript; no package manager, framework, compilation or application server.
- README and CNAME identify GitHub Pages and bookednow.co.za. README lists Cloudflare DNS; DNS settings were not changed.
- Routes use directories with index.html and some root HTML files.
- Repeated navigation and style blocks rather than a component library. Productions reuses a copy of the homepage brand CSS; future style changes must keep it in step.
- Existing enquiry channels: WhatsApp and an external Tally form. No credentials or backend integration for production enquiries exists in this checkout.
- Existing Cloudflare analytics on public pages; scan-specific consent and AI policies left intact. New Productions page does not add tracking scripts.
- Existing shell checks concern the Tarryn client site, not the main site. No applicable lint, typecheck, test or build commands exist.

## Files

Created: `productions/index.html`, `productions/brand.css`, `productions/productions.css`, `productions/config.js`, `productions/enquiry.js`, this report.

Modified: `index.html` (teaser and navigation), `agencies/index.html`, `infrastructure/index.html`, `legacy/index.html`, `work.html`, `creative-pages/index.html` (navigation), `privacy-policy.html` (brief handling explanation), `sitemap.xml` (canonical page entry).

Core service copy, prices, billing links, legal terms, scan consent, client assets and existing integrations preserved.

## Enquiry delivery

The local preview offers the existing WhatsApp handoff. On the two approved production hostnames, the staged website configuration offers direct submission through the verified Cloudflare receiver to Make. Activate the saved Make scenario before releasing the website change. Required name, valid email, project type, description and contact consent are checked. Team size and field lengths are bounded. A hidden honeypot provides a basic bot signal. Brief rendering uses textContent, not HTML; input is encoded for the WhatsApp link. The user reviews the brief before choosing a channel. No email or WhatsApp message was sent during testing.

The page itself stores no brief between visits. Refreshing clears the form. WhatsApp review says “Not sent yet”; direct submission confirms only after Make returns a saved reference. A failure preserves the brief and reference for retry. Copy/edit and WhatsApp controls provide fallbacks. No Make address or API key is exposed in browser code.

**Updated 10 October:** The receiver and direct-submit mode are implemented in `automation/` and `productions/enquiry.js`. Ten mocked checks and browser tests against a local synthetic receiver pass. A real test through the deployed Cloudflare receiver returned HTTP 200 and the matching UUID after a record was written in Make. Two synthetic projects for the same email were verified in the actual store; retries reuse their UUID. Make is now active with user approval; website publication is approved. The user chose Make-only storage, without Google Sheets or Gmail. See `automation/README.md` for current configuration and release requirements.

**Release gate:** The receiver is verified. Make activation and the GitHub Pages website release have user approval. Internal notifications remain outside the chosen Make-only scope. The store has a 1 MB allocation and needs capacity review before increasing volume. The existing generic Tally link remains separate.

Keep secrets on the receiving server. The staged privacy disclosure names the providers and a manual 24-month retention limit. No scheduled removal or email notification is configured.

## Configuration

`productions/config.js` holds public destination records and budget options. Only destinations with status `enquiry` appear in the enquiry selector. Destination records include descriptions, gallery slots, capabilities, creative/accommodation partners and experiences. Empty partner/gallery lists are intentional. Budget choices currently avoid invented price bands; the visitor may enter an amount and currency. Add approved bands to budgetOptions later.

Page service copy and SEO remain static and indexable without JavaScript. If destination content expands, generate it at build time rather than hiding it in browser-only data.

## SEO and accessibility

Unique title/description, canonical and Open Graph URL, existing brand social image, Twitter metadata, Service structured data, sitemap entry, headings and internal links. Cape Town is the only structured service area. Skip link, native labelled fields, required consent, review focus, live error/copy status, visible keyboard focus, reduced-motion styling and mobile menu.

## Validation

- `node --check productions/config.js` and `node --check productions/enquiry.js`: passed.
- Browser: blank form rejected at name; otherwise-valid form without consent rejected at consent; valid consented form produced correctly encoded WhatsApp brief with selected services; edit preserved values and restored focus. No external send.
- Mobile 390 × 844: document width 390; no unlabelled visible form fields; menu opened with Productions visible and closed on Escape.
- Markup checks: one h1, unique IDs, local assets/links, anchors, valid Service JSON and sitemap XML passed. New page avoids two missing favicon files inherited from homepage metadata.
- Tablet 1024 × 768: homepage and Productions navigation stayed within the viewport without overlapping; homepage teaser present. Desktop and mobile visual review completed.
- `git diff --check`: passed. Static site requires no build; no framework lint/typecheck suite is configured. Existing client-site launch checks were reviewed and do not apply to this change.
- Live receiver-to-Make save and matching UUID receipt passed. Same UUID retry remained one record; a new UUID with the same email remained a separate project. Make consent-false rejection returned HTTP 400 without a new record.
- End-to-end WhatsApp delivery and automatic notifications were not tested; no external message was sent.

## Next development step

Publish the approved release to main, then verify the live form and saved receipt.
