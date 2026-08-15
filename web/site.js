/* T2DECODE — Site Scripts (CSP Compliant) */

// 1. Scroll Progress Bar
window.addEventListener('scroll', () => {
  const winScroll = document.body.scrollTop || document.documentElement.scrollTop;
  const height = document.documentElement.scrollHeight - document.documentElement.clientHeight;
  if (height <= 0) return;
  const scrolled = (winScroll / height) * 100;
  const pb = document.getElementById('scroll-progress');
  if (pb) pb.style.width = scrolled + '%';
});

// 2. Tab Switcher (Simulateurs)
function switchSimTab(index) {
  const btns = document.querySelectorAll('.sim-tab-btn');
  const panes = document.querySelectorAll('.sim-pane');
  btns.forEach((btn, i) => {
    btn.classList.toggle('active', i === index);
    btn.setAttribute('aria-selected', i === index ? 'true' : 'false');
  });
  panes.forEach((pane, i) => {
    pane.classList.toggle('active', i === index);
  });
}

document.addEventListener('DOMContentLoaded', () => {
  // Attach event listeners to tab buttons
  const tabBtns = document.querySelectorAll('.sim-tab-btn');
  tabBtns.forEach((btn, index) => {
    btn.addEventListener('click', () => switchSimTab(index));
  });

  // Flag image error handling (replace inline onerror)
  const flagImgs = document.querySelectorAll('#ls-cards img, #ls-main-btn img');
  flagImgs.forEach(img => {
    img.addEventListener('error', function() {
      this.style.display = 'none';
      const fallbackSpan = this.nextElementSibling;
      if (fallbackSpan) fallbackSpan.style.display = 'inline';
      const globeIcon = document.getElementById('ls-globe-icon');
      if (this.id === 'ls-flag' && globeIcon) {
        globeIcon.style.display = 'block';
      }
    });
  });

  // Language selector widget toggle & selection
  const root = document.getElementById('ls-root');
  const mainBtn = document.getElementById('ls-main-btn');
  if (root && mainBtn) {
    mainBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      root.classList.toggle('ls-open');
    });

    const cards = document.querySelectorAll('.ls-card');
    cards.forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        cards.forEach(c => c.classList.remove('ls-active'));
        btn.classList.add('ls-active');
        const flagImg = btn.querySelector('img');
        const mainImg = document.getElementById('ls-flag');
        if (flagImg && mainImg && flagImg.style.display !== 'none') {
          mainImg.src = flagImg.src;
        }
        root.classList.remove('ls-open');
      });
    });

    document.addEventListener('click', (e) => {
      if (root.classList.contains('ls-open') && !root.contains(e.target)) {
        root.classList.remove('ls-open');
      }
    });
  }
});

// 3. ServiceWorker Registration
if ('serviceWorker' in navigator && location.protocol === 'https:') {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js').catch(err => console.warn(err));
  });
}

// 4. GitLab Auto-Version Fetcher
(async function () {
  const API = 'https://gitlab.com/api/v4/projects/tutodecode-org%2FT2DECODE/releases?per_page=1';
  try {
    const res = await fetch(API);
    if (!res.ok) throw new Error('HTTP ' + res.status);
    const [release] = await res.json();
    if (!release) throw new Error('Aucune release');
    const tag = release.tag_name;
    const name = release.name || tag;
    const url = 'https://gitlab.com/tutodecode-org/T2DECODE/-/releases/' + tag;

    const sv = document.getElementById('stat-version');
    if (sv) sv.textContent = tag;
    const sn = document.getElementById('stat-release-name');
    if (sn) sn.textContent = name;
    const btn = document.getElementById('dl-btn');
    if (btn) { btn.href = url; btn.textContent = '⬇ Télécharger ' + tag; }
    const badge = document.getElementById('badge-version');
    if (badge) { badge.src = 'https://img.shields.io/badge/version-' + tag.replace(/-/g, '--') + '-f0e4cf'; badge.alt = 'Version ' + tag; }
    document.title = 'T2DECODE ' + tag + ' — Plateforme locale de cybersécurité | TUTODECODE';
    const md = document.getElementById('meta-description');
    if (md) md.setAttribute('content', 'T2DECODE ' + tag + ' — Application native 100% hors ligne pour apprendre la cybersécurité. Open source GPLv3. Fondée par Maxime MARTIN CIVET, association loi 1901 TUTODECODE (SIREN 102763133).');
    const fv = document.getElementById('footer-version');
    if (fv) fv.textContent = 'T2DECODE ' + tag;
    console.info('[T2DECODE] ' + tag + ' — ' + name);
  } catch (e) {
    const sv = document.getElementById('stat-version');
    if (sv) sv.textContent = 'v1.0.3';
    const btn = document.getElementById('dl-btn');
    if (btn) btn.textContent = '⬇ Télécharger';
    console.warn('[T2DECODE] GitLab API :', e.message);
  }
})();
