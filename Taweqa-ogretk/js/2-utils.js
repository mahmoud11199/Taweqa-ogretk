function hideAllScreens() {
  landingPage.classList.add('hidden');
  authContainer.style.display = 'none';
  driverApp.classList.remove('active'); driverApp.style.display = 'none';
  passengerApp.classList.remove('active'); passengerApp.style.display = 'none';
  loadingScreen.classList.add('hidden');
}

function showScreen(id) {
  hideAllScreens();
  var el = document.getElementById(id);
  if (!el) return;
  if (id === 'landing-page') el.classList.remove('hidden');
  else if (id === 'auth-container') el.style.display = 'block';
  else { el.classList.add('active'); el.style.display = 'block'; }
}

function showLandingPage() { showScreen('landing-page'); initLandingPage(); }
function showAuth(form) { showScreen('auth-container'); showAuthForm(form || 'login'); }
window.showAuth = showAuth;

var selectedRole = 'passenger';
function showAuthForm(form) {
  ['login-card','register-card','forgot-card','reset-form','success-card','error-card','processing-card'].forEach(function(id) {
    var el = document.getElementById(id);
    if (el) el.style.display = 'none';
  });
  var card = document.getElementById(form + '-card');
  if (card) card.style.display = 'block';
}
window.showAuthForm = showAuthForm;

function selectRole(role) {
  selectedRole = role;
  document.getElementById('role-driver').classList.toggle('active', role === 'driver');
  document.getElementById('role-passenger').classList.toggle('active', role === 'passenger');
  var dtypeSection = document.getElementById('driver-type-section');
  if (role === 'driver') {
    dtypeSection.style.display = 'block';
    document.getElementById('register-btn-text').textContent = 'تسجيل كسائق';
  } else {
    dtypeSection.style.display = 'none';
    document.getElementById('register-btn-text').textContent = 'تسجيل كراكب';
    hideAllDriverFields();
  }
}
window.selectRole = selectRole;

function hideAllDriverFields() {
  document.querySelectorAll('.driver-fields').forEach(function(el) { el.style.display = 'none'; });
  document.querySelectorAll('.dtype-btn').forEach(function(el) { el.classList.remove('active'); });
  document.getElementById('reg-driver-type').value = '';
}
window.selectDriverType = function(type) {
  document.querySelectorAll('.dtype-btn').forEach(function(el) {
    el.classList.toggle('active', el.getAttribute('data-type') === type);
  });
  document.getElementById('reg-driver-type').value = type;
  hideAllDriverFields();
  var section = document.getElementById('driver-fields-' + type);
  if (section) section.style.display = 'block';
};
function getDriverFields(type) {
  var fields = {};
  switch (type) {
    case 'private':
      fields = {
        plate: document.getElementById('dprivate-plate').value.trim(),
        model: document.getElementById('dprivate-model').value.trim(),
        year: document.getElementById('dprivate-year').value.trim(),
        license: document.getElementById('dprivate-license').files[0],
        carLicense: document.getElementById('dprivate-car-license').files[0],
        criminal: document.getElementById('dprivate-criminal').files[0]
      };
      break;
    case 'tuk-tuk':
      fields = {
        nationalId: document.getElementById('dtuktuk-national').value.trim(),
        chassis: document.getElementById('dtuktuk-chassis').value.trim(),
        area: document.getElementById('dtuktuk-area').value.trim(),
        idFront: document.getElementById('dtuktuk-id-front').files[0],
        idBack: document.getElementById('dtuktuk-id-back').files[0],
        contract: document.getElementById('dtuktuk-contract').files[0],
        video: document.getElementById('dtuktuk-video').files[0]
      };
      break;
    case 'motorcycle':
      fields = {
        plate: document.getElementById('dmoto-plate').value.trim(),
        model: document.getElementById('dmoto-model').value.trim(),
        license: document.getElementById('dmoto-license').files[0],
        bikeLicense: document.getElementById('dmoto-bike-license').files[0],
        nationalId: document.getElementById('dmoto-national-id').files[0]
      };
      break;
  }
  return fields;
}
function validateDriverFields(type) {
  var fields = getDriverFields(type);
  var errors = [];
  switch (type) {
    case 'private':
      if (!fields.plate) errors.push('رقم السيارة (اللوحة)');
      if (!fields.model) errors.push('الموديل');
      if (!fields.year) errors.push('سنة الصنع');
      if (!fields.license) errors.push('صورة رخصة القيادة');
      if (!fields.carLicense) errors.push('صورة رخصة السيارة');
      if (!fields.criminal) errors.push('صورة الفيش والتشبيه');
      break;
    case 'tuk-tuk':
      if (!fields.nationalId) errors.push('الرقم القومي لصاحب التوك توك');
      if (!fields.idFront) errors.push('صورة البطاقة (وجه)');
      if (!fields.idBack) errors.push('صورة البطاقة (ظهر)');
      if (!fields.contract) errors.push('عقد الشراء/المبايعة');
      break;
    case 'motorcycle':
      if (!fields.plate) errors.push('رقم اللوحة');
      if (!fields.model) errors.push('الماركة/الموديل');
      if (!fields.license) errors.push('رخصة قيادة الدراجة النارية');
      if (!fields.bikeLicense) errors.push('رخصة الموتوسيكل');
      if (!fields.nationalId) errors.push('صورة بطاقة الرقم القومي');
      break;
  }
  return errors;
}

function setLoading(prefix, loading) {
  var btn = document.getElementById(prefix + '-btn');
  var ld = document.getElementById(prefix + '-loading');
  if (btn) btn.style.display = loading ? 'none' : '';
  if (ld) ld.classList.toggle('hidden-el', !loading);
}

function showAlert(id, msg, type) {
  var el = document.getElementById(id);
  if (!el) return;
  el.textContent = msg;
  el.className = 'auth-alert ' + (type || 'error');
}

function escapeHTML(value) {
  return String(value == null ? '' : value).replace(/[&<>"']/g, function(ch) {
    return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[ch];
  });
}

function clampNumber(value, min, max, fallback) {
  var n = Number(value);
  if (!Number.isFinite(n)) return fallback;
  return Math.min(max, Math.max(min, n));
}

window.showToast = function(msg) {
  var t = document.getElementById('toast');
  t.innerText = msg; t.style.display = 'block';
  setTimeout(function() { t.style.display = 'none'; }, 3000);
};
