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
