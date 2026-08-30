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
- The demo has no login, backend, analytics, or live AI request. It is not the full Flutter application.

## Browser Storage

The demo persists five `localStorage` keys on the current browser and device. No other key on this origin is read, exported, or deleted.

| Key | Holds |
| --- | --- |
| `anchor.locale` | Locale choice, shared by the product site and the demo |
| `anchor.demo.progress.v1` | Versioned quiz progress |
| `anchor.demo.library.v1` | Library imported from local files |
| `anchor.demo.agent.v1` | Guided Agent session, including learner-written reflections |
| `anchor.demo.theme.v1` | Theme preference |

The demo's Profile surface lists all five keys with their measured sizes, including keys not written yet, so the full set of names is visible. Deletion is scoped by name: progress, library, and the Agent session each have their own confirmed delete control, and "clear all local data" removes exactly these five keys rather than calling `localStorage.clear()`, because this origin also serves the product site. Backup export writes the three learning keys (progress, library, Agent session) to a JSON file in the browser's own download folder; locale and theme are display preferences and stay out of the file.

## Local File Import

The demo reads local `.md`, `.markdown`, and `.txt` files (up to 128 KB) through a file picker or drag and drop, so a learner can see how Anchor splits a document into sections. Restore reads a `.json` backup the same way.

Reading a file is browser-local: contents are parsed in the page and kept in `anchor.demo.library.v1` on this device. Nothing is sent to a backend, storage service, or AI provider, and there is none to send to. The deployed `_headers` sets `connect-src 'none'`, and a Playwright check asserts no off-origin request.

## Development And Verification

```bash
cd web
npm ci
npm test
```

`npm test` runs the Node data/state tests in `tests/*.test.mjs` first, then the Playwright browser suite in `tests/demo.spec.js`. The Node tests cover the bundled datasets and the pure state logic: progress, library, Agent session, theme, backup and restore, search, and the redirect table. The browser suite drives the deployed surfaces: locale and metadata, all 12 questions, citations, scripted tutor disclosure, completion review, library import and search, the guided Agent session, Profile storage inventory, backup and restore, scoped deletion, theme, recovery, reset, keyboard operation, ARIA state, responsive navigation, screenshots, overflow, and off-origin requests.

Both suites must pass. Read the counts from the runner rather than from this file.

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
