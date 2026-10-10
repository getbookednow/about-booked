# Production website → Make

## Current state

The receiver is deployed with user approval at `https://booked-production-enquiries.luca-a74.workers.dev/api/production-enquiry`. A synthetic request through the deployed receiver returned HTTP 200 with its matching UUID after Make saved the record. Ten mocked receiver tests also pass. Make is active with user approval. Website publication is complete at https://bookednow.co.za/productions/.

`productions/config.js` now selects the verified endpoint only on the two approved production hostnames. Local previews still offer WhatsApp, since localhost is deliberately absent from the receiver origin list.

Saved Make scenario: [BOOKED Productions Website Enquiries](https://eu1.make.com/3038994/scenarios/7877415/edit). Storage: [BOOKED Production Enquiries](https://eu1.make.com/3038994/data-stores/browse/213280), allocated 1 MB. This is a small starting store; review capacity before increasing enquiry volume. No scheduled record removal or capacity alert is configured.

The user chose to keep enquiry records inside Make. Google Sheets and Gmail access must not be requested. No email or WhatsApp messages should be sent by this flow.

## Flow

Website review → HTTPS receiver → Make custom webhook → consent/source validation → Make Data Store write keyed by submission_id → final Webhook Response.

A UUID identifies a project submission. A retry keeps that reference; a changed brief gets a new one. Separate projects from the same email must remain separate records. Make uses add/replace on the UUID, with sequential processing. No email-based deduplication.

The receiver validates and bounds all fields, accepts only Cape Town, requires project contact consent, stamps server receipt time/source, applies five attempts per IP per minute, rejects unexpected website origins and oversized bodies, and keeps the Make webhook in a server secret. No submitted details are logged by the receiver. Safe operational errors log only their stage, error type and an enumerated reason. Cloudflare invocation logs are enabled. The IP is used for rate limiting, not passed to Make.

Success is accepted only when Make returns JSON with `ok: true` and the matching `submission_id` after saving. Make's default `Accepted` queue response is deliberately rejected. Outages preserve the brief for retry; there is no automatic retry that could spam Make. Request-body limits and rate limiting are basic spam controls, not proof that a visitor is human.

## Receiver deployment (approval required)

Use the existing Cloudflare account if available; a Worker can run alongside GitHub Pages. Do not change site hosting or DNS merely to add this endpoint.

From `automation/`, with official Wrangler tooling:

1. Authenticate the existing Cloudflare account, with user approval for any new account access.
2. Verify `wrangler.jsonc` rate-limit binding/namespace and the allowed production origins.
3. Set the `MAKE_WEBHOOK_URL` secret from the verified Make webhook using `wrangler secret put MAKE_WEBHOOK_URL`. Never paste it into frontend code or commit it. If webhook API-key authentication is added, keep the key server-side too.
4. Deploy only after user approval. Use the returned Worker URL + `/api/production-enquiry` as the public enquiryEndpoint; do not invent a deployment URL.
5. Keep localhost out of the production origin list. Use separate staging settings for preview tests.
6. Run synthetic tests with `example.com` details and verify the actual Make record and matching receipt. Retry the same UUID and confirm one record remains. Try another UUID with the same email and confirm two project records.
7. Review the staged privacy changes describing direct and WhatsApp modes. Make records must be manually reviewed for removal within the stated 24-month retention limit and deleted on a valid request. No scheduled retention deletion has been configured. Check provider processing terms before enabling the new channel.
8. Activate Make and release the website only with approval. Merging the main branch may deploy GitHub Pages.

## Make contract

Every field the receiver emits is listed in `worker.mjs` and the sample payload. Data store name: BOOKED Production Enquiries. Record key: submission_id. Set a practical review/removal policy before real submissions start.

Valid saved record: HTTP 200, Content-Type application/json, body `{"ok":true,"submission_id":"<actual UUID>"}`.

Invalid input: HTTP 400, JSON `{"ok":false}`.

Storage error: HTTP 503, JSON `{"ok":false}`; success must not run afterward. Do not expose module error details or credentials in the response.

## Browser verification

A separate localhost receiver was used with fake Make storage responses. Valid form submission reached the receiver and displayed a saved reference. A simulated first-write outage showed an error; Retry saved successfully. The main preview on port 8765 remains on the real disabled-until-configured mode. No real visitor details were sent.

The existing private booked-scan-api repository was inspected for reuse: its visible deployment is marked inactive. It was not altered. The new Cloudflare Worker is deployed on the existing business account, with `MAKE_WEBHOOK_URL` stored as a Secret, production origins set, compatibility date 2026-10-10, and `ENQUIRY_RATE_LIMITER` namespace 1001 set to five attempts per 60 seconds. Existing Workers and DNS remain untouched.

Live checks: production-origin preflight returned 204; empty JSON returned 400; a valid synthetic request returned 200 with UUID `22222222-2222-4222-8222-222222222222`. The actual data store shows two distinct projects for producer@example.com. A retry of UUID `11111111-1111-4111-8111-111111111111` left one record for that UUID. Earlier tests missed Make's two-minute Run once window while network approval was pending; the successful test paused the approved command until Make was listening. The queued synthetic request was processed with explicit user approval during activation.

The Make consent-false test used UUID `33333333-3333-4333-8333-333333333333`; it took the rejection branch and returned HTTP 400. The test card labels non-2xx as "Sending failed", but execution inspection confirms this was the expected rejection. The data store remained at two records.

Cloudflare runtime testing required using manual redirect mode. Redirect responses are rejected, never followed; the Make address remains private. The deployed receiver does not treat Make's queued `Accepted` response as proof of storage.

## Checks

`node --test automation/worker.test.mjs`

`node --check productions/enquiry.js`

Unit tests use synthetic data and mocked Make responses. The separately observed live test proves receiver-to-Make storage and matching receipt, and Make is now active for the approved website release.

## Live activation correction

Process data in order is OFF: Make rejects live Webhook Response confirmation when sequential processing is ON. Immediate scheduling and stored incomplete executions remain enabled. A live form retry returned a saved receipt for `4f9f6aa9-b295-4ade-ac45-624f90e5b57a`, verified in the actual store as one record. Earlier draft instructions requiring sequential processing are superseded by this verified setting.
