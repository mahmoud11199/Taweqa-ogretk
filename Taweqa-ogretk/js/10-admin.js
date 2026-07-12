  var adminApp = document.getElementById('admin-app');

  function switchAdminTab(tab, btn) {
    ['dashboard','drivers','applications','trips','sos'].forEach(function(t) {
      var el = document.getElementById('admin-' + t + '-section');
      if (el) el.style.display = t === tab ? 'block' : 'none';
    });
    document.querySelectorAll('#admin-app .app-nav .tab-btn').forEach(function(b) { b.classList.remove('active'); });
    if (btn) btn.classList.add('active');
  }
  window.switchAdminTab = switchAdminTab;

  async function loadAdminStats() {
    if (!supabase) return;
    try {
      var { data: profiles } = await supabase.from('profiles').select('role').limit(2000);
      var drivers = profiles ? profiles.filter(function(p) { return p.role === 'driver'; }).length : 0;
      var passengers = profiles ? profiles.filter(function(p) { return p.role === 'passenger'; }).length : 0;
      document.getElementById('admin-stat-drivers').textContent = drivers;
      document.getElementById('admin-stat-passengers').textContent = passengers;
      var { count: tripsCount } = await supabase.from('trips').select('id', { count: 'exact', head: true });
      document.getElementById('admin-stat-trips').textContent = tripsCount || 0;
      var { count: appsCount } = await supabase.from('driver_applications').select('id', { count: 'exact', head: true }).eq('status', 'pending');
      document.getElementById('admin-stat-applications').textContent = appsCount || 0;
    } catch(e) { console.error('Admin stats error:', e); }
  }

  async function loadAdminDrivers() {
    if (!supabase) return;
    var list = document.getElementById('adminDriversList');
    try {
      var { data: drv } = await supabase.from('drivers').select('id, is_available, driver_type, car_model, car_plate, active_trips_count, created_at').order('created_at', { ascending: false }).limit(100);
      if (!drv || !drv.length) { list.innerHTML = '<div class="empty-state">لا يوجد سائقين</div>'; return; }
      var ids = drv.map(function(d) { return d.id; });
      var { data: profs } = await supabase.from('profiles').select('id, full_name, phone').in('id', ids);
      var pm = {}; if (profs) profs.forEach(function(p) { pm[p.id] = p; });
      list.innerHTML = drv.map(function(d) {
        var p = pm[d.id] || {};
        return '<div class="driver-request-item"><div class="top"><span class="name">' + escapeHTML(p.full_name || '---') + '</span><span class="req-badge ' + (d.is_available ? '' : 'cancelled') + '">' + (d.is_available ? '🟢 متاح' : '🔴 مشغول') + '</span></div><div class="info"><i class="fas fa-phone"></i> ' + escapeHTML(p.phone || '-') + '</div><div class="info"><i class="fas fa-tag"></i> ' + escapeHTML(d.driver_type || '-') + '</div><div class="info"><i class="fas fa-car"></i> ' + escapeHTML(d.car_model || '') + ' ' + escapeHTML(d.car_plate || '') + '</div><div class="info"><i class="fas fa-route"></i> رحلات نشطة: ' + (d.active_trips_count || 0) + '</div></div>';
      }).join('');
    } catch(e) { list.innerHTML = '<div class="empty-state">خطأ</div>'; console.error(e); }
  }
  window.loadAdminDrivers = loadAdminDrivers;

  async function loadAdminApplications() {
    if (!supabase) return;
    var list = document.getElementById('adminApplicationsList');
    try {
      var { data: apps } = await supabase.from('driver_applications').select('*').eq('status', 'pending').order('created_at', { ascending: false }).limit(50);
      if (!apps || !apps.length) { list.innerHTML = '<div class="empty-state">لا توجد طلبات معلقة</div>'; return; }
      list.innerHTML = apps.map(function(a) {
        var payload = a.payload || {};
        var filesHtml = '';
        if (payload.fileUrls) {
          filesHtml = '<div style="font-size:11px;margin-top:4px;">';
          for (var k in payload.fileUrls) {
            filesHtml += '<a href="' + escapeHTML(payload.fileUrls[k]) + '" target="_blank" style="color:var(--meter-primary);display:inline-block;margin:2px 4px;"><i class="fas fa-file"></i> ' + escapeHTML(payload.fields[k] || k) + '</a>';
          }
          filesHtml += '</div>';
        }
        return '<div class="driver-request-item"><div class="top"><span class="name">' + escapeHTML(payload.full_name || a.user_id) + '</span><span class="req-badge pending">معلق</span></div><div class="info"><i class="fas fa-phone"></i> ' + escapeHTML(payload.phone || '-') + '</div><div class="info"><i class="fas fa-tag"></i> ' + escapeHTML(payload.driver_type || '-') + '</div>' + filesHtml + '<div class="req-actions"><button class="btn btn-success btn-sm" onclick="approveDriverApp(\'' + a.user_id + '\')" style="padding:4px 12px;font-size:11px;"><i class="fas fa-check"></i> قبول</button><button class="btn btn-danger btn-sm" onclick="rejectDriverApp(\'' + a.user_id + '\')" style="padding:4px 12px;font-size:11px;"><i class="fas fa-times"></i> رفض</button></div></div>';
      }).join('');
    } catch(e) { list.innerHTML = '<div class="empty-state">خطأ</div>'; console.error(e); }
  }
  window.loadAdminApplications = loadAdminApplications;

  window.approveDriverApp = async function(userId) {
    if (!confirm('قبول طلب السائق؟')) return;
    try {
      await supabase.from('driver_applications').update({ status: 'approved' }).eq('user_id', userId);
      showToast('✅ تم قبول السائق');
      loadAdminApplications(); loadAdminStats();
    } catch(e) { showToast('❌ فشل'); console.error(e); }
  };

  window.rejectDriverApp = async function(userId) {
    if (!confirm('رفض طلب السائق؟')) return;
    try {
      await supabase.from('driver_applications').update({ status: 'rejected' }).eq('user_id', userId);
      showToast('تم رفض الطلب');
      loadAdminApplications(); loadAdminStats();
    } catch(e) { showToast('❌ فشل'); console.error(e); }
  };

  async function loadAdminTrips() {
    if (!supabase) return;
    var list = document.getElementById('adminTripsList');
    try {
      var { data: trips } = await supabase.from('trips').select('id, join_code, status, classification, total_fare, distance_km, driver_id, passenger_id, created_at, payment_method, payment_status').order('created_at', { ascending: false }).limit(50);
      if (!trips || !trips.length) { list.innerHTML = '<div class="empty-state">لا توجد رحلات</div>'; return; }
      list.innerHTML = trips.map(function(t) {
        var sc = t.status === 'completed' ? 'var(--success)' : t.status === 'cancelled' ? 'var(--error)' : t.status === 'started' || t.status === 'ongoing' ? '#3b82f6' : 'var(--accent)';
        return '<div class="history-item"><div class="history-header"><span style="color:' + sc + ';">' + escapeHTML(t.status || '-') + '</span><span style="color:var(--meter-primary)">' + escapeHTML(t.join_code || '-') + '</span></div><div class="history-details"><div>' + (t.classification === 'private' ? 'مخصوص' : 'أفراد') + '</div><div>' + clampNumber(t.distance_km, 0, 1000, 0).toFixed(1) + ' كم</div><div>' + new Date(t.created_at).toLocaleString('ar-EG') + '</div></div><div class="history-fare">' + clampNumber(t.total_fare, 0, 100000, 0).toFixed(2) + ' ج</div><div style="font-size:10px;color:var(--meter-muted);margin-top:2px;">' + (t.payment_method === 'wallet' ? 'محفظة' : 'نقدي') + ' | ' + (t.payment_status || '-') + '</div></div>';
      }).join('');
    } catch(e) { list.innerHTML = '<div class="empty-state">خطأ</div>'; console.error(e); }
  }
  window.loadAdminTrips = loadAdminTrips;

  async function loadAdminSos() {
    if (!supabase) return;
    var list = document.getElementById('adminSosList');
    try {
      var { data: sos } = await supabase.from('ride_requests').select('id, passenger_id, note, created_at').ilike('note', '%SOS%').order('created_at', { ascending: false }).limit(50);
      if (!sos || !sos.length) { list.innerHTML = '<div class="empty-state">لا توجد بلاغات SOS</div>'; return; }
      list.innerHTML = sos.map(function(s) {
        return '<div class="driver-request-item" style="border-right:3px solid var(--error);"><div class="top"><span class="name" style="color:var(--error);"><i class="fas fa-exclamation-triangle"></i> SOS</span><span class="req-badge cancelled">' + new Date(s.created_at).toLocaleString('ar-EG') + '</span></div><div class="info"><i class="fas fa-user"></i> ' + escapeHTML(s.passenger_id) + '</div><div class="info" style="color:var(--error);">' + escapeHTML(s.note || '') + '</div></div>';
      }).join('');
    } catch(e) { list.innerHTML = '<div class="empty-state">خطأ</div>'; console.error(e); }
  }
  window.loadAdminSos = loadAdminSos;

  window.processScheduledNow = async function() {
    if (!supabase) return;
    try {
      var { data, error } = await supabase.rpc('process_scheduled_rides');
      if (error) { showToast('❌ ' + error.message); return; }
      showToast('✅ تمت معالجة ' + (data || 0) + ' رحلة');
      loadAdminStats();
    } catch(e) { showToast('❌ فشل'); console.error(e); }
  };
