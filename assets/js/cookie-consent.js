// Adapted from the PYNQ gh_pages cookie-consent.js.
// Copyright (C) 2023 Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT

document.addEventListener('DOMContentLoaded', () => {
  const banner = document.getElementById('cookie-consent');
  const accept = document.getElementById('cookie-accept');
  const reject = document.getElementById('cookie-reject');
  if (!banner || !accept || !reject) return;

  const analyticsId = 'G-MV1L2SX33L';
  const consentKey = 'cookieConsent';
  const productionHost = ['pynq.io', 'www.pynq.io'].includes(window.location.hostname);
  let analyticsLoaded = false;
  let settingsTrigger = null;

  const readChoice = () => {
    try {
      const saved = localStorage.getItem(consentKey);
      if (saved === 'accepted' || saved === 'rejected') return saved;
      if (localStorage.getItem('cookieRejected') === 'true') return 'rejected';
      if (saved === 'true') return 'accepted';
    } catch (_) {
      // Continue with a session-only choice when storage is unavailable.
    }
    return null;
  };

  const saveChoice = choice => {
    try {
      localStorage.setItem(consentKey, choice);
      localStorage.removeItem('cookieRejected');
    } catch (_) {
      // The visitor can still make a choice for this page.
    }
  };

  const showBanner = focus => {
    banner.hidden = false;
    banner.style.display = 'block'; // Also supports pages using the old Jekyll layout.
    if (focus) (banner.querySelector('#cookie-consent-title') || reject).focus();
  };

  const hideBanner = () => {
    banner.hidden = true;
    banner.style.display = 'none';
    if (settingsTrigger) settingsTrigger.focus();
    settingsTrigger = null;
  };

  const loadAnalytics = () => {
    if (!productionHost || analyticsLoaded) return;
    analyticsLoaded = true;
    window[`ga-disable-${analyticsId}`] = false;
    window.dataLayer = window.dataLayer || [];
    window.gtag = function () { window.dataLayer.push(arguments); };
    window.gtag('js', new Date());
    window.gtag('config', analyticsId);
    const script = document.createElement('script');
    script.async = true;
    script.src = `https://www.googletagmanager.com/gtag/js?id=${analyticsId}`;
    document.head.appendChild(script);
  };

  const clearAnalyticsCookies = () => {
    document.cookie.split(';').forEach(cookie => {
      const name = cookie.trim().split('=')[0];
      if (!/^(?:_ga(?:_|$)|_gid$|_gat(?:_|$))/.test(name)) return;
      for (const domain of ['', window.location.hostname, '.pynq.io']) {
        document.cookie = `${name}=; Max-Age=0; path=/${domain ? `; domain=${domain}` : ''}`;
      }
    });
  };

  accept.addEventListener('click', event => {
    event.preventDefault();
    saveChoice('accepted');
    hideBanner();
    loadAnalytics();
  });

  reject.addEventListener('click', event => {
    event.preventDefault();
    saveChoice('rejected');
    window[`ga-disable-${analyticsId}`] = true;
    clearAnalyticsCookies();
    hideBanner();
    if (analyticsLoaded) window.location.reload();
  });

  document.querySelectorAll('a[href$="#cookiessettings"]').forEach(link => {
    link.addEventListener('click', event => {
      event.preventDefault();
      settingsTrigger = link;
      showBanner(true);
    });
  });
  window.addEventListener('hashchange', () => {
    if (window.location.hash === '#cookiessettings') showBanner(true);
  });

  const choice = readChoice();
  if (choice === 'accepted') loadAnalytics();
  else {
    window[`ga-disable-${analyticsId}`] = true;
    if (productionHost) clearAnalyticsCookies();
  }
  if (!choice || window.location.hash === '#cookiessettings') showBanner(false);
});
