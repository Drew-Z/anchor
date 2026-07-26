# Anchor Web Deployment

The production website is a static Cloudflare Pages project.

## Published Layout

- Pages output directory: `web/landing`
- Product site: `https://anchor.playlab.eu.cc/`
- Interactive demo: `https://anchor.playlab.eu.cc/app/`
- Direct demo document: `https://anchor.playlab.eu.cc/app/index.html`

`web/app` is not a publishable source. The demo must remain under `web/landing/app` so it ships in the same immutable static deployment as the product site.

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
```

Then verify in a browser:

- `/` and `/app/` are distinct pages.
- Chinese/English selection persists between both surfaces.
- Flutter, Git, and JavaScript datasets can be selected.
- A submitted answer shows feedback, explanation, locator, source excerpt, and scripted tutor hints.
- The demo makes no provider, analytics, upload, or backend request.
- Desktop, tablet, and mobile views have no horizontal overflow or overlapping controls.

## Rollback

Use Cloudflare Pages deployment history to restore the previous production deployment, then revert the isolated repository commit. No database or persistent application identifier changes are part of this website release.
