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
window.setFieldError = function(fieldId, hasError) {
  var el = typeof fieldId === 'string' ? document.getElementById(fieldId) : fieldId;
  if (el) {
    el.style.borderColor = hasError ? 'var(--error,#ef4444)' : '';
    el.style.boxShadow = hasError ? '0 0 0 2px rgba(239,68,68,0.2)' : '';
  }
};

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

window.showPromptModal = function(options) {
  return new Promise(function(resolve) {
    var overlay = document.createElement('div');
    overlay.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,0.6);z-index:9999;display:flex;align-items:center;justify-content:center;padding:20px;direction:rtl';
    var card = document.createElement('div');
    card.style.cssText = 'background:var(--card-bg,#1e293b);color:var(--text,#fff);border-radius:16px;padding:24px;width:100%;max-width:380px;box-shadow:0 16px 48px rgba(0,0,0,0.4);';
    var title = document.createElement('div');
    title.style.cssText = 'font-size:16px;font-weight:700;margin-bottom:16px;text-align:center';
    title.textContent = options.title || 'إدخال';
    card.appendChild(title);
    var input;
    if (options.fields) {
      options.fields.forEach(function(f) {
        var label = document.createElement('div');
        label.style.cssText = 'font-size:12px;color:var(--meter-muted,#888);margin-bottom:4px;margin-top:8px';
        label.textContent = f.label;
        card.appendChild(label);
        var inp = document.createElement(f.type === 'textarea' ? 'textarea' : 'input');
        inp.type = f.type === 'textarea' ? undefined : (f.type || 'text');
        inp.placeholder = f.placeholder || '';
        if (f.type === 'password') inp.autocomplete = 'off';
        inp.style.cssText = 'width:100%;padding:10px 12px;border-radius:10px;border:1px solid var(--meter-border,#333);background:rgba(255,255,255,0.05);color:#fff;font-size:14px;outline:none;box-sizing:border-box;font-family:inherit';
        if (f.defaultValue) inp.value = f.defaultValue;
        card.appendChild(inp);
        if (!input) input = inp;
      });
    } else {
      input = document.createElement('input');
      input.type = options.type === 'password' ? 'password' : (options.type || 'text');
      input.placeholder = options.placeholder || '';
      input.style.cssText = 'width:100%;padding:10px 12px;border-radius:10px;border:1px solid var(--meter-border,#333);background:rgba(255,255,255,0.05);color:#fff;font-size:14px;outline:none;box-sizing:border-box;font-family:inherit';
      if (options.defaultValue) input.value = options.defaultValue;
      card.appendChild(input);
    }
    var btnRow = document.createElement('div');
    btnRow.style.cssText = 'display:flex;gap:10px;margin-top:18px';
    var confirmBtn = document.createElement('button');
    confirmBtn.textContent = options.confirmText || 'تأكيد';
    confirmBtn.style.cssText = 'flex:1;padding:10px;border-radius:10px;border:none;background:var(--success,#22c55e);color:#fff;font-size:14px;font-weight:700;cursor:pointer';
    var cancelBtn = document.createElement('button');
    cancelBtn.textContent = options.cancelText || 'إلغاء';
    cancelBtn.style.cssText = 'flex:1;padding:10px;border-radius:10px;border:1px solid var(--meter-border,#333);background:transparent;color:var(--text-muted,#888);font-size:14px;cursor:pointer';
    btnRow.appendChild(cancelBtn);
    btnRow.appendChild(confirmBtn);
    card.appendChild(btnRow);
    overlay.appendChild(card);
    document.body.appendChild(overlay);
    if (input) setTimeout(function() { input.focus(); }, 100);
    function close() { if (overlay.parentNode) overlay.parentNode.removeChild(overlay); }
    confirmBtn.onclick = function() {
      var val;
      if (options.fields) {
        val = {};
        options.fields.forEach(function(f, i) {
          var inp = card.querySelectorAll('input,textarea')[i];
          val[f.key] = inp ? inp.value.trim() : '';
        });
      } else {
        val = input ? input.value.trim() : '';
      }
      if (options.validator) {
        var err = options.validator(val);
        if (err) { showToast(err); return; }
      }
      close(); resolve(val);
    };
    cancelBtn.onclick = function() { close(); resolve(null); };
    overlay.onclick = function(e) { if (e.target === overlay) { close(); resolve(null); } };
    if (input) input.onkeydown = function(e) {
      if (e.key === 'Enter') confirmBtn.click();
      if (e.key === 'Escape') cancelBtn.click();
    };
  });
};

window.showLoading = function(msg) {
  var el = document.getElementById('app-loading');
  if (!el) {
    el = document.createElement('div');
    el.id = 'app-loading';
    el.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,0.5);z-index:9998;display:flex;align-items:center;justify-content:center;flex-direction:column;gap:12px;direction:rtl';
    var spinner = document.createElement('div');
    spinner.style.cssText = 'width:40px;height:40px;border:4px solid rgba(255,255,255,0.1);border-top-color:var(--meter-primary,#f59e0b);border-radius:50%;animation:spin 0.8s linear infinite';
    el.appendChild(spinner);
    var txt = document.createElement('div');
    txt.id = 'app-loading-text';
    txt.style.cssText = 'color:#fff;font-size:14px;font-weight:600';
    el.appendChild(txt);
    document.body.appendChild(el);
    if (!document.getElementById('app-loading-style')) {
      var style = document.createElement('style');
      style.id = 'app-loading-style';
      style.textContent = '@keyframes spin{to{transform:rotate(360deg)}}';
      document.head.appendChild(style);
    }
  }
  document.getElementById('app-loading-text').textContent = msg || 'جاري التحميل...';
  el.style.display = 'flex';
};
window.hideLoading = function() {
  var el = document.getElementById('app-loading');
  if (el) el.style.display = 'none';
};

window.showToast = function(msg) {
  var container = document.getElementById('toast-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'toast-container';
    container.style.cssText = 'position:fixed;top:16px;left:50%;transform:translateX(-50%);z-index:1000;display:flex;flex-direction:column;gap:8px;max-width:90%;width:400px;pointer-events:none';
    container.setAttribute('role', 'status');
    container.setAttribute('aria-live', 'polite');
    document.body.appendChild(container);
  }
  var t = document.createElement('div');
  t.style.cssText = 'background:var(--card-bg,#1e293b);color:var(--text,#fff);padding:12px 20px;border-radius:12px;box-shadow:0 8px 32px rgba(0,0,0,0.3);text-align:center;font-size:14px;line-height:1.5;word-break:break-word;opacity:0;transform:translateY(-10px);transition:all 0.3s ease;direction:rtl';
  t.textContent = msg;
  container.appendChild(t);
  requestAnimationFrame(function() { t.style.opacity = '1'; t.style.transform = 'translateY(0)'; });
  setTimeout(function() {
    t.style.opacity = '0'; t.style.transform = 'translateY(-10px)';
    setTimeout(function() { if (t.parentNode) t.parentNode.removeChild(t); }, 300);
  }, 3000);
};
