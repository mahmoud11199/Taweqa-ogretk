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
  document.getElementById('register-btn-text').textContent = role === 'driver' ? 'تسجيل كسائق' : 'تسجيل كراكب';
}
window.selectRole = selectRole;

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
