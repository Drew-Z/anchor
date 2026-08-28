# Anchor Web Delivery Summary

## Delivered Surfaces

- `web/landing/index.html`: bilingual product site with persistent locale, responsive navigation, accurate metadata, and CTAs to `/app/`.
- `web/landing/app/index.html`: static learning workspace with a toolbar, dataset sidebar, responsive mobile drawer, answer feedback, explanations, source evidence, scripted tutor hints, completion, recovery, and reset.
- `web/landing/assets/social-preview.png`: production social preview generated from the real demo surface.

Cloudflare Pages publishes `web/landing`, so the product site and demo ship together. The old `web/app` placeholder is not a deployment source.

## Evidence-Bound Claims

- Three bundled datasets contain twelve questions across single-choice, multiple-choice, and boolean formats.
- The demo stores only locale and versioned progress in the browser.
- No backend, upload, analytics, or live AI provider is part of the demo.
- Scripted tutor hints are explicitly labeled and never presented as a live model response.
- Marketing statistics without versioned experiment evidence were removed.

## Verification

`web/package.json` provides deterministic data/state tests and Playwright checks for the local or deployed site. The suite covers both languages, metadata, every bundled question, citations, tutor disclosure, completion, recovery/reset, keyboard and ARIA state, desktop/tablet/mobile screenshots, overflow, and the no-off-origin-request boundary.

Production deployment and rollback instructions live in [DEPLOYMENT.md](./DEPLOYMENT.md).
