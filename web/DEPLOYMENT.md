# Anchor Web Deployment

The production website is a static Cloudflare Pages project.

## Published Layout

- Pages output directory: `web/landing`
- Product site: `https://anchor.playlab.eu.cc/`
- Interactive demo: `https://anchor.playlab.eu.cc/app/` (canonical)
- Direct demo document: `https://anchor.playlab.eu.cc/app/index.html` (redirects to `/app/`)

`web/app` is not a publishable source. The demo must remain under `web/landing/app` so it ships in the same immutable static deployment as the product site.

## Canonical Demo Entry

`/app/` is the one canonical demo URL. `web/landing/_redirects` sends both `/app` and `/app/index.html` there with a permanent redirect, so a bookmark or search result naming the document lands on the canonical path instead of serving a second copy of the same page.

`npm run serve` is a plain static file server and does not read `_redirects`, so local requests cannot demonstrate this behaviour. The rules are asserted against the published file by `npm run test:unit`, and against the deployment by the smoke check below.

## Cache Policy

`web/landing/_headers` sets the policy. There are two classes, and the conservative one is the default:

- `/assets/*` gets `public, max-age=86400, stale-while-revalidate=604800, no-transform`. Images and icons change by publishing a new file rather than by editing a published one, so a cached copy cannot contradict the page that loads it.
- Every published document, script, and stylesheet gets `public, max-age=0, must-revalidate, no-transform`. The response is still cacheable; a cache may reuse it only after the origin confirms it is current, which costs one conditional request and returns `304` when nothing changed.

The second class is strict on purpose. None of those files is content-hashed, and the `?v=` stamps that exist are partial: `app.js` carries one but the `data.js` it imports does not, and `i18n.js` is fetched both with a stamp and without. Without revalidation a browser could hold a stale module next to a fresh document and run a pairing that was never published.

The rules name paths explicitly instead of relying on a suffix wildcard: `/`, `/index.html`, `/404.html`, `/app/`, `/app/index.html`, and the prefix form already proven by `/assets/*` for `/scripts/*`, `/styles/*`, `/app/scripts/*`, and `/app/styles/*`. Each block states its whole `Cache-Control` value, so no path depends on inheriting one from the `/*` baseline, and each value ends in `no-transform`, which keeps the baseline's own `Cache-Control` a subset of it.

The policy is static and provider-free: no service worker, no runtime cache, no cache-busting code. Adding a document, script, or stylesheet to the deployment requires a matching rule. `npm run test:unit` reads the published `_headers` from disk, asserts the required paths and directives, and fails when a shipped file has no rule.

`npm run serve` does not read `_headers` either, so no local request can show these values. The published file is the contract; the response headers are checked against the deployment by the smoke check below.

## Local Validation

```bash
cd web
npm ci
npm test
```

The browser suite starts a local static server and verifies both language modes, the complete quiz path, citations, scripted tutor hints, mobile navigation, screenshots, and the no-external-request contract.

## Production Deploy

Run only after the local tests pass and the current Git diff has been reviewed:

```bash
cd web
npx wrangler pages deploy landing --project-name anchor-learning --branch main
```

Do not paste Cloudflare account IDs, API tokens, or dashboard-specific URLs into repository documentation.

## Smoke Check

```bash
curl -I https://anchor.playlab.eu.cc/
curl -I https://anchor.playlab.eu.cc/app/
curl -I https://anchor.playlab.eu.cc/app/index.html
curl -sI https://anchor.playlab.eu.cc/app/index.html | grep -i '^location:'

for path in / /app/ /app/scripts/app.js /app/scripts/data.js /app/styles/app.css /scripts/main.js /scripts/i18n.js /styles/main.css /assets/anchor-icon.svg; do
  printf '%s ' "$path"
  curl -sI "https://anchor.playlab.eu.cc$path" | grep -i '^cache-control:'
done
```

Required results:

- `/` returns `200`.
- `/app/` returns `200`.
- `/app/index.html` returns a permanent redirect, `301` or `308`, and `Location: /app/`. A `200` means the redirect did not reach the deployment; a `302` or `307` means it shipped as temporary and does not make `/app/` canonical.
- Every path in the loop reports a `Cache-Control`. `/assets/anchor-icon.svg` reports `max-age=86400` with `stale-while-revalidate=604800`; every other path reports `max-age=0` with `must-revalidate`. All of them report `no-transform`.
- A missing `Cache-Control`, a missing `must-revalidate`, or any `max-age` above zero outside `/assets/` means the `_headers` rule for that path did not reach the deployment. Nothing in this repository has observed these responses; run the loop after deploying and record what it returns.

Then verify in a browser:

- `/` and `/app/` are distinct pages.
- Opening `/app/index.html` leaves the address bar on `/app/`.
- Chinese/English selection persists between both surfaces.
- Flutter, Git, and JavaScript datasets can be selected.
- A submitted answer shows feedback, explanation, locator, source excerpt, and scripted tutor hints.
- The demo makes no provider, analytics, upload, or backend request.
- Desktop, tablet, and mobile views have no horizontal overflow or overlapping controls.

## Rollback

Use Cloudflare Pages deployment history to restore the previous production deployment, then revert the isolated repository commit. No database or persistent application identifier changes are part of this website release.
