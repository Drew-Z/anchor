import { expect, test } from '@playwright/test';
import { DATASETS, SHELL_TEXT, countSources } from '../landing/app/scripts/data.js';
import { PROGRESS_STORAGE_KEY } from '../landing/app/scripts/app.js';

const expectedOrigin = new URL(process.env.ANCHOR_BASE_URL ?? 'http://127.0.0.1:4173').origin;

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
  await expect(page.locator('.shell-card [data-reset-progress]')).toBeVisible();
  await page.locator('.shell-card [data-reset-progress]').click();
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
  await expect(page.locator('#app-content')).toContainText('no file picker');
  await expect(page.locator('#app-content a[href="../#native-app"]')).toBeVisible();
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
