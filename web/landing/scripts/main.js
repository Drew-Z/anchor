// Anchor Learning - Landing Page Scripts

// ========== GitHub Stars Fetcher ==========
async function fetchGitHubStars() {
  try {
    const response = await fetch('https://api.github.com/repos/Drew-Z/anchor');
    if (response.ok) {
      const data = await response.json();
      const starsElement = document.getElementById('github-stars');
      if (starsElement) {
        starsElement.textContent = `${data.stargazers_count} stars`;
      }
    }
  } catch (error) {
    console.error('Failed to fetch GitHub stars:', error);
  }
}

// ========== Mobile Menu Toggle ==========
function initMobileMenu() {
  const toggle = document.querySelector('.mobile-menu-toggle');
  const navLinks = document.querySelector('.nav-links');

  if (toggle && navLinks) {
    toggle.addEventListener('click', () => {
      navLinks.classList.toggle('active');
      toggle.classList.toggle('active');
    });

    // Close menu when clicking outside
    document.addEventListener('click', (e) => {
      if (!toggle.contains(e.target) && !navLinks.contains(e.target)) {
        navLinks.classList.remove('active');
        toggle.classList.remove('active');
      }
    });

    // Close menu when clicking a link
    navLinks.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        navLinks.classList.remove('active');
        toggle.classList.remove('active');
      });
    });
  }
}

// ========== Smooth Scroll with Offset ==========
function initSmoothScroll() {
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      const href = this.getAttribute('href');
      if (href === '#') return;

      e.preventDefault();
      const target = document.querySelector(href);

      if (target) {
        const navHeight = document.querySelector('.nav').offsetHeight;
        const targetPosition = target.offsetTop - navHeight - 20;

        window.scrollTo({
          top: targetPosition,
          behavior: 'smooth'
        });
      }
    });
  });
}

// ========== Intersection Observer for Fade-in Animations ==========
function initAnimations() {
  const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('fade-in');
        observer.unobserve(entry.target);
      }
    });
  }, observerOptions);

  // Observe elements
  document.querySelectorAll('.feature-card, .workflow-step, .arch-layer, .use-case-card, .community-card').forEach(el => {
    observer.observe(el);
  });
}

// ========== Active Nav Link Highlight ==========
function initActiveNavLinks() {
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('.nav-links a[href^="#"]');

  function highlightNavLink() {
    const scrollPosition = window.scrollY + 100;

    sections.forEach(section => {
      const sectionTop = section.offsetTop;
      const sectionHeight = section.offsetHeight;
      const sectionId = section.getAttribute('id');

      if (scrollPosition >= sectionTop && scrollPosition < sectionTop + sectionHeight) {
        navLinks.forEach(link => {
          link.classList.remove('active');
          if (link.getAttribute('href') === `#${sectionId}`) {
            link.classList.add('active');
          }
        });
      }
    });
  }

  window.addEventListener('scroll', highlightNavLink);
  highlightNavLink(); // Initial call
}

// ========== Copy Install Command ==========
function initCopyCommand() {
  const installCode = document.querySelector('.install-code');

  if (installCode) {
    installCode.style.cursor = 'pointer';
    installCode.title = 'Click to copy';

    installCode.addEventListener('click', async () => {
      try {
        await navigator.clipboard.writeText(installCode.textContent);

        // Visual feedback
        const originalText = installCode.textContent;
        installCode.textContent = '✓ Copied to clipboard!';
        installCode.style.color = '#22D3EE';

        setTimeout(() => {
          installCode.textContent = originalText;
          installCode.style.color = '';
        }, 2000);
      } catch (error) {
        console.error('Failed to copy:', error);
      }
    });
  }
}

// ========== Nav Background on Scroll ==========
function initNavScroll() {
  const nav = document.querySelector('.nav');

  function updateNav() {
    if (window.scrollY > 50) {
      nav.classList.add('scrolled');
    } else {
      nav.classList.remove('scrolled');
    }
  }

  window.addEventListener('scroll', updateNav);
  updateNav(); // Initial call
}

// ========== Analytics (placeholder) ==========
function trackEvent(category, action, label) {
  // Placeholder for analytics
  console.log('Event:', category, action, label);

  // If using Google Analytics:
  // if (typeof gtag !== 'undefined') {
  //   gtag('event', action, {
  //     'event_category': category,
  //     'event_label': label
  //   });
  // }
}

// Track CTA clicks
function initAnalytics() {
  document.querySelectorAll('.btn-primary, .btn-secondary').forEach(btn => {
    btn.addEventListener('click', () => {
      const text = btn.textContent.trim();
      trackEvent('CTA', 'click', text);
    });
  });

  document.querySelectorAll('.community-card').forEach(card => {
    card.addEventListener('click', () => {
      const title = card.querySelector('h3').textContent;
      trackEvent('Community', 'click', title);
    });
  });
}

// ========== Keyboard Navigation Improvements ==========
function initKeyboardNav() {
  // Allow Escape to close mobile menu
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      const navLinks = document.querySelector('.nav-links');
      const toggle = document.querySelector('.mobile-menu-toggle');

      if (navLinks && toggle) {
        navLinks.classList.remove('active');
        toggle.classList.remove('active');
      }
    }
  });
}

// ========== Preload Critical Resources ==========
function preloadResources() {
  // Preload GitHub API request
  const link = document.createElement('link');
  link.rel = 'dns-prefetch';
  link.href = 'https://api.github.com';
  document.head.appendChild(link);
}

// ========== Performance: Lazy Load Images ==========
function initLazyLoad() {
  if ('loading' in HTMLImageElement.prototype) {
    // Browser supports native lazy loading
    document.querySelectorAll('img[data-src]').forEach(img => {
      img.src = img.dataset.src;
    });
  } else {
    // Fallback for older browsers
    const lazyImages = document.querySelectorAll('img[data-src]');
    const imageObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const img = entry.target;
          img.src = img.dataset.src;
          imageObserver.unobserve(img);
        }
      });
    });

    lazyImages.forEach(img => imageObserver.observe(img));
  }
}

// ========== Initialize Everything ==========
function init() {
  // Fetch dynamic data
  fetchGitHubStars();

  // Initialize features
  initMobileMenu();
  initSmoothScroll();
  initAnimations();
  initActiveNavLinks();
  initCopyCommand();
  initNavScroll();
  initAnalytics();
  initKeyboardNav();
  initLazyLoad();

  // Preload resources
  preloadResources();

  console.log('⚓ Anchor Learning - Landing page initialized');
}

// Run when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}

// ========== Export for Testing ==========
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    fetchGitHubStars,
    trackEvent,
    init
  };
}
