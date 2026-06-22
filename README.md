# BOOKED.

**AI readability infrastructure for fashion creatives.**

Live at [bookednow.co.za](https://bookednow.co.za)

---

## What this repo is

Primary site repository for BOOKED. — deployed via GitHub Pages to `bookednow.co.za`.

BOOKED. closes the legibility gap: the space between a creative's actual career quality and how discoverable they are to the systems that decide who gets booked.

---

## Repo structure
about-booked/

├── index.html                    # Main site

├── scan/                         # Free AI Readability Scan tool

├── infrastructure/               # AI Readability Layer service page

├── legacy/                       # Legacy full build service page

├── creative-pages/               # Client portfolio pages

├── portfoliopreview/             # Free landing page preview tool

├── .well-known/

│   └── ai-plugin.json            # Agent discovery manifest

├── llms.txt                      # AI retrieval guidance

├── services.json                 # Structured product feed (agent-readable)

├── contact.json                  # Contact data (machine-readable)

├── robots.txt                    # Explicit AI crawler permissions

├── sitemap.xml                   # XML sitemap

├── og-image.jpg                  # Open Graph share image

├── booked-case-study-001.html    # Case Study 001

├── privacy-policy.html

└── terms-of-service.html

---

## Agent stack

This repo is fully instrumented for AI crawlers, retrieval bots, and action-capable agents:

| File | Purpose |
|---|---|
| `llms.txt` | Retrieval bots — what BOOKED. is, pricing, CTA |
| `services.json` | Schema.org OfferCatalog — agent shopping feed |
| `.well-known/ai-plugin.json` | OpenAI agent discovery handshake |
| `robots.txt` | Explicitly permits GPTBot, ClaudeBot, PerplexityBot, Applebot, Meta-ExternalAgent |
| `sitemap.xml` | Index coverage |

---

## Stack

- Hosting: GitHub Pages
- Domain: Cloudflare DNS
- Fonts: Cormorant Garamond / DM Sans / DM Mono
- Automation: Make.com + Anthropic API
- Billing: EFT

---

## Contact

WhatsApp: [+27637549122](https://wa.me/27637549122)
Email: luca@bookednow.co.za
