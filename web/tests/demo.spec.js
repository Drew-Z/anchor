import { expect, test } from '@playwright/test';

const expectedOrigin = new URL(process.env.ANCHOR_BASE_URL ?? 'http://127.0.0.1:4173').origin;

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
  await expect(page.locator('h1')).toContainText('选择一个数据集');
  await expect(page.locator('html')).toHaveAttribute('lang', 'zh-CN');
});

test('a learner can answer, inspect evidence, use tutor hints, and continue', async ({ page }) => {
  const offOriginRequests = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOriginRequests.push(request.url());
  });

  await page.goto('/app/');
  await page.locator('[data-select-dataset="flutter"]').first().click();
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

test('mobile dataset navigation works without horizontal overflow', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/app/');
  await page.locator('#dataset-menu-button').click();
  await expect(page.locator('#dataset-sidebar')).toHaveClass(/is-open/);
  await page.locator('#dataset-list [data-select-dataset="javascript"]').click();
  await expect(page.locator('.question-title')).toContainText('queued callback');
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  expect(overflow).toBeLessThanOrEqual(0);
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

test('captures the landing page with real demo media', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto('/');
  await expect(page.locator('.hero-media')).toHaveCSS('background-image', /anchor-demo-preview\.webp/);
  const screenshot = await page.screenshot({ fullPage: true, path: 'test-results/evidence/anchor-landing-desktop.png' });
  expect(screenshot.byteLength).toBeGreaterThan(50_000);
});

for (const viewport of [
  { name: 'desktop', width: 1440, height: 900 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'mobile', width: 390, height: 844 },
]) {
  test(`captures nonblank ${viewport.name} product evidence`, async ({ page }) => {
    await page.setViewportSize({ width: viewport.width, height: viewport.height });
    await page.goto('/app/');
    await page.locator('.dataset-choice[data-select-dataset="git"]').click();
    await page.locator('input[value="snapshot"]').check();
    await page.locator('[data-submit]').click();
    const screenshot = await page.screenshot({ fullPage: true, path: `test-results/evidence/anchor-demo-${viewport.name}.png` });
    expect(screenshot.byteLength).toBeGreaterThan(10_000);
  });
}
