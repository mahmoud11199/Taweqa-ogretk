var landingInitialized = false;
function initLandingPage() {
  if (landingInitialized) return;
  landingInitialized = true;
  initReveal();
  loadStats();
  setInterval(loadStats, 60000);
}

function initReveal() {
  var els = document.querySelectorAll('.reveal:not(.visible)');
  if (!els.length) return;
  var obs = new IntersectionObserver(function(entries) {
    entries.forEach(function(entry) {
      if (entry.isIntersecting) { entry.target.classList.add('visible'); obs.unobserve(entry.target); }
    });
  }, { threshold: 0.1 });
  els.forEach(function(el) { obs.observe(el); });
}

function animateCounters() {
  document.querySelectorAll('.stat-value').forEach(function(el) {
    var target = parseFloat(el.getAttribute('data-target'));
    if (isNaN(target)) return;
    var suffix = el.getAttribute('data-suffix') || '';
    var duration = 1200, start = performance.now();
    function step(now) {
      var p = Math.min((now - start) / duration, 1);
      var eased = 1 - Math.pow(1 - p, 3);
      var current = Math.round(eased * target);
      el.textContent = current.toLocaleString('ar-EG') + suffix;
      if (p < 1) requestAnimationFrame(step);
      else el.textContent = target.toLocaleString('ar-EG') + suffix;
    }
    requestAnimationFrame(step);
  });
}

async function loadStatsFromDB() {
  if (!supabase) throw new Error('No supabase');
  try {
    var { data, error } = await supabase.rpc('get_public_stats');
    if (!error && data) return data;
  } catch(e) {}
  async function safeQuery(promise) { try { return await promise; } catch(e) { return { data: [] }; } }
  var q1 = safeQuery(supabase.from('profiles').select('id, role').limit(1000));
  var q2 = safeQuery(supabase.from('trips').select('total_fare, distance_km, status, created_at').limit(1000));
  var q3 = safeQuery(supabase.from('ratings').select('score').limit(1000));
  var q4 = safeQuery(supabase.from('drivers').select('id, is_available'));
  var q5 = safeQuery(supabase.from('referrals').select('id, status'));
  var results = await Promise.all([q1, q2, q3, q4, q5]);
  var profiles = results[0].data || [];
  var trips = results[1].data || [];
  var ratings = results[2].data || [];
  var drivers = results[3].data || [];
  var referrals = results[4].data || [];

  var usersTotal = profiles.length;
  var usersDrivers = profiles.filter(function(p) { return p.role === 'driver'; }).length;
  var usersPassengers = profiles.filter(function(p) { return p.role === 'passenger'; }).length;
  var tripsAll = trips;
  var tripsCompleted = trips.filter(function(t) { return t.status === 'completed'; });
  var tripsCancelled = trips.filter(function(t) { return t.status === 'cancelled'; });
  var today = new Date(); today.setHours(0,0,0,0);
  var tripsToday = trips.filter(function(t) { return new Date(t.created_at) >= today; });
  var weekAgo = new Date(Date.now() - 7*24*60*60*1000);
  var tripsWeek = trips.filter(function(t) { return new Date(t.created_at) >= weekAgo; });
  var monthAgo = new Date(Date.now() - 30*24*60*60*1000);
  var tripsMonth = trips.filter(function(t) { return new Date(t.created_at) >= monthAgo; });
  var totalFare = tripsCompleted.reduce(function(s, t) { return s + (parseFloat(t.total_fare) || 0); }, 0);
  var totalDist = tripsCompleted.reduce(function(s, t) { return s + (parseFloat(t.distance_km) || 0); }, 0);
  var avgFare = tripsCompleted.length > 0 ? totalFare / tripsCompleted.length : 0;
  var activeDrivers = drivers.filter(function(d) { return d.is_available === true; }).length;
  var avgRating = ratings.length > 0 ? ratings.reduce(function(s, r) { return s + r.score; }, 0) / ratings.length : 0;
  var refTotal = referrals.length;
  var refSuccessful = referrals.filter(function(r) { return r.status === 'completed' || r.status === 'rewarded'; }).length;

  return {
    users: { total: usersTotal, drivers: usersDrivers, passengers: usersPassengers },
    trips: {
      total: tripsAll.length, completed: tripsCompleted.length, cancelled: tripsCancelled.length,
      today: tripsToday.length, this_week: tripsWeek.length, this_month: tripsMonth.length,
      total_fare: totalFare, avg_fare: avgFare, total_distance_km: totalDist
    },
    drivers: { active: activeDrivers, available_now: activeDrivers },
    ratings: { avg_score: parseFloat(avgRating.toFixed(1)), total: ratings.length },
    referrals: { total: refTotal, successful: refSuccessful }
  };
}

function renderStats(stats) {
  var grid = document.getElementById('statsGrid');
  if (!grid) return;
  var fn = function(n) { return (!n && n !== 0) ? '0' : Number(n).toLocaleString('ar-EG'); };
  var cards = [
    { val: stats.users.total, label: 'إجمالي المستخدمين', sub: fn(stats.users.drivers) + ' سائق | ' + fn(stats.users.passengers) + ' راكب', icon: 'fa-users', cls: 'stat-purple', suffix: '' },
    { val: stats.trips.completed, label: 'رحلات مكتملة', sub: fn(stats.trips.total) + ' إجمالي | ' + fn(stats.trips.cancelled) + ' ملغية', icon: 'fa-check-circle', cls: 'stat-green', suffix: '' },
    { val: stats.trips.today, label: 'رحلات اليوم', sub: fn(stats.trips.this_week) + ' أسبوع | ' + fn(stats.trips.this_month) + ' شهر', icon: 'fa-calendar-day', cls: 'stat-blue', suffix: '' },
    { val: stats.trips.total_fare, label: 'إجمالي الإيرادات', sub: 'متوسط ' + fn(stats.trips.avg_fare) + ' ج.م للرحلة', icon: 'fa-money-bill-wave', cls: 'stat-gold', suffix: '' },
    { val: Math.round(stats.trips.total_distance_km), label: 'إجمالي المسافة', sub: 'جميع الرحلات المكتملة', icon: 'fa-road', cls: 'stat-orange', suffix: ' كم' },
    { val: stats.drivers.active, label: 'سائقين نشطين', sub: fn(stats.drivers.available_now) + ' متاح الآن', icon: 'fa-users-gear', cls: 'stat-emerald', suffix: '' },
    { val: stats.ratings.avg_score, label: 'متوسط التقييم', sub: fn(stats.ratings.total) + ' تقييم', icon: 'fa-star', cls: 'stat-pink', suffix: '' },
    { val: stats.referrals.total, label: 'إحالات السائقين', sub: fn(stats.referrals.successful) + ' إحالة ناجحة', icon: 'fa-link', cls: 'stat-blue', suffix: '' }
  ];
  var html = '';
  cards.forEach(function(c, i) {
    var safeVal = clampNumber(c.val, 0, 1000000000, 0);
    html += '<div class="stat-card ' + escapeHTML(c.cls) + '" style="transition-delay:' + (0.05*i) + 's"><div class="stat-icon"><i class="fas ' + escapeHTML(c.icon) + '"></i></div><div class="stat-value" data-target="' + safeVal + '" data-suffix="' + escapeHTML(c.suffix) + '">0</div><div class="stat-label">' + escapeHTML(c.label) + '</div><div class="stat-sublabel">' + escapeHTML(c.sub) + '</div></div>';
  });
  grid.innerHTML = html;
  setTimeout(function() {
    grid.querySelectorAll('.stat-card').forEach(function(el, i) { setTimeout(function() { el.classList.add('visible'); }, i * 80); });
    animateCounters();
  }, 200);
}

async function loadStats() {
  var grid = document.getElementById('statsGrid');
  if (!grid) return;
  try {
    var stats = await loadStatsFromDB();
    renderStats(stats);
  } catch(e2) {
    console.error('Stats error:', e2);
    grid.innerHTML = '<div style="grid-column:1/-1;text-align:center;color:var(--text-muted);padding:40px;">تعذر تحميل الإحصائيات</div>';
  }
}

window.toggleFaq = function(el) {
  el.classList.toggle('open');
  var a = el.nextElementSibling;
  if (a) a.classList.toggle('open');
};
