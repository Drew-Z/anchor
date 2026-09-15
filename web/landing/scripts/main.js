import { initializeLocale, setLocale, translate } from './i18n.js';

/** Controls a keyboard can reach, in document order. */
const FOCUSABLE = 'a[href], button:not([disabled]), [tabindex]:not([tabindex="-1"])';

/**
 * The control that opened the mobile menu, so dismissing it can hand focus back. Null whenever the menu is
 * closed, which is also how a close tells a real dismissal from the repeated `setMenuState(false)` calls
 * that choosing a link or a language makes.
 */
let menuReturnFocus = null;

/**
 * True while the navigation is a panel behind the trigger rather than a row in the header. The trigger is
 * only displayed at that breakpoint, so asking whether it is on screen keeps the breakpoint itself in the
 * stylesheet instead of repeating the width here.
 */
function panelMode(button) {
  return (button?.getClientRects().length ?? 0) > 0;
}

function menuIsOpen(navigation) {
  return navigation?.classList.contains('is-open') === true;
}

/** The links a keyboard can reach inside the open panel, in document order. */
function menuFocusables(navigation) {
  const nodes = navigation?.querySelectorAll(FOCUSABLE) ?? [];
  return [...nodes].filter((node) => node.getClientRects().length > 0);
}

/**
 * Opens or closes the navigation. As a panel it is modal over a scrim, so opening moves focus inside it and
 * a dismissal hands focus back to whatever opened it. A close that comes from choosing a link or a language
 * passes `restoreFocus: false`: that choice already put focus where the reader asked for it, and the
 * trigger would only take it straight back. Desktop is untouched, where the navigation is a header row with
 * no scrim and nothing to open or close.
 */
function setMenuState(open, { restoreFocus = true } = {}) {
  const button = document.querySelector('.menu-button');
  const navigation = document.querySelector('.primary-nav');
  const scrim = document.querySelector('.nav-scrim');
  if (!button || !navigation) return;
  const wasOpen = menuIsOpen(navigation);

  button.setAttribute('aria-expanded', String(open));
  button.setAttribute('aria-label', translate(open ? 'a11y.closeMenu' : 'a11y.openMenu'));
  navigation.classList.toggle('is-open', open);
  if (scrim) scrim.hidden = !open;

  if (!panelMode(button)) {
    menuReturnFocus = null;
    return;
  }
  if (open && !wasOpen) {
    const opener = document.activeElement;
    // The trigger is the way in, and a browser that does not focus a clicked button leaves the active
    // element somewhere the reader never asked to return to, so that falls back to the trigger.
    menuReturnFocus = opener instanceof HTMLElement && !navigation.contains(opener) && opener.matches(FOCUSABLE)
      ? opener
      : button;
    menuFocusables(navigation)[0]?.focus();
    return;
  }
  if (!open && wasOpen) {
    const opener = menuReturnFocus;
    menuReturnFocus = null;
    if (restoreFocus) (opener?.isConnected ? opener : button).focus();
  }
}

function initializeNavigation() {
  const button = document.querySelector('.menu-button');
  const navigation = document.querySelector('.primary-nav');
  const scrim = document.querySelector('.nav-scrim');
  if (!button || !navigation) return;

  button.addEventListener('click', () => {
    setMenuState(button.getAttribute('aria-expanded') !== 'true');
  });

  navigation.addEventListener('click', (event) => {
    // Choosing a destination is not a dismissal: the reader has moved on to that section, so focus stays
    // with the link they picked rather than returning to the trigger.
    if (event.target instanceof HTMLAnchorElement) setMenuState(false, { restoreFocus: false });
  });

  // A click on the scrim is a click at the page the panel is covering: treat it as a dismissal.
  scrim?.addEventListener('click', () => setMenuState(false));

  document.addEventListener('keydown', (event) => {
    // An open panel is modal: the scrim covers the page, so Tab stays inside it rather than walking onto
    // links the reader cannot see or click.
    if (event.key === 'Tab' && menuIsOpen(navigation) && panelMode(button)) {
      const focusables = menuFocusables(navigation);
      const first = focusables[0];
      const last = focusables[focusables.length - 1];
      const active = document.activeElement;
      if (first && (active === (event.shiftKey ? first : last) || !navigation.contains(active))) {
        event.preventDefault();
        (event.shiftKey ? last : first).focus();
      }
      return;
    }

    // Only an open panel has anything to dismiss, and `setMenuState` keeps a closed one from moving focus.
    if (event.key === 'Escape') setMenuState(false);
  });
}

function initializeLocaleButtons() {
  document.querySelectorAll('[data-locale]').forEach((button) => {
    button.addEventListener('click', () => {
      setLocale(button.dataset.locale);
      // A language choice leaves focus on the switch that made it, so the reader can change their mind.
      setMenuState(false, { restoreFocus: false });
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
