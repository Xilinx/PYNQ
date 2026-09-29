const menuButton = document.querySelector('.menu-toggle');
const navigation = document.querySelector('.site-nav');

if (menuButton && navigation) {
  const sectionLinks = [...navigation.querySelectorAll('a[href^="#"]')];
  const sections = sectionLinks.map(link => document.querySelector(link.getAttribute('href')));
  const closeMenu = () => {
    navigation.classList.remove('open');
    menuButton.setAttribute('aria-expanded', 'false');
    menuButton.setAttribute('aria-label', 'Open menu');
  };

  menuButton.addEventListener('click', () => {
    const isOpen = navigation.classList.toggle('open');
    menuButton.setAttribute('aria-expanded', String(isOpen));
    menuButton.setAttribute('aria-label', isOpen ? 'Close menu' : 'Open menu');
  });
  navigation.querySelectorAll('a').forEach(link => link.addEventListener('click', closeMenu));
  document.addEventListener('keydown', event => {
    if (event.key === 'Escape') closeMenu();
  });

  let scrollFrame = 0;
  const updateActiveLink = () => {
    scrollFrame = 0;
    const marker = window.scrollY + document.querySelector('.site-header').offsetHeight + Math.min(window.innerHeight * 0.3, 180);
    let activeIndex = 0;
    sections.forEach((section, index) => {
      if (section && section.offsetTop <= marker) activeIndex = index;
    });
    sectionLinks.forEach((link, index) => {
      const active = index === activeIndex;
      link.classList.toggle('is-active', active);
      if (active) link.setAttribute('aria-current', 'location');
      else link.removeAttribute('aria-current');
    });
  };
  const scheduleActiveUpdate = () => {
    if (!scrollFrame) scrollFrame = requestAnimationFrame(updateActiveLink);
  };
  window.addEventListener('scroll', scheduleActiveUpdate, { passive: true });
  window.addEventListener('resize', scheduleActiveUpdate);
  window.addEventListener('hashchange', scheduleActiveUpdate);
  updateActiveLink();
}
