import { getLocale, initializeLocale, setLocale, translate } from '../../scripts/i18n.js?v=20260829-1';
import {
  DATA_VERSION,
  DATASETS,
  LOCAL_IMPORT_LIMITS,
  SHELL_TEXT,
  collectSources,
  countQuestions,
  countSources,
  createEmptyLibrary,
  createLocalSource,
  formatBytes,
  formatCount,
  formatImportedAt,
  getDataset,
  looksBinary,
  normalizeLocalLibrary,
  sectionLocator,
  textFor,
  validateDatasets,
  validateImportCandidate,
} from './data.js';

export const PROGRESS_STORAGE_KEY = 'anchor.demo.progress.v1';

/**
 * Imported sources live under their own key so resetting quiz progress never deletes a document the
 * learner brought in, and so a schema change on either side cannot invalidate the other.
 */
export const LOCAL_LIBRARY_STORAGE_KEY = 'anchor.demo.library.v1';

export function createInitialProgress() {
  return { version: DATA_VERSION, activeDatasetId: null, datasets: {} };
}

function createDatasetProgress() {
  return { currentIndex: 0, answers: {}, submitted: {}, completed: false };
}

export function isCorrect(question, selection = []) {
  const actual = [...new Set(selection)].sort();
  const expected = [...question.correct].sort();
  return actual.length === expected.length && actual.every((value, index) => value === expected[index]);
}

export function scoreDataset(dataset, datasetProgress) {
  return dataset.questions.reduce((score, question) => {
    if (!datasetProgress.submitted[question.id]) return score;
    return score + (isCorrect(question, datasetProgress.answers[question.id]) ? 1 : 0);
  }, 0);
}

export function normalizeProgress(candidate) {
  if (!candidate || candidate.version !== DATA_VERSION || typeof candidate !== 'object') return createInitialProgress();
  const normalized = createInitialProgress();
  normalized.activeDatasetId = getDataset(candidate.activeDatasetId) ? candidate.activeDatasetId : null;

  for (const dataset of DATASETS) {
    const source = candidate.datasets?.[dataset.id];
    if (!source || typeof source !== 'object') continue;
    const target = createDatasetProgress();
    target.currentIndex = Number.isInteger(source.currentIndex)
      ? Math.min(Math.max(source.currentIndex, 0), dataset.questions.length - 1)
      : 0;
    target.completed = source.completed === true;
    for (const question of dataset.questions) {
      const optionIds = new Set(question.options.map((option) => option.id));
      const answer = Array.isArray(source.answers?.[question.id])
        ? [...new Set(source.answers[question.id].filter((id) => optionIds.has(id)))]
        : [];
      if (answer.length) target.answers[question.id] = answer;
      if (source.submitted?.[question.id] === true && answer.length) target.submitted[question.id] = true;
    }
    normalized.datasets[dataset.id] = target;
  }
  return normalized;
}

export const VIEWS = ['home', 'decks', 'agent', 'library', 'profile', 'import'];
export const DEFAULT_VIEW = 'home';

/**
 * Hash routing keeps every shell surface linkable on static hosting, with no server rewrite and no
 * history API dependency beyond normalising a bare `/app/` entry.
 */
export function parseRoute(hash, hasDataset = (id) => Boolean(getDataset(id))) {
  const [rawView, rawDataset] = String(hash ?? '')
    .replace(/^#\/?/, '')
    .split('/')
    .map((part) => decodeURIComponent(part ?? '').trim());
  const view = VIEWS.includes(rawView) ? rawView : DEFAULT_VIEW;
  const datasetId = view === 'decks' && rawDataset && hasDataset(rawDataset) ? rawDataset : null;
  return { view, datasetId };
}

export function routeHash({ view, datasetId } = {}) {
  const target = VIEWS.includes(view) ? view : DEFAULT_VIEW;
  return target === 'decks' && datasetId ? `#/decks/${encodeURIComponent(datasetId)}` : `#/${target}`;
}

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

function loadProgress(storage = globalThis.localStorage) {
  try {
    const value = storage?.getItem(PROGRESS_STORAGE_KEY);
    return value ? normalizeProgress(JSON.parse(value)) : createInitialProgress();
  } catch {
    return createInitialProgress();
  }
}

function saveProgress(progress, storage = globalThis.localStorage) {
  try {
    storage?.setItem(PROGRESS_STORAGE_KEY, JSON.stringify(progress));
  } catch {
    // Storage is an enhancement; the active session remains usable without it.
  }
}

function loadLibrary(storage = globalThis.localStorage) {
  try {
    const value = storage?.getItem(LOCAL_LIBRARY_STORAGE_KEY);
    return value ? normalizeLocalLibrary(JSON.parse(value)) : createEmptyLibrary();
  } catch {
    return createEmptyLibrary();
  }
}

/** Returns false when the browser refuses the write, so the UI can say so instead of losing data silently. */
function saveLibrary(library, storage = globalThis.localStorage) {
  try {
    storage?.setItem(LOCAL_LIBRARY_STORAGE_KEY, JSON.stringify(library));
    return true;
  } catch {
    return false;
  }
}

if (typeof document !== 'undefined') {
  const content = document.querySelector('#app-content');
  const datasetList = document.querySelector('#dataset-list');
  const announcer = document.querySelector('#app-announcer');
  const sidebar = document.querySelector('#dataset-sidebar');
  const menuButton = document.querySelector('#dataset-menu-button');
  const closeButton = document.querySelector('#dataset-menu-close');
  const navList = document.querySelector('#app-nav');
  const tabBar = document.querySelector('#app-tabbar');
  const sidebarImport = document.querySelector('#sidebar-import');
  const privacyNote = document.querySelector('#privacy-note');
  let progress = loadProgress();
  let library = loadLibrary();
  let route = parseRoute(window.location.hash);
  const openTutorQuestions = new Set();

  // Import is a three-step flow: select, review, confirm. Only `library` is ever persisted, so a
  // selected-but-unconfirmed file exists in memory alone and disappears on reload.
  let importDraft = null;
  let importError = null;
  let importSaved = null;
  let readToken = 0;
  const expandedSources = new Set();
  let pendingDelete = null;

  function locale() {
    return getLocale();
  }

  function shell(value) {
    return textFor(value, locale());
  }

  const NAV_ICONS = {
    home: '<path d="M3 9.5 10 4l7 5.5V16a1 1 0 0 1-1 1h-3.5v-4.5h-5V17H4a1 1 0 0 1-1-1Z"/>',
    decks: '<path d="M4 3.5h9l3 3V16a.5.5 0 0 1-.5.5h-11A.5.5 0 0 1 4 16Z"/><path d="M6.75 8.5h6.5M6.75 11.5h6.5M6.75 14h4"/>',
    agent: '<rect x="4" y="6.5" width="12" height="9.5" rx="2"/><path d="M10 3v3.5M7.5 10.5h.01M12.5 10.5h.01M8 13.5h4"/>',
    library: '<path d="M4 4.5h4.5v11H4Z"/><path d="M9.5 4.5H14v11H9.5Z"/><path d="M6.25 7.5h.01M11.75 7.5h.01"/>',
    profile: '<circle cx="10" cy="7.5" r="3"/><path d="M4.5 16.5c0-2.8 2.5-4.5 5.5-4.5s5.5 1.7 5.5 4.5"/>',
    import: '<path d="M10 3.5v8M6.75 8.25 10 11.5l3.25-3.25"/><path d="M4.5 14v1.5a1 1 0 0 0 1 1h9a1 1 0 0 0 1-1V14"/>',
  };

  const NAV_ITEMS = [
    { view: 'home', label: () => shell(SHELL_TEXT.navLearn) },
    { view: 'decks', label: () => shell(SHELL_TEXT.navDecks) },
    { view: 'agent', label: () => shell(SHELL_TEXT.navAgent) },
    { view: 'library', label: () => shell(SHELL_TEXT.navLibrary) },
    { view: 'profile', label: () => shell(SHELL_TEXT.navProfile) },
  ];

  function navIcon(view) {
    return `<svg class="nav-icon" viewBox="0 0 20 20" width="20" height="20" aria-hidden="true" focusable="false">${NAV_ICONS[view]}</svg>`;
  }

  function badge(kind) {
    const label = kind === 'android' ? SHELL_TEXT.badgeAndroid : SHELL_TEXT.badgeLocal;
    return `<span class="scope-badge scope-${kind}">${escapeHtml(shell(label))}</span>`;
  }

  /** Navigates the shell. Returns true when the hash actually changed and `hashchange` will render. */
  function navigate(next) {
    const target = routeHash(next);
    if (window.location.hash === target) return false;
    window.location.hash = target;
    return true;
  }

  function datasetProgress(datasetId) {
    progress.datasets[datasetId] ??= createDatasetProgress();
    return progress.datasets[datasetId];
  }

  function announce(message) {
    if (!announcer) return;
    announcer.textContent = '';
    window.requestAnimationFrame(() => {
      announcer.textContent = message;
    });
  }

  function setSidebarOpen(open) {
    sidebar?.classList.toggle('is-open', open);
    menuButton?.setAttribute('aria-expanded', String(open));
    menuButton?.setAttribute('aria-label', translate(open ? 'app.closeMenu' : 'app.menu'));
  }

  function persistAndRender() {
    saveProgress(progress);
    render();
  }

  /**
   * Re-renders, then restores focus. Every surface is rebuilt from `innerHTML`, so a control that
   * triggered the change no longer exists afterwards and focus has to be re-established by hand.
   */
  function rerender({ focus, message } = {}) {
    render();
    const target = typeof focus === 'function' ? focus() : focus ? document.querySelector(focus) : null;
    target?.focus();
    if (message) announce(message);
  }

  function localSourceNode(sourceId) {
    return [...document.querySelectorAll('[data-local-source]')].find((node) => node.dataset.localSource === sourceId) ?? null;
  }

  function renderDatasetList() {
    if (!datasetList) return;
    datasetList.innerHTML = DATASETS.map((dataset) => {
      const state = datasetProgress(dataset.id);
      const submitted = Object.values(state.submitted).filter(Boolean).length;
      return `
        <button class="dataset-button" type="button" data-select-dataset="${dataset.id}" aria-current="${route.datasetId === dataset.id ? 'page' : 'false'}">
          <span class="dataset-mark">${dataset.mark}</span>
          <span class="dataset-label">
            <strong>${escapeHtml(textFor(dataset.title, locale()))}</strong>
            <span>${dataset.questions.length} ${escapeHtml(translate('app.questions'))}</span>
          </span>
          <span class="dataset-progress">${submitted}/${dataset.questions.length}</span>
        </button>`;
    }).join('');
  }

  function renderNavigation() {
    const links = NAV_ITEMS.map((item) => {
      const active = route.view === item.view;
      return `
        <a class="nav-link" href="${routeHash({ view: item.view })}" data-nav-route="${item.view}"${active ? ' aria-current="page"' : ''}>
          ${navIcon(item.view)}
          <span>${escapeHtml(item.label())}</span>
        </a>`;
    }).join('');

    if (navList) {
      navList.setAttribute('aria-label', shell(SHELL_TEXT.navAria));
      navList.innerHTML = links;
    }
    if (tabBar) {
      tabBar.setAttribute('aria-label', shell(SHELL_TEXT.navAria));
      tabBar.innerHTML = NAV_ITEMS.map((item) => {
        const active = route.view === item.view;
        return `
          <a class="tab-link" href="${routeHash({ view: item.view })}" data-tab-route="${item.view}"${active ? ' aria-current="page"' : ''}>
            ${navIcon(item.view)}
            <span>${escapeHtml(item.label())}</span>
          </a>`;
      }).join('');
    }
    if (sidebarImport) {
      const active = route.view === 'import';
      sidebarImport.innerHTML = `
        <a class="nav-link nav-link-import" href="${routeHash({ view: 'import' })}" data-nav-route="import"${active ? ' aria-current="page"' : ''}>
          ${navIcon('import')}
          <span>${escapeHtml(shell(SHELL_TEXT.navImport))}</span>
        </a>`;
    }
    if (privacyNote) {
      privacyNote.innerHTML = `
        <strong>${escapeHtml(shell(SHELL_TEXT.privacy.title))}</strong>
        <p>${escapeHtml(shell(SHELL_TEXT.privacy.body))}</p>`;
    }
  }

  function submittedCountFor(dataset) {
    return Object.values(datasetProgress(dataset.id).submitted).filter(Boolean).length;
  }

  function progressSummary() {
    return DATASETS.reduce((summary, dataset) => {
      const state = datasetProgress(dataset.id);
      const submitted = submittedCountFor(dataset);
      summary.total += dataset.questions.length;
      summary.submitted += submitted;
      summary.correct += scoreDataset(dataset, state);
      if (submitted > 0 || state.completed) summary.started += 1;
      return summary;
    }, { total: 0, submitted: 0, correct: 0, started: 0 });
  }

  /** Deterministic resume target: the stored active dataset when it still has work, else the first one. */
  function continueTarget() {
    const partial = DATASETS.filter((dataset) => !datasetProgress(dataset.id).completed && submittedCountFor(dataset) > 0);
    return partial.find((dataset) => dataset.id === progress.activeDatasetId) ?? partial[0] ?? null;
  }

  function viewHeading(eyebrow, title, body) {
    return `
      <header class="view-heading">
        <p class="eyebrow">${escapeHtml(eyebrow)}</p>
        <h1>${escapeHtml(title)}</h1>
        <p class="view-lead">${escapeHtml(body)}</p>
      </header>`;
  }

  function scopeList(items) {
    return `<ul class="scope-list">${items.map((item) => `<li>${escapeHtml(shell(item))}</li>`).join('')}</ul>`;
  }

  function renderHome() {
    const summary = progressSummary();
    const resume = continueTarget();
    const text = SHELL_TEXT.home;

    const resumeCard = resume ? `
      <article class="shell-card shell-card-accent">
        <div class="shell-card-head">
          <span class="dataset-mark">${resume.mark}</span>
          <div>
            <h2>${escapeHtml(shell(text.continueTitle))}</h2>
            <p>${escapeHtml(textFor(resume.title, locale()))} · ${submittedCountFor(resume)}/${resume.questions.length}</p>
          </div>
        </div>
        <a class="button button-primary" href="${routeHash({ view: 'decks', datasetId: resume.id })}">${escapeHtml(shell(text.continueAction))}</a>
      </article>` : '';

    content.innerHTML = `
      <section class="shell-view" data-view="home">
        ${viewHeading(shell(text.eyebrow), shell(text.title), shell(text.body))}
        <p class="shell-scope">${badge('local')}<span>${escapeHtml(shell(SHELL_TEXT.browserScope))}</span></p>

        <div class="stat-grid">
          <div class="stat-card"><span>${escapeHtml(shell(text.statAnswered))}</span><strong>${summary.submitted}<small>/${summary.total}</small></strong></div>
          <div class="stat-card"><span>${escapeHtml(shell(text.statCorrect))}</span><strong>${summary.correct}<small>/${summary.total}</small></strong></div>
          <div class="stat-card"><span>${escapeHtml(shell(text.statStarted))}</span><strong>${summary.started}<small>/${DATASETS.length}</small></strong></div>
        </div>

        <div class="shell-cards">
          ${resumeCard}
          <article class="shell-card">
            <h2>${escapeHtml(shell(text.startTitle))}</h2>
            <p>${escapeHtml(shell(text.startBody))}</p>
            <a class="button ${resume ? 'button-secondary' : 'button-primary'}" href="${routeHash({ view: 'decks' })}">${escapeHtml(shell(text.startAction))}</a>
          </article>
          <article class="shell-card">
            <div class="shell-card-head"><h2>${escapeHtml(shell(text.importTitle))}</h2>${badge('android')}</div>
            <p>${escapeHtml(shell(text.importBody))}</p>
            <a class="button button-secondary" href="${routeHash({ view: 'import' })}" data-nav-route="import">${escapeHtml(shell(text.importAction))}</a>
          </article>
        </div>

        <section class="shell-section">
          <h2>${escapeHtml(shell(text.planTitle))}</h2>
          <p class="section-lead">${escapeHtml(shell(text.planBody))}</p>
          <ul class="plan-list">
            ${DATASETS.map((dataset) => {
              const state = datasetProgress(dataset.id);
              const submitted = submittedCountFor(dataset);
              const remaining = dataset.questions.length - submitted;
              const status = state.completed || remaining === 0
                ? escapeHtml(shell(text.planDone))
                : escapeHtml(formatCount(shell(text.planRemaining), { n: remaining }));
              return `
                <li>
                  <a class="plan-row" href="${routeHash({ view: 'decks', datasetId: dataset.id })}">
                    <span class="dataset-mark">${dataset.mark}</span>
                    <span class="plan-label">
                      <strong>${escapeHtml(textFor(dataset.title, locale()))}</strong>
                      <span>${submitted}/${dataset.questions.length} ${escapeHtml(translate('app.questions'))}</span>
                    </span>
                    <span class="plan-status${state.completed || remaining === 0 ? ' is-done' : ''}">${status}</span>
                    <span class="plan-arrow" aria-hidden="true">→</span>
                  </a>
                </li>`;
            }).join('')}
          </ul>
        </section>
      </section>`;
  }

  // The dataset chooser keeps the `welcome-view` class so the original quiz entry point, its styles,
  // and its regression coverage stay anchored to the same node inside the new shell.
  function renderDeckChooser() {
    content.innerHTML = `
      <section class="shell-view welcome-view" data-view="decks">
        <div class="welcome-heading">
          <p class="eyebrow">${escapeHtml(shell(SHELL_TEXT.decks.eyebrow))}</p>
          <h1>${escapeHtml(translate('app.chooseDataset'))}</h1>
          <p>${escapeHtml(translate('app.chooseDatasetBody'))}</p>
        </div>
        <div class="dataset-grid">
          ${DATASETS.map((dataset) => {
            const submitted = submittedCountFor(dataset);
            return `
            <button class="dataset-choice" type="button" data-select-dataset="${dataset.id}">
              <span class="dataset-mark">${dataset.mark}</span>
              <h2>${escapeHtml(textFor(dataset.title, locale()))}</h2>
              <p>${escapeHtml(textFor(dataset.summary, locale()))}</p>
              <footer>
                <span>${submitted}/${dataset.questions.length} ${escapeHtml(translate('app.questions'))}</span>
                <span aria-hidden="true">→</span>
              </footer>
            </button>`;
          }).join('')}
        </div>
        <p class="shell-scope shell-scope-footer">${badge('android')}<span>${escapeHtml(shell(SHELL_TEXT.decks.note))}</span></p>
      </section>`;
  }

  function renderAgent() {
    const text = SHELL_TEXT.agent;
    content.innerHTML = `
      <section class="shell-view" data-view="agent">
        ${viewHeading(shell(text.eyebrow), shell(text.title), shell(text.body))}
        <div class="shell-cards">
          <article class="shell-card shell-card-accent">
            <div class="shell-card-head">
              <h2>${escapeHtml(shell(text.tutorTitle))}</h2>
              ${badge('local')}
            </div>
            <p>${escapeHtml(shell(text.tutorBody))}</p>
            <p class="tutor-disclosure">${escapeHtml(translate('app.tutorDisclosure'))}</p>
            <a class="button button-primary" href="${routeHash({ view: 'decks' })}">${escapeHtml(shell(text.tutorAction))}</a>
          </article>
          <article class="shell-card">
            <div class="shell-card-head">
              <h2>${escapeHtml(shell(text.nativeTitle))}</h2>
              ${badge('android')}
            </div>
            <p>${escapeHtml(shell(text.nativeBody))}</p>
            ${scopeList([text.nativeTutor, text.nativeInterview, text.nativeTarget, text.nativeReview])}
          </article>
        </div>
      </section>`;
  }

  const SECTION_KIND_KEYS = { heading: 'kindHeading', preamble: 'kindPreamble', document: 'kindDocument' };

  /**
   * Renders imported passages as escaped text under a locator derived from the file name.
   *
   * These are deliberately not `.citation-item`s. A bundled citation has been checked against the
   * question it explains; an imported excerpt is only file text the browser happened to read.
   */
  function renderLocalSections(source) {
    return source.sections.map((section) => `
      <article class="local-section">
        <div class="local-section-locator">
          <span>${escapeHtml(sectionLocator(source, section))}</span>
          <span class="local-section-kind">${escapeHtml(shell(SHELL_TEXT.localLibrary[SECTION_KIND_KEYS[section.kind] ?? 'kindDocument']))}</span>
        </div>
        ${section.heading ? `<h4 class="local-section-heading">${escapeHtml(section.heading)}</h4>` : ''}
        ${section.excerpt ? `<p class="local-section-text">${escapeHtml(section.excerpt)}</p>` : ''}
      </article>`).join('');
  }

  function localSourceMeta(source) {
    const text = SHELL_TEXT.localLibrary;
    const parts = [formatCount(shell(text.sectionsLabel), { n: source.sections.length })];
    if (source.bytes) parts.push(formatBytes(source.bytes));
    const when = formatImportedAt(source.importedAt);
    if (when) parts.push(formatCount(shell(text.importedAt), { when }));
    return parts.join(' · ');
  }

  function renderRemoveConfirm(title, body, confirmLabel, confirmAttribute) {
    const text = SHELL_TEXT.localLibrary;
    return `
      <div class="local-confirm" role="group" aria-label="${escapeHtml(title)}">
        <p class="local-confirm-title"><strong>${escapeHtml(title)}</strong></p>
        <p class="local-confirm-body">${escapeHtml(body)}</p>
        <div class="card-actions">
          <button class="button button-danger" type="button" ${confirmAttribute}>${escapeHtml(confirmLabel)}</button>
          <button class="button button-secondary" type="button" data-cancel-remove>${escapeHtml(shell(text.removeCancelAction))}</button>
        </div>
      </div>`;
  }

  function renderLocalSource(source, index) {
    const text = SHELL_TEXT.localLibrary;
    const expanded = expandedSources.has(source.id);
    const regionId = `local-sections-${index}`;
    return `
      <article class="local-source" data-local-source="${escapeHtml(source.id)}">
        <div class="local-source-head">
          <div class="local-source-title">
            <strong>${escapeHtml(source.name)}</strong>
            <span>${escapeHtml(localSourceMeta(source))}</span>
          </div>
          <div class="local-source-actions">
            <button class="button button-secondary local-toggle" type="button" data-toggle-source="${escapeHtml(source.id)}" aria-expanded="${expanded}" aria-controls="${regionId}">
              ${escapeHtml(shell(expanded ? text.collapseAction : text.expandAction))}
            </button>
            <button class="button button-secondary local-remove" type="button" data-remove-source="${escapeHtml(source.id)}">${escapeHtml(shell(text.removeAction))}</button>
          </div>
        </div>
        ${source.truncated ? `<p class="local-truncated">${escapeHtml(formatCount(shell(SHELL_TEXT.importer.reviewTruncated), { n: LOCAL_IMPORT_LIMITS.maxSections }))}</p>` : ''}
        ${pendingDelete === source.id ? renderRemoveConfirm(
          formatCount(shell(text.removeConfirmTitle), { name: source.name }),
          shell(text.removeConfirmBody),
          shell(text.removeConfirmAction),
          `data-confirm-remove="${escapeHtml(source.id)}"`,
        ) : ''}
        ${expanded ? `<div id="${regionId}" class="local-section-list">${renderLocalSections(source)}</div>` : ''}
      </article>`;
  }

  function renderLocalLibrary() {
    const text = SHELL_TEXT.localLibrary;
    const head = `
      <div class="shell-card-head"><h2>${escapeHtml(shell(text.title))}</h2>${badge('local')}</div>
      <p class="section-lead">${escapeHtml(shell(text.body))}</p>`;

    if (!library.sources.length) {
      return `
        <section id="local-library" class="shell-section local-library" tabindex="-1">
          ${head}
          <p class="local-empty" data-local-empty>${escapeHtml(shell(text.empty))}</p>
          <a class="button button-secondary" href="${routeHash({ view: 'import' })}">${escapeHtml(shell(text.emptyAction))}</a>
        </section>`;
    }

    return `
      <section id="local-library" class="shell-section local-library" tabindex="-1">
        ${head}
        <div class="local-source-list">${library.sources.map(renderLocalSource).join('')}</div>
        <p class="tutor-disclosure local-no-ai">${escapeHtml(shell(text.noAi))}</p>
        <div class="local-reset">
          <h3>${escapeHtml(shell(text.resetTitle))}</h3>
          <p>${escapeHtml(shell(text.resetBody))}</p>
          ${pendingDelete === 'all' ? renderRemoveConfirm(
            shell(text.resetTitle),
            shell(text.resetBody),
            formatCount(shell(text.resetConfirmAction), { n: library.sources.length }),
            'data-confirm-reset-library',
          ) : `<button class="button button-secondary" type="button" data-reset-library>${escapeHtml(shell(text.resetAction))}</button>`}
        </div>
      </section>`;
  }

  function renderLibrary() {
    const text = SHELL_TEXT.library;
    const groups = collectSources();
    content.innerHTML = `
      <section class="shell-view" data-view="library">
        ${viewHeading(
          shell(text.eyebrow),
          shell(text.title),
          formatCount(shell(text.body), { n: countSources(), q: countQuestions() }),
        )}
        <p class="shell-scope">${badge('local')}<span>${escapeHtml(shell(SHELL_TEXT.browserScope))}</span></p>

        ${renderLocalLibrary()}

        <section class="shell-section bundled-library">
          <div class="shell-card-head"><h2>${escapeHtml(shell(text.bundledTitle))}</h2>${badge('local')}</div>
          <p class="section-lead">${escapeHtml(shell(text.bundledBody))}</p>
        </section>

        ${groups.map((group) => `
          <section class="source-group">
            <header class="source-group-head">
              <span class="dataset-mark">${group.mark}</span>
              <h2>${escapeHtml(textFor(group.title, locale()))}</h2>
              <a class="source-group-link" href="${routeHash({ view: 'decks', datasetId: group.id })}">${escapeHtml(shell(text.openDataset))}</a>
            </header>
            <div class="citation-list">
              ${group.excerpts.map((entry) => `
                <article class="citation-item">
                  <div class="citation-locator"><span>${escapeHtml(entry.locator)}</span><span class="source-kind">SOURCE</span></div>
                  <blockquote>${escapeHtml(textFor(entry.excerpt, locale()))}</blockquote>
                  <p class="citation-question"><span>${escapeHtml(shell(text.questionLabel))}</span>${escapeHtml(textFor(entry.prompt, locale()))}</p>
                </article>`).join('')}
            </div>
          </section>`).join('')}

        <p class="shell-scope shell-scope-footer">${badge('android')}<span>${escapeHtml(shell(SHELL_TEXT.sources.body))}</span></p>
        <a class="button button-secondary" href="${routeHash({ view: 'import' })}">${escapeHtml(shell(SHELL_TEXT.navImport))}</a>
      </section>`;
  }

  function renderProfile() {
    const text = SHELL_TEXT.profile;
    const summary = progressSummary();
    content.innerHTML = `
      <section class="shell-view" data-view="profile">
        ${viewHeading(shell(text.eyebrow), shell(text.title), shell(text.body))}

        <div class="stat-grid">
          <div class="stat-card"><span>${escapeHtml(shell(SHELL_TEXT.home.statAnswered))}</span><strong>${summary.submitted}<small>/${summary.total}</small></strong></div>
          <div class="stat-card"><span>${escapeHtml(shell(SHELL_TEXT.home.statCorrect))}</span><strong>${summary.correct}<small>/${summary.total}</small></strong></div>
          <div class="stat-card"><span>${escapeHtml(shell(SHELL_TEXT.home.statStarted))}</span><strong>${summary.started}<small>/${DATASETS.length}</small></strong></div>
        </div>

        <div class="shell-cards">
          <article class="shell-card">
            <div class="shell-card-head"><h2>${escapeHtml(shell(text.storageTitle))}</h2>${badge('local')}</div>
            <p>${escapeHtml(shell(text.storageBody))}</p>
          </article>
          <article class="shell-card">
            <div class="shell-card-head"><h2>${escapeHtml(shell(text.accountTitle))}</h2>${badge('local')}</div>
            <p>${escapeHtml(shell(text.accountBody))}</p>
          </article>
          <article class="shell-card">
            <h2>${escapeHtml(shell(text.languageTitle))}</h2>
            <p>${escapeHtml(shell(text.languageBody))}</p>
          </article>
          <article class="shell-card">
            <h2>${escapeHtml(shell(text.resetTitle))}</h2>
            <p>${escapeHtml(shell(text.resetBody))}</p>
            <button class="button button-secondary" type="button" data-reset-progress>${escapeHtml(translate('app.reset'))}</button>
          </article>
          <article class="shell-card">
            <div class="shell-card-head"><h2>${escapeHtml(shell(text.nativeTitle))}</h2>${badge('android')}</div>
            ${scopeList([text.nativeStreak, text.nativeSettings, text.nativeBackup])}
          </article>
        </div>
      </section>`;
  }

  /** Turns the current `importError` into localized copy. Returns '' when there is nothing to report. */
  function importErrorMessage() {
    if (!importError) return '';
    const text = SHELL_TEXT.importer;
    const kb = Math.round(LOCAL_IMPORT_LIMITS.maxBytes / 1024);
    switch (importError.reason) {
      case 'size':
        return formatCount(shell(text.errorSize), { size: formatBytes(importError.bytes ?? 0), kb });
      case 'empty':
        return shell(text.errorEmpty);
      case 'binary':
        return shell(text.errorBinary);
      case 'read':
        return shell(text.errorRead);
      case 'full':
        return formatCount(shell(text.errorFull), { sources: LOCAL_IMPORT_LIMITS.maxSources });
      case 'storage':
        return shell(text.errorStorage);
      default:
        return shell(text.errorType);
    }
  }

  function renderImportPicker() {
    const text = SHELL_TEXT.importer;
    const error = importErrorMessage();
    const describedBy = ['import-limits', error ? 'import-error' : ''].filter(Boolean).join(' ');
    const limits = formatCount(shell(text.limits), {
      kb: Math.round(LOCAL_IMPORT_LIMITS.maxBytes / 1024),
      sources: LOCAL_IMPORT_LIMITS.maxSources,
    });
    return `
      <section class="shell-section import-panel">
        <h2>${escapeHtml(shell(text.pickTitle))}</h2>
        <p class="section-lead">${escapeHtml(shell(text.pickBody))}</p>
        <div class="import-drop" data-import-drop>
          <input id="import-file" class="import-file" type="file" data-import-input
            accept=".md,.markdown,.txt,text/markdown,text/plain" aria-describedby="${describedBy}">
          <label class="import-drop-label" for="import-file">
            ${navIcon('import')}
            <strong>${escapeHtml(shell(text.pickAction))}</strong>
            <span>${escapeHtml(shell(text.dropHint))}</span>
          </label>
        </div>
        <p id="import-limits" class="import-limits">${escapeHtml(limits)}</p>
        ${error ? `<p id="import-error" class="import-error" role="alert" data-import-error>${escapeHtml(error)}</p>` : ''}
      </section>`;
  }

  /** The review step. Rendered from the in-memory draft only, so nothing here has been stored yet. */
  function renderImportReview() {
    if (!importDraft) return '';
    const text = SHELL_TEXT.importer;
    const source = importDraft.source;
    const truncated = source.truncated
      ? `<p class="local-truncated">${escapeHtml(formatCount(shell(text.reviewTruncated), { n: LOCAL_IMPORT_LIMITS.maxSections }))}</p>`
      : '';
    return `
      <article class="shell-card shell-card-accent import-review" data-import-review>
        <div class="shell-card-head"><h2>${escapeHtml(shell(text.reviewTitle))}</h2>${badge('local')}</div>
        <p>${escapeHtml(shell(text.reviewBody))}</p>
        <dl class="import-meta">
          <div><dt>${escapeHtml(shell(text.metaFile))}</dt><dd data-review-name>${escapeHtml(source.name)}</dd></div>
          <div><dt>${escapeHtml(shell(text.metaSize))}</dt><dd>${escapeHtml(formatBytes(source.bytes))}</dd></div>
          <div><dt>${escapeHtml(shell(text.metaSections))}</dt><dd data-review-sections>${escapeHtml(formatCount(shell(text.reviewSections), { n: source.sections.length }))}</dd></div>
        </dl>
        ${truncated}
        <div class="local-section-list">${renderLocalSections(source)}</div>
        <div class="card-actions">
          <button class="button button-primary" type="button" data-import-confirm>${escapeHtml(shell(text.confirmAction))}</button>
          <button class="button button-secondary" type="button" data-import-cancel>${escapeHtml(shell(text.cancelAction))}</button>
        </div>
      </article>`;
  }

  /** Post-save confirmation, replaced by the picker again as soon as another file is selected. */
  function renderImportSaved() {
    if (!importSaved) return '';
    const text = SHELL_TEXT.importer;
    const body = formatCount(shell(text.savedBody), { name: importSaved.name, n: importSaved.sectionCount });
    return `
      <article class="shell-card shell-card-accent import-saved" data-import-saved>
        <div class="shell-card-head"><h2>${escapeHtml(shell(text.savedTitle))}</h2>${badge('local')}</div>
        <p>${escapeHtml(body)}</p>
        <a class="button button-primary" href="${routeHash({ view: 'library' })}">${escapeHtml(shell(text.savedAction))}</a>
      </article>`;
  }

  function renderImport() {
    const text = SHELL_TEXT.sources;
    const importer = SHELL_TEXT.importer;
    const steps = [
      ['workflow.importTitle', 'workflow.importBody'],
      ['workflow.generateTitle', 'workflow.generateBody'],
      ['workflow.verifyTitle', 'workflow.verifyBody'],
      ['workflow.reviewTitle', 'workflow.reviewBody'],
    ];
    content.innerHTML = `
      <section class="shell-view" data-view="import">
        ${viewHeading(shell(text.eyebrow), shell(text.title), shell(text.body))}
        <p class="shell-scope">${badge('local')}<span>${escapeHtml(shell(SHELL_TEXT.browserScope))}</span></p>

        ${renderImportSaved()}
        ${renderImportPicker()}
        ${renderImportReview()}

        <div class="shell-cards">
          <article class="shell-card import-no-ai">
            <div class="shell-card-head"><h2>${escapeHtml(shell(importer.noAiTitle))}</h2>${badge('android')}</div>
            <p>${escapeHtml(shell(importer.noAiBody))}</p>
            <div class="card-actions">
              <a class="button button-secondary" href="../#native-app">${escapeHtml(shell(text.productAction))}</a>
            </div>
          </article>
          <article class="shell-card">
            <div class="shell-card-head"><h2>${escapeHtml(shell(text.nativeTitle))}</h2>${badge('android')}</div>
            <p>${escapeHtml(shell(text.nativeBody))}</p>
          </article>
          <article class="shell-card shell-card-accent">
            <div class="shell-card-head"><h2>${escapeHtml(shell(SHELL_TEXT.privacy.title))}</h2>${badge('local')}</div>
            <p>${escapeHtml(shell(SHELL_TEXT.privacy.body))}</p>
            <a class="button button-primary" href="${routeHash({ view: 'decks' })}">${escapeHtml(shell(text.demoAction))}</a>
          </article>
        </div>

        <section class="shell-section">
          <h2>${escapeHtml(shell(text.loopTitle))}</h2>
          <ol class="loop-list">
            ${steps.map(([title, body], index) => `
              <li>
                <span class="loop-index">${index + 1}</span>
                <div><strong>${escapeHtml(translate(title))}</strong><p>${escapeHtml(translate(body))}</p></div>
              </li>`).join('')}
          </ol>
        </section>
      </section>`;
  }

  function questionKindLabel(type) {
    const labels = {
      single: { en: 'Single choice', zh: '单选题' },
      multiple: { en: 'Multiple choice', zh: '多选题' },
      boolean: { en: 'True / false', zh: '判断题' },
    };
    return labels[type][locale()];
  }

  function questionInstruction(type) {
    return translate(type === 'multiple' ? 'app.selectMany' : type === 'boolean' ? 'app.trueFalse' : 'app.selectOne');
  }

  function questionCounter(index, total) {
    return locale() === 'zh'
      ? `${translate('app.question')} ${index + 1} ${translate('app.of')} ${total}`
      : `${translate('app.question')} ${index + 1} ${translate('app.of')} ${total}`;
  }

  function renderFeedback(question, state) {
    if (!state.submitted[question.id]) return '';
    const selected = state.answers[question.id] ?? [];
    const correct = isCorrect(question, selected);
    const tutorOpen = openTutorQuestions.has(question.id);
    return `
      <section class="feedback-panel" aria-live="polite">
        <div class="feedback-status${correct ? '' : ' is-incorrect'}">
          <span aria-hidden="true">${correct ? '✓' : '!'}</span>
          <strong>${escapeHtml(translate(correct ? 'app.correct' : 'app.incorrect'))}</strong>
        </div>
        <div class="explanation-block">
          <h2>${escapeHtml(translate('app.explanation'))}</h2>
          <p>${escapeHtml(textFor(question.explanation, locale()))}</p>
        </div>
        <div class="citation-section">
          <h2>${escapeHtml(translate('app.sourceEvidence'))}</h2>
          <div class="citation-list">
            ${question.citations.map((citation) => `
              <article class="citation-item">
                <div class="citation-locator"><span>${escapeHtml(citation.locator)}</span><span class="source-kind">SOURCE</span></div>
                <blockquote>${escapeHtml(textFor(citation.excerpt, locale()))}</blockquote>
              </article>`).join('')}
          </div>
        </div>
        <button class="button button-secondary tutor-trigger" type="button" data-toggle-tutor="${question.id}" aria-expanded="${tutorOpen}" aria-controls="tutor-${escapeHtml(question.id)}">${escapeHtml(translate('app.tutor'))}</button>
        ${tutorOpen ? `
          <aside id="tutor-${escapeHtml(question.id)}" class="tutor-panel" aria-label="${escapeHtml(translate('app.tutorPanel'))}">
            <h2>${escapeHtml(translate('app.tutorLabel'))}</h2>
            <p class="tutor-disclosure">${escapeHtml(translate('app.tutorDisclosure'))}</p>
            <ul>${question.tutorHints.map((hint) => `<li>${escapeHtml(textFor(hint, locale()))}</li>`).join('')}</ul>
          </aside>` : ''}
      </section>`;
  }

  function deckBreadcrumb() {
    return `
      <p class="view-breadcrumb">
        <a href="${routeHash({ view: 'decks' })}" data-nav-route="decks">
          <span aria-hidden="true">←</span>${escapeHtml(shell(SHELL_TEXT.backToDecks))}
        </a>
      </p>`;
  }

  function renderQuiz(dataset) {
    const state = datasetProgress(dataset.id);
    if (state.completed) {
      renderCompletion(dataset, state);
      return;
    }

    const question = dataset.questions[state.currentIndex];
    const selected = state.answers[question.id] ?? [];
    const submitted = state.submitted[question.id] === true;
    const submittedCount = Object.values(state.submitted).filter(Boolean).length;
    const score = scoreDataset(dataset, state);
    const inputType = question.type === 'multiple' ? 'checkbox' : 'radio';
    const options = question.options.map((option) => {
      const checked = selected.includes(option.id);
      const classes = ['answer-option'];
      if (submitted && question.correct.includes(option.id)) classes.push('is-correct');
      if (submitted && checked && !question.correct.includes(option.id)) classes.push('is-incorrect');
      return `
        <label class="${classes.join(' ')}">
          <input type="${inputType}" name="answer" value="${option.id}" ${checked ? 'checked' : ''} ${submitted ? 'disabled' : ''}>
          <span>${escapeHtml(textFor(option.label, locale()))}</span>
        </label>`;
    }).join('');

    content.innerHTML = `
      <section class="quiz-view">
        ${deckBreadcrumb()}
        <header class="quiz-header">
          <div><h1>${escapeHtml(textFor(dataset.title, locale()))}</h1><p>${escapeHtml(textFor(dataset.summary, locale()))}</p></div>
          <div class="score-block"><span>${escapeHtml(translate('app.score'))}</span><strong>${score}/${dataset.questions.length}</strong></div>
          <div class="progress-track" role="progressbar" aria-label="${escapeHtml(translate('app.progress'))}" aria-valuemin="0" aria-valuemax="${dataset.questions.length}" aria-valuenow="${submittedCount}">
            <div class="progress-bar progress-step-${submittedCount}"></div>
          </div>
        </header>
        <article class="question-panel">
          <div class="question-meta">
            <span class="question-kind">${escapeHtml(questionKindLabel(question.type))}</span>
            <span class="question-index">${escapeHtml(questionCounter(state.currentIndex, dataset.questions.length))}</span>
          </div>
          <h2 class="question-title">${escapeHtml(textFor(question.prompt, locale()))}</h2>
          <p class="question-instruction">${escapeHtml(questionInstruction(question.type))}</p>
          <fieldset class="answer-list" aria-label="${escapeHtml(questionInstruction(question.type))}">${options}</fieldset>
          <div class="question-actions">
            <button class="button button-secondary" type="button" data-previous ${state.currentIndex === 0 ? 'disabled' : ''}>${escapeHtml(translate('app.previous'))}</button>
            <div class="action-group">
              ${submitted ? `<button class="button button-primary" type="button" data-next>${escapeHtml(translate(state.currentIndex === dataset.questions.length - 1 ? 'app.finish' : 'app.next'))}</button>` : `<button class="button button-primary" type="button" data-submit ${selected.length ? '' : 'disabled'}>${escapeHtml(translate('app.submit'))}</button>`}
            </div>
          </div>
          ${renderFeedback(question, state)}
        </article>
      </section>`;
  }

  function renderCompletion(dataset, state) {
    const score = scoreDataset(dataset, state);
    content.innerHTML = `
      <section class="completion-view">
        <div class="completion-inner">
          ${deckBreadcrumb()}
          <p class="eyebrow">${escapeHtml(textFor(dataset.title, locale()))}</p>
          <h1>${escapeHtml(translate('app.completed'))}</h1>
          <p>${escapeHtml(translate('app.completedBody'))}</p>
          <div class="completion-score"><strong>${score}</strong><span>/ ${dataset.questions.length}</span></div>
          <div class="completion-actions">
            <button class="button button-primary" type="button" data-review>${escapeHtml(translate('app.reviewAgain'))}</button>
            <button class="button button-secondary" type="button" data-choose-another>${escapeHtml(translate('app.chooseAnother'))}</button>
          </div>
        </div>
      </section>`;
  }

  const SURFACES = {
    home: renderHome,
    agent: renderAgent,
    library: renderLibrary,
    profile: renderProfile,
    import: renderImport,
  };

  function render() {
    route = parseRoute(window.location.hash);

    // A bare, unknown, or unresolvable hash resolves to a real route, so the address stays
    // copyable and reloadable. `replaceState` avoids both a history entry and a reload.
    const canonicalHash = routeHash(route);
    if (window.location.hash !== canonicalHash) window.history.replaceState(null, '', canonicalHash);

    renderNavigation();
    renderDatasetList();
    document.body.dataset.view = route.view;

    if (route.view === 'decks') {
      const dataset = getDataset(route.datasetId);
      if (dataset) {
        // The route is the only writer of the resume hint, so opening a deck from a link, a deep
        // link, or a reload all keep Home's continue card pointing at the last deck actually seen.
        if (progress.activeDatasetId !== dataset.id) {
          progress.activeDatasetId = dataset.id;
          datasetProgress(dataset.id);
          saveProgress(progress);
        }
        renderQuiz(dataset);
      } else {
        renderDeckChooser();
      }
      return;
    }
    (SURFACES[route.view] ?? renderHome)();
  }

  function selectDataset(datasetId) {
    if (!getDataset(datasetId)) return;
    setSidebarOpen(false);
    if (!navigate({ view: 'decks', datasetId })) render();
    content?.focus();
  }

  function currentContext() {
    const dataset = getDataset(route.datasetId);
    if (!dataset) return null;
    const state = datasetProgress(dataset.id);
    return { dataset, state, question: dataset.questions[state.currentIndex] };
  }

  function importFailed(reason, bytes) {
    importDraft = null;
    importError = { reason, bytes };
    rerender({ focus: '[data-import-input]' });
  }

  /**
   * Validates and parses one picked or dropped file into a review draft. Nothing reaches storage here:
   * the draft keeps the raw text so the record can be rebuilt at confirm time with a real timestamp.
   */
  async function handleFileSelection(file) {
    if (!file) return;
    importSaved = null;
    const check = validateImportCandidate(file, { sourceCount: library.sources.length });
    if (!check.ok) {
      importFailed(check.reason, file.size);
      return;
    }

    // Reads are async, so a second pick while the first is in flight would otherwise race. Only the
    // newest token is allowed to publish its result.
    readToken += 1;
    const token = readToken;
    let text;
    try {
      text = await file.text();
    } catch {
      if (token === readToken) importFailed('read', file.size);
      return;
    }
    if (token !== readToken) return;

    if (looksBinary(text)) {
      importFailed('binary', file.size);
      return;
    }
    const source = createLocalSource({ name: file.name, size: file.size, text, existingIds: library.sources.map((entry) => entry.id) });
    if (!source.sections.length) {
      importFailed('empty', file.size);
      return;
    }

    importError = null;
    importDraft = { source, text };
    rerender({
      focus: '[data-import-confirm]',
      message: formatCount(shell(SHELL_TEXT.importer.announceReview), { name: source.name }),
    });
  }

  /** Handles the import surface's own controls. Returns true when the click was consumed. */
  function handleImportClick(event) {
    if (event.target.closest('[data-import-confirm]')) {
      if (!importDraft) return true;
      // Rebuilt at confirm time so the stored timestamp is when the learner agreed to save, and so the
      // id is unique against the library as it stands now rather than as it stood during review.
      const source = createLocalSource({
        name: importDraft.source.name,
        size: importDraft.source.bytes,
        text: importDraft.text,
        existingIds: library.sources.map((entry) => entry.id),
      });
      const next = { ...library, sources: [source, ...library.sources] };
      if (!saveLibrary(next)) {
        // Keep the draft: the learner can free space and confirm again.
        importError = { reason: 'storage' };
        rerender({ focus: '[data-import-error]' });
        return true;
      }
      library = next;
      importDraft = null;
      importError = null;
      importSaved = { name: source.name, sectionCount: source.sections.length };
      rerender({
        focus: '[data-import-saved] .button',
        message: formatCount(shell(SHELL_TEXT.importer.announceSaved), { name: source.name, n: source.sections.length }),
      });
      return true;
    }

    if (event.target.closest('[data-import-cancel]')) {
      importDraft = null;
      importError = null;
      readToken += 1;
      rerender({ focus: '[data-import-input]' });
      return true;
    }
    return false;
  }

  /** Handles the browser library's expand, remove, and reset controls. Returns true when consumed. */
  function handleLocalLibraryClick(event) {
    const toggle = event.target.closest('[data-toggle-source]');
    if (toggle) {
      const id = toggle.dataset.toggleSource;
      if (expandedSources.has(id)) expandedSources.delete(id);
      else expandedSources.add(id);
      rerender({ focus: () => localSourceNode(id)?.querySelector('[data-toggle-source]') });
      return true;
    }

    const remove = event.target.closest('[data-remove-source]');
    if (remove) {
      pendingDelete = remove.dataset.removeSource;
      rerender({ focus: () => localSourceNode(pendingDelete)?.querySelector('[data-confirm-remove]') });
      return true;
    }

    if (event.target.closest('[data-reset-library]')) {
      pendingDelete = 'all';
      rerender({ focus: '[data-confirm-reset-library]' });
      return true;
    }

    if (event.target.closest('[data-cancel-remove]')) {
      const id = pendingDelete;
      pendingDelete = null;
      rerender({
        focus: () => (id === 'all'
          ? document.querySelector('[data-reset-library]')
          : localSourceNode(id)?.querySelector('[data-remove-source]')),
      });
      return true;
    }

    const confirmRemove = event.target.closest('[data-confirm-remove]');
    if (confirmRemove) {
      const id = confirmRemove.dataset.confirmRemove;
      const source = library.sources.find((entry) => entry.id === id);
      pendingDelete = null;
      if (!source) {
        rerender();
        return true;
      }
      // Scoped to this id only. Every other imported source and all bundled data is untouched.
      library = { ...library, sources: library.sources.filter((entry) => entry.id !== id) };
      expandedSources.delete(id);
      saveLibrary(library);
      importSaved = null;
      rerender({
        focus: '#local-library',
        message: formatCount(shell(SHELL_TEXT.localLibrary.announceRemoved), { name: source.name }),
      });
      return true;
    }

    if (event.target.closest('[data-confirm-reset-library]')) {
      const removed = library.sources.length;
      pendingDelete = null;
      library = createEmptyLibrary();
      expandedSources.clear();
      importSaved = null;
      try {
        globalThis.localStorage?.removeItem(LOCAL_LIBRARY_STORAGE_KEY);
      } catch {
        // Reset remains effective for the active session.
      }
      rerender({
        focus: '#local-library',
        message: formatCount(shell(SHELL_TEXT.localLibrary.announceReset), { n: removed }),
      });
      return true;
    }
    return false;
  }

  document.addEventListener('change', (event) => {
    const fileInput = event.target.closest('[data-import-input]');
    if (fileInput) {
      const file = fileInput.files?.[0] ?? null;
      // Clearing the value lets the same file be picked again after a discard or a rejection.
      fileInput.value = '';
      handleFileSelection(file);
      return;
    }

    const input = event.target.closest('input[name="answer"]');
    const context = currentContext();
    if (!input || !context || context.state.submitted[context.question.id]) return;
    const current = new Set(context.state.answers[context.question.id] ?? []);
    if (context.question.type === 'multiple') {
      if (input.checked) current.add(input.value);
      else current.delete(input.value);
    } else {
      current.clear();
      current.add(input.value);
    }
    context.state.answers[context.question.id] = [...current];
    saveProgress(progress);
    const submit = document.querySelector('[data-submit]');
    if (submit) submit.disabled = current.size === 0;
  });

  document.addEventListener('click', (event) => {
    const datasetButton = event.target.closest('[data-select-dataset]');
    if (datasetButton) {
      selectDataset(datasetButton.dataset.selectDataset);
      return;
    }

    if (event.target.closest('[data-reset-progress]')) {
      // Deliberately scoped to the quiz key. Imported sources are the learner's own material and are
      // only removed through the library's own reset control.
      progress = createInitialProgress();
      openTutorQuestions.clear();
      try {
        globalThis.localStorage?.removeItem(PROGRESS_STORAGE_KEY);
      } catch {
        // Reset remains effective for the active session.
      }
      setSidebarOpen(false);
      if (!navigate(route.datasetId ? { view: 'decks' } : route)) render();
      announce(translate('app.progressReset'));
      return;
    }

    if (handleImportClick(event) || handleLocalLibraryClick(event)) return;

    const context = currentContext();
    if (event.target.closest('[data-submit]') && context) {
      const answer = context.state.answers[context.question.id] ?? [];
      if (!answer.length) return;
      context.state.submitted[context.question.id] = true;
      announce(translate(isCorrect(context.question, answer) ? 'app.correct' : 'app.incorrect'));
      persistAndRender();
      return;
    }

    if (event.target.closest('[data-previous]') && context) {
      context.state.currentIndex = Math.max(0, context.state.currentIndex - 1);
      persistAndRender();
      content?.focus();
      return;
    }

    if (event.target.closest('[data-next]') && context) {
      if (context.state.currentIndex === context.dataset.questions.length - 1) context.state.completed = true;
      else context.state.currentIndex += 1;
      persistAndRender();
      content?.focus();
      return;
    }

    const tutorButton = event.target.closest('[data-toggle-tutor]');
    if (tutorButton) {
      const questionId = tutorButton.dataset.toggleTutor;
      if (openTutorQuestions.has(questionId)) openTutorQuestions.delete(questionId);
      else openTutorQuestions.add(questionId);
      render();
      document.querySelector(`[data-toggle-tutor="${questionId}"]`)?.focus();
      return;
    }

    if (event.target.closest('[data-review]') && context) {
      context.state.currentIndex = 0;
      context.state.completed = false;
      persistAndRender();
      content?.focus();
      return;
    }

    if (event.target.closest('[data-choose-another]')) {
      progress.activeDatasetId = null;
      saveProgress(progress);
      if (!navigate({ view: 'decks' })) render();
      content?.focus();
    }
  });

  // Drag events are cancelled document-wide: without this the browser navigates to the dropped file and
  // the demo is gone. Only a drop that lands inside the zone is treated as an import.
  document.addEventListener('dragover', (event) => {
    if (!event.dataTransfer?.types?.includes('Files')) return;
    event.preventDefault();
    event.target.closest?.('[data-import-drop]')?.classList.add('is-dragging');
  });

  document.addEventListener('dragleave', (event) => {
    event.target.closest?.('[data-import-drop]')?.classList.remove('is-dragging');
  });

  document.addEventListener('drop', (event) => {
    const zone = event.target.closest?.('[data-import-drop]');
    if (!event.dataTransfer?.files?.length && !zone) return;
    event.preventDefault();
    document.querySelector('[data-import-drop]')?.classList.remove('is-dragging');
    if (zone) handleFileSelection(event.dataTransfer?.files?.[0] ?? null);
  });

  document.querySelectorAll('[data-locale]').forEach((button) => {
    button.addEventListener('click', () => setLocale(button.dataset.locale));
  });

  menuButton?.addEventListener('click', () => setSidebarOpen(menuButton.getAttribute('aria-expanded') !== 'true'));
  closeButton?.addEventListener('click', () => setSidebarOpen(false));

  window.addEventListener('anchor:localechange', render);
  window.addEventListener('hashchange', () => {
    setSidebarOpen(false);
    // A half-answered confirmation should not be waiting when the learner comes back to a surface.
    pendingDelete = null;
    importError = null;
    render();
    content?.focus();
  });
  window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') setSidebarOpen(false);
  });

  const dataErrors = validateDatasets();
  if (dataErrors.length) {
    console.error('Anchor demo data validation failed', dataErrors);
    progress = createInitialProgress();
  }

  initializeLocale();
  render();
}
