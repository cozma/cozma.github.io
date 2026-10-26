// One-page mode: in-page nav + scroll-spy, hash sync, lazy embeds, and reveal/parallax for the
// section heroes after Home. Loaded after main.js (which handles nav toggle, hero strips,
// carousels, lightbox, global reveal and the Home hero parallax).
(function () {
  var root = document.documentElement;
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var hasIO = 'IntersectionObserver' in window;

  document.addEventListener('DOMContentLoaded', function () {
    var nav = document.querySelector('.nav'), btn = document.querySelector('.nav-toggle');
    var secs = [].slice.call(document.querySelectorAll('.op-sec'));
    var links = {};
    [].forEach.call(nav.querySelectorAll('a[href^="#"]'), function (a) { links[a.hash.slice(1)] = a; });
    var current = null, userNav = false, lock = false, lockT;

    function setHash(id) {
      var url = id && id !== 'home' ? '#' + id : location.pathname + location.search;
      if (url !== location.hash) history.replaceState(null, '', url);
    }
    function setCurrent(id) {
      if (id === current) return;
      current = id;
      Object.keys(links).forEach(function (k) {
        if (k === id) links[k].setAttribute('aria-current', 'location'); else links[k].removeAttribute('aria-current');
      });
      if (userNav) setHash(id);
    }
    function secAtProbe() {  // section under a line 40% down the viewport
      var y = window.innerHeight * 0.4, hit = secs[0];
      secs.forEach(function (s) { if (s.getBoundingClientRect().top <= y) hit = s; });
      if (window.innerHeight + window.scrollY >= root.scrollHeight - 4) hit = secs[secs.length - 1];
      return hit.id;
    }

    // ---- scroll-spy (IntersectionObserver on a thin band 40% down the viewport)
    if (hasIO) {
      var spy = new IntersectionObserver(function (es) {
        if (lock) return;
        es.forEach(function (e) { if (e.isIntersecting) setCurrent(e.target.id); });
      }, { rootMargin: '-40% 0px -59% 0px' });
      secs.forEach(function (s) { spy.observe(s); });
    }
    var bottomT;
    window.addEventListener('scroll', function () {
      if (lock) { clearTimeout(lockT); lockT = setTimeout(unlock, 140); return; }
      clearTimeout(bottomT); bottomT = setTimeout(function () { setCurrent(secAtProbe()); }, 80); // bottom-of-page / fallback
    }, { passive: true });
    function unlock() { lock = false; setCurrent(secAtProbe()); }
    // Only rewrite the URL once the visitor starts moving around (keeps deep links like #alertix on load).
    ['wheel', 'touchmove', 'keydown'].forEach(function (ev) {
      window.addEventListener(ev, function () { userNav = true; }, { passive: true, once: true });
    });

    // ---- in-page links (nav, brand, cards, cross-links)
    document.addEventListener('click', function (e) {
      var a = e.target.closest && e.target.closest('a[href^="#"]');
      if (!a || e.defaultPrevented || e.metaKey || e.ctrlKey || e.shiftKey || e.button) return;
      var id = a.hash.slice(1), t = id && document.getElementById(id);
      if (!t) return;
      e.preventDefault();
      userNav = true;
      var sec = t.closest('.op-sec');
      lock = true; clearTimeout(lockT); lockT = setTimeout(unlock, 900);
      if (sec) setCurrent(sec.id);
      setHash(id === 'home' ? null : id);
      if (id === 'home') window.scrollTo({ top: 0, behavior: reduce ? 'auto' : 'smooth' });
      else t.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth', block: 'start' });
      if (!t.hasAttribute('tabindex')) t.setAttribute('tabindex', '-1');
      t.focus({ preventScroll: true });
      if (nav.classList.contains('open')) { nav.classList.remove('open'); btn && btn.setAttribute('aria-expanded', 'false'); }
    });

    // Arriving with a hash (or via a redirect stub): settle on the target once layout is final.
    if (location.hash.length > 1) {
      var go = function () {
        var t = document.getElementById(location.hash.slice(1));
        if (t) t.scrollIntoView({ behavior: 'instant', block: 'start' });
        setCurrent(secAtProbe());
      };
      if (document.fonts && document.fonts.ready) document.fonts.ready.then(function () { requestAnimationFrame(go); });
      window.addEventListener('load', go);
    } else setCurrent(secAtProbe());

    // ---- lazy embeds: inject the real iframe ~600px before it scrolls into view
    var embeds = [].slice.call(document.querySelectorAll('.lazy-embed'));
    function inject(ph) {
      var tpl = document.createElement('template');
      tpl.innerHTML = ph.getAttribute('data-embed');
      var ifr = tpl.content.querySelector('iframe');
      if (ifr) { ifr.removeAttribute('loading'); ph.replaceWith(ifr); }
    }
    if (hasIO) {
      var eio = new IntersectionObserver(function (es) {
        es.forEach(function (e) { if (e.isIntersecting) { eio.unobserve(e.target); inject(e.target); } });
      }, { rootMargin: '600px 0px' });
      embeds.forEach(function (ph) { eio.observe(ph); });
    } else embeds.forEach(inject);

    // ---- reveal + parallax for the section heroes after Home (main.js covers the rest)
    if (reduce || !root.classList.contains('js') || !hasIO) return;
    var heroes = [].slice.call(document.querySelectorAll('.op-sec:not(#home) > .hero'));
    var items = [];
    heroes.forEach(function (h) {
      [].forEach.call(h.querySelectorAll('.wrap > :not(.anim):not(.wave)'), function (el) { items.push(el); });
    });
    function done(el) { el.classList.remove('reveal', 'in'); el.style.transitionDelay = ''; }
    var rio = new IntersectionObserver(function (es) {
      var vis = es.filter(function (e) { return e.isIntersecting; });
      es.forEach(function (e) {
        if (!e.isIntersecting && e.boundingClientRect.bottom < 0) {  // already passed (e.g. hash jump)
          rio.unobserve(e.target); e.target.classList.add('instant'); done(e.target); e.target.offsetWidth; e.target.classList.remove('instant');
        }
      });
      vis.forEach(function (e, i) {
        var el = e.target, d = Math.min(i, 5) * 90;
        rio.unobserve(el); el.style.transitionDelay = d + 'ms'; el.classList.add('in');
        setTimeout(function () { done(el); }, d + 1000);
      });
    }, { rootMargin: '0px 0px -6% 0px', threshold: 0.01 });
    items.forEach(function (el) { el.classList.add('reveal'); rio.observe(el); });
    window.addEventListener('scroll', function () {
      if (window.innerHeight + window.scrollY >= root.scrollHeight - 4)
        items.forEach(function (el) { if (el.classList.contains('reveal') && !el.classList.contains('in')) { el.classList.add('in'); setTimeout(function () { done(el); }, 1000); } });
    }, { passive: true });

    // Hero strips drift: a touch slower than the text while the hero enters, faster as it leaves.
    var strips = heroes.map(function (h) { var s = h.querySelector('.anim, .wave'); if (s) s.classList.add('px-layer'); return [h, s]; })
                       .filter(function (p) { return p[1]; });
    var ticking = false;
    function frame() {
      ticking = false;
      var vh = window.innerHeight, rects = strips.map(function (p) { return p[0].getBoundingClientRect(); });
      strips.forEach(function (p, i) {
        var t = rects[i].top, h = rects[i].height;
        if (t > vh + 50 || t + h < -200) return;
        var off = t > 0 ? Math.min(t / vh, 1) * 22 : Math.max(t, -h) * 0.22;
        p[1].style.transform = 'translate3d(0,' + off.toFixed(1) + 'px,0)';
      });
    }
    function queue() { if (!ticking) { ticking = true; requestAnimationFrame(frame); } }
    window.addEventListener('scroll', queue, { passive: true });
    window.addEventListener('resize', queue, { passive: true });
    queue();
  });
})();
