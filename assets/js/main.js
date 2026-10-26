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
