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
```

Required results:

- `/` returns `200`.
- `/app/` returns `200`.
- `/app/index.html` returns a permanent redirect, `301` or `308`, and `Location: /app/`. A `200` means the redirect did not reach the deployment; a `302` or `307` means it shipped as temporary and does not make `/app/` canonical.

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
