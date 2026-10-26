// Mobile nav toggle + generated waveform bars. Minimal, no dependencies.
document.addEventListener('DOMContentLoaded', function () {
  var btn = document.querySelector('.nav-toggle'), nav = document.querySelector('.nav');
  if (btn && nav) btn.addEventListener('click', function () {
    var open = nav.classList.toggle('open');
    btn.setAttribute('aria-expanded', open ? 'true' : 'false');
  });
  document.querySelectorAll('.wave').forEach(function (w) {
    var n = parseInt(w.dataset.bars || '48', 10);
    for (var i = 0; i < n; i++) {
      var b = document.createElement('i');
      var h = 8 + Math.abs(Math.sin(i * 0.55) * Math.cos(i * 0.17)) * 26;
      b.style.height = h.toFixed(1) + 'px';
      b.style.animationDelay = (i * 0.06).toFixed(2) + 's';
      w.appendChild(b);
    }
  });
});

// Per-page hero motifs (.anim-*). Decorative only; CSS does the motion.
document.addEventListener('DOMContentLoaded', function () {
  var NS = 'http://www.w3.org/2000/svg';
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  function el(tag, cls, parent) { var e = document.createElement(tag); if (cls) e.className = cls; if (parent) parent.appendChild(e); return e; }
  function sinePath(w, period, amp, mid) {
    var d = 'M0 ' + mid.toFixed(2);
    for (var x = 2; x <= w; x += 2) d += ' L' + x + ' ' + (mid + Math.sin(x / period * Math.PI * 2) * amp).toFixed(2);
    return d;
  }
  var builders = {
    // Home: two sine lines drifting past each other (the "mix").
    sine: function (a) {
      [['l1', 84, 11], ['l2', 112, 7]].forEach(function (c) {
        var ln = el('div', 'ln ' + c[0], a), svg = document.createElementNS(NS, 'svg'), p = document.createElementNS(NS, 'path');
        svg.setAttribute('viewBox', '0 0 672 34'); p.setAttribute('d', sinePath(672, c[1], c[2], 17));
        svg.appendChild(p); ln.appendChild(svg);
      });
    },
    // Day Job: packets travelling along a line, lighting nodes as they pass.
    flow: function (a) {
      var dur = 4.8, fr = [0.08, 0.3, 0.52, 0.74, 0.94];
      fr.forEach(function (f) { var b = el('b', '', a); b.style.left = (f * 100) + '%'; b.style.animationDelay = (f * dur - dur).toFixed(2) + 's'; });
      [0, 0.5].forEach(function (o) { var k = el('span', 'pk', a); k.style.animationDelay = (-o * dur).toFixed(2) + 's'; });
    },
    // Applications: a short line of code typing itself out.
    code: function (a) {
      var lines = ['git push origin main', 'npm run hack -- --ar', 'new AudioContext()', 'render(<Scene ar />)', 'make it_work && ship'];
      el('span', 'pr', a).textContent = '$';
      var tx = el('span', 'tx', a); el('span', 'cur', a);
      if (reduce) { tx.textContent = lines[0]; return; }
      var li = 0, ci = 0, del = false;
      function tick() {
        if (a.classList.contains('paused')) return setTimeout(tick, 400);
        var s = lines[li], wait;
        if (!del) { ci++; wait = ci === s.length ? 2200 : 70 + Math.random() * 70; if (ci === s.length) del = true; }
        else { ci--; wait = 28; if (ci === 0) { del = false; li = (li + 1) % lines.length; wait = 500; } }
        tx.textContent = s.slice(0, ci);
        setTimeout(tick, wait);
      }
      setTimeout(tick, 400);
    },
    // Graphics: wireframe cubes, each with a counter-rotating cube inside.
    cube: function (a) {
      function cube(parent) { var c = el('span', 'cb', parent); for (var i = 0; i < 6; i++) el('i', '', c); return c; }
      for (var n = 0; n < 3; n++) {
        var o = cube(a), inner = cube(o);
        o.style.animationDelay = (-n * 4.7) + 's'; inner.style.animationDelay = (-n * 3) + 's';
      }
    },
    // The Dagsby: a sagging string of bulbs twinkling in sequence.
    lights: function (a) {
      var n = 16, top = 3, sag = 16, svg = document.createElementNS(NS, 'svg'), p = document.createElementNS(NS, 'path');
      svg.setAttribute('viewBox', '0 0 100 34'); svg.setAttribute('preserveAspectRatio', 'none');
      p.setAttribute('d', 'M0 ' + top + ' Q50 ' + (top + 2 * sag) + ' 100 ' + top);
      svg.appendChild(p); a.appendChild(svg);
      for (var i = 0; i < n; i++) {
        var t = (i + 0.5) / n, b = el('i', '', a);
        b.style.left = (t * 100).toFixed(2) + '%';
        b.style.top = (top + 1 + 4 * sag * t * (1 - t)).toFixed(1) + 'px';
        b.style.animationDelay = ((i * 0.26) % 4.2 - 4.2).toFixed(2) + 's';
      }
    }
  };
  var anims = document.querySelectorAll('.anim');
  anims.forEach(function (a) {
    var m = a.className.match(/\banim-(\w+)/);
    if (m && builders[m[1]]) builders[m[1]](a);
  });
  // Pause motion while the strip is off-screen.
  if ('IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) { e.target.classList.toggle('paused', !e.isIntersecting); });
    });
    anims.forEach(function (a) { io.observe(a); });
  }
});

// Lightbox (Graphics gallery + flyers carousel).
document.addEventListener('DOMContentLoaded', function () {
  var lb = document.querySelector('.lightbox');
  if (!lb) return;
  var img = lb.querySelector('img'), t = lb.querySelector('.lb-title'), m = lb.querySelector('.lb-meta'),
      a = lb.querySelector('.lb-link'), sep = lb.querySelector('.lb-sep'), opener = null;
  function close() { lb.hidden = true; img.removeAttribute('src'); document.body.style.overflow = ''; if (opener) opener.focus(); }
  document.querySelectorAll('.gthumb, .car-open').forEach(function (b) {
    b.addEventListener('click', function () {
      opener = b;
      img.src = b.dataset.full; img.alt = (b.querySelector('img') || {}).alt || b.dataset.title;
      t.textContent = b.dataset.title; m.textContent = b.dataset.meta || '';
      var hasLink = !!b.dataset.link;
      a.hidden = sep.hidden = !hasLink;
      if (hasLink) { a.href = b.dataset.link; a.textContent = b.dataset.linktext || 'Open ↗'; }
      lb.hidden = false; document.body.style.overflow = 'hidden';
      lb.querySelector('.lb-close').focus();
    });
  });
  lb.addEventListener('click', function (e) { if (e.target === lb || e.target.classList.contains('lb-close')) close(); });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && !lb.hidden) close(); });
});

// Flyers carousel: native scroll-snap (touch/trackpad swipe) + arrows, dots, keyboard.
document.addEventListener('DOMContentLoaded', function () {
  document.querySelectorAll('.carousel').forEach(function (car) {
    var track = car.querySelector('.car-track'), slides = [].slice.call(track.children),
        prev = car.querySelector('.car-prev'), next = car.querySelector('.car-next'),
        dots = [].slice.call(car.parentNode.querySelectorAll('.car-dot'));
    function current() {
      var x = track.scrollLeft, best = 0, d = Infinity;
      slides.forEach(function (s, i) { var dd = Math.abs(s.offsetLeft - track.offsetLeft - x); if (dd < d) { d = dd; best = i; } });
      return best;
    }
    function go(i) {
      i = Math.max(0, Math.min(slides.length - 1, i));
      track.scrollTo({ left: slides[i].offsetLeft - track.offsetLeft, behavior: 'smooth' });
    }
    function update() {
      var c = current(), end = track.scrollLeft + track.clientWidth >= track.scrollWidth - 4;
      if (end) c = slides.length - 1;
      dots.forEach(function (d, i) { if (i === c) d.setAttribute('aria-current', 'true'); else d.removeAttribute('aria-current'); });
      prev.disabled = track.scrollLeft <= 2; next.disabled = end;
    }
    prev.addEventListener('click', function () { go(current() - 1); });
    next.addEventListener('click', function () { go(current() + 1); });
    dots.forEach(function (d, i) { d.addEventListener('click', function () { go(i); }); });
    car.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowRight') { e.preventDefault(); go(current() + 1); }
      else if (e.key === 'ArrowLeft') { e.preventDefault(); go(current() - 1); }
      else if (e.key === 'Home') { e.preventDefault(); go(0); }
      else if (e.key === 'End') { e.preventDefault(); go(slides.length - 1); }
    });
    var tmr; track.addEventListener('scroll', function () { clearTimeout(tmr); tmr = setTimeout(update, 60); }, { passive: true });
    window.addEventListener('resize', update);
    update();
  });
});

// Scroll reveal + subtle parallax. Progressive enhancement: nothing is hidden
// unless this script runs (html.js + .reveal are added here), and everything is
// skipped under prefers-reduced-motion.
(function () {
  var root = document.documentElement;
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (reduce || !('IntersectionObserver' in window) || !('requestAnimationFrame' in window)) return;
  root.classList.add('js');

  var REVEAL = [
    'main section .section-head', 'main section > .wrap > .eyebrow', 'main section > .wrap > h2',
    '.card', '.app', '.compact > div', '.job', '.two > div > h2', '.two > div > h3', '.two ul.clean li',
    '.project h2', '.project .meta', '.project > div > p', '.project > div > h4', '.project .placard',
    '.project .tags', '.flow > div', '.project ul.clean li', '.media figure', '.media blockquote',
    '.radio-copy', '.radio-media .embed', '.radio-media h4', '.episodes li',
    '.plat', '.gitem', '.carousel', '.car-dots',
    '.review-feature', '.review', '.highlights li', '.rating', 'main section .btn',
    'main section .note', 'main section > .wrap > p', 'main section > .wrap > h4'
  ].join(',');
  var DRIFT = '.media figure > a > img, .app .shot img, .gthumb img';

  document.addEventListener('DOMContentLoaded', function () {
    // ---- reveal ----
    var items = [].slice.call(document.querySelectorAll(REVEAL)).filter(function (el) {
      return !el.closest('.hero, .lightbox, .site-header');
    });
    // Skip anything nested inside another reveal target (it moves with its parent).
    var set = new Set(items);
    items = items.filter(function (el) {
      for (var p = el.parentElement; p; p = p.parentElement) if (set.has(p)) return false;
      return true;
    });
    function done(el) {
      el.classList.remove('reveal', 'in'); el.style.transitionDelay = '';
    }
    function show(el, delay, instant) {
      if (!el.classList.contains('reveal') || el.classList.contains('in')) return;
      io.unobserve(el);
      if (instant) { el.classList.add('instant'); done(el); el.offsetWidth; el.classList.remove('instant'); return; }
      el.style.transitionDelay = delay + 'ms';
      el.classList.add('in');
      var fin = function (e) { if (!e || e.target === el) { el.removeEventListener('transitionend', fin); clearTimeout(t); done(el); } };
      var t = setTimeout(fin, delay + 1200);
      el.addEventListener('transitionend', fin);
    }
    var io = new IntersectionObserver(function (entries) {
      var vis = [];
      entries.forEach(function (e) {
        if (e.isIntersecting) vis.push(e);
        else if (e.boundingClientRect.bottom < 0) show(e.target, 0, true); // already scrolled past (anchor jump)
      });
      vis.sort(function (a, b) {
        var ra = a.boundingClientRect, rb = b.boundingClientRect;
        return (Math.round(ra.top / 40) - Math.round(rb.top / 40)) || (ra.left - rb.left);
      });
      vis.forEach(function (e, i) { show(e.target, Math.min(i, 6) * 85, false); });
    }, { rootMargin: '0px 0px -6% 0px', threshold: 0.01 });
    items.forEach(function (el) { el.classList.add('reveal'); io.observe(el); });
    // Safety net: at the very bottom of the page, show anything still pending.
    function atBottom() {
      if (window.innerHeight + window.scrollY >= root.scrollHeight - 4)
        items.forEach(function (el, i) { show(el, 0, false); });
    }

    // ---- parallax ----
    var wide = window.matchMedia('(min-width: 821px)');
    var heroStrip = document.querySelector('.hero .anim, .hero .wave');
    var heroFig = document.querySelector('.hero-grid > figure');
    var hero = document.querySelector('.hero');
    var drift = [].slice.call(document.querySelectorAll(DRIFT));
    var near = new Set();
    var dio = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) near.add(e.target); else near.delete(e.target); });
      queue();
    }, { rootMargin: '25% 0px' });
    drift.forEach(function (img) {
      img.classList.add('px-drift');
      var frame = img.closest('a, .shot, .gthumb') || img.parentElement;
      img._frame = frame; frame.classList.add('px-frame');
      dio.observe(frame); frame._img = img;
    });
    if (heroStrip) heroStrip.classList.add('px-layer');
    if (heroFig) heroFig.classList.add('px-layer');

    var ticking = false;
    function queue() { if (!ticking) { ticking = true; requestAnimationFrame(frame); } }
    function frame() {
      ticking = false;
      var y = window.scrollY, vh = window.innerHeight, heroH = hero ? hero.offsetHeight : 0;
      // Reads first…
      var reads = [];
      near.forEach(function (fr) { reads.push([fr._img, fr.getBoundingClientRect()]); });
      // …then writes.
      if (y < heroH + 200) {
        var k = Math.min(y, heroH);
        if (heroStrip) heroStrip.style.transform = 'translate3d(0,' + (-k * 0.22).toFixed(1) + 'px,0)';
        if (heroFig) heroFig.style.transform = wide.matches ? 'translate3d(0,' + (-k * 0.09).toFixed(1) + 'px,0)' : '';
      }
      reads.forEach(function (r) {
        var rect = r[1], h = rect.height || 1;
        var p = (rect.top + h / 2 - vh / 2) / (vh / 2 + h / 2); // -1 … 1 across the viewport
        p = Math.max(-1, Math.min(1, p));
        // scale(1.08) leaves 4% of height spare on each side; use 90% of it.
        r[0].style.setProperty('--py', (p * h * 0.036).toFixed(1) + 'px');
      });
    }
    window.addEventListener('scroll', function () { queue(); atBottom(); }, { passive: true });
    window.addEventListener('resize', queue, { passive: true });
    queue(); atBottom();
  });
})();
