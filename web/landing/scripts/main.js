import { initializeLocale, setLocale, translate } from './i18n.js';

function setMenuState(open) {
  const button = document.querySelector('.menu-button');
  const navigation = document.querySelector('.primary-nav');
  if (!button || !navigation) return;
  button.setAttribute('aria-expanded', String(open));
  button.setAttribute('aria-label', translate(open ? 'a11y.closeMenu' : 'a11y.openMenu'));
  navigation.classList.toggle('is-open', open);
}

function initializeNavigation() {
  const button = document.querySelector('.menu-button');
  const navigation = document.querySelector('.primary-nav');
  if (!button || !navigation) return;

  button.addEventListener('click', () => {
    setMenuState(button.getAttribute('aria-expanded') !== 'true');
  });

  navigation.addEventListener('click', (event) => {
    if (event.target instanceof HTMLAnchorElement) setMenuState(false);
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
      setMenuState(false);
      button.focus();
    }
  });
}

function initializeLocaleButtons() {
  document.querySelectorAll('[data-locale]').forEach((button) => {
    button.addEventListener('click', () => {
      setLocale(button.dataset.locale);
      setMenuState(false);
    });
  });
}

function initializeCopyCommand() {
  const button = document.querySelector('[data-copy]');
  if (!button) return;

  button.addEventListener('click', async () => {
    const label = button.querySelector('.copy-label');
    try {
      await navigator.clipboard.writeText(button.dataset.copy ?? '');
      if (label) label.textContent = translate('actions.copied');
    } catch {
      if (label) label.textContent = translate('actions.copyFailed');
    }
    window.setTimeout(() => {
      if (label) label.textContent = translate('actions.copyInstall');
    }, 1800);
  });
}

initializeLocale();
initializeLocaleButtons();
initializeNavigation();
initializeCopyCommand();
