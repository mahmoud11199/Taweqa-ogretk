	  document.addEventListener('DOMContentLoaded', function() {
    var np = document.getElementById('new-password');
    var cp = document.getElementById('confirm-password');
    var pe = document.getElementById('password-error');
    var sb = document.getElementById('password-strength');
    if (np) {
      np.addEventListener('input', function() {
        var len = this.value.length;
        if (len === 0) { sb.style.width = '0'; sb.style.background = ''; return; }
        sb.style.width = '100%';
        if (len < 6) sb.style.background = '#ef4444';
        else if (len < 10) sb.style.background = '#f59e0b';
        else sb.style.background = '#22c55e';
      });
      np.addEventListener('keydown', function(e) { if (e.key === 'Enter' && cp) cp.focus(); });
    }
    if (cp) {
      cp.addEventListener('input', function() {
        if (this.value.length > 0 && this.value !== np.value) { pe.textContent = 'كلمة السر غير متطابقة'; pe.style.display = 'block'; }
        else { pe.style.display = 'none'; }
      });
      cp.addEventListener('keydown', function(e) { if (e.key === 'Enter') handlePasswordReset(); });
    }

    // Register form password strength
    var rp = document.getElementById('reg-password');
    var rc = document.getElementById('reg-confirm');
    var rs = document.getElementById('reg-password-strength');
    var re = document.getElementById('reg-password-error');
    if (rp) {
      rp.addEventListener('input', function() {
        var len = this.value.length;
        if (len === 0) { rs.style.width = '0'; rs.style.background = ''; return; }
        rs.style.width = '100%';
        if (len < 6) rs.style.background = '#ef4444';
        else if (len < 10) rs.style.background = '#f59e0b';
        else rs.style.background = '#22c55e';
      });
    }
    if (rc) {
      rc.addEventListener('input', function() {
        if (this.value.length > 0 && this.value !== rp.value) { re.textContent = 'كلمة السر غير متطابقة'; re.style.display = 'block'; }
        else { re.style.display = 'none'; }
      });
    }
  });
  var sessionInitialized = false;

  // Fallback: show landing page after 4s regardless of what happens
  var loadingFallback = setTimeout(function() {
    if (loadingScreen && !loadingScreen.classList.contains('hidden')) {
      console.warn('Loading fallback triggered');
      showLandingPage();
    }
  }, 4000);

  function safeInitSession() {
    if (sessionInitialized) return;
    initSession().catch(function(e) {
      console.error('initSession failed:', e);
      showLandingPage();
    });
  }

  async function init() {
    try {
      // Check auth redirect first
      var handled = await handleAuthRedirect();
      if (handled) { clearTimeout(loadingFallback); return; }
      // Listen for auth state changes
      if (supabase) {
        supabase.auth.onAuthStateChanged(function(event, session) {
          if (event === 'SIGNED_IN' && session) {
            sessionInitialized = true;
            currentUser = session.user;
            initSession().catch(function(e) { console.error(e); showLandingPage(); });
          }
          if (event === 'SIGNED_OUT') {
            sessionInitialized = false;
            currentUser = null; currentProfile = null;
            showLandingPage();
          }
        });
      }
      // Try to get existing session
      safeInitSession();
    } catch(e) {
      console.error('Init error:', e);
      showLandingPage();
    }
  }

  init();
