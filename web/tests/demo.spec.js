import { expect, test } from '@playwright/test';
import {
  AGENT_SESSION_LIMITS,
  AGENT_SESSION_VERSION,
  DATA_VERSION,
  DATASETS,
  LOCAL_IMPORT_LIMITS,
  SHELL_TEXT,
  buildAgentScript,
  countSources,
  formatCount,
  getDataset,
  sourceRevisitSearch,
} from '../landing/app/scripts/data.js';
import {
  AGENT_SESSION_STORAGE_KEY,
  ANCHOR_STORAGE_KEYS,
  LOCAL_LIBRARY_STORAGE_KEY,
  PROGRESS_STORAGE_KEY,
  THEME_STORAGE_KEY,
  routeHash,
} from '../landing/app/scripts/app.js';
// The landing page and the demo share one locale key, so the menu tests can prove they left it alone.
import { STORAGE_KEY as LOCALE_STORAGE_KEY } from '../landing/scripts/i18n.js';

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

test('the 404 page follows the stored locale and returns home without leaving origin', async ({ page }) => {
  const offOriginRequests = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOriginRequests.push(request.url());
  });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/');

  await page.evaluate((key) => localStorage.setItem(key, 'zh'), LOCALE_STORAGE_KEY);
  const chineseResponse = await page.goto('/missing/nested/page');
  expect(chineseResponse.status()).toBe(404);
  await expect(page.locator('html')).toHaveAttribute('lang', 'zh-CN');
  await expect(page).toHaveTitle('页面不存在 - Anchor Learning 锚学');
  await expect(page.locator('.not-found-page p')).toHaveText('你访问的页面不存在。');
  await expect(page.locator('.not-found-page .button')).toHaveText('返回 Anchor Learning 锚学');
  await expect(page.locator('.not-found-page')).not.toContainText('The page you requested does not exist.');
  expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(390);

  await page.locator('.not-found-page .button').click();
  await expect(page).toHaveURL(`${expectedOrigin}/`);
  await expect(page.locator('.hero-lead')).toContainText('技术文档和代码');

  await page.evaluate((key) => localStorage.setItem(key, 'en'), LOCALE_STORAGE_KEY);
  const englishResponse = await page.goto('/another-missing-page');
  expect(englishResponse.status()).toBe(404);
  await expect(page.locator('html')).toHaveAttribute('lang', 'en');
  await expect(page).toHaveTitle('Page not found - Anchor Learning');
  await expect(page.locator('.not-found-page p')).toHaveText('The page you requested does not exist.');
  await expect(page.locator('.not-found-page .button')).toHaveText('Go to Anchor Learning');
  await expect(page.locator('.not-found-page')).not.toContainText('你访问的页面不存在。');
  expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(390);
  expect(offOriginRequests, `unexpected off-origin requests: ${offOriginRequests.join(', ')}`).toEqual([]);
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

const reviewRows = (page) => page.locator('[data-completion-row]');
const reviewText = SHELL_TEXT.completion;

/**
 * Writes one completed deck straight to storage so a test can pick which rows are right, wrong, and
 * unanswered. Answering through the UI can only ever produce a fully submitted deck, and the review has to
 * hold up on the records a restored backup or an older key can actually leave behind.
 */
async function seedCompletedDataset(page, datasetId, plan) {
  const dataset = getDataset(datasetId);
  const answers = {};
  const submitted = {};
  dataset.questions.forEach((question, index) => {
    const outcome = plan[index] ?? 'correct';
    if (outcome === 'unanswered') return;
    const wrong = question.options.filter((option) => !question.correct.includes(option.id)).map((option) => option.id);
    answers[question.id] = outcome === 'correct' ? [...question.correct] : [wrong[0]];
    submitted[question.id] = true;
  });

  // Written once and picked up by a reload, the way the app reads any stored record. An init script would
  // re-seed on every load and quietly undo whatever the review's own controls saved.
  await page.goto(`/app/#/decks/${datasetId}`);
  await page.evaluate(([key, record]) => localStorage.setItem(key, JSON.stringify(record)), [PROGRESS_STORAGE_KEY, {
    version: DATA_VERSION,
    activeDatasetId: datasetId,
    datasets: {
      [datasetId]: { currentIndex: dataset.questions.length - 1, completed: true, answers, submitted },
    },
    daily: { date: '', answered: 0 },
  }]);
  await page.reload();
  await expect(page.locator('.completion-view')).toBeVisible();
  return dataset;
}

test('the completion review shows every answer against the source that settles it', async ({ page }) => {
  const offOrigin = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOrigin.push(request.url());
  });

  // Two supported, one not, one never submitted: every state the review can report, on one screen.
  const dataset = await seedCompletedDataset(page, 'flutter', ['correct', 'incorrect', 'correct', 'unanswered']);
  const [first, second, , fourth] = dataset.questions;

  // The score keeps counting supported answers only, and the summary says the same thing in words.
  await expect(page.locator('.completion-score strong')).toHaveText('2');
  await expect(page.locator('[data-completion-review]')).toHaveAttribute('data-completion-review', 'flutter');
  await expect(page.locator('[data-completion-summary]')).toHaveText('2 of 4 answers are supported by their source.');
  await expect(page.locator('[data-completion-gap]')).toHaveText('Marked complete with unanswered questions: 1. Reset progress to answer them.');
  await expect(reviewRows(page)).toHaveCount(dataset.questions.length);

  // Rows are in dataset order, so the review reads the way the deck was taken.
  expect(await reviewRows(page).evaluateAll((nodes) => nodes.map((node) => node.dataset.completionRow)))
    .toEqual(dataset.questions.map((question) => question.id));
  expect(await reviewRows(page).evaluateAll((nodes) => nodes.map((node) => node.dataset.reviewStatus)))
    .toEqual(['correct', 'incorrect', 'correct', 'unanswered']);

  const supported = reviewRows(page).nth(0);
  await expect(supported.locator('.question-index')).toHaveText('Question 1 of 4');
  await expect(supported.locator('.completion-status-label')).toHaveText(reviewText.statusCorrect.en);
  await expect(supported.locator('.completion-row-prompt')).toHaveText(first.prompt.en);
  await expect(supported.locator('.completion-answer-mine')).toContainText(reviewText.yourAnswer.en);
  await expect(supported.locator('.completion-answer-mine .completion-answer-value'))
    .toHaveText(first.options.find((option) => option.id === first.correct[0]).label.en);
  await expect(supported.locator('.completion-answer-expected .completion-answer-value'))
    .toHaveText(first.options.find((option) => option.id === first.correct[0]).label.en);

  // A wrong row prints both answers, so the difference is on screen rather than left to memory.
  const missed = reviewRows(page).nth(1);
  await expect(missed.locator('.completion-status-label')).toHaveText(reviewText.statusIncorrect.en);
  const wrongOption = second.options.find((option) => !second.correct.includes(option.id));
  await expect(missed.locator('.completion-answer-mine .completion-answer-value')).toHaveText(wrongOption.label.en);
  await expect(missed.locator('.completion-answer-expected .completion-answer-value'))
    .toContainText(second.options.find((option) => option.id === second.correct[0]).label.en);

  // Nothing stored says so plainly instead of being reported as a wrong answer.
  const blank = reviewRows(page).nth(3);
  await expect(blank.locator('.completion-status-label')).toHaveText(reviewText.statusUnanswered.en);
  await expect(blank.locator('.completion-answer-mine .completion-answer-value')).toHaveText(reviewText.noAnswer.en);
  await expect(blank.locator('.completion-answer-expected .completion-answer-value'))
    .toContainText(fourth.options.find((option) => option.id === fourth.correct[0]).label.en);

  // Every row carries the citation its question ships with, quoted, not summarized.
  for (const [index, question] of dataset.questions.entries()) {
    const row = reviewRows(page).nth(index);
    await expect(row.locator('.citation-locator')).toContainText(question.citations[0].locator);
    await expect(row.locator('.citation-item blockquote')).toHaveText(question.citations[0].excerpt.en);
    await expect(row.locator('[data-completion-source]')).toHaveAttribute('data-completion-source', question.citations[0].locator);
  }

  await expect(page.locator('.completion-review .tutor-disclosure')).toContainText('no model reviewed your work');
  expect(offOrigin).toEqual([]);
});

test('a review row opens its source in the library and its question in the deck', async ({ page }) => {
  const offOrigin = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOrigin.push(request.url());
  });

  const dataset = await seedCompletedDataset(page, 'git', ['correct', 'incorrect', 'unanswered', 'correct']);
  const missed = reviewRows(page).nth(1);
  const citation = dataset.questions[1].citations[0];

  // Following the source link is a route change, not a fetch: the Library resolves the same locator locally.
  const link = missed.locator('[data-completion-source]');
  await expect(link).toHaveText(reviewText.sourceAction.en);
  const expectedHash = routeHash({ view: 'library', search: sourceRevisitSearch(citation.locator, dataset.id) });
  await expect(link).toHaveAttribute('href', expectedHash);
  await link.click();
  await expect(page).toHaveURL(new RegExp(`${expectedHash.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`));
  await expect(page.locator('[data-library-search]')).toBeVisible();

  // The link lands on the passage the answer cited, filtered to the deck it came from, with the query
  // carried into the field so the learner can widen the search from there.
  await expect(searchField(page)).toHaveValue(citation.locator);
  await expect(searchResults(page)).toHaveCount(1);
  await expect(searchResults(page).first().locator('.library-result-locator')).toHaveText(citation.locator);
  await expect(searchResults(page).first().locator('.library-result-scope-name')).toHaveText(dataset.title.en);
  await expect(searchResults(page).first()).toHaveAttribute('data-result-kind', 'bundled');

  // Opening a row moves the deck to that question with the stored answer intact, beside the feedback and
  // citation that explain it. A submitted answer is final here, so the options stay locked.
  await page.goBack();
  await expect(page.locator('.completion-view')).toBeVisible();
  const wrongOption = dataset.questions[1].options.find((option) => !dataset.questions[1].correct.includes(option.id));
  await reviewRows(page).nth(1).locator('[data-completion-revisit]').click();
  await expect(page.locator('.quiz-view')).toBeVisible();
  await expect(page.locator('.quiz-view .question-index')).toContainText('Question 2 of 4');
  await expect(page.locator('#app-announcer'))
    .toHaveText('Opened question 2 of 4. Your stored answer and its source are shown.');
  await expect(page.locator(`input[value="${wrongOption.id}"]`)).toBeChecked();
  await expect(page.locator(`input[value="${wrongOption.id}"]`)).toBeDisabled();
  await expect(page.locator('.feedback-status')).toContainText('Review the source and try the next question');
  await expect(page.locator('.citation-locator')).toContainText(citation.locator);

  // The opened position is real state, so a reload stays on that question instead of bouncing to the review.
  await page.reload();
  await expect(page.locator('.quiz-view .question-index')).toContainText('Question 2 of 4');

  // The gap is what a learner can still act on. Walking forward from the opened question reaches the one
  // that was never answered, and answering it closes the gap the review reported.
  await page.locator('[data-next]').click();
  await expect(page.locator('.quiz-view .question-index')).toContainText('Question 3 of 4');
  await expect(page.locator('.feedback-status')).toHaveCount(0);
  for (const optionId of dataset.questions[2].correct) await page.locator(`input[value="${optionId}"]`).check();
  await page.locator('[data-submit]').click();
  await expect(page.locator('.feedback-status')).toContainText('Supported by the source');
  await page.locator('[data-next]').click();

  await expect(page.locator('.quiz-view .question-index')).toContainText('Question 4 of 4');
  await page.locator('[data-next]').click();

  await expect(page.locator('.completion-view')).toBeVisible();
  await expect(page.locator('.completion-score strong')).toHaveText('3');
  await expect(page.locator('[data-completion-summary]')).toHaveText('3 of 4 answers are supported by their source.');
  await expect(page.locator('[data-completion-gap]')).toHaveCount(0);
  expect(await reviewRows(page).evaluateAll((nodes) => nodes.map((node) => node.dataset.reviewStatus)))
    .toEqual(['correct', 'incorrect', 'correct', 'correct']);

  // The screen's original exits still work now that a review sits below them.
  await page.locator('[data-review]').click();
  await expect(page.locator('.quiz-view')).toBeVisible();
  await expect(page.locator('.quiz-view .question-index')).toContainText('Question 1 of 4');

  await seedCompletedDataset(page, 'git', ['correct', 'correct', 'correct', 'correct']);
  await page.locator('[data-choose-another]').click();
  await expect(page).toHaveURL(/#\/decks$/);
  await expect(page.locator('.dataset-grid')).toBeVisible();
  expect(offOrigin).toEqual([]);
});

test('the completion review reads in both languages and fits a phone', async ({ page }) => {
  const dataset = await seedCompletedDataset(page, 'javascript', ['correct', 'incorrect', 'unanswered', 'correct']);

  await page.locator('[data-locale="zh"]').click();
  await expect(page.locator('[data-completion-review] h2')).toHaveText(reviewText.reviewTitle.zh);
  await expect(page.locator('[data-completion-summary]')).toHaveText('4 道题中有 2 道得到来源支持。');
  await expect(page.locator('[data-completion-gap]')).toContainText('1 道题未作答');
  await expect(reviewRows(page).nth(0).locator('.completion-status-label')).toHaveText(reviewText.statusCorrect.zh);
  await expect(reviewRows(page).nth(1).locator('.completion-status-label')).toHaveText(reviewText.statusIncorrect.zh);
  await expect(reviewRows(page).nth(2).locator('.completion-status-label')).toHaveText(reviewText.statusUnanswered.zh);
  await expect(reviewRows(page).nth(2).locator('.completion-answer-value.is-empty')).toHaveText(reviewText.noAnswer.zh);
  await expect(reviewRows(page).nth(0).locator('.completion-row-prompt')).toHaveText(dataset.questions[0].prompt.zh);
  await expect(reviewRows(page).nth(0).locator('[data-completion-source]')).toHaveText(reviewText.sourceAction.zh);
  await expect(reviewRows(page).nth(0).locator('[data-completion-revisit]')).toHaveText(reviewText.revisitAction.zh);

  // The locator is the same string in either language, so a row leads to the same passage.
  await expect(reviewRows(page).nth(0).locator('.citation-locator'))
    .toContainText(dataset.questions[0].citations[0].locator);
  await expect(reviewRows(page).nth(0).locator('.citation-item blockquote'))
    .toHaveText(dataset.questions[0].citations[0].excerpt.zh);

  // 中文 announces the opened question too, in the language on screen.
  await reviewRows(page).nth(1).locator('[data-completion-revisit]').click();
  await expect(page.locator('#app-announcer')).toHaveText('已打开第 2 / 4 题，其中显示你保存的答案及其来源。');

  await page.locator('[data-locale="en"]').click();
  await seedCompletedDataset(page, 'javascript', ['correct', 'incorrect', 'unanswered', 'correct']);

  // A review this tall must not centre itself out of reach: the score has to be at the top of the scroll.
  await page.setViewportSize({ width: 1280, height: 800 });
  const scoreTop = await page.locator('.completion-score').evaluate((node) => node.getBoundingClientRect().top);
  expect(scoreTop).toBeGreaterThan(0);

  await page.setViewportSize({ width: 390, height: 844 });
  await expect(reviewRows(page)).toHaveCount(dataset.questions.length);
  await expect(reviewRows(page).nth(0).locator('[data-completion-revisit]')).toBeVisible();
  await expect(reviewRows(page).nth(0).locator('[data-completion-source]')).toBeVisible();
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  expect(overflow).toBeLessThanOrEqual(0);

  // Only the progress key is touched by a review; the source link never writes library state.
  const keys = await storedKeys(page);
  expect(keys[LOCAL_LIBRARY_STORAGE_KEY]).toBeNull();
  expect(keys[AGENT_SESSION_STORAGE_KEY]).toBeNull();
  expect(keys[PROGRESS_STORAGE_KEY]).not.toBeNull();
});

const feedbackText = SHELL_TEXT.feedback;

/** Submits one answer in a deck and waits for the feedback panel it opens. */
async function submitAnswer(page, datasetId, { correct = true } = {}) {
  const dataset = getDataset(datasetId);
  const question = dataset.questions[0];
  const wrong = question.options.filter((option) => !question.correct.includes(option.id));
  const picked = correct ? question.correct : [wrong[0].id];
  await page.goto(`/app/#/decks/${datasetId}`);
  for (const optionId of picked) await page.locator(`input[value="${optionId}"]`).check();
  await page.locator('[data-submit]').click();
  await expect(page.locator('.feedback-panel')).toBeVisible();
  return { dataset, question, picked };
}

test('a submitted answer links its citation into the library and browser back returns to it', async ({ page }) => {
  const offOrigin = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOrigin.push(request.url());
  });

  const { dataset, question, picked } = await submitAnswer(page, 'flutter', { correct: true });
  const citation = question.citations[0];

  // The evidence panel offers the passage itself, not just its address. The link is the same search the
  // review row uses, so both surfaces lead to one record.
  const link = page.locator('.feedback-panel [data-feedback-source]');
  await expect(link).toHaveCount(question.citations.length);
  await expect(link.first()).toHaveText(feedbackText.sourceAction.en);
  await expect(page.locator('.feedback-source-hint')).toHaveText(feedbackText.sourceHint.en);

  // Two links in one panel need two names, so each carries its own locator.
  await expect(link.first()).toHaveAttribute('aria-label', `Read ${citation.locator} in the library`);
  const expectedHash = routeHash({ view: 'library', search: sourceRevisitSearch(citation.locator, dataset.id) });
  await expect(link.first()).toHaveAttribute('href', expectedHash);

  // Following it is a route change, not a fetch: the locator resolves against the bundled index in-browser.
  await link.first().click();
  await expect(page).toHaveURL(new RegExp(`${expectedHash.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`));
  await expect(page.locator('[data-library-search]')).toBeVisible();
  await expect(searchField(page)).toHaveValue(citation.locator);
  await expect(searchResults(page)).toHaveCount(1);
  await expect(searchResults(page).first().locator('.library-result-locator')).toHaveText(citation.locator);
  await expect(searchResults(page).first().locator('.library-result-scope-name')).toHaveText(dataset.title.en);
  await expect(searchResults(page).first()).toHaveAttribute('data-result-kind', 'bundled');

  // Back returns to the same submitted question, not to the top of the deck: the stored answer is still
  // checked and still locked, with the feedback, explanation, and citation that came with it.
  await page.goBack();
  await expect(page.locator('.quiz-view')).toBeVisible();
  await expect(page.locator('.quiz-view .question-index')).toContainText(`Question 1 of ${dataset.questions.length}`);
  await expect(page.locator(`input[value="${picked[0]}"]`)).toBeChecked();
  await expect(page.locator(`input[value="${picked[0]}"]`)).toBeDisabled();
  await expect(page.locator('.feedback-status')).toContainText('Supported by the source');
  await expect(page.locator('.explanation-block p')).toHaveText(question.explanation.en);
  await expect(page.locator('.citation-item blockquote').first()).toHaveText(citation.excerpt.en);
  await expect(page.locator('[data-feedback-source]').first()).toHaveAttribute('href', expectedHash);
  await expect(page.locator('[data-next]')).toBeVisible();

  // The position is stored state, so a reload holds the question rather than restarting the deck.
  await page.reload();
  await expect(page.locator('.quiz-view .question-index')).toContainText(`Question 1 of ${dataset.questions.length}`);
  await expect(page.locator('.feedback-panel')).toBeVisible();
  await expect(page.locator(`input[value="${picked[0]}"]`)).toBeChecked();

  // Reading a source is a read: it records nothing about the library or an agent session.
  const keys = await storedKeys(page);
  expect(keys[LOCAL_LIBRARY_STORAGE_KEY]).toBeNull();
  expect(keys[AGENT_SESSION_STORAGE_KEY]).toBeNull();
  expect(keys[PROGRESS_STORAGE_KEY]).not.toBeNull();
  expect(offOrigin).toEqual([]);
});

test('a wrong answer keeps its source link and its open tutor panel across the trip', async ({ page }) => {
  const offOrigin = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOrigin.push(request.url());
  });

  // A wrong answer is exactly when the passage matters, so the link is offered on the same terms.
  const { dataset, question, picked } = await submitAnswer(page, 'git', { correct: false });
  const citation = question.citations[0];
  await expect(page.locator('.feedback-status.is-incorrect')).toContainText('Review the source');

  // Open the tutor first: its disclosure and hints are part of the state that has to survive the trip.
  const tutorTrigger = page.locator(`[data-toggle-tutor="${question.id}"]`);
  await expect(tutorTrigger).toHaveAttribute('aria-expanded', 'false');
  await tutorTrigger.click();
  await expect(tutorTrigger).toHaveAttribute('aria-expanded', 'true');
  await expect(page.locator('.tutor-panel')).toBeVisible();
  await expect(page.locator('.tutor-disclosure')).toBeVisible();

  const expectedHash = routeHash({ view: 'library', search: sourceRevisitSearch(citation.locator, dataset.id) });
  const link = page.locator('[data-feedback-source]').first();
  await expect(link).toHaveAttribute('href', expectedHash);

  // The link is a real anchor, so it is reachable and followable from the keyboard.
  await link.focus();
  await expect(link).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page.locator('[data-library-search]')).toBeVisible();
  await expect(searchResults(page)).toHaveCount(1);
  await expect(searchResults(page).first().locator('.library-result-locator')).toHaveText(citation.locator);

  // Back restores the whole panel: wrong answer still locked in, feedback still saying so, tutor still open.
  await page.goBack();
  await expect(page.locator('.quiz-view')).toBeVisible();
  await expect(page.locator(`input[value="${picked[0]}"]`)).toBeChecked();
  await expect(page.locator(`input[value="${picked[0]}"]`)).toBeDisabled();
  await expect(page.locator('.feedback-status.is-incorrect')).toContainText('Review the source');
  await expect(page.locator('.explanation-block p')).toHaveText(question.explanation.en);
  await expect(page.locator('.citation-item blockquote').first()).toHaveText(citation.excerpt.en);
  await expect(page.locator('.tutor-panel')).toBeVisible();
  await expect(page.locator(`[data-toggle-tutor="${question.id}"]`)).toHaveAttribute('aria-expanded', 'true');
  await expect(page.locator('.tutor-panel li').first()).toHaveText(question.tutorHints[0].en);

  // The tutor stays a deliberate disclosure: it is in-memory, so a reload closes it again while the
  // submitted answer and its evidence stay exactly where they were.
  await page.reload();
  await expect(page.locator(`input[value="${picked[0]}"]`)).toBeChecked();
  await expect(page.locator('.feedback-panel')).toBeVisible();
  await expect(page.locator('.tutor-panel')).toHaveCount(0);
  await expect(page.locator(`[data-toggle-tutor="${question.id}"]`)).toHaveAttribute('aria-expanded', 'false');
  await expect(page.locator('[data-feedback-source]').first()).toHaveAttribute('href', expectedHash);
  expect(offOrigin).toEqual([]);
});

test('the feedback source link reads in both languages and fits a phone', async ({ page }) => {
  const { dataset, question } = await submitAnswer(page, 'javascript', { correct: true });
  const citation = question.citations[0];

  await page.locator('[data-locale="zh"]').click();
  await expect(page.locator('[data-feedback-source]').first()).toHaveText(feedbackText.sourceAction.zh);
  await expect(page.locator('.feedback-source-hint')).toHaveText(feedbackText.sourceHint.zh);
  await expect(page.locator('[data-feedback-source]').first())
    .toHaveAttribute('aria-label', `在知识库中阅读 ${citation.locator}`);
  await expect(page.locator('.citation-item blockquote').first()).toHaveText(citation.excerpt.zh);

  // The locator is the same string in either language, so 中文 leads to the same passage.
  const expectedHash = routeHash({ view: 'library', search: sourceRevisitSearch(citation.locator, dataset.id) });
  await expect(page.locator('[data-feedback-source]').first()).toHaveAttribute('href', expectedHash);
  await page.locator('[data-feedback-source]').first().click();
  await expect(searchResults(page)).toHaveCount(1);
  await expect(searchResults(page).first().locator('.library-result-scope-name')).toHaveText(dataset.title.zh);
  await page.goBack();
  await expect(page.locator('.feedback-panel')).toBeVisible();
  await expect(page.locator('[data-feedback-source]').first()).toHaveText(feedbackText.sourceAction.zh);

  await page.locator('[data-locale="en"]').click();
  await expect(page.locator('[data-feedback-source]').first()).toHaveText(feedbackText.sourceAction.en);

  // A citation card plus a link must not push the panel past a phone's width in either language.
  await page.setViewportSize({ width: 390, height: 844 });
  for (const locale of ['en', 'zh']) {
    await page.locator(`[data-locale="${locale}"]`).click();
    await expect(page.locator('[data-feedback-source]').first()).toBeVisible();
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow).toBeLessThanOrEqual(0);
  }
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

const drawer = (page) => page.locator('#dataset-sidebar');
const drawerScrim = (page) => page.locator('#app-scrim');
const drawerTrigger = (page) => page.locator('#dataset-menu-button');

/** Opens the mobile drawer the way a learner does, and waits for it to take focus. */
async function openDrawer(page) {
  await drawerTrigger(page).click();
  await expect(drawer(page)).toHaveClass(/is-open/);
  await expect(drawerTrigger(page)).toHaveAttribute('aria-expanded', 'true');
  await expect(page.locator('#dataset-menu-close')).toBeFocused();
}

/** The id of whatever a click would land on out in the content area, beside the drawer. */
function topmostBesideDrawer(page) {
  return page.evaluate(() => document.elementFromPoint(window.innerWidth - 24, window.innerHeight / 2)?.id ?? null);
}

test('the mobile drawer opens over a scrim that holds focus until it is dismissed', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/app/');
  await expect(drawerScrim(page)).toBeHidden();

  await openDrawer(page);
  await expect(drawerScrim(page)).toBeVisible();
  // The scrim is a surface to dismiss through, not something to read: the trigger and the close button
  // already say everything it would, so it stays out of the accessibility tree.
  await expect(drawerScrim(page)).toHaveAttribute('aria-hidden', 'true');
  await expect(drawerScrim(page)).toBeEmpty();
  expect(await topmostBesideDrawer(page)).toBe('app-scrim');

  // Tab stays in the drawer while the scrim covers everything else. The primary links live in the tab
  // bar at this width, so the drawer runs from its close button to the reset button.
  await page.keyboard.press('Shift+Tab');
  await expect(page.locator('#reset-progress')).toBeFocused();
  await page.keyboard.press('Tab');
  await expect(page.locator('#dataset-menu-close')).toBeFocused();

  await page.keyboard.press('Escape');
  await expect(drawer(page)).not.toHaveClass(/is-open/);
  await expect(drawerScrim(page)).toBeHidden();
  await expect(drawerTrigger(page)).toHaveAttribute('aria-expanded', 'false');
  await expect(drawerTrigger(page)).toBeFocused();

  // A click at the content is a dismissal too, and it hands focus back the same way Escape does.
  await openDrawer(page);
  await drawerScrim(page).click({ position: { x: 360, y: 400 } });
  await expect(drawer(page)).not.toHaveClass(/is-open/);
  await expect(drawerScrim(page)).toBeHidden();
  await expect(drawerTrigger(page)).toBeFocused();
  expect(await topmostBesideDrawer(page)).not.toBe('app-scrim');

  // The close button is a dismissal as well, so it restores the trigger rather than leaving focus in a
  // drawer that is no longer on screen.
  await openDrawer(page);
  await page.locator('#dataset-menu-close').click();
  await expect(drawer(page)).not.toHaveClass(/is-open/);
  await expect(drawerTrigger(page)).toBeFocused();

  // The scrim has to actually dim the content, in either palette: a token that failed to resolve would
  // leave a fully transparent overlay that still passes every other check here.
  await openDrawer(page);
  const lightScrim = await drawerScrim(page).evaluate((node) => getComputedStyle(node).backgroundColor);
  expect(lightScrim).not.toBe('rgba(0, 0, 0, 0)');

  await page.evaluate((key) => localStorage.setItem(key, JSON.stringify({ version: 1, theme: 'dark' })), THEME_STORAGE_KEY);
  await page.reload();
  await openDrawer(page);
  const darkScrim = await drawerScrim(page).evaluate((node) => getComputedStyle(node).backgroundColor);
  expect(darkScrim).not.toBe('rgba(0, 0, 0, 0)');
  expect(darkScrim).not.toBe(lightScrim);
});

test('choosing a surface from the mobile drawer closes it and leaves focus on that surface', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/app/#/import');

  // The drawer's own link to the surface already on screen: no address change, so nothing else can be
  // relied on to close it.
  await openDrawer(page);
  await page.locator('#sidebar-import [data-nav-route="import"]').click();
  await expect(drawer(page)).not.toHaveClass(/is-open/);
  await expect(drawerScrim(page)).toBeHidden();
  await expect(page).toHaveURL(/#\/import$/);
  await expect(page.locator('#app-content')).toBeFocused();
  await expect(drawerTrigger(page)).not.toBeFocused();

  // A dataset is a navigation too: the deck takes focus and the trigger does not take it back.
  await page.goto('/app/');
  await openDrawer(page);
  await page.locator('#dataset-list [data-select-dataset="git"]').click();
  await expect(drawer(page)).not.toHaveClass(/is-open/);
  await expect(drawerScrim(page)).toBeHidden();
  await expect(page).toHaveURL(/#\/decks\/git$/);
  await expect(page.locator('#app-content')).toBeFocused();
  await expect(drawerTrigger(page)).not.toBeFocused();

  // The tab bar is the primary navigation at this width and stays above the scrim, so reaching for it
  // while the drawer is open has to close the drawer rather than be swallowed by it.
  await openDrawer(page);
  await page.locator('#app-tabbar [data-tab-route="library"]').click();
  await expect(drawer(page)).not.toHaveClass(/is-open/);
  await expect(drawerScrim(page)).toBeHidden();
  await expect(page).toHaveURL(/#\/library$/);
  await expect(page.locator('#app-content')).toBeFocused();
  await expect(drawerTrigger(page)).not.toBeFocused();

  // The tab for the surface already on screen is the case with no address change at all, so the drawer has
  // to close on the click itself.
  await openDrawer(page);
  await page.locator('#app-tabbar [data-tab-route="library"]').click();
  await expect(drawer(page)).not.toHaveClass(/is-open/);
  await expect(drawerScrim(page)).toBeHidden();
  await expect(page).toHaveURL(/#\/library$/);
  await expect(page.locator('#app-content')).toBeFocused();
  await expect(drawerTrigger(page)).not.toBeFocused();
});

test('the desktop sidebar keeps its column behaviour with no scrim and no focus moves', async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.goto('/app/');
  await expect(drawer(page)).toBeVisible();
  await expect(drawerTrigger(page)).toBeHidden();
  await expect(drawerScrim(page)).toBeHidden();
  expect(await topmostBesideDrawer(page)).not.toBe('app-scrim');

  // Escape belongs to the drawer, so on a permanent column it must not pull focus out of the surface.
  const current = page.locator('#app-nav [data-nav-route="library"]');
  await current.click();
  await expect(page.locator('#app-content')).toBeFocused();
  await page.keyboard.press('Escape');
  await expect(page.locator('#app-content')).toBeFocused();
  await expect(drawer(page)).toBeVisible();
  await expect(drawerScrim(page)).toBeHidden();

  // The link to the surface already on screen changes nothing here: no drawer to close, no focus to move.
  await current.focus();
  await current.click();
  await expect(current).toBeFocused();
  await expect(page).toHaveURL(/#\/library$/);
});

const deckSearch = (page) => page.locator('[data-deck-search-input]');
const deckCards = (page) => page.locator('[data-deck-card]');
const deckStatus = (page) => page.locator('[data-deck-status]');

/** How much of one card's track the fill actually covers, measured rather than read off a class. */
async function deckFillRatio(card) {
  const [fill, track] = await Promise.all([
    card.locator('.progress-bar').evaluate((node) => node.getBoundingClientRect().width),
    card.locator('.progress-track').evaluate((node) => node.getBoundingClientRect().width),
  ]);
  return track > 0 ? fill / track : 0;
}

/**
 * Answers the first `count` questions of one bundled deck through the UI and returns to the deck
 * library. Progress is cleared first so the deck always resumes at its first question, which keeps the
 * counts a card is asserted on exact rather than cumulative across calls.
 */
async function answerQuestions(page, datasetId, count) {
  await page.goto(`/app/#/decks/${datasetId}`);
  await page.evaluate((key) => localStorage.removeItem(key), PROGRESS_STORAGE_KEY);
  await page.reload();

  for (const question of getDataset(datasetId).questions.slice(0, count)) {
    for (const optionId of question.correct) await page.locator(`input[value="${optionId}"]`).check();
    await page.locator('[data-submit]').click();
    await expect(page.locator('.feedback-status')).toBeVisible();
    await page.locator('[data-next]').click();
  }

  await page.goto('/app/#/decks');
  await expect(deckCards(page).first()).toBeVisible();
}

test('the deck library filters by title and counts what it is showing', async ({ page }) => {
  await page.goto('/app/#/decks');
  await expect(deckCards(page)).toHaveCount(DATASETS.length);
  await expect(deckStatus(page)).toContainText(`Decks: ${DATASETS.length}`);
  await expect(deckStatus(page)).toContainText('Verified questions: 12');

  await deckSearch(page).fill('flutter');
  await expect(deckCards(page)).toHaveCount(1);
  await expect(deckCards(page).first()).toHaveAttribute('data-deck-card', 'flutter');
  await expect(deckStatus(page)).toContainText(`Decks matching “flutter”: 1 of ${DATASETS.length}`);
  // Only the part that matched is marked, so the result can be explained by pointing at the title.
  await expect(deckCards(page).first().locator('mark')).toHaveText('Flutter');

  // Folding covers case and width; every term still has to appear in the same title.
  await deckSearch(page).fill('  GIT  ');
  await expect(deckCards(page)).toHaveCount(1);
  await expect(deckCards(page).first()).toHaveAttribute('data-deck-card', 'git');
  await deckSearch(page).fill('git runtime');
  await expect(deckCards(page)).toHaveCount(0);

  // A summary word is not searched: the field says it matches the deck name, and it means it.
  await deckSearch(page).fill('staging');
  await expect(deckCards(page)).toHaveCount(0);

  // The query is view state, not a route, so filtering never rewrites the address.
  await expect(page).toHaveURL(/#\/decks$/);
  await page.locator('[data-deck-search-clear]').click();
  await expect(deckSearch(page)).toHaveValue('');
  await expect(deckSearch(page)).toBeFocused();
  await expect(deckCards(page)).toHaveCount(DATASETS.length);
  await expect(page.locator('#app-announcer')).toHaveText(`Deck search cleared. Showing all ${DATASETS.length} decks.`);

  // Searching and clearing wrote nothing: the query is not the learner's data to keep.
  expect(await page.evaluate((keys) => keys.filter((key) => localStorage.getItem(key) !== null), ANCHOR_STORAGE_KEYS)).toEqual([]);

  // Opening a deck and coming back keeps the query: it lives as long as the tab, not the surface.
  await deckSearch(page).fill('git');
  await deckCards(page).first().click();
  await expect(page).toHaveURL(/#\/decks\/git$/);
  await page.locator('#app-nav [data-nav-route="decks"]').click();
  await expect(deckSearch(page)).toHaveValue('git');
  await expect(deckCards(page)).toHaveCount(1);

  // A reload starts clean, which is the honest outcome for a query that was never stored.
  await page.reload();
  await expect(deckSearch(page)).toHaveValue('');
  await expect(deckCards(page)).toHaveCount(DATASETS.length);
});

test('a deck card reports verified questions and this browser\'s own progress', async ({ page }) => {
  await page.goto('/app/#/decks');
  const flutter = page.locator('[data-deck-card="flutter"]');
  await expect(flutter.locator('[data-deck-verified]')).toHaveText('4 verified / 4 total');
  await expect(flutter.locator('[data-deck-answered]')).toHaveText('0/4 answered');
  await expect(flutter.locator('[data-deck-percent]')).toHaveText('Not started');
  await expect(flutter.locator('[data-deck-action-label]')).toContainText('Start studying');
  await expect(flutter).toHaveAttribute('data-deck-action', 'start');
  await expect(flutter).toHaveAttribute('data-deck-tier', 'start');
  await expect(flutter).toBeEnabled();

  await answerQuestions(page, 'flutter', 1);
  await expect(flutter.locator('[data-deck-answered]')).toHaveText('1/4 answered');
  await expect(flutter.locator('[data-deck-percent]')).toHaveText('25% answered');
  await expect(flutter.locator('[data-deck-action-label]')).toContainText('Continue studying');
  await expect(flutter).toHaveAttribute('data-deck-action', 'continue');
  // The bar carries no value of its own: the percentage is text beside it, so the width is a class.
  await expect(flutter.locator('.progress-bar')).toHaveClass(/deck-fill-30/);
  await expect(flutter.locator('.progress-track')).toHaveAttribute('aria-hidden', 'true');
  // And it has to render at that width. The class alone proves nothing: these are spans inside a
  // button, where an inline box would drop the width and leave an empty track.
  expect(await deckFillRatio(flutter)).toBeGreaterThan(0.2);
  expect(await deckFillRatio(flutter)).toBeLessThan(0.4);

  // Progress belongs to one deck, so the others still read as untouched.
  const git = page.locator('[data-deck-card="git"]');
  await expect(git.locator('[data-deck-percent]')).toHaveText('Not started');
  await expect(git).toHaveAttribute('data-deck-action', 'start');

  await answerQuestions(page, 'flutter', 4);
  await expect(flutter.locator('[data-deck-answered]')).toHaveText('4/4 answered');
  await expect(flutter.locator('[data-deck-percent]')).toHaveText('100% answered');
  await expect(flutter.locator('[data-deck-action-label]')).toContainText('Review again');
  await expect(flutter).toHaveAttribute('data-deck-tier', 'complete');
  await expect(flutter.locator('.progress-bar')).toHaveClass(/deck-fill-100/);
  expect(await deckFillRatio(flutter)).toBeCloseTo(1, 2);

  // A card is still the way into the deck: the action is a label on that one button, not a second target.
  await flutter.click();
  await expect(page).toHaveURL(/#\/decks\/flutter$/);

  // Resetting progress puts every card back to its unstarted reading.
  await page.locator('#reset-progress').click();
  await expect(page).toHaveURL(/#\/decks$/);
  await expect(page.locator('[data-deck-card="flutter"] [data-deck-percent]')).toHaveText('Not started');
  await expect(page.locator('[data-deck-card="flutter"] [data-deck-answered]')).toHaveText('0/4 answered');
});

test('the deck library separates no match from an empty query, and offers a local import', async ({ page }) => {
  await page.goto('/app/#/decks');
  await expect(page.locator('[data-deck-empty]')).toHaveCount(0);

  await deckSearch(page).fill('kubernetes');
  const empty = page.locator('[data-deck-empty]');
  await expect(empty).toHaveAttribute('data-empty-kind', 'no-results');
  await expect(empty).toContainText('kubernetes');
  await expect(empty).toContainText(String(DATASETS.length));
  await expect(deckStatus(page)).toContainText(`0 of ${DATASETS.length}`);
  await expect(deckCards(page)).toHaveCount(0);
  // The grid goes away with the results rather than standing empty above the explanation.
  await expect(page.locator('.deck-grid')).toHaveCount(0);

  // The query is echoed into both, so both have to escape it.
  await deckSearch(page).fill('<img src=x onerror=alert(1)>');
  await expect(empty).toContainText('onerror=alert(1)');
  await expect(empty.locator('img')).toHaveCount(0);
  await expect(deckStatus(page).locator('img')).toHaveCount(0);

  // Adding material is the way past bundled decks, and it stays inside this browser.
  await page.locator('[data-deck-import]').click();
  await expect(page).toHaveURL(/#\/import$/);
  await expect(page.locator('body')).toHaveAttribute('data-view', 'import');
});

test('deck search and card status stay bilingual', async ({ page }) => {
  await answerQuestions(page, 'git', 2);
  await deckSearch(page).fill('git');
  await expect(deckCards(page)).toHaveCount(1);

  await page.locator('[data-locale="zh"]').click();
  // The query belongs to the learner, not to the language, so a switch keeps it and re-matches.
  await expect(deckSearch(page)).toHaveValue('git');
  await expect(deckCards(page)).toHaveCount(1);
  await expect(page.locator('label[for="deck-search-input"]')).toHaveText(SHELL_TEXT.decks.searchLabel.zh);
  await expect(deckSearch(page)).toHaveAttribute('placeholder', SHELL_TEXT.decks.searchPlaceholder.zh);
  await expect(page.locator('[data-deck-search-clear]')).toHaveText(SHELL_TEXT.decks.searchClear.zh);
  await expect(page.locator('[data-deck-import]')).toHaveText(SHELL_TEXT.decks.importAction.zh);

  const git = page.locator('[data-deck-card="git"]');
  await expect(git.locator('[data-deck-verified]')).toHaveText('4 已核验 / 4 总题');
  await expect(git.locator('[data-deck-answered]')).toHaveText('已答 2/4');
  await expect(git.locator('[data-deck-percent]')).toHaveText('已答 50%');
  await expect(git.locator('[data-deck-action-label]')).toContainText(SHELL_TEXT.decks.actionContinue.zh);
  await expect(deckStatus(page)).toContainText('/ 3');

  // A Chinese query matches the Chinese titles, which is what the hint promises.
  await deckSearch(page).fill('协作');
  await expect(deckCards(page)).toHaveCount(1);
  await expect(deckCards(page).first()).toHaveAttribute('data-deck-card', 'git');
  await deckSearch(page).fill('');
  await expect(deckStatus(page)).toContainText('已核验题目：12');

  await page.locator('[data-locale="en"]').click();
  await expect(page.locator('label[for="deck-search-input"]')).toHaveText(SHELL_TEXT.decks.searchLabel.en);
  await expect(page.locator('[data-deck-card="git"] [data-deck-percent]')).toHaveText('50% answered');
});

test('the deck library takes the keyboard and stays announced', async ({ page }) => {
  await page.goto('/app/#/decks');
  await expect(deckStatus(page)).toHaveAttribute('role', 'status');
  await expect(deckStatus(page)).toHaveAttribute('aria-live', 'polite');
  await expect(page.locator('[data-deck-search]')).toHaveAttribute('role', 'search');
  await expect(deckSearch(page)).toHaveAttribute('aria-describedby', 'deck-search-hint');
  await expect(page.locator('#deck-search-hint')).toContainText('60 characters');
  // Nothing here posts anywhere, so there is no form to submit.
  await expect(page.locator('.deck-toolbar form')).toHaveCount(0);

  // The clear button only exists once there is something to clear.
  await expect(page.locator('[data-deck-search-clear]')).toBeHidden();
  await deckSearch(page).click();
  await page.keyboard.type('javascript');
  await expect(page.locator('[data-deck-search-clear]')).toBeVisible();
  await expect(deckCards(page)).toHaveCount(1);

  // Enter cannot submit anything, so it moves to the first deck that matched.
  await page.keyboard.press('Enter');
  await expect(deckCards(page).first()).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(/#\/decks\/javascript$/);

  await page.goto('/app/#/decks');
  await deckSearch(page).fill('flutter');
  await deckSearch(page).press('Escape');
  await expect(deckSearch(page)).toHaveValue('');
  await expect(deckSearch(page)).toBeFocused();
  await expect(deckCards(page)).toHaveCount(DATASETS.length);
  await expect(page.locator('#app-announcer')).toHaveText(`Deck search cleared. Showing all ${DATASETS.length} decks.`);

  // Each card is one button whose name reads as the whole card, so the bar must not add a second
  // widget inside it: a nested progressbar would only be flattened into that name.
  await expect(page.locator('.deck-grid').getByRole('button', { name: /Flutter lifecycle/ })).toHaveCount(1);
  await expect(page.locator('.deck-grid [role="progressbar"]')).toHaveCount(0);
  await expect(page.locator('.deck-grid button')).toHaveCount(DATASETS.length);

  // A capped field cannot grow a query past what matching will read.
  await expect(deckSearch(page)).toHaveAttribute('maxlength', '60');
  await deckSearch(page).fill('x'.repeat(120));
  expect((await deckSearch(page).inputValue()).length).toBe(60);
});

test('the deck library fits a 390px viewport and asks nothing of the network', async ({ page }) => {
  const offOrigin = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOrigin.push(request.url());
  });
  const overflow = () => page.evaluate(() => Math.max(
    document.documentElement.scrollWidth - document.documentElement.clientWidth,
    document.body.scrollWidth - document.body.clientWidth,
  ));

  // Progress is built at the default size, then the viewport narrows: this test is about the deck
  // layout, not about tapping the quiz under a fixed tab bar.
  await answerQuestions(page, 'javascript', 3);
  await page.setViewportSize({ width: 390, height: 844 });
  expect(await overflow(), 'the idle deck library overflows at 390px').toBeLessThanOrEqual(0);
  await expect(page.locator('[data-deck-card="javascript"] [data-deck-percent]')).toHaveText('75% answered');

  await deckSearch(page).fill('javascript');
  await expect(deckCards(page)).toHaveCount(1);
  expect(await overflow(), 'a single deck result overflows at 390px').toBeLessThanOrEqual(0);

  await deckSearch(page).fill('kubernetes');
  await expect(page.locator('[data-deck-empty]')).toBeVisible();
  expect(await overflow(), 'the no-result state overflows at 390px').toBeLessThanOrEqual(0);

  await page.locator('[data-locale="zh"]').click();
  expect(await overflow(), 'Chinese deck copy overflows at 390px').toBeLessThanOrEqual(0);
  await expect(page.locator('.app-tabbar')).toBeVisible();

  expect(offOrigin).toEqual([]);
});

const homeToday = (page) => page.locator('[data-home-today]');
const homeFocus = (page) => page.locator('[data-home-focus]');
const homePlanRows = (page) => page.locator('[data-home-plan-row]');

/** Opens Home on a cleared progress key, so every number on it is exactly what this test produced. */
async function openHomeFresh(page) {
  await page.goto('/app/#/home');
  await page.evaluate((key) => localStorage.removeItem(key), PROGRESS_STORAGE_KEY);
  await page.reload();
  await expect(homeToday(page)).toBeVisible();
}

/** Answers every question of one deck through the UI, leaving the other decks' progress alone. */
async function answerWholeDeck(page, datasetId) {
  await page.goto(`/app/#/decks/${datasetId}`);
  for (const question of getDataset(datasetId).questions) {
    for (const optionId of question.correct) await page.locator(`input[value="${optionId}"]`).check();
    await page.locator('[data-submit]').click();
    await expect(page.locator('.feedback-status')).toBeVisible();
    await page.locator('[data-next]').click();
  }
}

test('home opens on a zero state that offers a first deck rather than a queue', async ({ page }) => {
  await openHomeFresh(page);

  await expect(page.locator('[data-home-answered]')).toHaveText('0/12');
  await expect(page.locator('[data-home-correct]')).toHaveText('0/12');
  await expect(page.locator('[data-home-percent]')).toHaveText('0%');
  await expect(page.locator('[data-home-started]')).toHaveText(`0/${DATASETS.length}`);

  // Today is a local target derived from what is left to answer, not a schedule handed down.
  await expect(page.locator('[data-home-today-goal]')).toHaveText('0 of 4 answered today');
  await expect(page.locator('[data-home-today-status]')).toHaveText(SHELL_TEXT.home.todayEmpty.en);
  await expect(homeToday(page)).toHaveAttribute('data-home-today-state', 'open');
  await expect(homeToday(page).locator('[role="progressbar"]')).toHaveAttribute('aria-valuenow', '0');
  await expect(homeToday(page).locator('[role="progressbar"]')).toHaveAttribute('aria-valuemax', '4');
  await expect(homeToday(page).locator('[data-home-today-note]')).toHaveText(SHELL_TEXT.home.todayBody.en);

  // With nothing started the next step is the first bundled deck, offered as a start.
  await expect(homeFocus(page)).toHaveAttribute('data-home-focus', DATASETS[0].id);
  await expect(homeFocus(page)).toHaveAttribute('data-home-focus-action', 'start');
  await expect(homeFocus(page)).toContainText(DATASETS[0].title.en);
  await expect(homeFocus(page)).toContainText('4 of 4 questions left');
  await expect(homeFocus(page).locator('.button')).toContainText(SHELL_TEXT.decks.actionStart.en);
  await expect(homeFocus(page).locator('.button')).toHaveAttribute('href', `#/decks/${DATASETS[0].id}`);

  // Every bundled deck is listed, in bundled order, with nothing marked done.
  await expect(homePlanRows(page)).toHaveCount(DATASETS.length);
  for (const [index, dataset] of DATASETS.entries()) {
    const row = homePlanRows(page).nth(index);
    await expect(row).toHaveAttribute('data-home-plan-row', dataset.id);
    await expect(row).toContainText(dataset.title.en);
    await expect(row.locator('[data-home-plan-count]')).toHaveText('0/4 questions');
    await expect(row.locator('[data-home-plan-status]')).toHaveText(SHELL_TEXT.home.planRemaining.en.replace('{n}', '4'));
    await expect(row.locator('.progress-bar')).toHaveClass(/deck-fill-0/);
  }
  await expect(page.locator('[data-home-plan-summary]')).toHaveText(`0 of ${DATASETS.length} decks complete`);

  // Nothing on this surface claims a queue, a streak, an account, or a model call.
  const homeText = (await page.locator('#app-content').innerText()).toLowerCase();
  for (const word of ['streak', ' xp', 'hearts', 'due today', 'scheduled for', 'sign in', 'sync']) {
    expect(homeText, `home should not claim “${word.trim()}”`).not.toContain(word);
  }
});

test('home follows the progress this browser stored, one deck at a time', async ({ page }) => {
  await openHomeFresh(page);
  await answerQuestions(page, 'flutter', 1);
  await page.goto('/app/#/home');

  await expect(page.locator('[data-home-answered]')).toHaveText('1/12');
  await expect(page.locator('[data-home-correct]')).toHaveText('1/12');
  await expect(page.locator('[data-home-percent]')).toHaveText('8%');
  await expect(page.locator('[data-home-started]')).toHaveText(`1/${DATASETS.length}`);

  await expect(page.locator('[data-home-today-goal]')).toHaveText('1 of 4 answered today');
  await expect(page.locator('[data-home-today-status]')).toHaveText('3 to go');
  await expect(homeToday(page).locator('[role="progressbar"]')).toHaveAttribute('aria-valuenow', '1');
  await expect(homeToday(page).locator('.progress-bar')).toHaveClass(/agent-fill-30/);

  // The deck with work in it becomes the resume target, and the label changes with it.
  await expect(homeFocus(page)).toHaveAttribute('data-home-focus', 'flutter');
  await expect(homeFocus(page)).toHaveAttribute('data-home-focus-action', 'continue');
  await expect(homeFocus(page)).toContainText('3 of 4 questions left');
  await expect(homeFocus(page).locator('.button')).toContainText(SHELL_TEXT.decks.actionContinue.en);

  // Progress belongs to one deck: the other rows still read as untouched.
  const flutterRow = page.locator('[data-home-plan-row="flutter"]');
  await expect(flutterRow.locator('[data-home-plan-count]')).toHaveText('1/4 questions');
  await expect(flutterRow.locator('[data-home-plan-status]')).toHaveText('3 left');
  await expect(flutterRow.locator('.progress-bar')).toHaveClass(/deck-fill-30/);
  await expect(page.locator('[data-home-plan-row="git"] [data-home-plan-count]')).toHaveText('0/4 questions');
  await expect(page.locator('[data-home-plan-summary]')).toHaveText(`0 of ${DATASETS.length} decks complete`);

  // Finishing that deck marks its row done and moves the next step to the next unfinished deck.
  await answerQuestions(page, 'flutter', 4);
  await page.goto('/app/#/home');
  await expect(page.locator('[data-home-answered]')).toHaveText('4/12');
  await expect(page.locator('[data-home-percent]')).toHaveText('33%');
  await expect(flutterRow.locator('[data-home-plan-status]')).toHaveText(SHELL_TEXT.home.planDone.en);
  await expect(flutterRow.locator('[data-home-plan-status]')).toHaveClass(/is-done/);
  await expect(flutterRow.locator('.progress-bar')).toHaveClass(/deck-fill-100/);
  await expect(page.locator('[data-home-plan-summary]')).toHaveText(`1 of ${DATASETS.length} decks complete`);
  await expect(homeFocus(page)).toHaveAttribute('data-home-focus', 'git');
  await expect(homeFocus(page)).toHaveAttribute('data-home-focus-action', 'start');

  // Four answers in one day is the target, and the line keeps the real count rather than a fraction.
  await expect(page.locator('[data-home-today-goal]')).toHaveText('4 answered today');
  await expect(page.locator('[data-home-today-status]')).toHaveText(SHELL_TEXT.home.todayMet.en);
  await expect(homeToday(page)).toHaveAttribute('data-home-today-state', 'met');

  // Resetting progress puts the whole surface back to its zero state, today's count included.
  await page.locator('#reset-progress').click();
  await expect(page.locator('[data-home-answered]')).toHaveText('0/12');
  await expect(page.locator('[data-home-today-goal]')).toHaveText('0 of 4 answered today');
  await expect(homeFocus(page)).toHaveAttribute('data-home-focus-action', 'start');
  await expect(page.locator('[data-home-plan-summary]')).toHaveText(`0 of ${DATASETS.length} decks complete`);
});

test('home stops promising a goal once every bundled question is answered', async ({ page }) => {
  await openHomeFresh(page);
  for (const dataset of DATASETS) await answerWholeDeck(page, dataset.id);
  await page.goto('/app/#/home');

  await expect(page.locator('[data-home-answered]')).toHaveText('12/12');
  await expect(page.locator('[data-home-percent]')).toHaveText('100%');
  await expect(page.locator('[data-home-started]')).toHaveText(`${DATASETS.length}/${DATASETS.length}`);
  await expect(page.locator('[data-home-plan-summary]')).toHaveText(`${DATASETS.length} of ${DATASETS.length} decks complete`);
  await expect(page.locator('[data-home-plan-status].is-done')).toHaveCount(DATASETS.length);

  // The bundled set is finished, so Home points at import instead of a target it cannot offer.
  await expect(homeToday(page)).toHaveAttribute('data-home-today-state', 'exhausted');
  await expect(page.locator('[data-home-today-goal]')).toHaveText('12 answered today');
  await expect(page.locator('[data-home-today-note]')).toHaveText(SHELL_TEXT.home.todayExhausted.en);

  // There is still one deck to open, now as a review rather than as unfinished work.
  await expect(homeFocus(page)).toHaveAttribute('data-home-focus-action', 'review');
  await expect(homeFocus(page)).toContainText('All 4 questions answered');
  await expect(homeFocus(page).locator('.button')).toContainText(SHELL_TEXT.decks.actionReview.en);
});

test('home reaches every next surface, stays bilingual, and asks for nothing off-origin', async ({ page }) => {
  const offOriginRequests = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOriginRequests.push(request.url());
  });

  await openHomeFresh(page);

  // Four explicit next actions, each landing on the surface it names.
  const destinations = [['decks', '#/decks'], ['agent', '#/agent'], ['library', '#/library'], ['import', '#/import']];
  for (const [action, hash] of destinations) {
    const card = page.locator(`[data-home-action="${action}"]`);
    await expect(card.locator('.button')).toHaveAttribute('href', hash);
    await card.locator('.button').click();
    await expect(page).toHaveURL(new RegExp(`${hash.replace('#/', '#/')}$`));
    await page.goto('/app/#/home');
  }

  // The import action keeps its Android scope badge: reading a file is local, building questions is not.
  await expect(page.locator('[data-home-action="import"] .scope-badge.scope-android')).toBeVisible();

  // Keyboard order runs down the surface: the focus deck, then the four actions, then the plan rows.
  // Tabbing stops at the last plan row so the walk asserts the order rather than a step count.
  const lastRow = DATASETS.at(-1).id;
  const marker = () => page.evaluate(() => {
    const node = document.activeElement;
    if (!node || !document.getElementById('app-content')?.contains(node)) return null;
    return node.closest('[data-home-focus]') ? 'focus'
      : node.closest('[data-home-action]')?.dataset.homeAction
      ?? node.closest('[data-home-plan-row]')?.dataset.homePlanRow
      ?? null;
  });

  await page.locator('.view-heading h1').click();
  const reachable = [];
  for (let step = 0; step < 20 && reachable.at(-1) !== lastRow; step += 1) {
    await page.keyboard.press('Tab');
    const current = await marker();
    if (current && reachable.at(-1) !== current) reachable.push(current);
  }
  expect(reachable).toEqual(['focus', 'decks', 'agent', 'library', 'import', ...DATASETS.map((dataset) => dataset.id)]);

  // Enter on that row opens its deck, so a plan row is a real target for the keyboard too.
  await expect(page.locator(`[data-home-plan-row="${lastRow}"]`)).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(new RegExp(`#/decks/${lastRow}$`));

  // Every number and label on the surface has a Chinese reading; none of them fall back to English.
  // Progress is cleared first because opening that deck left a resume hint behind, as it should.
  await openHomeFresh(page);
  await page.locator('[data-locale="zh"]').click();
  await expect(page.locator('#app-content h1')).toContainText(SHELL_TEXT.home.title.zh);
  await expect(homeToday(page)).toContainText(SHELL_TEXT.home.todayTitle.zh);
  await expect(page.locator('[data-home-today-goal]')).toHaveText('今天已答 0 / 4 题');
  await expect(page.locator('[data-home-today-note]')).toHaveText(SHELL_TEXT.home.todayBody.zh);
  await expect(homeFocus(page)).toContainText(DATASETS[0].title.zh);
  await expect(homeFocus(page).locator('.button')).toContainText(SHELL_TEXT.decks.actionStart.zh);
  await expect(page.locator('[data-home-action="agent"]')).toContainText(SHELL_TEXT.home.agentTitle.zh);
  await expect(page.locator('[data-home-action="library"]')).toContainText(SHELL_TEXT.home.libraryTitle.zh);
  await expect(page.locator('[data-home-plan-summary]')).toHaveText(`已完成 0 / ${DATASETS.length} 个题包`);
  await expect(page.locator('[data-home-plan-row="git"] [data-home-plan-status]')).toHaveText('还剩 4 题');

  // The dashboard has to fit a phone in either language, bar and four-number grid included.
  for (const locale of ['zh', 'en']) {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.locator(`[data-locale="${locale}"]`).click();
    await expect(page.locator('[data-home-plan-summary]')).toBeVisible();
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow, `home overflows at 390px in ${locale}`).toBeLessThanOrEqual(0);
  }

  // The bar has to render at a width, not just carry the class: a zero-width track would show nothing.
  await answerQuestions(page, 'flutter', 1);
  await page.goto('/app/#/home');
  const ratio = await deckFillRatio(homeToday(page));
  expect(ratio).toBeGreaterThan(0.2);
  expect(ratio).toBeLessThan(0.4);
  expect(await deckFillRatio(page.locator('[data-home-plan-row="flutter"]'))).toBeGreaterThan(0.2);

  expect(offOriginRequests).toEqual([]);
});

const homeAgentCard = (page) => page.locator('[data-home-action="agent"]');

/**
 * Writes `count` reflections through the agent UI, advancing a turn for each, and returns to Home. Any
 * earlier session is cleared first so the start panel is on screen and the counts Home is asserted on
 * belong to this call alone.
 */
async function walkAgentTurns(page, datasetId, count) {
  await page.goto('/app/#/agent');
  await page.evaluate((key) => localStorage.removeItem(key), AGENT_SESSION_STORAGE_KEY);
  await page.reload();
  await startAgentSession(page, datasetId);
  for (let index = 0; index < count; index += 1) {
    await page.locator('[data-agent-reflection]').fill(`My own words for turn ${index + 1}.`);
    await page.locator('[data-agent-advance]').click();
  }
  await page.goto('/app/#/home');
  await expect(homeToday(page)).toBeVisible();
}

test('home resumes the guided agent session this browser is part-way through', async ({ page }) => {
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(error.message));
  const dataset = getDataset('flutter');
  const total = buildAgentScript(dataset).length;
  const text = SHELL_TEXT.home;

  // With nothing stored, the Agent slot is the start affordance it has always been.
  await page.goto('/app/#/home');
  await page.evaluate((key) => localStorage.removeItem(key), AGENT_SESSION_STORAGE_KEY);
  await page.reload();
  await expect(homeAgentCard(page)).toHaveAttribute('data-home-agent-state', 'idle');
  await expect(homeAgentCard(page)).toContainText(text.agentTitle.en);
  await expect(homeAgentCard(page)).toContainText(text.agentBody.en);
  await expect(homeAgentCard(page).locator('.button')).toContainText(text.agentAction.en);
  await expect(page.locator('[data-home-agent-turn]')).toHaveCount(0);

  // One reflection written, now sitting on turn 2: the card names the dataset, the position, and the work.
  await walkAgentTurns(page, 'flutter', 1);
  await expect(homeAgentCard(page)).toHaveAttribute('data-home-agent-state', 'active');
  await expect(homeAgentCard(page)).toHaveAttribute('data-home-agent', 'flutter');
  await expect(homeAgentCard(page)).toHaveAttribute('data-home-agent-action', 'resume');
  await expect(homeAgentCard(page)).toContainText(text.agentResumeEyebrow.en);
  await expect(homeAgentCard(page)).toContainText(text.agentResumeTitle.en);
  await expect(page.locator('[data-home-agent-detail]')).toHaveText(dataset.title.en);
  await expect(page.locator('[data-home-agent-turn]')).toHaveText(`Turn 2 of ${total}`);
  await expect(page.locator('[data-home-agent-written]')).toHaveText(`1 of ${total} reflections written`);
  await expect(page.locator('[data-home-agent-note]')).toHaveText(text.agentResumeNote.en);
  await expect(homeAgentCard(page).locator('.dataset-mark')).toHaveText(dataset.mark);

  // The bar is a real width and an announced value, not just a class on an empty track.
  const meter = homeAgentCard(page).locator('[role="progressbar"]');
  await expect(meter).toHaveAttribute('aria-valuemax', String(total));
  await expect(meter).toHaveAttribute('aria-valuenow', '1');
  await expect(meter).toHaveAttribute('aria-valuetext', `1 of ${total} reflections written`);
  await expect(meter).toHaveAttribute('aria-label', text.agentResumeProgressLabel.en);
  const ratio = await deckFillRatio(homeAgentCard(page));
  expect(ratio).toBeGreaterThan(0.2);
  expect(ratio).toBeLessThan(0.4);

  // One link into the Agent, reachable and followable from the keyboard, landing on the same turn.
  const link = page.locator('[data-home-agent-link]');
  await expect(homeAgentCard(page).locator('a')).toHaveCount(1);
  await expect(link).toHaveAttribute('href', '#/agent');
  await expect(link).toContainText(text.agentResumeAction.en);
  await link.focus();
  await expect(link).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(/#\/agent$/);
  await expect(page.locator('[data-agent-counter]')).toHaveText(`Turn 2 of ${total}`);
  await expect(page.locator('[data-agent-reflection]')).toHaveValue('');
  await expect(page.locator('[data-agent-start]')).toHaveCount(0);

  // A second reflection moves the card with it, and a reload keeps both from local storage alone.
  await page.locator('[data-agent-reflection]').fill('Turn two in my own words.');
  await page.locator('[data-agent-advance]').click();
  await page.goto('/app/#/home');
  await expect(page.locator('[data-home-agent-turn]')).toHaveText(`Turn 3 of ${total}`);
  await expect(page.locator('[data-home-agent-written]')).toHaveText(`2 of ${total} reflections written`);
  await page.reload();
  await expect(homeAgentCard(page)).toHaveAttribute('data-home-agent-state', 'active');
  await expect(page.locator('[data-home-agent-turn]')).toHaveText(`Turn 3 of ${total}`);
  await expect(page.locator('[data-home-agent-written]')).toHaveText(`2 of ${total} reflections written`);

  // Home reads the session; it never writes one. Opening Home leaves the stored record untouched.
  const before = await storedAgentSession(page);
  await page.goto('/app/#/decks');
  await page.goto('/app/#/home');
  expect(await storedAgentSession(page)).toEqual(before);

  // The quiz focus card is a separate concern and still points at deck work, not at the session.
  await expect(homeFocus(page)).toHaveAttribute('data-home-focus-action', /start|continue/);
  await expect(homeFocus(page).locator('.button')).toHaveAttribute('href', /#\/decks\//);

  // Clearing the session from Profile puts Home back on the start card, with quiz progress kept.
  await answerQuestions(page, 'flutter', 1);
  await page.goto('/app/#/profile');
  await page.locator('[data-privacy-reset="agent"]').click();
  await page.locator('[data-privacy-confirm-action="agent"]').click();
  await page.goto('/app/#/home');
  await expect(homeAgentCard(page)).toHaveAttribute('data-home-agent-state', 'idle');
  await expect(homeAgentCard(page)).toContainText(text.agentAction.en);
  await expect(page.locator('[data-home-answered]')).toHaveText('1/12');

  expect(pageErrors).toEqual([]);
});

test('home offers a review of a finished agent session, in either language, on a phone', async ({ page }) => {
  const offOrigin = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOrigin.push(request.url());
  });
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(error.message));
  const dataset = getDataset('git');
  const total = buildAgentScript(dataset).length;
  const text = SHELL_TEXT.home;

  await walkAgentTurns(page, 'git', total);
  await expect(homeAgentCard(page)).toHaveAttribute('data-home-agent-state', 'complete');
  await expect(homeAgentCard(page)).toHaveAttribute('data-home-agent', 'git');
  await expect(homeAgentCard(page)).toHaveAttribute('data-home-agent-action', 'review');
  await expect(homeAgentCard(page)).toContainText(text.agentReviewTitle.en);
  await expect(homeAgentCard(page)).not.toContainText(text.agentResumeTitle.en);
  await expect(page.locator('[data-home-agent-detail]')).toHaveText(dataset.title.en);
  await expect(page.locator('[data-home-agent-turn]')).toHaveText(`Turn ${total} of ${total}`);
  await expect(page.locator('[data-home-agent-written]')).toHaveText(`All ${total} reflections written`);
  await expect(page.locator('[data-home-agent-written]')).toHaveClass(/is-done/);
  await expect(homeAgentCard(page).locator('[role="progressbar"]')).toHaveAttribute('aria-valuenow', String(total));
  expect(await deckFillRatio(homeAgentCard(page))).toBeGreaterThan(0.95);

  // The one link opens the recap the session already produced, not a fresh session.
  const link = page.locator('[data-home-agent-link]');
  await expect(link).toContainText(text.agentReviewAction.en);
  await expect(link).toHaveAttribute('href', '#/agent');
  await link.click();
  await expect(page).toHaveURL(/#\/agent$/);
  await expect(page.locator('[data-agent-complete]')).toBeVisible();
  await expect(page.locator('[data-agent-recap]')).toHaveCount(total);
  await expect(page.locator('[data-agent-start]')).toHaveCount(0);

  // The finished card survives a reload, and the browser back button returns to it.
  await page.goBack();
  await expect(page).toHaveURL(/#\/home$/);
  await expect(homeAgentCard(page)).toHaveAttribute('data-home-agent-state', 'complete');
  await page.reload();
  await expect(homeAgentCard(page)).toHaveAttribute('data-home-agent-state', 'complete');
  await expect(page.locator('[data-home-agent-written]')).toHaveText(`All ${total} reflections written`);

  // Every line of the card has a Chinese reading, counts included, and the session is not the locale's.
  await page.locator('[data-locale="zh"]').click();
  await expect(homeAgentCard(page)).toContainText(text.agentResumeEyebrow.zh);
  await expect(homeAgentCard(page)).toContainText(text.agentReviewTitle.zh);
  await expect(page.locator('[data-home-agent-detail]')).toHaveText(dataset.title.zh);
  await expect(page.locator('[data-home-agent-turn]')).toHaveText(`第 ${total} 轮 / 共 ${total} 轮`);
  await expect(page.locator('[data-home-agent-written]')).toHaveText(`${total} 条思考已全部写下`);
  await expect(page.locator('[data-home-agent-note]')).toHaveText(text.agentResumeNote.zh);
  await expect(link).toContainText(text.agentReviewAction.zh);
  await expect(homeAgentCard(page).locator('[role="progressbar"]')).toHaveAttribute('aria-label', text.agentResumeProgressLabel.zh);
  await expect(homeAgentCard(page)).toHaveAttribute('data-home-agent-state', 'complete');

  // Both languages have to fit a phone, bar and dataset mark included.
  const overflow = () =>
    page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  for (const locale of ['zh', 'en']) {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.locator(`[data-locale="${locale}"]`).click();
    await expect(homeAgentCard(page)).toBeVisible();
    await expect(page.locator('[data-home-agent-turn]')).toBeVisible();
    expect(await overflow(), `the home agent card overflows at 390px in ${locale}`).toBeLessThanOrEqual(0);
    expect(await deckFillRatio(homeAgentCard(page))).toBeGreaterThan(0.95);
  }

  // A part-way session on a phone is the same card with a partial bar, and still fits.
  await walkAgentTurns(page, 'javascript', 1);
  await expect(homeAgentCard(page)).toHaveAttribute('data-home-agent-state', 'active');
  await expect(homeAgentCard(page)).toHaveAttribute('data-home-agent', 'javascript');
  expect(await overflow(), 'a resumable home agent card overflows at 390px').toBeLessThanOrEqual(0);

  // A stored session this build cannot replay falls back to the start card rather than a broken resume.
  await page.evaluate(
    ([key, value]) => window.localStorage.setItem(key, value),
    [AGENT_SESSION_STORAGE_KEY, `{"version":${AGENT_SESSION_VERSION},"datasetId":"retired-dataset","turnIndex":2,"completed":true}`],
  );
  await page.reload();
  await expect(homeAgentCard(page)).toHaveAttribute('data-home-agent-state', 'idle');
  await expect(homeAgentCard(page)).toContainText(SHELL_TEXT.home.agentAction.en);
  await expect(page.locator('[data-home-agent-turn]')).toHaveCount(0);
  await expect(homeToday(page)).toBeVisible();

  for (const value of ['not json at all', 'null', '[]', '{"version":99,"datasetId":"git","turnIndex":0}']) {
    await page.evaluate(([key, stored]) => window.localStorage.setItem(key, stored), [AGENT_SESSION_STORAGE_KEY, value]);
    await page.reload();
    await expect(homeAgentCard(page)).toHaveAttribute('data-home-agent-state', 'idle');
    await expect(page.locator('#app-content h1')).toBeVisible();
  }

  expect(offOrigin, `unexpected off-origin requests: ${offOrigin.join(', ')}`).toEqual([]);
  expect(pageErrors).toEqual([]);
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
  await expect(homeFocus(page)).toContainText(resumeDataset.title.en);
  await expect(homeFocus(page).locator('.button')).toHaveAttribute('href', `#/decks/${resumeDataset.id}`);

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

/** Text with one heading per language, so a search can be checked in English and in Chinese. */
const SEARCH_FIXTURE = [
  '# Anchor overview',
  'Anchor keeps every question attached to the passage it came from.',
  '',
  '## Widget lifecycle',
  'My own notes about a StatefulWidget rebuild and its State object.',
  '',
  '## 复习计划',
  '每周复习一次提交记录。',
].join('\n');

/** Imports one file through the real picker, then lands on the library. */
async function seedSearchLibrary(page, options = {}) {
  await page.goto('/app/#/import');
  await pickFile(page, { text: SEARCH_FIXTURE, ...options });
  await page.locator('[data-import-confirm]').click();
  await expect(page.locator('[data-import-saved]')).toBeVisible();
  await page.goto('/app/#/library');
  await expect(page.locator('[data-library-search]')).toBeVisible();
}

const searchField = (page) => page.locator('[data-library-search-input]');
const searchResults = (page) => page.locator('[data-library-result]');

test('library search matches bundled evidence and says which field matched', async ({ page }) => {
  const offOrigin = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOrigin.push(request.url());
  });

  await page.goto('/app/#/library');

  // Nothing is searched yet, so the surface counts the corpus instead of guessing.
  await expect(page.locator('[data-library-search-empty]')).toHaveAttribute('data-empty-kind', 'idle');
  await expect(page.locator('[data-library-search-status]')).toContainText('12');
  await expect(page.locator('[data-library-search-clear]')).toBeHidden();
  await expect(page.locator('label[for="library-search-input"]')).toHaveText(SHELL_TEXT.library.search.label.en);
  await expect(searchField(page)).toHaveAttribute('maxlength', '80');

  await searchField(page).fill('initState');
  await expect(searchResults(page)).not.toHaveCount(0);
  await expect(page.locator('[data-library-search-empty]')).toHaveCount(0);
  await expect(page.locator('[data-library-search-clear]')).toBeVisible();

  const first = searchResults(page).first();
  await expect(first).toHaveAttribute('data-result-kind', 'bundled');
  await expect(first.locator('.library-result-kind')).toHaveText(SHELL_TEXT.library.search.badgeBundled.en);
  await expect(first.locator('.library-result-scope-name')).toHaveText(getDataset('flutter').title.en);
  await expect(first.locator('.library-result-locator')).toHaveText('flutter/state-lifecycle.md#initState');
  await expect(first.locator('.library-result-note')).toHaveText(SHELL_TEXT.library.search.noteBundled.en);
  await expect(first.locator('.library-result-reason')).toContainText(SHELL_TEXT.library.search.reasonExcerpt.en);
  await expect(first.locator('mark').first()).toHaveText(/initState/i);

  // The match carries its own way back to the exact question it was checked against, which is the
  // second one in this deck rather than wherever the deck was last left.
  const cited = getDataset('flutter').questions[1];
  await expect(first.locator('.library-result-actions a')).toHaveAttribute(
    'href',
    `#/decks/flutter?question=${cited.id}`,
  );
  await first.locator('.library-result-actions a').click();
  await expect(page).toHaveURL(/#\/decks\/flutter$/);
  await expect(page.locator('.quiz-view')).toBeVisible();
  await expect(page.locator('.quiz-view .question-index')).toContainText('Question 2 of 4');
  await expect(page.locator('.quiz-view .question-title')).toHaveText(cited.prompt.en);
  expect(offOrigin).toEqual([]);
});

test('a bundled result opens the cited question, and back returns to the same search', async ({ page }) => {
  const offOrigin = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOrigin.push(request.url());
  });
  const dataset = getDataset('flutter');
  const cited = dataset.questions[1];

  // A deck already in progress somewhere else is what makes "exact" mean something: without the
  // question in the link, this deck would reopen on its third question.
  await answerQuestions(page, 'flutter', 3);
  await page.goto('/app/#/decks/flutter');
  await expect(page.locator('.quiz-view .question-index')).toContainText('Question 4 of 4');

  await page.goto('/app/#/library?q=initState&kind=bundled');
  await expect(searchResults(page)).not.toHaveCount(0);
  const first = searchResults(page).first();
  await expect(first.locator('.library-result-actions a')).toHaveAttribute(
    'aria-label',
    formatCount(SHELL_TEXT.library.search.openBundledLabel.en, { name: dataset.title.en }),
  );

  await first.locator('.library-result-actions a').click();
  await expect(page.locator('.quiz-view .question-index')).toContainText('Question 2 of 4');
  await expect(page.locator('.quiz-view .question-title')).toHaveText(cited.prompt.en);
  // The announcement says the one thing the address cannot: why this question and not another.
  await expect(page.locator('#app-announcer')).toContainText('checked against');

  // The question is a pointer that gets consumed, so the address a learner ends up holding is the deck.
  await expect(page).toHaveURL(/#\/decks\/flutter$/);

  // A reload of that address resumes on the cited question, because the stored index does the
  // remembering once the link has been followed.
  await page.reload();
  await expect(page.locator('.quiz-view .question-index')).toContainText('Question 2 of 4');

  // Back returns to the results with the query and the kind filter still in the address.
  await page.goBack();
  await expect(page).toHaveURL(/#\/library\?q=initState&kind=bundled$/);
  await expect(searchField(page)).toHaveValue('initState');
  await expect(page.locator('[data-library-search-kind][value="bundled"]')).toBeChecked();
  await expect(searchResults(page)).not.toHaveCount(0);

  // The answer this question already had is still on it: the route moves the deck, it does not
  // re-open the question for a second attempt.
  await first.locator('.library-result-actions a').click();
  await expect(page.locator('.feedback-status')).toBeVisible();
  await expect(page.locator('.answer-list input:checked')).toHaveCount(cited.correct.length);
  await expect(page.locator('[data-next]')).toBeVisible();

  // A link naming a question this build does not ship opens the deck without moving it.
  await page.goto('/app/#/decks/flutter?question=flutter-not-a-question');
  await expect(page).toHaveURL(/#\/decks\/flutter$/);
  await expect(page.locator('.quiz-view .question-index')).toContainText('Question 2 of 4');

  // A finished deck reopens on the cited passage rather than on its score, because following a
  // citation is re-reading and not re-scoring. The answers it already holds are still there.
  await page.evaluate((key) => localStorage.removeItem(key), PROGRESS_STORAGE_KEY);
  await page.reload();
  await answerWholeDeck(page, 'flutter');
  await expect(page.locator('[data-completion-row]').first()).toBeVisible();
  await page.goto(`/app/#/decks/flutter?question=${cited.id}`);
  await expect(page.locator('.quiz-view .question-index')).toContainText('Question 2 of 4');
  await expect(page.locator('.answer-list input:checked')).toHaveCount(cited.correct.length);
  expect(offOrigin).toEqual([]);
});

test('library search matches imported file text and leads back to that section', async ({ page }) => {
  await seedSearchLibrary(page);

  await searchField(page).fill('StatefulWidget rebuild');
  const imported = searchResults(page).filter({ has: page.locator('[data-library-result-open]') }).first();
  await expect(imported).toHaveAttribute('data-result-kind', 'imported');
  await expect(imported.locator('.library-result-kind')).toHaveText(SHELL_TEXT.library.search.badgeImported.en);
  await expect(imported.locator('.library-result-scope-name')).toHaveText('anchor-notes.md');
  await expect(imported.locator('.library-result-locator')).toHaveText('anchor-notes.md#widget-lifecycle');
  await expect(imported.locator('.library-result-detail')).toContainText('Widget lifecycle');
  await expect(imported.locator('.library-result-note')).toHaveText(SHELL_TEXT.library.search.noteImported.en);

  // Opening a result expands the stored source and puts the caret on that section.
  await imported.locator('[data-library-result-open]').click();
  await expect(page.locator('[data-toggle-source]')).toHaveAttribute('aria-expanded', 'true');
  await expect(page.locator('[data-local-section="1"]')).toBeFocused();
  await expect(page.locator('#app-announcer')).toContainText('anchor-notes.md');
  await expect(searchField(page)).toHaveValue('StatefulWidget rebuild');

  // The section is in the address, so it is a place rather than a toggle, and it is marked on screen
  // because a programmatic focus on one of these panels draws no ring of its own.
  await expect(page).toHaveURL(/[?&]open=[^&]+&sec=1$/);
  await expect(page.locator('[data-section-target="true"]')).toHaveCount(1);
  await expect(page.locator('[data-local-section="1"]')).toHaveAttribute('data-section-target', 'true');
});

test('an imported result opens the exact section, and back and reload both hold it', async ({ page }) => {
  const offOrigin = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOrigin.push(request.url());
  });
  await seedSearchLibrary(page);

  await searchField(page).fill('StatefulWidget rebuild');
  const imported = searchResults(page).filter({ has: page.locator('[data-library-result-open]') }).first();
  await expect(imported.locator('[data-library-result-open]')).toHaveAttribute(
    'aria-label',
    formatCount(SHELL_TEXT.library.search.openImportedLabel.en, { locator: 'anchor-notes.md#widget-lifecycle' }),
  );

  await imported.locator('[data-library-result-open]').click();
  const opened = new URL(page.url()).hash;
  expect(opened).toMatch(/[?&]q=StatefulWidget\+rebuild/);
  expect(opened).toMatch(/&sec=1$/);

  // A reload rebuilds the whole thing from the link: the query, the expansion, and the section, none
  // of which is stored anywhere. This is the state the address exists to carry.
  await page.reload();
  await expect(searchField(page)).toHaveValue('StatefulWidget rebuild');
  await expect(page.locator('[data-toggle-source]')).toHaveAttribute('aria-expanded', 'true');
  await expect(page.locator('[data-local-section="1"]')).toBeFocused();
  await expect(page.locator('[data-local-section="1"]')).toHaveAttribute('data-section-target', 'true');
  await expect(page.locator('.local-section')).toHaveCount(3);

  // Back undoes the move and leaves the search that produced it, because opening was a navigation.
  // The target goes; the panel stays open. A route can only ever expand a source, never collapse one,
  // so going back cannot close something the learner had opened by hand.
  await page.goBack();
  await expect(page).toHaveURL(/#\/library\?q=StatefulWidget\+rebuild$/);
  await expect(searchField(page)).toHaveValue('StatefulWidget rebuild');
  await expect(searchResults(page)).not.toHaveCount(0);
  await expect(page.locator('[data-section-target="true"]')).toHaveCount(0);

  // Forward returns to it, so the two are an ordinary pair of history entries.
  await page.goForward();
  await expect(page.locator('[data-local-section="1"]')).toHaveAttribute('data-section-target', 'true');

  // A second result in the same source moves the target rather than stacking another expansion.
  await searchField(page).fill('复习');
  await searchResults(page).first().locator('[data-library-result-open]').click();
  await expect(page).toHaveURL(/&sec=2$/);
  await expect(page.locator('[data-local-section="2"]')).toHaveAttribute('data-section-target', 'true');
  await expect(page.locator('[data-section-target="true"]')).toHaveCount(1);

  // Closing the source by hand makes the address false, so the address gives the target up.
  await page.locator('[data-toggle-source]').click();
  await expect(page).toHaveURL(/#\/library\?q=%E5%A4%8D%E4%B9%A0$/);
  await expect(page.locator('[data-toggle-source]')).toHaveAttribute('aria-expanded', 'false');
  await expect(page.locator('.local-section')).toHaveCount(0);

  // A link naming a section this browser does not hold opens the library without one.
  await page.goto('/app/#/library?q=%E5%A4%8D%E4%B9%A0&open=gone-from-here&sec=1');
  await expect(page).toHaveURL(/#\/library\?q=%E5%A4%8D%E4%B9%A0$/);
  await expect(page.locator('[data-library-search]')).toBeVisible();
  await expect(page.locator('[data-section-target="true"]')).toHaveCount(0);

  // So does one naming a section past the end of a source it does hold.
  const sourceId = await page.locator('[data-local-source]').first().getAttribute('data-local-source');
  await page.goto(`/app/#/library?open=${encodeURIComponent(sourceId)}&sec=99`);
  await expect(page).toHaveURL(/#\/library$/);
  await expect(page.locator('[data-section-target="true"]')).toHaveCount(0);

  // And one naming a real section restores it, which is what makes the link shareable.
  await page.goto(`/app/#/library?open=${encodeURIComponent(sourceId)}&sec=0`);
  await expect(page).toHaveURL(/&sec=0$/);
  await expect(page.locator('[data-local-section="0"]')).toHaveAttribute('data-section-target', 'true');
  await expect(page.locator('[data-local-section="0"]')).toBeFocused();
  expect(offOrigin).toEqual([]);
});

test('exact result navigation reads the same in Chinese', async ({ page }) => {
  const dataset = getDataset('flutter');
  await seedSearchLibrary(page);
  await page.locator('[data-locale="zh"]').click();

  await searchField(page).fill('StatefulWidget');
  const imported = searchResults(page).filter({ has: page.locator('[data-library-result-open]') }).first();
  await expect(imported.locator('[data-library-result-open]')).toHaveText(SHELL_TEXT.library.search.openImported.zh);
  await expect(imported.locator('[data-library-result-open]')).toHaveAttribute(
    'aria-label',
    formatCount(SHELL_TEXT.library.search.openImportedLabel.zh, { locator: 'anchor-notes.md#widget-lifecycle' }),
  );
  await imported.locator('[data-library-result-open]').click();
  await expect(page.locator('[data-local-section="1"]')).toHaveAttribute('data-section-target', 'true');
  await expect(page.locator('#app-announcer')).toContainText('已在导入来源列表中显示');

  // A locale switch keeps the target: the language changes the copy, not the place.
  await page.locator('[data-locale="en"]').click();
  await expect(page.locator('[data-local-section="1"]')).toHaveAttribute('data-section-target', 'true');
  await expect(page.locator('[data-library-result-open]').first()).toHaveText(SHELL_TEXT.library.search.openImported.en);

  await page.locator('[data-locale="zh"]').click();
  await searchField(page).fill('initState');
  const bundled = searchResults(page).filter({ has: page.locator('.library-result-actions a') }).first();
  await expect(bundled.locator('.library-result-actions a')).toHaveText(SHELL_TEXT.library.search.openBundled.zh);
  await expect(bundled.locator('.library-result-actions a')).toHaveAttribute(
    'aria-label',
    formatCount(SHELL_TEXT.library.search.openBundledLabel.zh, { name: dataset.title.zh }),
  );

  await bundled.locator('.library-result-actions a').click();
  await expect(page.locator('.quiz-view .question-index')).toContainText('2');
  await expect(page.locator('.quiz-view .question-title')).toHaveText(dataset.questions[1].prompt.zh);
  await expect(page.locator('#app-announcer')).toContainText('此摘录所校验的题目');
  await page.goBack();
  await expect(searchField(page)).toHaveValue('initState');
});

test('library search filters by source kind and by one dataset or file', async ({ page }) => {
  await seedSearchLibrary(page);
  await searchField(page).fill('state');

  const kinds = () => searchResults(page).evaluateAll((nodes) => [...new Set(nodes.map((node) => node.dataset.resultKind))]);
  expect(await kinds()).toEqual(['bundled', 'imported']);

  await page.locator('[data-library-search-kind][value="imported"]').check();
  expect(await kinds()).toEqual(['imported']);
  await expect(page).toHaveURL(/kind=imported/);
  // The scope list narrows with the kind, so it can never offer a filter that returns nothing.
  await expect(page.locator('[data-library-search-scope] option')).toHaveCount(2);

  await page.locator('[data-library-search-kind][value="bundled"]').check();
  expect(await kinds()).toEqual(['bundled']);
  await expect(page.locator('[data-library-search-scope] option')).toHaveCount(DATASETS.length + 1);

  await page.locator('[data-library-search-scope]').selectOption('bundled:flutter');
  await expect(page).toHaveURL(/src=bundled%3Aflutter/);
  const scopes = await searchResults(page).locator('.library-result-scope-name').allTextContents();
  expect([...new Set(scopes)]).toEqual([getDataset('flutter').title.en]);

  // A filter that survives into a shared link is dropped once its source is gone.
  await page.locator('[data-library-search-kind][value="all"]').check();
  await page.goto('/app/#/library?q=state&src=imported%3Agone');
  await expect(page).toHaveURL(/#\/library\?q=state$/);
  await expect(page.locator('[data-library-search-scope]')).toHaveValue('');
  expect(await kinds()).toEqual(['bundled', 'imported']);
});

test('library search distinguishes no query, no match, and no imported sources', async ({ page }) => {
  await page.goto('/app/#/library');
  const empty = page.locator('[data-library-search-empty]');
  await expect(empty).toHaveAttribute('data-empty-kind', 'idle');
  await expect(empty).toContainText(SHELL_TEXT.library.search.emptyIdle.en);

  // Asking only for imported text before importing anything is a state, not a failed search.
  await page.locator('[data-library-search-kind][value="imported"]').check();
  await searchField(page).fill('anchor');
  await expect(empty).toHaveAttribute('data-empty-kind', 'no-imported');
  await expect(empty).toContainText(SHELL_TEXT.library.search.emptyNoImported.en);

  await page.locator('[data-library-search-kind][value="all"]').check();
  await searchField(page).fill('kubernetes');
  await expect(empty).toHaveAttribute('data-empty-kind', 'no-results');
  await expect(empty).toContainText('kubernetes');
  await expect(page.locator('[data-library-search-status]')).toContainText('0');

  // Clearing restores the idle state, empties the address, and returns focus to the field.
  await page.locator('[data-library-search-clear]').click();
  await expect(searchField(page)).toHaveValue('');
  await expect(searchField(page)).toBeFocused();
  await expect(page).toHaveURL(/#\/library$/);
  await expect(empty).toHaveAttribute('data-empty-kind', 'idle');
  await expect(page.locator('#app-announcer')).toHaveText(SHELL_TEXT.library.search.announceCleared.en);
});

test('library search survives a shared link, a reload, and a locale switch', async ({ page }) => {
  await seedSearchLibrary(page);

  await searchField(page).fill('复习');
  await expect(page).toHaveURL(/q=%E5%A4%8D%E4%B9%A0/);
  await expect(searchResults(page)).toHaveCount(1);

  // The address is the state, so a reload rebuilds the same search from the link alone.
  await page.reload();
  await expect(searchField(page)).toHaveValue('复习');
  await expect(searchResults(page)).toHaveCount(1);
  await expect(searchResults(page).first().locator('.library-result-locator')).toHaveText('anchor-notes.md#复习计划');

  await page.locator('[data-locale="zh"]').click();
  await expect(searchField(page)).toHaveValue('复习');
  await expect(searchResults(page)).toHaveCount(1);
  await expect(page.locator('label[for="library-search-input"]')).toHaveText(SHELL_TEXT.library.search.label.zh);
  await expect(searchResults(page).first().locator('.library-result-kind')).toHaveText(SHELL_TEXT.library.search.badgeImported.zh);

  // Switching back keeps the learner's query, which belongs to them and not to the language.
  await page.locator('[data-locale="en"]').click();
  await expect(searchField(page)).toHaveValue('复习');
  await expect(searchResults(page)).toHaveCount(1);
  await expect(page.locator('label[for="library-search-input"]')).toHaveText(SHELL_TEXT.library.search.label.en);

  // A query only the other language can match is honest about finding nothing.
  await searchField(page).fill('lifecycle');
  await expect(searchResults(page)).not.toHaveCount(0);
});

test('library search takes the keyboard and stays announced', async ({ page }) => {
  await seedSearchLibrary(page);

  await searchField(page).click();
  await page.keyboard.type('initState');
  await expect(page.locator('[data-library-search-status]')).toHaveAttribute('aria-live', 'polite');
  await expect(page.locator('[data-library-search-results]')).toBeVisible();

  // Enter reaches the first result instead of submitting anything.
  await page.keyboard.press('Enter');
  await expect(searchResults(page).first().locator('.button')).toBeFocused();
  await expect(page).toHaveURL(/#\/library\?q=initState$/);

  await searchField(page).press('Escape');
  await expect(searchField(page)).toHaveValue('');
  await expect(page).toHaveURL(/#\/library$/);

  // Escape elsewhere still belongs to the mobile drawer.
  await expect(page.locator('.library-search-kinds legend')).toHaveText(SHELL_TEXT.library.search.kindLegend.en);
  await expect(page.locator('[data-library-search-scope]')).toHaveAttribute('id', 'library-search-scope');
  await expect(page.locator('label[for="library-search-scope"]')).toBeVisible();
});

test('library search renders hostile file text and hostile queries as text', async ({ page }) => {
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(error.message));

  const hostile = [
    '# <img src=x onerror="window.__anchorPwned = true">',
    '<script>window.__anchorPwned = true;</script>',
    '',
    '## Second & <b>bold</b>',
    '</p></div><iframe src="https://example.com"></iframe>',
  ].join('\n');

  await seedSearchLibrary(page, { name: '<b>notes</b>.md', text: hostile });

  await searchField(page).fill('<script>');
  await expect(searchResults(page)).not.toHaveCount(0);
  await expect(searchResults(page).first().locator('.library-result-text')).toContainText('<script>window.__anchorPwned = true;</script>');
  await expect(page.locator('.library-result b, .library-result img, .library-result iframe, .library-result script')).toHaveCount(0);

  // The file name reaches the result and the scope filter as text, including inside the option label.
  await searchField(page).fill('notes');
  await expect(searchResults(page).first().locator('.library-result-scope-name')).toHaveText('<b>notes</b>.md');
  await expect(page.locator('[data-library-search-scope] option').last()).toHaveText('<b>notes</b>.md');

  // A query is echoed into the empty state, so it has to be escaped there too.
  await searchField(page).fill('kubernetes <img src=x onerror=alert(1)>');
  await expect(page.locator('[data-library-search-empty]')).toHaveAttribute('data-empty-kind', 'no-results');
  await expect(page.locator('[data-library-search-empty]')).toContainText('onerror=alert(1)');
  await expect(page.locator('[data-library-search-empty] img')).toHaveCount(0);

  // A malformed escape in a shared link must not throw while the hash is read.
  await page.goto('/app/#/library?q=100%');
  await expect(searchField(page)).toHaveValue('100%');
  await expect(page.locator('[data-library-search]')).toBeVisible();

  expect(await page.evaluate(() => window.__anchorPwned)).toBeUndefined();
  expect(pageErrors).toEqual([]);
});

test('library search fits a 390px viewport and asks nothing of the network', async ({ page }) => {
  const offOrigin = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOrigin.push(request.url());
  });
  const overflow = () => page.evaluate(() => Math.max(
    document.documentElement.scrollWidth - document.documentElement.clientWidth,
    document.body.scrollWidth - document.body.clientWidth,
  ));

  await page.setViewportSize({ width: 390, height: 844 });
  await seedSearchLibrary(page, { name: 'a-rather-long-mobile-filename-for-layout.md' });
  expect(await overflow(), 'idle library search overflows at 390px').toBeLessThanOrEqual(0);

  await searchField(page).fill('state');
  await expect(searchResults(page)).not.toHaveCount(0);
  expect(await overflow(), 'library results overflow at 390px').toBeLessThanOrEqual(0);
  await expect(page.locator('.app-tabbar')).toBeVisible();
  expect(await page.locator('.app-tabbar').evaluate((node) => getComputedStyle(node).position)).toBe('fixed');

  await page.locator('[data-library-search-kind][value="imported"]').check();
  await searchResults(page).first().locator('[data-library-result-open]').click();
  await expect(page.locator('.local-section')).toHaveCount(3);
  await expect(page.locator('[data-section-target="true"]')).toHaveCount(1);
  expect(await overflow(), 'expanded source below results overflows at 390px').toBeLessThanOrEqual(0);

  // The marked section has to survive the reload at this width too, and stay inside it.
  await page.reload();
  await expect(page.locator('[data-section-target="true"]')).toHaveCount(1);
  expect(await overflow(), 'a restored section target overflows at 390px').toBeLessThanOrEqual(0);

  await searchField(page).fill('a-rather-long-mobile-filename-for-layout');
  expect(await overflow(), 'a long locator overflows at 390px').toBeLessThanOrEqual(0);
  expect(offOrigin).toEqual([]);
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

/** The library search one agent turn's citation leads to, as an address. */
const agentSourceHash = (turn) => routeHash({ view: 'library', search: turn.citationTarget.search });

test('an agent turn links its citation into the library and back returns to the same turn', async ({ page }) => {
  const offOrigin = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOrigin.push(request.url());
  });
  const agentText = SHELL_TEXT.agent;
  const dataset = getDataset('flutter');
  const script = buildAgentScript(dataset);
  const turn = script[1];

  await startAgentSession(page, 'flutter');

  // Reach the second turn with state worth losing: a reflection behind it, a hint open on it, and a
  // progress bar that has counted the first turn.
  await page.locator('[data-agent-reflection]').fill('First turn, in my own words.');
  await page.locator('[data-agent-advance]').click();
  await expect(page.locator('[data-agent-counter]')).toHaveText(`Turn 2 of ${script.length}`);
  await page.locator('[data-agent-hint]').click();
  await expect(page.locator('[data-agent-hint-list] li')).toHaveCount(1);
  await page.locator('[data-agent-reflection]').fill('Second turn, in my own words.');
  await expect(page.locator('.agent-progress [role="progressbar"]')).toHaveAttribute('aria-valuemax', String(script.length));

  // The excerpt under the turn offers the record it was cut from, with the locator in its name and the
  // return path spelled out.
  const link = page.locator('.agent-turn [data-agent-source]');
  await expect(link).toHaveCount(1);
  await expect(link).toHaveText(agentText.sourceAction.en);
  await expect(link).toHaveAttribute('data-agent-source', turn.citation.locator);
  await expect(link).toHaveAttribute('aria-label', `Read ${turn.citation.locator} in the library`);
  await expect(page.locator('.agent-turn .agent-source-hint')).toHaveText(agentText.sourceHint.en);
  const expectedHash = agentSourceHash(turn);
  await expect(link).toHaveAttribute('href', expectedHash);

  // Following it is a route change, not a fetch: the locator resolves against the bundled index in-browser,
  // scoped to this dataset, so it lands on the one passage this turn was built from.
  await link.click();
  await expect(page).toHaveURL(new RegExp(`${expectedHash.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`));
  await expect(page.locator('[data-library-search]')).toBeVisible();
  await expect(searchField(page)).toHaveValue(turn.citation.locator);
  await expect(searchResults(page)).toHaveCount(1);
  await expect(searchResults(page).first().locator('.library-result-locator')).toHaveText(turn.citation.locator);
  await expect(searchResults(page).first().locator('.library-result-scope-name')).toHaveText(dataset.title.en);
  await expect(searchResults(page).first()).toHaveAttribute('data-result-kind', 'bundled');
  // The announcement says the one thing the address cannot: that the session was not spent to read this.
  await expect(page.locator('#app-announcer')).toContainText(turn.citation.locator);

  // Back returns to the same turn, not to the start panel: reflection, revealed hint, and progress intact.
  await page.goBack();
  await expect(page.locator('[data-agent-turn]')).toBeVisible();
  await expect(page.locator('[data-agent-counter]')).toHaveText(`Turn 2 of ${script.length}`);
  await expect(page.locator('[data-agent-prompt]')).toHaveText(turn.prompt.en);
  await expect(page.locator('[data-agent-reflection]')).toHaveValue('Second turn, in my own words.');
  await expect(page.locator('[data-agent-hint-list] li')).toHaveCount(1);
  await expect(page.locator('[data-agent-hint-list] li').first()).toHaveText(turn.hints[0].en);
  // The bar counts reflections held in storage, so on this fresh render it has both of them.
  await expect(page.locator('.agent-progress [role="progressbar"]')).toHaveAttribute('aria-valuenow', '2');
  await expect(page.locator('[data-agent-advance]')).not.toHaveAttribute('aria-disabled', 'true');
  await expect(page.locator('.agent-turn [data-agent-source]')).toHaveAttribute('href', expectedHash);

  // The link is a real anchor, so the keyboard follows it on the same terms.
  const back = page.locator('.agent-turn [data-agent-source]');
  await back.focus();
  await expect(back).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(searchResults(page)).toHaveCount(1);
  await page.goBack();
  await expect(page.locator('[data-agent-reflection]')).toHaveValue('Second turn, in my own words.');

  // The trip is a read, so the stored session is unchanged by it and a reload resumes the same turn.
  const stored = await storedAgentSession(page);
  expect(stored.datasetId).toBe(dataset.id);
  expect(stored.turnIndex).toBe(1);
  expect(stored.completed).toBe(false);
  expect(stored.hints[turn.questionId]).toBe(1);
  expect(stored.reflections[turn.questionId]).toBe('Second turn, in my own words.');
  await page.reload();
  await expect(page.locator('[data-agent-counter]')).toHaveText(`Turn 2 of ${script.length}`);
  await expect(page.locator('[data-agent-reflection]')).toHaveValue('Second turn, in my own words.');
  await expect(page.locator('[data-agent-hint-list] li')).toHaveCount(1);
  await expect(page.locator('.agent-turn [data-agent-source]')).toHaveAttribute('href', expectedHash);
  expect(await storedAgentSession(page)).toEqual(stored);

  // Reading a source records nothing outside the agent's own key.
  const keys = await storedKeys(page);
  expect(keys[LOCAL_LIBRARY_STORAGE_KEY]).toBeNull();
  expect(keys[PROGRESS_STORAGE_KEY]).toBeNull();
  expect(keys[AGENT_SESSION_STORAGE_KEY]).not.toBeNull();
  expect(offOrigin).toEqual([]);
});

test('every completed agent recap row links its passage and back returns to the recap', async ({ page }) => {
  const offOrigin = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOrigin.push(request.url());
  });
  const agentText = SHELL_TEXT.agent;
  const dataset = getDataset('git');
  const script = buildAgentScript(dataset);

  await startAgentSession(page, 'git');
  for (const [index, turn] of script.entries()) {
    await page.locator('[data-agent-reflection]').fill(`Turn ${index + 1}: ${turn.questionId}.`);
    await page.locator('[data-agent-advance]').click();
  }
  await expect(page.locator('[data-agent-complete]')).toBeVisible();

  // Every turn in the recap offers its own passage, so a finished session is reviewable row by row.
  await expect(page.locator('[data-agent-complete] [data-agent-source]')).toHaveCount(script.length);
  await expect(page.locator('.agent-recap .agent-source-hint')).toHaveText(agentText.recapSourceHint.en);

  for (const turn of script) {
    const row = page.locator(`[data-agent-recap="${turn.questionId}"]`);
    const link = row.locator('[data-agent-source]');
    await expect(link).toHaveAttribute('aria-label', `Read ${turn.citation.locator} in the library`);
    await expect(link).toHaveAttribute('href', agentSourceHash(turn));
  }

  // Follow the last row, which is the one a learner reaches after reading the whole recap.
  const last = script[script.length - 1];
  const expectedHash = agentSourceHash(last);
  await page.locator(`[data-agent-recap="${last.questionId}"] [data-agent-source]`).click();
  await expect(page).toHaveURL(new RegExp(`${expectedHash.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`));
  await expect(searchResults(page)).toHaveCount(1);
  await expect(searchResults(page).first().locator('.library-result-locator')).toHaveText(last.citation.locator);
  await expect(searchResults(page).first().locator('.library-result-scope-name')).toHaveText(dataset.title.en);

  // Back returns to the completed recap with every reflection and both onward links still on it.
  await page.goBack();
  await expect(page.locator('[data-agent-complete]')).toBeVisible();
  await expect(page.locator('[data-agent-recap]')).toHaveCount(script.length);
  await expect(page.locator('.agent-progress [role="progressbar"]')).toHaveAttribute('aria-valuenow', String(script.length));
  for (const [index, turn] of script.entries()) {
    const row = page.locator(`[data-agent-recap="${turn.questionId}"]`);
    await expect(row).toContainText(`Turn ${index + 1}: ${turn.questionId}.`);
    await expect(row).toContainText(turn.explanation.en);
  }
  await expect(page.locator(`[data-agent-complete] a[href="#/decks/${dataset.id}"]`)).toBeVisible();

  // Completion is stored state, so a reload after the trip is still the recap and not a fresh session.
  const stored = await storedAgentSession(page);
  expect(stored.completed).toBe(true);
  expect(Object.keys(stored.reflections)).toHaveLength(script.length);
  await page.reload();
  await expect(page.locator('[data-agent-complete]')).toBeVisible();
  await expect(page.locator('[data-agent-complete] [data-agent-source]')).toHaveCount(script.length);
  expect(await storedAgentSession(page)).toEqual(stored);
  expect(offOrigin).toEqual([]);
});

test('the agent source link reads in both languages and fits a phone', async ({ page }) => {
  const offOrigin = [];
  page.on('request', (request) => {
    if (new URL(request.url()).origin !== expectedOrigin) offOrigin.push(request.url());
  });
  const overflow = () =>
    page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  const agentText = SHELL_TEXT.agent;
  const dataset = getDataset('javascript');
  const script = buildAgentScript(dataset);
  const turn = script[0];

  await page.setViewportSize({ width: 390, height: 844 });
  await startAgentSession(page, 'javascript');
  expect(await overflow(), 'an agent source link overflows at 390px').toBeLessThanOrEqual(0);

  await page.locator('[data-locale="zh"]').click();
  const link = page.locator('.agent-turn [data-agent-source]');
  await expect(link).toHaveText(agentText.sourceAction.zh);
  await expect(page.locator('.agent-turn .agent-source-hint')).toHaveText(agentText.sourceHint.zh);
  await expect(link).toHaveAttribute('aria-label', `在知识库中阅读 ${turn.citation.locator}`);
  expect(await overflow(), 'the Chinese agent source link overflows at 390px').toBeLessThanOrEqual(0);

  // The locator is the same string in either language, so 中文 leads to the same passage.
  const expectedHash = agentSourceHash(turn);
  await expect(link).toHaveAttribute('href', expectedHash);
  await link.click();
  await expect(searchResults(page)).toHaveCount(1);
  await expect(searchResults(page).first().locator('.library-result-scope-name')).toHaveText(dataset.title.zh);
  expect(await overflow(), 'the scoped result overflows at 390px').toBeLessThanOrEqual(0);

  await page.goBack();
  await expect(page.locator('[data-agent-turn]')).toBeVisible();
  await expect(page.locator('[data-agent-prompt]')).toHaveText(turn.prompt.zh);
  await expect(page.locator('.agent-turn [data-agent-source]')).toHaveText(agentText.sourceAction.zh);

  // The recap says it in 中文 too, and four links stacked under four excerpts still fit the width.
  for (let index = 0; index < script.length; index += 1) {
    await page.locator('[data-agent-reflection]').fill('用我自己的话说一遍。');
    await page.locator('[data-agent-advance]').click();
  }
  await expect(page.locator('[data-agent-complete]')).toBeVisible();
  await expect(page.locator('.agent-recap .agent-source-hint')).toHaveText(agentText.recapSourceHint.zh);
  await expect(page.locator('[data-agent-complete] [data-agent-source]').first()).toHaveText(agentText.sourceAction.zh);
  expect(await overflow(), 'the agent recap source links overflow at 390px').toBeLessThanOrEqual(0);

  await page.locator('[data-locale="en"]').click();
  await expect(page.locator('[data-agent-complete] [data-agent-source]').first()).toHaveText(agentText.sourceAction.en);
  await expect(page.locator('[data-agent-complete] [data-agent-source]').first()).toHaveAttribute('href', agentSourceHash(script[0]));
  expect(offOrigin).toEqual([]);
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

const landingMenu = (page) => page.locator('.primary-nav');
const landingScrim = (page) => page.locator('#nav-scrim');
const landingTrigger = (page) => page.locator('.menu-button');
const landingLinks = (page) => landingMenu(page).locator('a');

/** Opens the landing menu the way a reader does, and waits for it to take focus. */
async function openLandingMenu(page) {
  await landingTrigger(page).click();
  await expect(landingMenu(page)).toHaveClass(/is-open/);
  await expect(landingTrigger(page)).toHaveAttribute('aria-expanded', 'true');
  await expect(landingLinks(page).first()).toBeFocused();
}

/** The id of whatever a click would land on down the page, below the open menu. */
function topmostBelowLandingMenu(page) {
  return page.evaluate(() => document.elementFromPoint(window.innerWidth / 2, window.innerHeight - 24)?.id ?? null);
}

/** True while a click at the trigger's own position would still reach the trigger. */
function triggerStaysClickable(page) {
  return landingTrigger(page).evaluate((node) => {
    const box = node.getBoundingClientRect();
    return node.contains(document.elementFromPoint(box.left + box.width / 2, box.top + box.height / 2));
  });
}

test('the landing menu opens over a scrim that holds focus until it is dismissed', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/');
  await expect(landingScrim(page)).toBeHidden();
  expect(await topmostBelowLandingMenu(page)).not.toBe('nav-scrim');

  await openLandingMenu(page);
  await expect(landingScrim(page)).toBeVisible();
  // The scrim is a surface to dismiss through, not something to read: the trigger already says everything
  // it would, so it stays out of the accessibility tree.
  await expect(landingScrim(page)).toHaveAttribute('aria-hidden', 'true');
  await expect(landingScrim(page)).toBeEmpty();
  expect(await topmostBelowLandingMenu(page)).toBe('nav-scrim');
  // It has to actually dim the page: a token that failed to resolve would leave a fully transparent
  // overlay that still passes every other check here.
  const scrimPaint = await landingScrim(page).evaluate((node) => getComputedStyle(node).backgroundColor);
  expect(scrimPaint).not.toBe('rgba(0, 0, 0, 0)');
  // The header stays above the scrim, so the trigger and the language switch remain reachable by pointer,
  // and the trigger says what pressing it does now in the wording the page already ships.
  expect(await triggerStaysClickable(page)).toBe(true);
  await expect(landingTrigger(page)).toHaveAttribute('aria-label', 'Close menu');

  // Tab walks the panel and stays there: the last link leads back to the first rather than onto the
  // language switch sitting above the scrim.
  const links = landingLinks(page);
  const count = await links.count();
  expect(count).toBeGreaterThan(1);
  await page.keyboard.press('Tab');
  await expect(links.nth(1)).toBeFocused();
  await links.nth(count - 1).focus();
  await page.keyboard.press('Tab');
  await expect(links.first()).toBeFocused();
  await page.keyboard.press('Shift+Tab');
  await expect(links.nth(count - 1)).toBeFocused();
  await expect(landingTrigger(page)).not.toBeFocused();

  // Escape is the keyboard dismissal, and it hands focus back to the trigger that opened the panel.
  await page.keyboard.press('Escape');
  await expect(landingMenu(page)).not.toHaveClass(/is-open/);
  await expect(landingScrim(page)).toBeHidden();
  await expect(landingTrigger(page)).toHaveAttribute('aria-expanded', 'false');
  await expect(landingTrigger(page)).toHaveAttribute('aria-label', 'Open menu');
  await expect(landingTrigger(page)).toBeFocused();

  // A click at the page is a dismissal too, and it restores focus the same way Escape does.
  await openLandingMenu(page);
  await landingScrim(page).click({ position: { x: 195, y: 700 } });
  await expect(landingMenu(page)).not.toHaveClass(/is-open/);
  await expect(landingScrim(page)).toBeHidden();
  await expect(landingTrigger(page)).toBeFocused();
  expect(await topmostBelowLandingMenu(page)).not.toBe('nav-scrim');

  // Escape with nothing open leaves focus where the reader put it: a closed panel has no dismissal to
  // report, so it must not pull focus onto the trigger.
  const heroAction = page.locator('.hero-actions .button-primary');
  await heroAction.focus();
  await page.keyboard.press('Escape');
  await expect(heroAction).toBeFocused();
  await expect(landingTrigger(page)).not.toBeFocused();
});

test('choosing a landing link or a language closes the menu without taking focus back', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/');

  // An in-page link is a choice, not a dismissal: focus stays with the section the reader picked instead of
  // jumping back to a trigger they are done with.
  await openLandingMenu(page);
  await landingMenu(page).locator('a[href="#workflow"]').click();
  await expect(landingMenu(page)).not.toHaveClass(/is-open/);
  await expect(landingScrim(page)).toBeHidden();
  await expect(landingTrigger(page)).toHaveAttribute('aria-expanded', 'false');
  await expect(landingTrigger(page)).not.toBeFocused();
  await expect(page).toHaveURL(/#workflow$/);

  // The language switch sits above the scrim, so it is still clickable while the panel is open. Choosing a
  // language closes the panel, keeps focus on the switch that made the choice, and relabels the trigger.
  await openLandingMenu(page);
  const chinese = page.locator('[data-locale="zh"]');
  await chinese.click();
  await expect(landingMenu(page)).not.toHaveClass(/is-open/);
  await expect(landingScrim(page)).toBeHidden();
  await expect(chinese).toBeFocused();
  await expect(landingTrigger(page)).not.toBeFocused();
  await expect(landingTrigger(page)).toHaveAttribute('aria-label', '打开菜单');

  // The wording holds in 中文 while it is open, and Escape still restores the trigger.
  await openLandingMenu(page);
  await expect(landingTrigger(page)).toHaveAttribute('aria-label', '关闭菜单');
  await page.keyboard.press('Escape');
  await expect(landingTrigger(page)).toBeFocused();
  await expect(landingTrigger(page)).toHaveAttribute('aria-label', '打开菜单');

  // Opening and dismissing the panel writes nothing: the language choice is the only key the page stored.
  expect(await page.evaluate(() => Object.keys(localStorage).sort())).toEqual([LOCALE_STORAGE_KEY]);
  expect(await page.evaluate((key) => localStorage.getItem(key), LOCALE_STORAGE_KEY)).toBe('zh');
});

test('the landing scrim and its focus trap stay inside the menu breakpoint', async ({ page }) => {
  await page.goto('/');
  await page.setViewportSize({ width: 820, height: 900 });
  await expect(landingTrigger(page)).toBeVisible();
  await openLandingMenu(page);
  await expect(landingScrim(page)).toBeVisible();

  // One pixel wider is the header row again: the navigation returns to the header and the scrim cannot
  // paint, even though the panel was left open, because the stylesheet owns that boundary.
  await page.setViewportSize({ width: 821, height: 900 });
  await expect(landingTrigger(page)).toBeHidden();
  await expect(landingScrim(page)).toBeHidden();
  await expect(landingMenu(page)).toBeVisible();
  expect(await topmostBelowLandingMenu(page)).not.toBe('nav-scrim');

  // With no panel on screen there is nothing to contain, so Tab leaves the navigation for the header.
  const links = landingLinks(page);
  await links.nth((await links.count()) - 1).focus();
  await page.keyboard.press('Tab');
  await expect(page.locator('[data-locale="zh"]')).toBeFocused();
});

test('the desktop landing navigation keeps its header row with no scrim and no focus moves', async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.goto('/');
  await expect(landingMenu(page)).toBeVisible();
  await expect(landingTrigger(page)).toBeHidden();
  await expect(landingScrim(page)).toBeHidden();
  expect(await topmostBelowLandingMenu(page)).not.toBe('nav-scrim');

  // The navigation is a row inside the header, not a panel hanging below it.
  const headerBox = await page.locator('.site-header').boundingBox();
  const navBox = await landingMenu(page).boundingBox();
  expect(navBox.y).toBeGreaterThanOrEqual(headerBox.y);
  expect(navBox.y + navBox.height).toBeLessThanOrEqual(headerBox.y + headerBox.height);

  // Escape belongs to the panel, so on a header row it must not pull focus onto a trigger that is not even
  // on screen.
  const demoLink = landingMenu(page).locator('a[href="#demo"]');
  await demoLink.focus();
  await page.keyboard.press('Escape');
  await expect(demoLink).toBeFocused();
  await expect(landingMenu(page)).toBeVisible();
  await expect(landingScrim(page)).toBeHidden();

  // A link still navigates, and nothing closes or reaches for the trigger behind it. Focus belongs to the
  // fragment the browser just targeted, which is where a reader's next Tab should carry on from.
  await demoLink.click();
  await expect(page).toHaveURL(/#demo$/);
  await expect(landingTrigger(page)).not.toBeFocused();
  await expect(landingMenu(page)).toBeVisible();
  await expect(landingScrim(page)).toBeHidden();
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
