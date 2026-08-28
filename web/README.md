# Anchor Web

This directory contains the production static website and its deterministic browser demo.

## Published Layout

```text
web/
├── landing/                 # Cloudflare Pages output
│   ├── index.html           # Bilingual product site
│   ├── app/                 # Bilingual interactive demo
│   │   ├── index.html
│   │   ├── scripts/
│   │   └── styles/
│   ├── assets/
│   ├── scripts/
│   ├── styles/
│   ├── _headers
│   └── _redirects
├── tests/                   # Data/state and Playwright contracts
├── package.json
└── wrangler.toml
```

Cloudflare Pages publishes `web/landing`. Do not move the demo back to `web/app`; that path is outside the deployed tree.

## Product Boundary

- `/` is the bilingual product site.
- `/app/` is a static guided demo with Flutter, Git, and JavaScript datasets.
- The demo contains 12 bundled questions across `single`, `multiple`, and `boolean` types.
- Answers show feedback, explanation, source locator, source excerpt, and clearly labeled scripted tutor hints.
- Locale is stored in `anchor.locale`; versioned progress is stored in `anchor.demo.progress.v1`.
- The demo has no login, upload, backend, analytics, or live AI request. It is not the full Flutter application.

## Development And Verification

```bash
cd web
npm ci
npm test
```

`npm test` runs five data/state tests and the Playwright browser suite. The browser checks cover locale and metadata, all 12 questions, citations, scripted tutor disclosure, completion, recovery, reset, keyboard operation, ARIA state, responsive navigation, screenshots, overflow, and off-origin requests.

To validate production instead of the local static server:

```bash
cd web
ANCHOR_BASE_URL=https://anchor.playlab.eu.cc npm run test:e2e
```

## Deployment

The authoritative deployment and rollback procedure is in [DEPLOYMENT.md](./DEPLOYMENT.md). The production URLs are:

- `https://anchor.playlab.eu.cc/`
- `https://anchor.playlab.eu.cc/app/`
- `https://anchor.playlab.eu.cc/app/index.html` (canonical redirect to `/app/`)

Do not add analytics or network integrations without changing the explicit no-external-request contract and its tests.
