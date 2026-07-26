import { getLocale, initializeLocale, setLocale, translate } from '../../scripts/i18n.js?v=20260727-2';
import { DATA_VERSION, DATASETS, getDataset, textFor, validateDatasets } from './data.js';

export const PROGRESS_STORAGE_KEY = 'anchor.demo.progress.v1';

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

if (typeof document !== 'undefined') {
  const content = document.querySelector('#app-content');
  const datasetList = document.querySelector('#dataset-list');
  const announcer = document.querySelector('#app-announcer');
  const sidebar = document.querySelector('#dataset-sidebar');
  const menuButton = document.querySelector('#dataset-menu-button');
  const closeButton = document.querySelector('#dataset-menu-close');
  const resetButton = document.querySelector('#reset-progress');
  let progress = loadProgress();
  const openTutorQuestions = new Set();

  function locale() {
    return getLocale();
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

  function renderDatasetList() {
    if (!datasetList) return;
    datasetList.innerHTML = DATASETS.map((dataset) => {
      const state = datasetProgress(dataset.id);
      const submitted = Object.values(state.submitted).filter(Boolean).length;
      return `
        <button class="dataset-button" type="button" data-select-dataset="${dataset.id}" aria-current="${progress.activeDatasetId === dataset.id ? 'page' : 'false'}">
          <span class="dataset-mark">${dataset.mark}</span>
          <span class="dataset-label">
            <strong>${escapeHtml(textFor(dataset.title, locale()))}</strong>
            <span>${dataset.questions.length} ${escapeHtml(translate('app.questions'))}</span>
          </span>
          <span class="dataset-progress">${submitted}/${dataset.questions.length}</span>
        </button>`;
    }).join('');
  }

  function renderWelcome() {
    content.innerHTML = `
      <section class="welcome-view">
        <div class="welcome-heading">
          <p class="eyebrow">ANCHOR DEMO</p>
          <h1>${escapeHtml(translate('app.chooseDataset'))}</h1>
          <p>${escapeHtml(translate('app.chooseDatasetBody'))}</p>
        </div>
        <div class="dataset-grid">
          ${DATASETS.map((dataset) => `
            <button class="dataset-choice" type="button" data-select-dataset="${dataset.id}">
              <span class="dataset-mark">${dataset.mark}</span>
              <h2>${escapeHtml(textFor(dataset.title, locale()))}</h2>
              <p>${escapeHtml(textFor(dataset.summary, locale()))}</p>
              <footer><span>${dataset.questions.length} ${escapeHtml(translate('app.questions'))}</span><span aria-hidden="true">→</span></footer>
            </button>`).join('')}
        </div>
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

  function render() {
    renderDatasetList();
    const dataset = getDataset(progress.activeDatasetId);
    if (dataset) renderQuiz(dataset);
    else renderWelcome();
  }

  function selectDataset(datasetId) {
    if (!getDataset(datasetId)) return;
    progress.activeDatasetId = datasetId;
    datasetProgress(datasetId);
    setSidebarOpen(false);
    persistAndRender();
    content?.focus();
  }

  function currentContext() {
    const dataset = getDataset(progress.activeDatasetId);
    if (!dataset) return null;
    const state = datasetProgress(dataset.id);
    return { dataset, state, question: dataset.questions[state.currentIndex] };
  }

  document.addEventListener('change', (event) => {
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
      persistAndRender();
      content?.focus();
    }
  });

  document.querySelectorAll('[data-locale]').forEach((button) => {
    button.addEventListener('click', () => setLocale(button.dataset.locale));
  });

  menuButton?.addEventListener('click', () => setSidebarOpen(menuButton.getAttribute('aria-expanded') !== 'true'));
  closeButton?.addEventListener('click', () => setSidebarOpen(false));
  resetButton?.addEventListener('click', () => {
    progress = createInitialProgress();
    openTutorQuestions.clear();
    try {
      globalThis.localStorage?.removeItem(PROGRESS_STORAGE_KEY);
    } catch {
      // Reset remains effective for the active session.
    }
    render();
    announce(translate('app.progressReset'));
  });

  window.addEventListener('anchor:localechange', render);
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
