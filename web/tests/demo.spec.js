import { expect, test } from '@playwright/test';
import {
  AGENT_SESSION_LIMITS,
  AGENT_SESSION_VERSION,
  DATASETS,
  LOCAL_IMPORT_LIMITS,
  SHELL_TEXT,
  buildAgentScript,
  countSources,
  getDataset,
} from '../landing/app/scripts/data.js';
import {
  AGENT_SESSION_STORAGE_KEY,
  ANCHOR_STORAGE_KEYS,
  LOCAL_LIBRARY_STORAGE_KEY,
  PROGRESS_STORAGE_KEY,
  THEME_STORAGE_KEY,
} from '../landing/app/scripts/app.js';

const expectedOrigin = new URL(process.env.ANCHOR_BASE_URL ?? 'http://127.0.0.1:4173').origin;

const IMPORT_FIXTURE = [
  '# Anchor overview',
  'Anchor keeps every question attached to the passage it came from.',
  '',
  '## Local storage',
  'Imported records stay in this browser.',
  '',
  '## Review loop',
  'Due items resurface on a schedule.',
].join('\n');

/** Feeds one in-memory file to the picker. No fixture is written to disk. */
async function pickFile(page, { name = 'anchor-notes.md', text = IMPORT_FIXTURE, mimeType = 'text/markdown' } = {}) {
  await page.locator('[data-import-input]').setInputFiles({ name, mimeType, buffer: Buffer.from(text, 'utf8') });
}

function storedSourceNames(page) {
  return page.evaluate((key) => {
    const raw = window.localStorage.getItem(key);
    return raw ? JSON.parse(raw).sources.map((source) => source.name) : null;
  }, LOCAL_LIBRARY_STORAGE_KEY);
}

function storedAgentSession(page) {
  return page.evaluate((key) => {
    const raw = window.localStorage.getItem(key);
    return raw ? JSON.parse(raw) : null;
  }, AGENT_SESSION_STORAGE_KEY);
}

/** Walks the start panel the way a learner would: pick a bundled dataset, then begin. */
async function startAgentSession(page, datasetId) {
  await page.goto('/app/#/agent');
  await page.locator(`[data-agent-dataset="${datasetId}"]`).check();
  await page.locator('[data-agent-start-session]').click();
  await expect(page.locator('[data-agent-turn]')).toBeVisible();
}

/** Feeds one in-memory backup file to the restore picker. */
async function pickBackup(page, { name = 'anchor-demo-backup.json', text, mimeType = 'application/json' }) {
  await page.locator('[data-restore-input]').setInputFiles({ name, mimeType, buffer: Buffer.from(text, 'utf8') });
}

/** All Anchor keys, so a test can assert exactly which ones a control touched. */
function storedKeys(page) {
  return page.evaluate((keys) => Object.fromEntries(keys.map((key) => [key, localStorage.getItem(key)])), ANCHOR_STORAGE_KEYS);
}

/** Builds real local state through the UI: one submitted answer, one import, one agent session. */
async function seedLocalState(page) {
  await page.goto('/app/#/decks/flutter');
  await page.locator('input[value="state"]').check();
  await page.locator('[data-submit]').click();

  await page.goto('/app/#/import');
  await pickFile(page);
  await page.locator('[data-import-confirm]').click();
  await expect(page.locator('[data-import-saved]')).toBeVisible();

  await startAgentSession(page, 'flutter');
  await page.locator('[data-agent-reflection]').fill('A reflection worth keeping.');
  await expect(page.locator('[data-agent-advance]')).not.toHaveAttribute('aria-disabled', 'true');
}

/** Clicks Export and returns the saved file's name and parsed contents. */
async function exportBackup(page) {
  const download = await Promise.all([
    page.waitForEvent('download'),
    page.locator('[data-backup-export]').click(),
  ]).then(([event]) => event);

  const stream = await download.createReadStream();
  const chunks = [];
  for await (const chunk of stream) chunks.push(chunk);
  const text = Buffer.concat(chunks).toString('utf8');
  return { name: download.suggestedFilename(), text, record: JSON.parse(text) };
}

const SHELL_SURFACES = [
  { route: 'home', view: 'home', en: SHELL_TEXT.navLearn.en, zh: SHELL_TEXT.navLearn.zh },
  { route: 'decks', view: 'decks', en: SHELL_TEXT.navDecks.en, zh: SHELL_TEXT.navDecks.zh },
  { route: 'agent', view: 'agent', en: SHELL_TEXT.navAgent.en, zh: SHELL_TEXT.navAgent.zh },
  { route: 'library', view: 'library', en: SHELL_TEXT.navLibrary.en, zh: SHELL_TEXT.navLibrary.zh },
  { route: 'profile', view: 'profile', en: SHELL_TEXT.navProfile.en, zh: SHELL_TEXT.navProfile.zh },
];

test('landing and demo share a persistent bilingual locale', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('h1')).toHaveText('Anchor Learning');
  await expect(page.locator('.hero-lead')).toContainText('source-grounded practice');

  await page.locator('[data-locale="zh"]').click();
  await expect(page.locator('.hero-lead')).toContainText('技术文档和代码');
  await expect(page.locator('html')).toHaveAttribute('lang', 'zh-CN');

  await page.reload();
  await expect(page.locator('.hero-lead')).toContainText('技术文档和代码');
  await page.goto('/app/');
  await expect(page.locator('h1')).toContainText(SHELL_TEXT.home.title.zh);
  await expect(page.locator('#app-nav')).toContainText(SHELL_TEXT.navLibrary.zh);
  await page.goto('/app/#/decks');
  await expect(page.locator('h1')).toContainText('选择一个数据集');
  await expect(page.locator('html')).toHaveAttribute('lang', 'zh-CN');
});

test('landing separates the Android Private Alpha from the static browser demo', async ({ page }) => {
  const offOriginRequests = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOriginRequests.push(request.url());
  });

  await page.goto('/');
  await expect(page.locator('.product-status')).toContainText('Android Private Alpha');
  await expect(page.locator('.product-status')).toContainText('Local-first SQLite');
  await expect(page.locator('.native-step')).toHaveCount(3);
  await expect(page.locator('.native-disclosure')).toContainText('No public APK');
  await expect(page.locator('.hero-note')).toContainText('static product sample');

  const nativeImages = page.locator('.device-frame img');
  await expect(nativeImages).toHaveCount(3);
  for (let index = 0; index < 3; index += 1) {
    await expect(nativeImages.nth(index)).toBeVisible();
    await expect.poll(() => nativeImages.nth(index).evaluate((image) => image.naturalWidth)).toBeGreaterThan(0);
  }

  await page.locator('[data-locale="zh"]').click();
  await expect(page.locator('.native-heading')).toContainText('Android 上的来源约束学习流程');
  await expect(page.locator('.native-disclosure')).toContainText('不提供公开 APK');
  expect(offOriginRequests).toEqual([]);
});

test('a learner can answer, inspect evidence, use tutor hints, and continue', async ({ page }) => {
  const offOriginRequests = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOriginRequests.push(request.url());
  });

  await page.goto('/app/#/decks');
  await page.locator('.dataset-choice[data-select-dataset="flutter"]').click();
  await expect(page).toHaveURL(/#\/decks\/flutter$/);
  await expect(page.locator('.question-title')).toContainText('Which object keeps mutable data');
  await page.locator('input[value="state"]').check();
  await page.locator('[data-submit]').click();
  await expect(page.locator('.feedback-status')).toContainText('Supported by the source');
  await expect(page.locator('.citation-locator')).toContainText('flutter/widgets.md#statefulwidget');

  await page.locator('[data-toggle-tutor]').click();
  await expect(page.locator('.tutor-panel')).toContainText('No live AI is running');
  await page.locator('[data-next]').click();
  await expect(page.locator('.question-index')).toContainText('Question 2 of 4');
  expect(offOriginRequests).toEqual([]);
});

test('all bundled datasets complete with citations, tutor disclosure, recovery, and reset', async ({ page }) => {
  const offOriginRequests = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOriginRequests.push(request.url());
  });

  await page.goto('/app/#/decks');
  for (const dataset of DATASETS) {
    await page.locator(`.dataset-choice[data-select-dataset="${dataset.id}"]`).click();
    await expect(page).toHaveURL(new RegExp(`#/decks/${dataset.id}$`));
    for (const [index, question] of dataset.questions.entries()) {
      await expect(page.locator('.question-index')).toContainText(`Question ${index + 1} of ${dataset.questions.length}`);
      for (const optionId of question.correct) await page.locator(`input[value="${optionId}"]`).check();
      await page.locator('[data-submit]').click();
      await expect(page.locator('.feedback-status')).toContainText('Supported by the source');
      await expect(page.locator('.citation-locator')).toContainText(question.citations[0].locator);
      const tutorButton = page.locator('[data-toggle-tutor]');
      await expect(tutorButton).toHaveAttribute('aria-controls', `tutor-${question.id}`);
      await tutorButton.click();
      await expect(page.locator(`#tutor-${question.id}`)).toContainText('No live AI is running');
      await page.locator('[data-next]').click();
    }
    await expect(page.locator('.completion-view')).toBeVisible();
    await expect(page.locator('.completion-score strong')).toHaveText(String(dataset.questions.length));
    await page.locator('[data-choose-another]').click();
  }

  expect(offOriginRequests).toEqual([]);
  await page.locator('#reset-progress').click();
  await expect(page.locator('.welcome-view')).toBeVisible();
  await page.locator('#dataset-list [data-select-dataset="flutter"]').click();
  await page.locator('input[value="state"]').check();
  await page.locator('[data-submit]').click();
  await page.reload();
  await expect(page).toHaveURL(/#\/decks\/flutter$/);
  await expect(page.locator('.feedback-status')).toContainText('Supported by the source');
  await page.locator('#reset-progress').click();
  await expect(page).toHaveURL(/#\/decks$/);
  await expect(page.locator('.welcome-view')).toBeVisible();
  expect(await page.evaluate((key) => localStorage.getItem(key), PROGRESS_STORAGE_KEY)).toBeNull();

  await page.goto('/app/#/profile');
  await page.locator('#dataset-list [data-select-dataset="git"]').click();
  await page.locator('input[value="snapshot"]').check();
  await page.locator('[data-submit]').click();
  await page.locator('[data-nav-route="profile"]').click();
  // The profile control confirms first; the sidebar's own reset stays immediate.
  const profileReset = page.locator('[data-privacy-reset="progress"]');
  await expect(profileReset).toBeEnabled();
  await profileReset.click();
  expect(await page.evaluate((key) => localStorage.getItem(key), PROGRESS_STORAGE_KEY)).not.toBeNull();
  await page.locator('[data-privacy-confirm-action="progress"]').click();
  await expect(page.locator('#app-announcer')).toHaveText('Local demo progress was reset.');
  expect(await page.evaluate((key) => localStorage.getItem(key), PROGRESS_STORAGE_KEY)).toBeNull();
});

test('malformed or incompatible progress returns safely to dataset selection', async ({ page }) => {
  await page.addInitScript(([key]) => localStorage.setItem(key, '{broken-json'), [PROGRESS_STORAGE_KEY]);
  await page.goto('/app/#/decks');
  await expect(page.locator('.welcome-view')).toBeVisible();

  await page.evaluate(([key]) => localStorage.setItem(key, JSON.stringify({ version: 999, activeDatasetId: 'git', datasets: {} })), [PROGRESS_STORAGE_KEY]);
  await page.reload();
  await expect(page.locator('.welcome-view')).toBeVisible();

  await page.goto('/app/#/decks/not-a-dataset');
  await expect(page.locator('.welcome-view')).toBeVisible();
  await page.goto('/app/#/nowhere');
  await expect(page).toHaveURL(/#\/home$/);
  await expect(page.locator('h1')).toContainText(SHELL_TEXT.home.title.en);
});

test('keyboard actions and live regions expose the learning state', async ({ page }) => {
  await page.goto('/');
  const chineseButton = page.locator('[data-locale="zh"]');
  await chineseButton.focus();
  await page.keyboard.press('Enter');
  await expect(page.locator('html')).toHaveAttribute('lang', 'zh-CN');

  await page.goto('/app/#/decks');
  const datasetButton = page.locator('.dataset-choice[data-select-dataset="flutter"]');
  await datasetButton.focus();
  await page.keyboard.press('Enter');
  const answer = page.locator('input[value="state"]');
  await answer.focus();
  await page.keyboard.press('Space');
  const submit = page.locator('[data-submit]');
  await submit.focus();
  await page.keyboard.press('Enter');
  await expect(page.locator('#app-announcer')).toHaveText('答案得到来源支持');
  await expect(page.getByRole('progressbar', { name: '已答题目' })).toHaveAttribute('aria-valuenow', '1');
});

test('mobile dataset navigation works without horizontal overflow', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/app/');
  await expect(page.locator('#app-tabbar')).toBeVisible();
  await expect(page.locator('#app-nav')).toBeHidden();
  await page.locator('#dataset-menu-button').click();
  await expect(page.locator('#dataset-sidebar')).toHaveClass(/is-open/);
  await page.locator('#dataset-list [data-select-dataset="javascript"]').click();
  await expect(page.locator('#dataset-sidebar')).not.toHaveClass(/is-open/);
  await expect(page.locator('.question-title')).toContainText('queued callback');
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  expect(overflow).toBeLessThanOrEqual(0);
});

test('the shell exposes every product surface on desktop and mobile', async ({ page }) => {
  const offOriginRequests = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOriginRequests.push(request.url());
  });

  await page.goto('/app/');
  await expect(page).toHaveURL(/#\/home$/);
  await expect(page.locator('body')).toHaveAttribute('data-view', 'home');

  for (const surface of SHELL_SURFACES) {
    const link = page.locator(`#app-nav [data-nav-route="${surface.route}"]`);
    await expect(link).toContainText(surface.en);
    await link.click();
    await expect(page).toHaveURL(new RegExp(`#/${surface.route}$`));
    await expect(page.locator('body')).toHaveAttribute('data-view', surface.view);
    await expect(link).toHaveAttribute('aria-current', 'page');
    await expect(page.locator('#app-nav [aria-current="page"]')).toHaveCount(1);
    await expect(page.locator('#app-content h1')).toBeVisible();
  }

  await page.locator('#sidebar-import [data-nav-route="import"]').click();
  await expect(page).toHaveURL(/#\/import$/);
  await expect(page.locator('#sidebar-import [data-nav-route="import"]')).toHaveAttribute('aria-current', 'page');
  await expect(page.locator('[data-import-input]')).toBeAttached();
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.importer.noAiTitle.en);
  await expect(page.locator('#app-content a[href="../#native-app"]').first()).toBeVisible();
  await expect(page.locator('#app-content')).not.toContainText('APK');

  // Opening a deck from a Home link must set the resume hint the same way the sidebar does, so
  // the continue card follows the last deck actually worked on rather than only sidebar picks.
  const resumeDataset = DATASETS[2];
  await page.goto('/app/#/home');
  await page.locator('.plan-row').nth(2).click();
  await expect(page).toHaveURL(new RegExp(`#/decks/${resumeDataset.id}$`));
  for (const optionId of resumeDataset.questions[0].correct) await page.locator(`input[value="${optionId}"]`).check();
  await page.locator('[data-submit]').click();
  await page.locator('[data-nav-route="home"]').first().click();
  await expect(page.locator('.shell-card-accent')).toContainText(resumeDataset.title.en);
  await expect(page.locator('.shell-card-accent .button')).toHaveAttribute('href', `#/decks/${resumeDataset.id}`);

  await page.goto('/app/#/library');
  await expect(page.locator('#app-content')).toContainText(String(countSources()));
  await expect(page.locator('.source-group')).toHaveCount(DATASETS.length);
  await expect(page.locator('.citation-locator').first()).toContainText(DATASETS[0].questions[0].citations[0].locator);
  await page.locator('.source-group-link').first().click();
  await expect(page).toHaveURL(new RegExp(`#/decks/${DATASETS[0].id}$`));

  // Import is not a primary tab in the native app either, so on mobile it stays reachable from
  // Home rather than only from behind the drawer button.
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/app/#/home');
  await expect(page.locator('#app-nav')).toBeHidden();
  const homeImport = page.locator('#app-content a[data-nav-route="import"]');
  await expect(homeImport).toBeVisible();
  await homeImport.click();
  await expect(page).toHaveURL(/#\/import$/);

  for (const surface of SHELL_SURFACES) {
    const tab = page.locator(`#app-tabbar [data-tab-route="${surface.route}"]`);
    await tab.click();
    await expect(page).toHaveURL(new RegExp(`#/${surface.route}$`));
    await expect(tab).toHaveAttribute('aria-current', 'page');
    await expect(page.locator('#app-content h1')).toBeVisible();
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow, `${surface.route} overflows at 390px`).toBeLessThanOrEqual(0);
  }

  expect(offOriginRequests).toEqual([]);
});

test('the shell surfaces stay bilingual and honest about unavailable capabilities', async ({ page }) => {
  await page.goto('/app/#/agent');
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.agent.title.en);
  await expect(page.locator('.scope-badge.scope-android').first()).toContainText(SHELL_TEXT.badgeAndroid.en);
  await expect(page.locator('.scope-badge.scope-local').first()).toContainText(SHELL_TEXT.badgeLocal.en);

  await page.locator('[data-locale="zh"]').click();
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.agent.title.zh);
  await expect(page.locator('#app-nav [data-nav-route="library"]')).toContainText(SHELL_TEXT.navLibrary.zh);
  await expect(page.locator('#app-tabbar [data-tab-route="profile"]')).toContainText(SHELL_TEXT.navProfile.zh);

  for (const surface of SHELL_SURFACES) {
    await page.goto(`/app/#/${surface.route}`);
    await expect(page.locator('#app-content h1')).toBeVisible();
    await expect(page.locator('#app-nav [data-nav-route="' + surface.route + '"]')).toContainText(surface.zh);
  }

  await page.goto('/app/#/profile');
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.profile.accountBody.zh);
});

test('an imported file is reviewed before it is stored, then survives a reload', async ({ page }) => {
  const offOriginRequests = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOriginRequests.push(request.url());
  });

  await page.goto('/app/#/import');
  await expect(page.locator('.import-drop')).toBeVisible();
  expect(await storedSourceNames(page)).toBeNull();

  await pickFile(page);
  const review = page.locator('[data-import-review]');
  await expect(review).toBeVisible();
  await expect(review.locator('[data-review-name]')).toHaveText('anchor-notes.md');
  await expect(review.locator('[data-review-sections]')).toContainText('3');
  await expect(review.locator('.local-section')).toHaveCount(3);
  await expect(review.locator('.local-section-heading').first()).toHaveText('Anchor overview');
  await expect(page.locator('[data-import-confirm]')).toBeFocused();

  // Selecting a file must not be the same act as keeping it.
  expect(await storedSourceNames(page)).toBeNull();
  await page.goto('/app/#/library');
  await expect(page.locator('.local-source')).toHaveCount(0);
  await expect(page.locator('[data-local-empty]')).toBeVisible();

  await page.goto('/app/#/import');
  await pickFile(page);
  await page.locator('[data-import-confirm]').click();
  await expect(page.locator('[data-import-saved]')).toContainText(SHELL_TEXT.importer.savedTitle.en);
  await expect(page.locator('[data-import-saved]')).toContainText('anchor-notes.md');
  await expect(page.locator('#app-announcer')).toContainText('anchor-notes.md');
  await expect(page.locator('[data-import-review]')).toHaveCount(0);
  expect(await storedSourceNames(page)).toEqual(['anchor-notes.md']);

  await page.locator('[data-import-saved] .button').click();
  await expect(page).toHaveURL(/#\/library$/);
  const source = page.locator('.local-source');
  await expect(source).toHaveCount(1);
  await expect(source).toContainText('anchor-notes.md');
  await expect(source).toContainText('3');

  await page.reload();
  await expect(page.locator('.local-source')).toHaveCount(1);
  const toggle = page.locator('[data-toggle-source]');
  await expect(toggle).toHaveAttribute('aria-expanded', 'false');
  await toggle.click();
  await expect(toggle).toHaveAttribute('aria-expanded', 'true');
  await expect(toggle).toBeFocused();
  const region = page.locator(`#${await toggle.getAttribute('aria-controls')}`);
  await expect(region.locator('.local-section')).toHaveCount(3);
  await expect(region.locator('.local-section-locator').first()).toContainText('anchor-notes.md#anchor-overview');

  // Bundled evidence stays separate from imported excerpts.
  await expect(page.locator('.source-group')).toHaveCount(DATASETS.length);
  await expect(page.locator('.citation-locator').first()).toContainText(DATASETS[0].questions[0].citations[0].locator);
  expect(offOriginRequests).toEqual([]);
});

test('a dropped file reaches the same review step as the picker', async ({ page }) => {
  await page.goto('/app/#/import');

  // Real `File` and `DataTransfer` objects, so this exercises the drop path rather than a shortcut.
  const dropped = await page.evaluate(() => {
    const transfer = new DataTransfer();
    transfer.items.add(new File(['# Dropped notes\nBody of the dropped file.'], 'dropped.md', { type: 'text/markdown' }));
    const zone = document.querySelector('[data-import-drop]');
    zone.dispatchEvent(new DragEvent('dragover', { bubbles: true, cancelable: true, dataTransfer: transfer }));
    const dragging = zone.classList.contains('is-dragging');
    const drop = new DragEvent('drop', { bubbles: true, cancelable: true, dataTransfer: transfer });
    zone.dispatchEvent(drop);
    return { dragging, defaultPrevented: drop.defaultPrevented };
  });

  // Without preventDefault the browser would navigate to the file and lose the demo.
  expect(dropped).toEqual({ dragging: true, defaultPrevented: true });
  await expect(page.locator('[data-review-name]')).toHaveText('dropped.md');
  await expect(page.locator('.import-drop.is-dragging')).toHaveCount(0);
  expect(await storedSourceNames(page)).toBeNull();

  await page.locator('[data-import-confirm]').click();
  expect(await storedSourceNames(page)).toEqual(['dropped.md']);
});

test('import refuses unsupported, oversized, and unreadable files with an alert', async ({ page }) => {
  await page.goto('/app/#/import');
  const error = page.locator('[data-import-error]');

  await pickFile(page, { name: 'slides.pdf', mimeType: 'application/pdf', text: 'not markdown' });
  await expect(error).toHaveAttribute('role', 'alert');
  await expect(error).toContainText('not supported');
  await expect(page.locator('[data-import-review]')).toHaveCount(0);
  await expect(page.locator('[data-import-input]')).toHaveAttribute('aria-describedby', /import-error/);

  await pickFile(page, { name: 'huge.txt', mimeType: 'text/plain', text: 'a'.repeat(LOCAL_IMPORT_LIMITS.maxBytes + 2_000) });
  await expect(error).toContainText(`${Math.round(LOCAL_IMPORT_LIMITS.maxBytes / 1024)} KB`);
  await expect(page.locator('[data-import-review]')).toHaveCount(0);

  await pickFile(page, { name: 'blank.txt', mimeType: 'text/plain', text: '' });
  await expect(error).toContainText('no readable text');

  await pickFile(page, { name: 'binary.txt', mimeType: 'text/plain', text: `head${String.fromCharCode(0)}tail` });
  await expect(error).toContainText('does not look like text');

  expect(await storedSourceNames(page)).toBeNull();

  // A valid pick clears the alert.
  await pickFile(page);
  await expect(page.locator('[data-import-error]')).toHaveCount(0);
  await expect(page.locator('[data-import-review]')).toBeVisible();
});

test('imported text is rendered as text and never as markup', async ({ page }) => {
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(error.message));

  const hostile = [
    '# <img src=x onerror="window.__anchorPwned = true">',
    '<script>window.__anchorPwned = true;</script>',
    '',
    '## Second & <b>bold</b>',
    '</p></div><iframe src="https://example.com"></iframe>',
  ].join('\n');

  await page.goto('/app/#/import');
  await pickFile(page, { name: '<b>notes</b>.md', text: hostile });
  await expect(page.locator('[data-review-name]')).toHaveText('<b>notes</b>.md');
  await page.locator('[data-import-confirm]').click();
  await page.goto('/app/#/library');
  await page.locator('[data-toggle-source]').click();

  await expect(page.locator('.local-source-title strong')).toHaveText('<b>notes</b>.md');
  await expect(page.locator('.local-section-text').first()).toContainText('<script>window.__anchorPwned = true;</script>');
  await expect(page.locator('.local-source b')).toHaveCount(0);
  await expect(page.locator('.local-source img, .local-source iframe, .local-source script')).toHaveCount(0);
  expect(await page.evaluate(() => window.__anchorPwned)).toBeUndefined();
  expect(pageErrors).toEqual([]);
});

test('removing an imported source is confirmed and scoped to that source', async ({ page }) => {
  await page.goto('/app/#/import');
  await pickFile(page, { name: 'first.md', text: '# First\nKeep this one.' });
  await page.locator('[data-import-confirm]').click();
  await pickFile(page, { name: 'second.md', text: '# Second\nRemove this one.' });
  await page.locator('[data-import-confirm]').click();

  await page.goto('/app/#/library');
  await expect(page.locator('.local-source')).toHaveCount(2);
  const target = page.locator('[data-local-source]').filter({ hasText: 'second.md' });

  await target.locator('[data-remove-source]').click();
  const confirm = target.locator('.local-confirm');
  await expect(confirm).toBeVisible();
  await expect(confirm).toContainText('second.md');
  await expect(target.locator('[data-confirm-remove]')).toBeFocused();
  // Nothing is gone until the second, deliberate click.
  await expect(page.locator('.local-source')).toHaveCount(2);
  expect(await storedSourceNames(page)).toEqual(['second.md', 'first.md']);

  await target.locator('[data-cancel-remove]').click();
  await expect(page.locator('.local-confirm')).toHaveCount(0);
  await expect(page.locator('.local-source')).toHaveCount(2);

  await target.locator('[data-remove-source]').click();
  await target.locator('[data-confirm-remove]').click();
  await expect(page.locator('.local-source')).toHaveCount(1);
  await expect(page.locator('.local-source')).toContainText('first.md');
  await expect(page.locator('#app-announcer')).toContainText('second.md');
  expect(await storedSourceNames(page)).toEqual(['first.md']);

  await page.reload();
  await expect(page.locator('.local-source')).toHaveCount(1);
  await expect(page.locator('.local-source')).toContainText('first.md');
});

test('resetting demo progress keeps imported sources, and the library resets separately', async ({ page }) => {
  await page.goto('/app/#/decks/flutter');
  await page.locator('input[value="state"]').check();
  await page.locator('[data-submit]').click();

  await page.goto('/app/#/import');
  await pickFile(page);
  await page.locator('[data-import-confirm]').click();

  await page.locator('#reset-progress').click();
  expect(await page.evaluate((key) => window.localStorage.getItem(key), PROGRESS_STORAGE_KEY)).toBeNull();
  await page.goto('/app/#/library');
  await expect(page.locator('.local-source')).toHaveCount(1);
  expect(await storedSourceNames(page)).toEqual(['anchor-notes.md']);

  await page.locator('[data-reset-library]').click();
  await expect(page.locator('[data-confirm-reset-library]')).toBeFocused();
  await expect(page.locator('.local-source')).toHaveCount(1);
  await page.locator('[data-confirm-reset-library]').click();
  await expect(page.locator('.local-source')).toHaveCount(0);
  await expect(page.locator('[data-local-empty]')).toBeVisible();
  expect(await storedSourceNames(page)).toBeNull();

  // Bundled sources are untouched by either reset.
  await expect(page.locator('.source-group')).toHaveCount(DATASETS.length);
  await page.reload();
  await expect(page.locator('.local-source')).toHaveCount(0);
  await expect(page.locator('.source-group')).toHaveCount(DATASETS.length);
});

test('malformed or stale library storage recovers instead of breaking the library', async ({ page }) => {
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(error.message));

  await page.goto('/app/#/library');
  for (const value of ['not json at all', '{"version":99,"sources":[{"id":"x"}]}', '{"version":1,"sources":"nope"}', 'null']) {
    await page.evaluate(([key, stored]) => window.localStorage.setItem(key, stored), [LOCAL_LIBRARY_STORAGE_KEY, value]);
    await page.reload();
    await expect(page.locator('#local-library')).toBeVisible();
    await expect(page.locator('.local-source')).toHaveCount(0);
    await expect(page.locator('.source-group')).toHaveCount(DATASETS.length);
  }

  // The demo still accepts a fresh import over the discarded record.
  await page.goto('/app/#/import');
  await pickFile(page);
  await page.locator('[data-import-confirm]').click();
  expect(await storedSourceNames(page)).toEqual(['anchor-notes.md']);
  expect(pageErrors).toEqual([]);
});

test('import and browser library copy stay bilingual', async ({ page }) => {
  await page.goto('/app/#/import');
  await page.locator('[data-locale="zh"]').click();
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.importer.pickTitle.zh);
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.importer.noAiBody.zh);
  await expect(page.locator('#privacy-note')).toContainText(SHELL_TEXT.privacy.title.zh);

  await pickFile(page, { name: '锚学笔记.md', text: '# 概念\n每个问题都附带来源。' });
  await expect(page.locator('[data-import-review]')).toContainText(SHELL_TEXT.importer.reviewTitle.zh);
  await expect(page.locator('[data-review-name]')).toHaveText('锚学笔记.md');
  await page.locator('[data-import-confirm]').click();
  await expect(page.locator('[data-import-saved]')).toContainText(SHELL_TEXT.importer.savedTitle.zh);

  await page.goto('/app/#/library');
  await expect(page.locator('#local-library')).toContainText(SHELL_TEXT.localLibrary.title.zh);
  await expect(page.locator('.local-source')).toContainText('锚学笔记.md');
  await page.locator('[data-toggle-source]').click();
  await expect(page.locator('.local-section-heading')).toHaveText('概念');
  await expect(page.locator('.local-section-text')).toContainText('每个问题都附带来源');

  // Switching back must not lose the stored source or leak the other language.
  await page.locator('[data-locale="en"]').click();
  await expect(page.locator('#local-library')).toContainText(SHELL_TEXT.localLibrary.title.en);
  await expect(page.locator('.local-source')).toContainText('锚学笔记.md');
});

test('import and browser library fit a 390px viewport without horizontal overflow', async ({ page }) => {
  const overflow = () => page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);

  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/app/#/import');
  await expect(page.locator('.import-drop')).toBeVisible();
  expect(await overflow(), 'import picker overflows at 390px').toBeLessThanOrEqual(0);

  await pickFile(page, { name: 'a-rather-long-mobile-filename-for-layout.md', text: IMPORT_FIXTURE });
  await expect(page.locator('[data-import-review]')).toBeVisible();
  expect(await overflow(), 'import review overflows at 390px').toBeLessThanOrEqual(0);

  await page.locator('[data-import-confirm]').click();
  await page.goto('/app/#/library');
  await page.locator('[data-toggle-source]').click();
  await expect(page.locator('.local-section')).toHaveCount(3);
  expect(await overflow(), 'expanded library overflows at 390px').toBeLessThanOrEqual(0);

  await page.locator('[data-remove-source]').click();
  await expect(page.locator('.local-confirm')).toBeVisible();
  expect(await overflow(), 'delete confirmation overflows at 390px').toBeLessThanOrEqual(0);
});

test('a guided agent session runs on bundled content from start to completion', async ({ page }) => {
  const offOriginRequests = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOriginRequests.push(request.url());
  });
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(error.message));

  const dataset = getDataset('flutter');
  const script = buildAgentScript(dataset);

  await page.goto('/app/#/agent');
  await expect(page.locator('[data-agent-start]')).toBeVisible();
  await expect(page.locator('[data-agent-start-session]')).toBeDisabled();
  await expect(page.locator('[data-agent-start-note]')).toBeVisible();
  expect(await storedAgentSession(page)).toBeNull();

  // Choosing a dataset unblocks the start control but stores nothing yet.
  await page.locator('[data-agent-dataset="flutter"]').check();
  await expect(page.locator('[data-agent-start-session]')).toBeEnabled();
  await expect(page.locator('[data-agent-start-note]')).toBeHidden();
  expect(await storedAgentSession(page)).toBeNull();

  await page.locator('[data-agent-start-session]').click();
  await expect(page.locator('[data-agent-turn]')).toBeFocused();
  await expect(page.locator('#app-announcer')).toContainText(dataset.title.en);
  await expect(page.locator('#app-announcer')).toContainText(`Turn 1 of ${script.length}`);
  await expect(page.locator('.agent-progress [role="progressbar"]')).toHaveAttribute('aria-valuemax', String(script.length));

  for (const [index, turn] of script.entries()) {
    await expect(page.locator('[data-agent-counter]')).toHaveText(`Turn ${index + 1} of ${script.length}`);
    await expect(page.locator('[data-agent-prompt]')).toHaveText(turn.prompt.en);
    await expect(page.locator('.agent-turn .citation-locator')).toContainText(turn.citation.locator);
    await expect(page.locator('.agent-turn blockquote')).toContainText(turn.citation.excerpt.en);

    // Hints are bundled text revealed one at a time behind an explicit local disclosure.
    await expect(page.locator('[data-agent-hint-list]')).toHaveCount(0);
    await page.locator('[data-agent-hint]').click();
    await expect(page.locator('[data-agent-hint-list] li')).toHaveCount(1);
    await expect(page.locator('[data-agent-hint-list] li').first()).toHaveText(turn.hints[0].en);
    await expect(page.locator('[data-agent-disclosure]')).toContainText('No live AI');
    await expect(page.locator('#app-announcer')).toContainText(`Hint 1 of ${turn.hints.length}`);

    await page.locator('[data-agent-reflection]').fill(`My own words for turn ${index + 1}.`);
    await expect(page.locator('[data-agent-count]')).toContainText(`/${AGENT_SESSION_LIMITS.maxReflectionChars}`);
    await page.locator('[data-agent-advance]').click();
  }

  await expect(page.locator('[data-agent-complete]')).toBeVisible();
  await expect(page.locator('[data-agent-done]')).toBeFocused();
  await expect(page.locator('#app-announcer')).toContainText(`${script.length} reflections`);
  await expect(page.locator('[data-agent-recap]')).toHaveCount(script.length);

  for (const [index, turn] of script.entries()) {
    const recap = page.locator(`[data-agent-recap="${turn.questionId}"]`);
    await expect(recap).toContainText(`My own words for turn ${index + 1}.`);
    await expect(recap).toContainText(turn.explanation.en);
    await expect(recap.locator('.citation-locator')).toContainText(turn.citation.locator);
  }

  await expect(page.locator(`[data-agent-complete] a[href="#/decks/${dataset.id}"]`)).toBeVisible();
  await expect(page.locator('[data-agent-complete] a[href="#/library"]')).toBeVisible();

  // The finished session survives a reload from local storage alone.
  await page.reload();
  await expect(page.locator('[data-agent-complete]')).toBeVisible();
  await expect(page.locator('[data-agent-recap]')).toHaveCount(script.length);
  const stored = await storedAgentSession(page);
  expect(stored.version).toBe(AGENT_SESSION_VERSION);
  expect(stored.datasetId).toBe(dataset.id);
  expect(stored.completed).toBe(true);
  expect(Object.keys(stored.reflections)).toHaveLength(script.length);

  expect(offOriginRequests, `unexpected off-origin requests: ${offOriginRequests.join(', ')}`).toEqual([]);
  expect(pageErrors).toEqual([]);
});

test('a guided agent turn will not advance until the learner writes something', async ({ page }) => {
  const script = buildAgentScript(getDataset('git'));
  await startAgentSession(page, 'git');

  const advance = page.locator('[data-agent-advance]');
  await expect(advance).toHaveAttribute('aria-disabled', 'true');

  // `aria-disabled` keeps the button in the tab order and still fires on a real pointer press, so the
  // reason can be announced instead of the press being swallowed. Playwright's actionability check
  // treats it as disabled, hence `force`.
  await advance.click({ force: true });
  const nudge = page.locator('[data-agent-nudge]');
  await expect(nudge).toBeVisible();
  await expect(nudge).toHaveText(SHELL_TEXT.agent.reflectionRequired.en);
  await expect(nudge).toBeFocused();
  await expect(page.locator('#app-announcer')).toContainText(SHELL_TEXT.agent.reflectionRequired.en);
  await expect(page.locator('[data-agent-counter]')).toHaveText(`Turn 1 of ${script.length}`);

  // Whitespace is not an answer.
  await page.locator('[data-agent-reflection]').fill('    ');
  await expect(advance).toHaveAttribute('aria-disabled', 'true');
  await advance.click({ force: true });
  await expect(page.locator('[data-agent-counter]')).toHaveText(`Turn 1 of ${script.length}`);
  expect((await storedAgentSession(page)).reflections).toEqual({});

  await page.locator('[data-agent-reflection]').fill('A commit is a snapshot, not a diff.');
  await expect(advance).not.toHaveAttribute('aria-disabled', 'true');
  await expect(page.locator('[data-agent-nudge]')).toHaveCount(0);
  await advance.click();
  await expect(page.locator('[data-agent-counter]')).toHaveText(`Turn 2 of ${script.length}`);
  await expect(page.locator('[data-agent-turn]')).toBeFocused();
  await expect(page.locator('[data-agent-reflection]')).toHaveValue('');

  // Hints run out visibly rather than disappearing.
  const hint = page.locator('[data-agent-hint]');
  const available = script[1].hints.length;
  for (let index = 0; index < available; index += 1) await hint.click();
  await expect(page.locator('[data-agent-hint-list] li')).toHaveCount(available);
  await expect(hint).toBeDisabled();
  await expect(hint).toHaveText(SHELL_TEXT.agent.hintAllShown.en);
  await expect(page.locator('#app-announcer')).toContainText(`Hint ${available} of ${available}`);
});

test('a guided agent session resumes mid-turn and outlives a quiz reset', async ({ page }) => {
  const script = buildAgentScript(getDataset('git'));

  await page.goto('/app/#/decks/flutter');
  await page.locator('input[value="state"]').check();
  await page.locator('[data-submit]').click();
  await expect(page.locator('.feedback-panel')).toBeVisible();

  await startAgentSession(page, 'git');
  await page.locator('[data-agent-hint]').click();
  await page.locator('[data-agent-reflection]').fill('Turn one in my own words.');
  await page.locator('[data-agent-advance]').click();
  await expect(page.locator('[data-agent-counter]')).toHaveText(`Turn 2 of ${script.length}`);

  // Typing is persisted as it happens, so a reload keeps the draft and the revealed hint.
  await page.locator('[data-agent-hint]').click();
  await page.locator('[data-agent-reflection]').fill('Halfway through turn two.');
  await page.reload();
  await expect(page.locator('[data-agent-counter]')).toHaveText(`Turn 2 of ${script.length}`);
  await expect(page.locator('[data-agent-reflection]')).toHaveValue('Halfway through turn two.');
  await expect(page.locator('[data-agent-hint-list] li')).toHaveCount(1);
  await expect(page.locator('[data-agent-advance]')).not.toHaveAttribute('aria-disabled', 'true');
  await expect(page.locator('[data-agent-complete]')).toHaveCount(0);

  // Leaving the surface and coming back is not a reset either.
  await page.goto('/app/#/library');
  await page.goto('/app/#/agent');
  await expect(page.locator('[data-agent-counter]')).toHaveText(`Turn 2 of ${script.length}`);

  // The quiz reset is scoped to quiz progress only.
  await page.locator('#reset-progress').click();
  expect(await page.evaluate((key) => window.localStorage.getItem(key), PROGRESS_STORAGE_KEY)).toBeNull();
  const stored = await storedAgentSession(page);
  expect(stored.datasetId).toBe('git');
  expect(stored.turnIndex).toBe(1);
  await page.goto('/app/#/agent');
  await expect(page.locator('[data-agent-counter]')).toHaveText(`Turn 2 of ${script.length}`);
  await expect(page.locator('[data-agent-reflection]')).toHaveValue('Halfway through turn two.');
});

test('clearing a guided agent session is confirmed and leaves quiz progress and imports alone', async ({ page }) => {
  await page.goto('/app/#/decks/flutter');
  await page.locator('input[value="state"]').check();
  await page.locator('[data-submit]').click();
  await expect(page.locator('.feedback-panel')).toBeVisible();

  await page.goto('/app/#/import');
  await pickFile(page);
  await page.locator('[data-import-confirm]').click();
  expect(await storedSourceNames(page)).toEqual(['anchor-notes.md']);

  await startAgentSession(page, 'flutter');
  await page.locator('[data-agent-reflection]').fill('Worth keeping until I say otherwise.');
  expect(await storedAgentSession(page)).not.toBeNull();

  await page.locator('[data-agent-clear]').click();
  const confirmPanel = page.locator('.agent-confirm');
  await expect(confirmPanel).toBeVisible();
  await expect(confirmPanel).toContainText(SHELL_TEXT.agent.clearBody.en);
  await expect(page.locator('[data-agent-clear-confirm]')).toBeFocused();

  // Nothing is discarded until the second, deliberate click.
  await expect(page.locator('[data-agent-turn]')).toBeVisible();
  expect(await storedAgentSession(page)).not.toBeNull();
  await page.locator('[data-agent-clear-cancel]').click();
  await expect(page.locator('.agent-confirm')).toHaveCount(0);
  await expect(page.locator('[data-agent-reflection]')).toHaveValue('Worth keeping until I say otherwise.');

  await page.locator('[data-agent-clear]').click();
  await page.locator('[data-agent-clear-confirm]').click();
  await expect(page.locator('[data-agent-start]')).toBeVisible();
  await expect(page.locator('[data-agent-turn]')).toHaveCount(0);
  await expect(page.locator('[data-agent-start-session]')).toBeFocused();
  await expect(page.locator('#app-announcer')).toContainText(SHELL_TEXT.agent.announceCleared.en);
  expect(await storedAgentSession(page)).toBeNull();

  // Scoped: the quiz answer and the imported source are untouched.
  expect(await page.evaluate((key) => window.localStorage.getItem(key), PROGRESS_STORAGE_KEY)).not.toBeNull();
  expect(await storedSourceNames(page)).toEqual(['anchor-notes.md']);
  await page.goto('/app/#/decks/flutter');
  await expect(page.locator('.feedback-panel')).toBeVisible();
});

test('malformed or stale agent session storage recovers instead of breaking the surface', async ({ page }) => {
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(error.message));
  const write = (value) =>
    page.evaluate(([key, stored]) => window.localStorage.setItem(key, stored), [AGENT_SESSION_STORAGE_KEY, value]);

  await page.goto('/app/#/agent');
  const unusable = [
    'not json at all',
    'null',
    '[]',
    '{"version":99,"datasetId":"flutter","turnIndex":0}',
    `{"version":${AGENT_SESSION_VERSION},"datasetId":"retired-dataset","turnIndex":2,"completed":true}`,
  ];
  for (const value of unusable) {
    await write(value);
    await page.reload();
    await expect(page.locator('#app-content h1')).toBeVisible();
    await expect(page.locator('[data-agent-start]')).toBeVisible();
    await expect(page.locator('[data-agent-complete]')).toHaveCount(0);
  }

  // A session for a real dataset with an inconsistent pointer resumes where the learner could
  // actually have been, instead of claiming a completion that never happened.
  await write(
    `{"version":${AGENT_SESSION_VERSION},"datasetId":"flutter","turnIndex":999,"completed":true,` +
      '"reflections":{"retired-question":"kept nowhere"},"hints":{"retired-question":9}}',
  );
  await page.reload();
  await expect(page.locator('[data-agent-counter]')).toHaveText(`Turn 1 of ${buildAgentScript(getDataset('flutter')).length}`);
  await expect(page.locator('[data-agent-complete]')).toHaveCount(0);
  await expect(page.locator('[data-agent-reflection]')).toHaveValue('');
  await expect(page.locator('[data-agent-hint-list]')).toHaveCount(0);
  await expect(page.locator('[data-agent-advance]')).toHaveAttribute('aria-disabled', 'true');

  expect(pageErrors).toEqual([]);
});

test('a reflection is kept as text and never rendered as markup', async ({ page }) => {
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(error.message));
  const hostile =
    '<img src=x onerror="window.__anchorPwned = true"> & </textarea><script>window.__anchorPwned = true;</script>';
  const script = buildAgentScript(getDataset('flutter'));

  await startAgentSession(page, 'flutter');
  await page.locator('[data-agent-reflection]').fill(hostile);

  // Round-tripped through storage and back into the textarea without becoming markup.
  await page.reload();
  await expect(page.locator('[data-agent-reflection]')).toHaveValue(hostile);
  await expect(page.locator('#app-content img, #app-content iframe, #app-content script')).toHaveCount(0);
  expect(await page.evaluate(() => window.__anchorPwned)).toBeUndefined();

  for (let index = 0; index < script.length; index += 1) {
    await page.locator('[data-agent-reflection]').fill(hostile);
    await page.locator('[data-agent-advance]').click();
  }

  await expect(page.locator('[data-agent-complete]')).toBeVisible();
  await expect(page.locator('.agent-recap-mine').first()).toContainText(hostile);
  await expect(page.locator('#app-content img, #app-content iframe, #app-content script')).toHaveCount(0);
  expect(await page.evaluate(() => window.__anchorPwned)).toBeUndefined();
  expect(pageErrors).toEqual([]);
});

test('guided agent copy stays bilingual and keeps the session across a locale switch', async ({ page }) => {
  const dataset = getDataset('flutter');

  await page.goto('/app/#/agent');
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.agent.modeTitle.en);
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.agent.nativeQa.en);
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.agent.nativeSocratic.en);

  await page.locator('[data-locale="zh"]').click();
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.agent.modeTitle.zh);
  await expect(page.locator('[data-agent-start-note]')).toHaveText(SHELL_TEXT.agent.startBlocked.zh);
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.agent.nativeQa.zh);
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.agent.nativeSocratic.zh);

  await page.locator('[data-agent-dataset="flutter"]').check();
  await page.locator('[data-agent-start-session]').click();
  await expect(page.locator('[data-agent-turn]')).toBeVisible();
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.agent.reflectionLabel.zh);
  await expect(page.locator('[data-agent-advance]')).toContainText(SHELL_TEXT.agent.nextAction.zh);
  await expect(page.locator('[data-agent-prompt]')).toHaveText(dataset.questions[0].prompt.zh);

  await page.locator('[data-agent-hint]').click();
  await expect(page.locator('[data-agent-hint-list] li').first()).toHaveText(dataset.questions[0].tutorHints[0].zh);
  await expect(page.locator('[data-agent-disclosure]')).toContainText('实时');

  // The stored session belongs to the learner, not to the locale.
  await page.locator('[data-agent-reflection]').fill('用我自己的话说一遍。');
  await page.locator('[data-locale="en"]').click();
  await expect(page.locator('[data-agent-reflection]')).toHaveValue('用我自己的话说一遍。');
  await expect(page.locator('[data-agent-prompt]')).toHaveText(dataset.questions[0].prompt.en);
  await expect(page.locator('[data-agent-advance]')).toContainText(SHELL_TEXT.agent.nextAction.en);
  await expect(page.locator('[data-agent-hint-list] li').first()).toHaveText(dataset.questions[0].tutorHints[0].en);
});

test('the guided agent session fits a 390px viewport without horizontal overflow', async ({ page }) => {
  const overflow = () =>
    page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  const script = buildAgentScript(getDataset('flutter'));

  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/app/#/agent');
  await expect(page.locator('[data-agent-start]')).toBeVisible();
  expect(await overflow(), 'agent start panel overflows at 390px').toBeLessThanOrEqual(0);

  await page.locator('[data-agent-dataset="flutter"]').check();
  await page.locator('[data-agent-start-session]').click();
  await expect(page.locator('[data-agent-turn]')).toBeVisible();
  expect(await overflow(), 'agent turn overflows at 390px').toBeLessThanOrEqual(0);

  await page.locator('[data-agent-hint]').click();
  await page.locator('[data-agent-hint]').click();
  await expect(page.locator('[data-agent-hint-list] li')).toHaveCount(2);
  expect(await overflow(), 'revealed hints overflow at 390px').toBeLessThanOrEqual(0);

  await page.locator('[data-agent-clear]').click();
  await expect(page.locator('.agent-confirm')).toBeVisible();
  expect(await overflow(), 'agent reset confirmation overflows at 390px').toBeLessThanOrEqual(0);
  await page.locator('[data-agent-clear-cancel]').click();

  // An unbroken reflection has to wrap instead of widening the page.
  for (let index = 0; index < script.length; index += 1) {
    await page.locator('[data-agent-reflection]').fill('unbrokenreflectionwithoutspaces'.repeat(10));
    expect(await overflow(), 'a long reflection overflows at 390px').toBeLessThanOrEqual(0);
    await page.locator('[data-agent-advance]').click();
  }
  await expect(page.locator('[data-agent-complete]')).toBeVisible();
  expect(await overflow(), 'agent recap overflows at 390px').toBeLessThanOrEqual(0);

  // The fixed mobile tab bar is still the primary navigation here.
  await expect(page.locator('#app-tabbar')).toBeVisible();
  await expect(page.locator('#app-tabbar [data-tab-route="agent"]')).toHaveAttribute('aria-current', 'page');
});

test('landing page keeps navigation and bilingual content usable on mobile', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/');
  await page.locator('.menu-button').click();
  await expect(page.locator('.menu-button')).toHaveAttribute('aria-expanded', 'true');
  await expect(page.locator('.primary-nav')).toHaveClass(/is-open/);
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  expect(overflow).toBeLessThanOrEqual(0);
  const screenshot = await page.screenshot({ fullPage: true, path: 'test-results/evidence/anchor-landing-mobile.png' });
  expect(screenshot.byteLength).toBeGreaterThan(20_000);
});

test.describe('browser locale default', () => {
  test.use({ locale: 'zh-CN' });

  test('uses Chinese initially and persists an English metadata choice', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh-CN');
    await expect(page).toHaveTitle(/来源可溯源/);
    await expect(page.locator('meta[name="description"]')).toHaveAttribute('content', /来源/);
    await page.locator('[data-locale="en"]').click();
    await expect(page.locator('html')).toHaveAttribute('lang', 'en');
    await expect(page).toHaveTitle(/Traceable/);
    await page.reload();
    await expect(page.locator('html')).toHaveAttribute('lang', 'en');
  });
});

test('captures the landing page with real demo media', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto('/');
  await expect(page.locator('.hero-media')).toHaveCSS('background-image', /anchor-demo-preview\.webp/);
  await expect(page.locator('#native-app')).toBeVisible();
  const nativeSectionTop = await page.locator('#native-app').evaluate((element) => element.getBoundingClientRect().top);
  expect(nativeSectionTop).toBeLessThan(900);
  const screenshot = await page.screenshot({ fullPage: true, path: 'test-results/evidence/anchor-landing-desktop.png' });
  expect(screenshot.byteLength).toBeGreaterThan(50_000);
});

for (const viewport of [
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'mobile', width: 390, height: 844 },
]) {
  test(`landing keeps the product and next section visible on ${viewport.name}`, async ({ page }) => {
    await page.setViewportSize({ width: viewport.width, height: viewport.height });
    await page.goto('/');
    await expect(page.locator('h1')).toHaveText('Anchor Learning');
    const nativeSectionTop = await page.locator('#native-app').evaluate((element) => element.getBoundingClientRect().top);
    expect(nativeSectionTop).toBeLessThan(viewport.height);
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow).toBeLessThanOrEqual(0);
    const screenshot = await page.screenshot({ fullPage: true, path: `test-results/evidence/anchor-landing-${viewport.name}.png` });
    expect(screenshot.byteLength).toBeGreaterThan(30_000);
  });
}

for (const viewport of [
  { name: 'desktop', width: 1440, height: 900 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'mobile', width: 390, height: 844 },
]) {
  test(`captures nonblank ${viewport.name} product evidence`, async ({ page }) => {
    await page.setViewportSize({ width: viewport.width, height: viewport.height });
    await page.goto('/app/#/decks');
    await page.locator('.dataset-choice[data-select-dataset="git"]').click();
    await page.locator('input[value="snapshot"]').check();
    await page.locator('[data-submit]').click();
    const screenshot = await page.screenshot({ fullPage: true, path: `test-results/evidence/anchor-demo-${viewport.name}.png` });
    expect(screenshot.byteLength).toBeGreaterThan(10_000);
  });
}

test('the profile lists every Anchor key it holds and measures what is stored', async ({ page }) => {
  await page.goto('/app/#/profile');
  const rows = page.locator('[data-storage-row]');
  await expect(rows).toHaveCount(ANCHOR_STORAGE_KEYS.length);
  for (const key of ANCHOR_STORAGE_KEYS) {
    await expect(page.locator(`[data-storage-row="${key}"]`)).toContainText(key);
  }
  await expect(page.locator(`[data-storage-row="${PROGRESS_STORAGE_KEY}"]`)).toContainText(SHELL_TEXT.profile.inventoryEmpty.en);
  await expect(page.locator('[data-backup-export]')).toBeDisabled();
  await expect(page.locator('[data-backup-empty]')).toBeVisible();

  await seedLocalState(page);
  await page.goto('/app/#/profile');
  await expect(page.locator(`[data-storage-row="${PROGRESS_STORAGE_KEY}"]`)).not.toContainText(SHELL_TEXT.profile.inventoryEmpty.en);
  await expect(page.locator(`[data-storage-row="${PROGRESS_STORAGE_KEY}"]`)).toContainText('1 submitted answers');
  await expect(page.locator(`[data-storage-row="${LOCAL_LIBRARY_STORAGE_KEY}"]`)).toContainText('1 sources, 3 sections');
  await expect(page.locator(`[data-storage-row="${AGENT_SESSION_STORAGE_KEY}"]`)).toContainText('1 reflections written');
  await expect(page.locator('.storage-total')).toContainText('stored keys');
  await expect(page.locator('[data-backup-export]')).toBeEnabled();
});

test('a backup exports the three local sections and no credentials', async ({ page }) => {
  const offOriginRequests = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOriginRequests.push(request.url());
  });

  // A key some other feature might have left on this origin. It must not reach the file.
  await page.addInitScript(() => localStorage.setItem('anchor.unrelated.token', 'sk-live-must-not-be-exported'));
  await seedLocalState(page);
  await page.goto('/app/#/profile');

  const { name, text, record } = await exportBackup(page);
  expect(name).toMatch(/^anchor-demo-backup-\d{4}-\d{2}-\d{2}\.json$/);
  expect(record.format).toBe('anchor.demo.backup');
  expect(record.version).toBe(1);
  expect(Object.keys(record).sort()).toEqual(['agent', 'exportedAt', 'format', 'library', 'progress', 'version']);
  expect(record.progress.datasets.flutter.submitted['flutter-state-owner']).toBe(true);
  expect(record.library.sources[0].name).toBe('anchor-notes.md');
  expect(Object.values(record.agent.reflections)).toContain('A reflection worth keeping.');
  expect(text).not.toContain('sk-live-must-not-be-exported');
  expect(text).not.toContain('anchor.unrelated.token');

  await expect(page.locator('#app-announcer')).toContainText(`Backup exported as ${name}`);
  expect(offOriginRequests).toEqual([]);
});

test('a restore is reviewed before it replaces anything, and cancelling changes nothing', async ({ page }) => {
  await seedLocalState(page);
  await page.goto('/app/#/profile');
  const { text: backupText } = await exportBackup(page);

  // Wipe local state, then restore the file that was just saved.
  await page.locator('[data-privacy-reset="all"]').click();
  await page.locator('[data-privacy-confirm-action="all"]').click();
  await expect(page.locator('#app-announcer')).toHaveText(SHELL_TEXT.profile.clearAllDone.en);
  expect(await storedSourceNames(page)).toBeNull();

  await pickBackup(page, { text: backupText, name: 'my-anchor-backup.json' });
  const review = page.locator('[data-restore-review]');
  await expect(review).toBeVisible();
  await expect(review).toBeFocused();
  await expect(review.locator('[data-restore-name]')).toHaveText('my-anchor-backup.json');
  await expect(review).toContainText('Schema version');
  await expect(review).toContainText('v1');
  await expect(review).toContainText('UTC');
  await expect(review.locator('.restore-sections li')).toHaveCount(3);
  await expect(review).toContainText('Quiz progress — 1 submitted answers');
  await expect(review).toContainText('Imported sources — 1 sources, 3 sections');
  await expect(review).toContainText('Guided Agent session — 1 reflections');
  await expect(review).toContainText(SHELL_TEXT.profile.restoreWarning.en);
  await expect(page.locator('#app-announcer')).toContainText('my-anchor-backup.json');

  // Nothing has been written yet.
  expect(await storedSourceNames(page)).toBeNull();
  expect(await page.evaluate((key) => localStorage.getItem(key), PROGRESS_STORAGE_KEY)).toBeNull();

  await page.locator('[data-restore-cancel]').click();
  await expect(review).toHaveCount(0);
  await expect(page.locator('#app-announcer')).toHaveText(SHELL_TEXT.profile.restoreCancelled.en);
  expect(await storedSourceNames(page)).toBeNull();
  expect(await page.evaluate((key) => localStorage.getItem(key), PROGRESS_STORAGE_KEY)).toBeNull();

  // Confirming does replace, and the restored state survives a reload on every surface.
  await pickBackup(page, { text: backupText, name: 'my-anchor-backup.json' });
  await page.locator('[data-restore-confirm]').click();
  await expect(page.locator('#app-announcer')).toHaveText('Local data replaced from my-anchor-backup.json.');
  await expect(page.locator('[data-restore-review]')).toHaveCount(0);
  expect(await storedSourceNames(page)).toEqual(['anchor-notes.md']);

  await page.reload();
  await expect(page.locator(`[data-storage-row="${PROGRESS_STORAGE_KEY}"]`)).toContainText('1 submitted answers');
  await page.goto('/app/#/library');
  await expect(page.locator('#local-library')).toContainText('anchor-notes.md');
  await page.goto('/app/#/agent');
  await expect(page.locator('[data-agent-turn]')).toBeVisible();
  await expect(page.locator('[data-agent-reflection]')).toHaveValue('A reflection worth keeping.');
  await page.goto('/app/#/decks/flutter');
  await expect(page.locator('.feedback-status')).toContainText('Supported by the source');
});

test('a malformed, foreign, oversized, or hostile backup is refused without touching local state', async ({ page }) => {
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(error.message));

  await seedLocalState(page);
  await page.goto('/app/#/profile');
  const before = await storedKeys(page);

  const rejections = [
    { label: 'wrong extension', file: { name: 'backup.md', text: '# not json', mimeType: 'text/markdown' }, message: SHELL_TEXT.profile.restoreErrorType.en },
    { label: 'not json', file: { name: 'backup.json', text: '{ broken' }, message: SHELL_TEXT.profile.restoreErrorJson.en },
    { label: 'foreign json', file: { name: 'backup.json', text: JSON.stringify({ app: 'somethingelse', data: [1, 2] }) }, message: SHELL_TEXT.profile.restoreErrorFormat.en },
    { label: 'json array', file: { name: 'backup.json', text: '[{"format":"anchor.demo.backup","version":1}]' }, message: SHELL_TEXT.profile.restoreErrorFormat.en },
    { label: 'future version', file: { name: 'backup.json', text: JSON.stringify({ format: 'anchor.demo.backup', version: 2, progress: {} }) }, message: SHELL_TEXT.profile.restoreErrorVersion.en },
    { label: 'no sections', file: { name: 'backup.json', text: JSON.stringify({ format: 'anchor.demo.backup', version: 1 }) }, message: SHELL_TEXT.profile.restoreErrorShape.en },
    { label: 'oversized', file: { name: 'backup.json', text: `{"format":"anchor.demo.backup","version":1,"pad":"${'x'.repeat(1_100_000)}"}` }, message: 'has to stay under' },
  ];

  for (const rejection of rejections) {
    await pickBackup(page, rejection.file);
    const error = page.locator('[data-restore-error]');
    await expect(error, rejection.label).toBeVisible();
    await expect(error, rejection.label).toContainText(rejection.message);
    await expect(page.locator('[data-restore-review]'), rejection.label).toHaveCount(0);
    expect(await storedKeys(page), rejection.label).toEqual(before);
  }

  expect(pageErrors).toEqual([]);
});

test('hostile text inside a backup is rendered as text and normalized on restore', async ({ page }) => {
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(error.message));

  await page.goto('/app/#/profile');
  const hostile = JSON.stringify({
    format: 'anchor.demo.backup',
    version: 1,
    exportedAt: Date.now(),
    progress: { version: 1, activeDatasetId: '<script>window.__pwned=1</script>', datasets: { flutter: { currentIndex: 9999, answers: { 'flutter-state-owner': ['state', 'injected'] }, submitted: { 'flutter-state-owner': true } } } },
    library: {
      version: 1,
      sources: [{
        id: 'hostile',
        name: '<img src=x onerror="window.__pwned=1">',
        bytes: 40,
        importedAt: Date.now(),
        sections: [{ id: 's1', kind: 'heading', heading: '<b>bold heading</b>', excerpt: '<script>window.__pwned=1</script>', line: 1 }],
      }],
    },
    agent: { version: 1, datasetId: 'flutter', turnIndex: 0, reflections: {}, hints: {} },
    stowaway: { please: '<script>window.__pwned=1</script>' },
  });

  await pickBackup(page, { text: hostile, name: '<img src=x onerror="window.__pwned=1">.json' });
  const review = page.locator('[data-restore-review]');
  await expect(review).toBeVisible();
  // The markup arrives as visible text, not as nodes.
  await expect(review.locator('[data-restore-name]')).toHaveText('<img src=x onerror="window.__pwned=1">.json');
  expect(await review.locator('img, script, b').count()).toBe(0);
  expect(await page.evaluate(() => window.__pwned)).toBeUndefined();

  await page.locator('[data-restore-confirm]').click();
  await expect(page.locator('#app-announcer')).toContainText('Local data replaced');
  expect(await page.evaluate(() => window.__pwned)).toBeUndefined();

  await page.goto('/app/#/library');
  await expect(page.locator('#local-library')).toContainText('<img src=x onerror="window.__pwned=1">');
  expect(await page.locator('#local-library img, #local-library script').count()).toBe(0);
  await page.locator('[data-toggle-source="hostile"]').click();
  await expect(page.locator('.local-section-heading').first()).toHaveText('<b>bold heading</b>');
  expect(await page.locator('.local-section b, .local-section script').count()).toBe(0);
  expect(await page.evaluate(() => window.__pwned)).toBeUndefined();

  // Unknown sections are never restorable, and the clamped index landed inside the dataset.
  const restored = await page.evaluate((key) => JSON.parse(localStorage.getItem(key)), PROGRESS_STORAGE_KEY);
  expect(restored.stowaway).toBeUndefined();
  expect(restored.activeDatasetId).toBeNull();
  expect(restored.datasets.flutter.currentIndex).toBe(3);
  expect(restored.datasets.flutter.answers['flutter-state-owner']).toEqual(['state']);
  expect(pageErrors).toEqual([]);
});

test('each delete control is confirmed on its own and never takes the other keys with it', async ({ page }) => {
  const scopes = [
    { action: 'progress', removes: PROGRESS_STORAGE_KEY, keeps: [LOCAL_LIBRARY_STORAGE_KEY, AGENT_SESSION_STORAGE_KEY], done: SHELL_TEXT.profile.resetDone.en },
    { action: 'agent', removes: AGENT_SESSION_STORAGE_KEY, keeps: [PROGRESS_STORAGE_KEY, LOCAL_LIBRARY_STORAGE_KEY], done: SHELL_TEXT.profile.agentResetDone.en },
    { action: 'library', removes: LOCAL_LIBRARY_STORAGE_KEY, keeps: [PROGRESS_STORAGE_KEY, AGENT_SESSION_STORAGE_KEY], done: SHELL_TEXT.profile.libraryResetDone.en },
  ];

  for (const scope of scopes) {
    // Each pass starts from a clean browser so one scope's deletion cannot mask the next one's seed.
    // The reload matters: clearing storage alone would leave the previous session live in memory.
    await page.goto('/app/#/profile');
    await page.evaluate((keys) => keys.forEach((key) => localStorage.removeItem(key)), ANCHOR_STORAGE_KEYS);
    await page.reload();
    await seedLocalState(page);
    await page.goto('/app/#/profile');
    const before = await storedKeys(page);
    for (const key of [scope.removes, ...scope.keeps]) expect(before[key], `${scope.action} seed ${key}`).not.toBeNull();

    // Opening the confirmation deletes nothing, and backing out leaves everything in place.
    await page.locator(`[data-privacy-reset="${scope.action}"]`).click();
    const confirm = page.locator(`[data-privacy-confirm="${scope.action}"]`);
    await expect(confirm).toBeVisible();
    await expect(confirm).toBeFocused();
    expect(await storedKeys(page), `${scope.action} pending`).toEqual(before);

    await page.locator('[data-privacy-cancel]').click();
    await expect(confirm).toHaveCount(0);
    await expect(page.locator(`[data-privacy-reset="${scope.action}"]`)).toBeFocused();
    expect(await storedKeys(page), `${scope.action} cancelled`).toEqual(before);

    await page.locator(`[data-privacy-reset="${scope.action}"]`).click();
    await page.locator(`[data-privacy-confirm-action="${scope.action}"]`).click();
    await expect(page.locator('#app-announcer')).toHaveText(scope.done);

    const after = await storedKeys(page);
    expect(after[scope.removes], `${scope.action} removed`).toBeNull();
    for (const key of scope.keeps) expect(after[key], `${scope.action} kept ${key}`).toEqual(before[key]);
  }
});

test('clear-all removes every Anchor key and leaves other keys on this origin alone', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('unrelated.site.setting', 'keep me');
    localStorage.setItem('anchor-landing-note', 'keep me too');
  });
  await seedLocalState(page);
  await page.goto('/app/#/profile');
  await page.locator('[data-set-theme="dark"]').click();
  // The locale key is only written once a learner picks a language, so click through to create it.
  await page.locator('[data-locale="zh"]').click();
  await page.locator('[data-locale="en"]').click();

  const before = await storedKeys(page);
  for (const key of ANCHOR_STORAGE_KEYS) expect(before[key], key).not.toBeNull();

  await page.locator('[data-privacy-reset="all"]').click();
  await expect(page.locator('[data-privacy-confirm="all"]')).toContainText('cannot be undone');
  expect(await storedKeys(page)).toEqual(before);

  await page.locator('[data-privacy-confirm-action="all"]').click();
  await expect(page.locator('#app-announcer')).toHaveText(SHELL_TEXT.profile.clearAllDone.en);

  const after = await storedKeys(page);
  for (const key of ANCHOR_STORAGE_KEYS) expect(after[key], key).toBeNull();
  expect(await page.evaluate(() => localStorage.getItem('unrelated.site.setting'))).toBe('keep me');
  expect(await page.evaluate(() => localStorage.getItem('anchor-landing-note'))).toBe('keep me too');

  // Every surface comes back empty rather than broken.
  await expect(page.locator('[data-backup-export]')).toBeDisabled();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  await page.goto('/app/#/library');
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.localLibrary.empty.en);
  await page.goto('/app/#/agent');
  await expect(page.locator('[data-agent-start-session]')).toBeVisible();
  await page.goto('/app/#/decks');
  await expect(page.locator('.welcome-view')).toBeVisible();
});

test('the theme choice is announced, persists, and repaints the shell', async ({ page }) => {
  await page.goto('/app/#/profile');
  const html = page.locator('html');
  const light = page.locator('[data-set-theme="light"]');
  const dark = page.locator('[data-set-theme="dark"]');

  await expect(page.locator('.theme-switch')).toHaveAttribute('aria-label', SHELL_TEXT.profile.themeLabel.en);
  await expect(html).toHaveAttribute('data-theme', 'light');
  await expect(light).toHaveAttribute('aria-pressed', 'true');
  await expect(dark).toHaveAttribute('aria-pressed', 'false');

  const lightPaper = await page.evaluate(() => getComputedStyle(document.body).backgroundColor);

  await dark.click();
  await expect(html).toHaveAttribute('data-theme', 'dark');
  await expect(dark).toHaveAttribute('aria-pressed', 'true');
  await expect(light).toHaveAttribute('aria-pressed', 'false');
  await expect(dark).toBeFocused();
  await expect(page.locator('#app-announcer')).toHaveText(SHELL_TEXT.profile.themeAnnounceDark.en);

  const darkPaper = await page.evaluate(() => getComputedStyle(document.body).backgroundColor);
  expect(darkPaper).not.toBe(lightPaper);
  expect(await page.evaluate((key) => JSON.parse(localStorage.getItem(key)), THEME_STORAGE_KEY)).toEqual({ version: 1, theme: 'dark' });

  // Survives a reload, and applies to every surface rather than only the profile.
  await page.reload();
  await expect(html).toHaveAttribute('data-theme', 'dark');
  expect(await page.evaluate(() => getComputedStyle(document.body).backgroundColor)).toBe(darkPaper);
  await page.goto('/app/#/decks/flutter');
  await expect(html).toHaveAttribute('data-theme', 'dark');
  await page.goto('/');
  // The marketing page does not read the app's theme key; the demo owns that surface only.
  await page.goto('/app/#/profile');
  await expect(html).toHaveAttribute('data-theme', 'dark');

  await page.locator('[data-set-theme="light"]').click();
  await expect(html).toHaveAttribute('data-theme', 'light');
  await expect(page.locator('#app-announcer')).toHaveText(SHELL_TEXT.profile.themeAnnounceLight.en);
  expect(await page.evaluate((key) => JSON.parse(localStorage.getItem(key)), THEME_STORAGE_KEY)).toEqual({ version: 1, theme: 'light' });
  await page.reload();
  await expect(html).toHaveAttribute('data-theme', 'light');
});

test('the system hint only decides the first visit, and a stale theme key is ignored', async ({ browser }) => {
  const context = await browser.newContext({ colorScheme: 'dark' });
  const page = await context.newPage();
  await page.goto('/app/#/profile');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await expect(page.locator('[data-set-theme="dark"]')).toHaveAttribute('aria-pressed', 'true');
  // Not written yet: the hint is followed without claiming to be the learner's choice.
  expect(await page.evaluate((key) => localStorage.getItem(key), THEME_STORAGE_KEY)).toBeNull();

  // A deliberate light choice outranks the dark system hint from then on.
  await page.locator('[data-set-theme="light"]').click();
  await page.reload();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');

  for (const stale of ['{broken', '"sepia"', JSON.stringify({ version: 99, theme: 'dark' }), JSON.stringify({ theme: 'dark' }), 'null']) {
    await page.evaluate(([key, value]) => localStorage.setItem(key, value), [THEME_STORAGE_KEY, stale]);
    await page.reload();
    // Falls back to the system hint rather than applying an unknown palette or throwing.
    await expect(page.locator('html'), stale).toHaveAttribute('data-theme', 'dark');
    await expect(page.locator('#app-content h1')).toBeVisible();
  }

  // A hand-written bare string is still honoured.
  await page.evaluate(([key]) => localStorage.setItem(key, '"light"'), [THEME_STORAGE_KEY]);
  await page.reload();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  await context.close();
});

test('the profile reads in both languages and fits a 390px screen in either theme', async ({ page }) => {
  const offOriginRequests = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOriginRequests.push(request.url());
  });
  const overflow = () => page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);

  await page.setViewportSize({ width: 390, height: 844 });
  await seedLocalState(page);
  await page.goto('/app/#/profile');

  for (const theme of ['light', 'dark']) {
    await page.locator(`[data-set-theme="${theme}"]`).click();
    await expect(page.locator('html')).toHaveAttribute('data-theme', theme);
    expect(await overflow(), `${theme} profile`).toBeLessThanOrEqual(0);

    // Open confirmations and the restore review add the widest content on this surface.
    await page.locator('[data-privacy-reset="all"]').click();
    await expect(page.locator('[data-privacy-confirm="all"]')).toBeVisible();
    expect(await overflow(), `${theme} confirm`).toBeLessThanOrEqual(0);
    await page.locator('[data-privacy-cancel]').click();
  }

  const { text: backupText } = await exportBackup(page);
  await pickBackup(page, { text: backupText, name: 'a-fairly-long-backup-file-name-from-another-device.json' });
  await expect(page.locator('[data-restore-review]')).toBeVisible();
  expect(await overflow(), 'restore review at 390px').toBeLessThanOrEqual(0);

  // Bilingual copy, still without overflow.
  await page.locator('[data-locale="zh"]').click();
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.profile.inventoryTitle.zh);
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.profile.backupTitle.zh);
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.profile.restoreTitle.zh);
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.profile.controlsTitle.zh);
  await expect(page.locator('#app-content')).toContainText(SHELL_TEXT.profile.themeBody.zh);
  await expect(page.locator('[data-set-theme="dark"]')).toContainText(SHELL_TEXT.profile.themeDark.zh);
  await expect(page.locator('[data-privacy-reset="library"]')).toHaveText(SHELL_TEXT.profile.libraryResetAction.zh);
  await expect(page.locator('.theme-switch')).toHaveAttribute('aria-label', SHELL_TEXT.profile.themeLabel.zh);
  expect(await overflow(), 'zh profile at 390px').toBeLessThanOrEqual(0);

  await page.locator('[data-privacy-reset="progress"]').click();
  await expect(page.locator('[data-privacy-confirm="progress"]')).toContainText(SHELL_TEXT.profile.resetConfirm.zh);
  expect(await overflow(), 'zh confirm at 390px').toBeLessThanOrEqual(0);
  await page.locator('[data-privacy-confirm-action="progress"]').click();
  await expect(page.locator('#app-announcer')).toHaveText(SHELL_TEXT.profile.resetDone.zh);

  // Desktop keeps the same surface intact.
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.locator('[data-locale="en"]').click();
  await expect(page.locator('.privacy-actions .privacy-row')).toHaveCount(4);
  await expect(page.locator('[data-backup-export]')).toBeEnabled();
  expect(await overflow(), 'desktop profile').toBeLessThanOrEqual(0);
  expect(offOriginRequests).toEqual([]);
});

test('a restore left half-finished never leaks into another surface', async ({ page }) => {
  await seedLocalState(page);
  await page.goto('/app/#/profile');
  const { text: backupText } = await exportBackup(page);

  await pickBackup(page, { text: backupText });
  await expect(page.locator('[data-restore-review]')).toBeVisible();
  await page.locator('[data-privacy-reset="library"]').click();
  await expect(page.locator('[data-privacy-confirm="library"]')).toBeVisible();

  // Leaving the surface abandons both the draft and the pending confirmation.
  await page.goto('/app/#/library');
  await page.goto('/app/#/profile');
  await expect(page.locator('[data-restore-review]')).toHaveCount(0);
  await expect(page.locator('[data-privacy-confirm="library"]')).toHaveCount(0);
  expect(await storedSourceNames(page)).toEqual(['anchor-notes.md']);

  // A rejected pick clears an earlier error once a good file follows it.
  await pickBackup(page, { name: 'wrong.txt', text: 'nope', mimeType: 'text/plain' });
  await expect(page.locator('[data-restore-error]')).toBeVisible();
  await pickBackup(page, { text: backupText });
  await expect(page.locator('[data-restore-error]')).toHaveCount(0);
  await expect(page.locator('[data-restore-review]')).toBeVisible();
});
