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
    if (!error && data) { console.log('Stats: RPC success', data); return data; }
    console.warn('Stats: RPC returned error or null', error, data);
  } catch(e) { console.warn('Stats: RPC threw', e); }
  async function safeQuery(promise) { try { return await promise; } catch(e) { console.warn('Stats: query failed', e); return { data: [] }; } }
  var q1 = safeQuery(supabase.from('profiles').select('id, role'));
  var q2 = safeQuery(supabase.from('trips').select('total_fare, distance_km, status, created_at'));
  var q3 = safeQuery(supabase.from('ratings').select('score'));
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

// --- Quick Fare Calculator ---
var calcGovernoratePrices = {
  cairo: { tuk_tuk: { base: 8, per_km: 3 }, microbus: { base: 5, per_km: 2 }, taxi: { base: 12, per_km: 4.5 }, private_car: { base: 10, per_km: 3.5 } },
  giza: { tuk_tuk: { base: 7, per_km: 3 }, microbus: { base: 5, per_km: 2 }, taxi: { base: 11, per_km: 4 }, private_car: { base: 10, per_km: 3.5 } },
  alex: { tuk_tuk: { base: 8, per_km: 3.5 }, microbus: { base: 5, per_km: 2 }, taxi: { base: 13, per_km: 5 }, private_car: { base: 11, per_km: 4 } },
  default: { tuk_tuk: { base: 6, per_km: 2.5 }, microbus: { base: 4, per_km: 1.5 }, taxi: { base: 10, per_km: 3.5 }, private_car: { base: 8, per_km: 3 } }
};

window.quickCalcFare = function() {
  var gov = document.getElementById('calc-governorate').value;
  var veh = document.getElementById('calc-vehicle').value;
  var dist = parseFloat(document.getElementById('calc-distance').value);
  var alertEl = document.getElementById('calc-alert');
  var resultEl = document.getElementById('calc-result');
  alertEl.className = 'calc-alert';
  resultEl.style.display = 'none';
  if (!gov) {
    alertEl.className = 'calc-alert error';
    alertEl.textContent = '⚠️ الرجاء اختيار المحافظة';
    alertEl.style.display = 'block';
    document.getElementById('calc-governorate').focus();
    return;
  }
  if (!veh) {
    alertEl.className = 'calc-alert error';
    alertEl.textContent = '⚠️ الرجاء اختيار نوع المركبة';
    alertEl.style.display = 'block';
    document.getElementById('calc-vehicle').focus();
    return;
  }
  if (!dist || dist <= 0) {
    alertEl.className = 'calc-alert error';
    alertEl.textContent = '⚠️ الرجاء إدخال المسافة التقريبية أو الضغط على "موقعي"';
    alertEl.style.display = 'block';
    document.getElementById('calc-distance').focus();
    return;
  }
  var prices = calcGovernoratePrices[gov] || calcGovernoratePrices.default;
  var vehKey = veh.replace(/-/g, '_');
  var price = prices[vehKey] || calcGovernoratePrices.default[vehKey] || { base: 5, per_km: 2.5 };
  var fare = price.base + (dist * price.per_km);
  var fareMin = Math.round(fare);
  var fareMax = Math.round(fare * 1.25);
  var govName = document.getElementById('calc-governorate').options[document.getElementById('calc-governorate').selectedIndex].text;
  var vehName = document.getElementById('calc-vehicle').options[document.getElementById('calc-vehicle').selectedIndex].text;
  document.getElementById('calc-r-governorate').textContent = govName;
  document.getElementById('calc-r-vehicle').textContent = vehName;
  document.getElementById('calc-r-distance').textContent = dist.toFixed(1) + ' كم';
  document.getElementById('calc-r-fare').textContent = fareMin + ' - ' + fareMax + ' ج.م';
  resultEl.style.display = 'block';
  var card = document.getElementById('calcCard');
  if (card) { card.style.transition = 'border-color 0.3s'; card.style.borderColor = 'rgba(34,197,94,0.3)'; setTimeout(function() { card.style.borderColor = ''; }, 2000); }
};

window.calcUseMyLocation = function() {
  var gpsStatus = document.getElementById('calc-gps-status');
  gpsStatus.style.display = 'block';
  gpsStatus.textContent = '⏳ جلب الموقع...';
  if (!navigator.geolocation) {
    gpsStatus.textContent = '⚠️ متصفحك لا يدعم تحديد الموقع';
    return;
  }
  navigator.geolocation.getCurrentPosition(
    function(pos) {
      var lat = pos.coords.latitude;
      var lng = pos.coords.longitude;
      gpsStatus.textContent = '✅ تم تحديد موقعك بنجاح (' + lat.toFixed(4) + ', ' + lng.toFixed(4) + ')';
      // Cairo center as reference: 30.0444, 31.2357
      var refLat = 30.0444, refLng = 31.2357;
      // Haversine formula for rough distance in km
      var R = 6371;
      var dLat = (lat - refLat) * Math.PI / 180;
      var dLng = (lng - refLng) * Math.PI / 180;
      var a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(refLat * Math.PI / 180) * Math.cos(lat * Math.PI / 180) * Math.sin(dLng/2) * Math.sin(dLng/2);
      var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      var distKm = Math.round(R * c * 10) / 10;
      if (distKm < 0.5) distKm = 1;
      document.getElementById('calc-distance').value = distKm;
      document.getElementById('calc-gps-btn').innerHTML = '<i class="fas fa-check"></i> تم';
      setTimeout(function() { document.getElementById('calc-gps-btn').innerHTML = '<i class="fas fa-location-dot"></i> موقعي'; }, 3000);
    },
    function(err) {
      var msgs = { 1: '⚠️ تم رفض إذن الموقع — يرجى السماح بالوصول للموقع في إعدادات المتصفح', 2: '⚠️ الموقع غير متاح — تأكد من تفعيل GPS', 3: '⏱️ انتهت مهلة تحديد الموقع — حاول مرة أخرى' };
      gpsStatus.textContent = msgs[err.code] || '⚠️ خطأ في تحديد الموقع: ' + err.message;
    },
    { enableHighAccuracy: true, timeout: 10000, maximumAge: 60000 }
  );
};

var installPrompt = null;
window.addEventListener('beforeinstallprompt', function(e) {
  e.preventDefault();
  installPrompt = e;
  var btn = document.getElementById('installPwaBtn');
  if (btn) btn.style.display = '';
});
window.addEventListener('appinstalled', function() {
  installPrompt = null;
  var btn = document.getElementById('installPwaBtn');
  if (btn) btn.style.display = 'none';
});
window.installApp = function() {
  if (installPrompt) {
    installPrompt.prompt();
    installPrompt.userChoice.then(function(choice) {
      if (choice.outcome === 'accepted') {
        installPrompt = null;
        var btn = document.getElementById('installPwaBtn');
        if (btn) btn.style.display = 'none';
      }
    });
  } else {
    alert('التطبيق مثبت بالفعل أو متصفحك لا يدعم التثبيت.\nافتح التطبيق من الشاشة الرئيسية أو استخدم متصفح Chrome/Edge/Firefox على أندرويد.');
  }
};
