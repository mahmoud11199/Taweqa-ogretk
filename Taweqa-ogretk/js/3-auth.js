window.handleRegister = async function() {
  if (!supabase) { showToast('خدمة التسجيل غير متاحة'); return; }
  var name = document.getElementById('reg-name').value.trim();
  var email = document.getElementById('reg-email').value.trim();
  var phone = document.getElementById('reg-phone').value.trim();
  var pass = document.getElementById('reg-password').value;
  var confirm = document.getElementById('reg-confirm').value;
  var refCode = document.getElementById('reg-ref').value.trim().toUpperCase();
  if (!name) { showAlert('register-alert', 'يرجى إدخال الاسم الكامل'); return; }
  if (!email) { showAlert('register-alert', 'يرجى إدخال البريد الإلكتروني'); return; }
  if (!pass || pass.length < 6) { showAlert('register-alert', 'كلمة السر يجب أن تكون 6 أحرف على الأقل'); return; }
  if (pass !== confirm) { showAlert('register-alert', 'كلمة السر غير متطابقة'); return; }
  setLoading('register', true);
  try {
    var requestedRole = selectedRole;
    var { data, error } = await supabase.auth.signUp({
      email: email, password: pass,
      options: { data: { full_name: name, role: requestedRole, phone: phone, ref: refCode || null } }
    });
    if (error) { showAlert('register-alert', error.message || 'فشل التسجيل'); setLoading('register', false); return; }
    if (data && data.user && requestedRole === 'driver') {
      await supabase.from('driver_applications').upsert({ user_id: data.user.id, status: 'pending', payload: { full_name: name, phone: phone } });
    }
    showAlert('register-alert', 'تم إنشاء الحساب بنجاح! جاري تحويلك...', 'success');
    setTimeout(function() {
      if (!sessionInitialized) { safeInitSession(); }
    }, 2000);
  } catch (e) { showAlert('register-alert', e.message || 'حدث خطأ'); setLoading('register', false); }
};

window.handleLogin = async function() {
  if (!supabase) {
    initSupa();
    if (!supabase) {
      await new Promise(function(r) { var _t2 = setInterval(function() { if (initSupa() || supabase) { clearInterval(_t2); r(); } }, 100); setTimeout(r, 3000); });
    }
  }
  if (!supabase) { showToast('خدمة الدخول غير متاحة'); return; }
  var email = document.getElementById('login-email').value.trim();
  var pass = document.getElementById('login-password').value;
  if (!email || !pass) { showAlert('login-alert', 'يرجى إدخال البريد وكلمة السر'); return; }
  setLoading('login', true);
  try {
    var { data, error } = await supabase.auth.signInWithPassword({ email: email, password: pass });
    if (error) { showAlert('login-alert', error.message || 'فشل تسجيل الدخول'); setLoading('login', false); return; }
    updateLastActivity();
    initSession();
  } catch (e) { showAlert('login-alert', e.message || 'حدث خطأ'); setLoading('login', false); }
};

window.deleteMyAccount = async function() {
  if (!supabase || !currentUser) { showToast('يجب تسجيل الدخول أولاً'); return; }
  if (!confirm('⚠️ هل أنت متأكد؟\n\nسيتم حذف حسابك وجميع بياناتك بشكل نهائي!\nلا يمكن التراجع عن هذا الإجراء.')) return;
  if (!confirm('✅ للتأكيد النهائي: اضغط OK لحذف الحساب')) return;
  try {
    showToast('جاري حذف الحساب...');
    var { data, error } = await supabase.functions.invoke('delete-account', {});
    if (error) { showToast('❌ فشل حذف الحساب: ' + error.message); return; }
    if (data && data.success) {
      currentUser = null; currentProfile = null;
      showLandingPage();
      showToast('✅ تم حذف الحساب وجميع البيانات المرتبطة');
    } else {
      showToast('❌ فشل حذف الحساب');
    }
  } catch (e) { showToast('❌ حدث خطأ: ' + e.message); console.error(e); }
};

window.handleLogout = async function() {
  if (!supabase) return;
  stopGlobalGPS();
  if (typeof trackInterval !== 'undefined' && trackInterval) { clearInterval(trackInterval); trackInterval = null; }
  if (window.passengerRequestPollTimer) { clearInterval(window.passengerRequestPollTimer); window.passengerRequestPollTimer = null; }
  if (typeof acceptedDriverLocTimer !== 'undefined' && acceptedDriverLocTimer) { clearInterval(acceptedDriverLocTimer); acceptedDriverLocTimer = null; }
  if (typeof driverRequestPollTimer !== 'undefined' && driverRequestPollTimer) { clearInterval(driverRequestPollTimer); driverRequestPollTimer = null; }
  if (typeof chatPollTimer !== 'undefined' && chatPollTimer) { clearInterval(chatPollTimer); chatPollTimer = null; }
  try { localStorage.removeItem('taweqe_last_activity'); } catch(e) {}
  await supabase.auth.signOut();
  currentUser = null; currentProfile = null;
  showLandingPage();
  showToast('تم تسجيل الخروج');
};

window.handleForgotPassword = function() { showAuthForm('forgot'); };
window.handleForgotPasswordSend = async function() {
  if (!supabase) return;
  var email = document.getElementById('forgot-email').value.trim();
  if (!email) { showAlert('forgot-alert', 'يرجى إدخال البريد الإلكتروني'); return; }
  setLoading('forgot', true);
  try {
    var { error } = await supabase.auth.resetPasswordForEmail(email, { redirectTo: SUPABASE_URL + '/functions/v1/auth-callback' });
    if (error) { showAlert('forgot-alert', error.message); setLoading('forgot', false); return; }
    showAlert('forgot-alert', 'تم إرسال رابط إعادة التعيين إلى بريدك', 'success');
    setLoading('forgot', false);
  } catch (e) { showAlert('forgot-alert', e.message); setLoading('forgot', false); }
};

window.handlePasswordReset = async function() {
  if (!supabase) return;
  var np = document.getElementById('new-password');
  var cp = document.getElementById('confirm-password');
  var pe = document.getElementById('password-error');
  pe.style.display = 'none';
  if (np.value.length < 6) { pe.textContent = 'كلمة السر يجب أن تكون 6 أحرف على الأقل'; pe.style.display = 'block'; return; }
  if (np.value !== cp.value) { pe.textContent = 'كلمة السر غير متطابقة'; pe.style.display = 'block'; return; }
  document.getElementById('reset-btn').style.display = 'none';
  document.getElementById('reset-loading').classList.remove('hidden-el');
  try {
    var { error } = await supabase.auth.updateUser({ password: np.value });
    if (error) { window.showError(error.message || 'فشل تغيير كلمة السر'); document.getElementById('reset-btn').style.display = 'block'; document.getElementById('reset-loading').classList.add('hidden-el'); return; }
    window.showSuccess('تم تغيير كلمة السر بنجاح', 'يمكنك الآن تسجيل الدخول بكلمة السر الجديدة');
  } catch (e) { window.showError(e.message || 'حدث خطأ'); document.getElementById('reset-btn').style.display = 'block'; document.getElementById('reset-loading').classList.add('hidden-el'); }
};

async function initSession() {
  if (!supabase) { clearTimeout(loadingFallback); showLandingPage(); return; }
  try {
    var { data: { session }, error } = await supabase.auth.getSession();
    if (error || !session) { sessionInitialized = true; clearTimeout(loadingFallback); showLandingPage(); return; }
    sessionInitialized = true;
    currentUser = session.user;
    if (checkSessionInactivity()) { clearTimeout(loadingFallback); showLandingPage(); return; }
    updateLastActivity();
    var { data: profile } = await supabase.from('profiles').select('*').eq('id', currentUser.id).single();
    currentProfile = profile;
    if (!profile) { clearTimeout(loadingFallback); showLandingPage(); return; }
    clearTimeout(loadingFallback);
    if (profile.role === 'driver') showDriverDashboard();
    else if (profile.role === 'passenger') showPassengerDashboard();
    else showLandingPage();
  } catch (e) { console.error('Session error:', e); clearTimeout(loadingFallback); showLandingPage(); }
}

function showDriverDashboard() {
  showScreen('driver-app');
  document.getElementById('driver-profile-name').textContent = currentProfile.full_name || currentUser.email;
  loadDriverStats();
  loadDriverRating();
  loadDriverCarInfo();
  loadDataFromStorage();
  switchActiveMeterUI(1);
  updateDotsUI();
  initDriverMap();
  initGlobalGPS();
  if ('Notification' in window && Notification.permission === 'default') {
    Notification.requestPermission();
  }
  if (driverRequestPollTimer) clearInterval(driverRequestPollTimer);
  driverRequestPollTimer = setInterval(function() {
    loadDriverRequests();
  }, 8000);
  loadDriverAvailability();
}

async function loadDriverAvailability() {
  if (!supabase || !currentUser) return;
  try {
    var { data: drv } = await supabase.from('drivers').select('is_available').eq('id', currentUser.id).single();
    if (drv) setDriverAvailableUI(drv.is_available);
  } catch(e) { console.error(e); }
}

function showPassengerDashboard() {
  showScreen('passenger-app');
  document.getElementById('passenger-profile-name').textContent = currentProfile.full_name || currentUser.email;
  loadPassengerStats();
}

async function loadDriverStats() {
  if (!supabase || !currentUser) return;
  try {
    var { data: trips } = await supabase.from('trips').select('total_fare').eq('driver_id', currentUser.id).eq('status', 'completed');
    if (trips) {
      document.getElementById('driver-stat-trips').textContent = trips.length;
      var rev = trips.reduce(function(s, t) { return s + (parseFloat(t.total_fare) || 0); }, 0);
      document.getElementById('driver-stat-revenue').textContent = rev.toFixed(0);
    }
  } catch (e) { console.error(e); }
}

async function loadPassengerStats() {
  if (!supabase || !currentUser) return;
  try {
    var { data: trips } = await supabase.from('trips').select('total_fare').eq('passenger_id', currentUser.id).eq('status', 'completed');
    if (trips) {
      document.getElementById('passenger-stat-trips').textContent = trips.length;
      var spent = trips.reduce(function(s, t) { return s + (parseFloat(t.total_fare) || 0); }, 0);
      document.getElementById('passenger-stat-spent').textContent = spent.toFixed(0);
    }
  } catch (e) { console.error(e); }
}

function parseHash() {
  var hash = window.location.hash.replace('#', '');
  if (!hash) return null;
  var params = {};
  hash.split('&').forEach(function(pair) {
    var parts = pair.split('=');
    if (parts[0] && parts[1]) params[decodeURIComponent(parts[0])] = decodeURIComponent(parts[1]);
  });
  return params;
}

function showOnly(el) {
  [document.getElementById('processing-card'), document.getElementById('success-card'), document.getElementById('error-card'), document.getElementById('reset-form')].forEach(function(e) { if (e) e.style.display = 'none'; });
  if (el) el.style.display = 'block';
}

window.showError = function(msg) {
  var el = document.getElementById('error-message');
  if (el) el.textContent = msg;
  showOnly(document.getElementById('error-card'));
};
window.showSuccess = function(title, msg) {
  var st = document.getElementById('success-title');
  var sm = document.getElementById('success-message');
  if (st) st.textContent = title;
  if (sm) sm.textContent = msg;
  showOnly(document.getElementById('success-card'));
};

async function handleAuthRedirect() {
  var params = parseHash();
  if (!params || !params.access_token) return false;
  if (!supabase) return false;
  showScreen('auth-container');
  document.getElementById('processing-card').style.display = 'block';
  try {
    var { error } = await supabase.auth.setSession({ access_token: params.access_token, refresh_token: params.refresh_token || '' });
    if (error) {
      document.getElementById('processing-card').style.display = 'block';
      if (params.type === 'signup') {
        var v = await supabase.auth.verifyOtp({ type: 'signup', token_hash: params.token_hash || '' });
        if (v.error) { window.showError(v.error.message || 'فشل تأكيد الحساب'); return true; }
      }
    }
    var type = params.type || '';
    if (type === 'signup') window.showSuccess('تم تأكيد حسابك', 'يمكنك الآن فتح التطبيق');
    else if (type === 'recovery') { document.getElementById('processing-card').style.display = 'none'; showOnly(document.getElementById('reset-form')); }
    else if (type === 'invite') window.showSuccess('تم قبول الدعوة', 'يمكنك الآن فتح التطبيق');
    else if (type === 'magiclink') window.showSuccess('تم تسجيل الدخول', 'يمكنك الآن فتح التطبيق');
    else window.showSuccess('تم بنجاح', 'يمكنك الآن فتح التطبيق');
  } catch (e) { console.error('Auth redirect error:', e); return false; }
  return true;
}

async function loadDriverCarInfo() {
  if (!supabase || !currentUser) return;
  var modelEl = document.getElementById('driver-car-model');
  var plateEl = document.getElementById('driver-car-plate');
  var colorEl = document.getElementById('driver-car-color');
  if (!modelEl) return;
  try {
    var { data: drv } = await supabase.from('drivers').select('car_model,car_plate,car_color').eq('id', currentUser.id).single();
    if (drv) {
      modelEl.value = drv.car_model || '';
      plateEl.value = drv.car_plate || '';
      colorEl.value = drv.car_color || '';
    }
  } catch(e) { console.error('Load car info error:', e); }
}

window.saveDriverCarInfo = async function() {
  if (!supabase || !currentUser) return;
  var model = document.getElementById('driver-car-model').value.trim();
  var plate = document.getElementById('driver-car-plate').value.trim();
  var color = document.getElementById('driver-car-color').value.trim();
  var statusEl = document.getElementById('driver-car-status');
  try {
    var { error } = await supabase.from('drivers').update({ car_model: model || null, car_plate: plate || null, car_color: color || null }).eq('id', currentUser.id);
    if (error) throw error;
    statusEl.style.display = 'block';
    setTimeout(function() { statusEl.style.display = 'none'; }, 3000);
  } catch(e) { console.error('Save car info error:', e); alert('فشل حفظ بيانات المركبة'); }
};
