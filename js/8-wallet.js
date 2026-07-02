  window.loadWallet = async function() {
    if (!supabase || !currentUser) return;
    var role = currentProfile && currentProfile.role === 'driver' ? 'driver' : 'passenger';
    try {
      // Load balance
      var { data: wallet } = await supabase.from('wallets').select('balance').eq('user_id', currentUser.id).single();
      if (wallet) {
        document.getElementById('wallet-balance-' + role).textContent = wallet.balance.toFixed(2) + ' ج';
      }
      // Load transactions
      var { data: txs } = await supabase.from('wallet_transactions').select('*').eq('user_id', currentUser.id).order('created_at', { ascending: false }).limit(20);
      var txList = document.getElementById('wallet-tx-list-' + role);
      if (txs && txs.length) {
        txList.innerHTML = txs.map(function(t) {
          var sign = t.amount >= 0 ? 'positive' : 'negative';
          var typeLabels = { charge: 'شحن', subscription: 'اشتراك', refund: 'استرداد', referral_reward: 'مكافأة إحالة', withdrawal: 'سحب' };
          var statusLabels = { pending: 'قيد الانتظار', completed: 'مكتملة', failed: 'فشلت' };
          return '<div class="tx-item">'
            + '<div><div class="tx-desc">' + escapeHTML(typeLabels[t.type] || t.type) + '</div>'
            + '<div class="tx-date">' + new Date(t.created_at).toLocaleString('ar-EG') + '</div></div>'
            + '<div style="text-align:left;"><div class="tx-amount ' + sign + '">' + (t.amount >= 0 ? '+' : '') + t.amount.toFixed(2) + ' ج</div>'
            + '<div style="font-size:10px;color:var(--meter-muted)">' + statusLabels[t.status] + '</div></div></div>';
        }).join('');
      } else {
        txList.innerHTML = '<div class="empty-state">لا توجد معاملات</div>';
      }
    } catch(e) { console.error(e); }
  };

  window.showChargeForm = function(role) {
    document.getElementById('charge-form-' + role).style.display = 'block';
  };
  window.hideChargeForm = function(role) {
    document.getElementById('charge-form-' + role).style.display = 'none';
  };

  window.processCharge = async function(role) {
    if (!supabase || !currentUser) return;
    var amount = parseFloat(document.getElementById('charge-amount-' + role).value);
    if (!amount || amount < 10) { showToast('أقل مبلغ للشحن 10 جنيه'); return; }
    try {
      // Mock Paymob charge: update balance immediately (test mode)
      var { data: wallet } = await supabase.from('wallets').select('balance').eq('user_id', currentUser.id).single();
      var newBalance = (wallet ? wallet.balance : 0) + amount;
      if (wallet) {
        await supabase.from('wallets').update({ balance: newBalance }).eq('user_id', currentUser.id);
      } else {
        await supabase.from('wallets').insert({ user_id: currentUser.id, balance: amount });
      }
      await supabase.from('wallet_transactions').insert({
        user_id: currentUser.id, amount: amount, type: 'charge', status: 'completed',
        description: 'شحن المحفظة - تجريبي'
      });
      showToast('✅ تم شحن ' + amount.toFixed(2) + ' ج بنجاح (وضع اختبار)');
      hideChargeForm(role);
      loadWallet();
      checkSubscription();
    } catch(e) { showToast('فشل الشحن'); console.error(e); }
  };

  window.showSubscription = async function(role) {
    if (!supabase || !currentUser) return;
    var price = role === 'driver' ? 299 : 89;
    var planName = role === 'driver' ? '🚘 باقة السائق' : '🧑 باقة الراكب';
    try {
      var { data: wallet } = await supabase.from('wallets').select('balance').eq('user_id', currentUser.id).single();
      var balance = wallet ? wallet.balance : 0;
      var { data: sub } = await supabase.from('subscriptions').select('*').eq('user_id', currentUser.id).eq('status', 'active').order('end_date', { ascending: false }).limit(1).maybeSingle();
      var subStatus = sub ? 'نشط حتى ' + new Date(sub.end_date).toLocaleDateString('ar-EG') : 'غير مشترك';
      var isActive = !!sub;
      if (confirm(
        planName + '\nالسعر: ' + price + ' ج/شهر\n'
        + 'رصيدك: ' + balance.toFixed(2) + ' ج\n'
        + 'الحالة: ' + subStatus + '\n\n'
        + (isActive ? 'هل تريد تجديد الاشتراك؟' : 'هل تريد الاشتراك؟')
      )) {
        if (balance < price) {
          showToast('❌ الرصيد غير كافٍ. اشحن المحفظة أولاً');
          return;
        }
        // Deduct & activate
        await supabase.from('wallets').update({ balance: balance - price }).eq('user_id', currentUser.id);
        await supabase.from('wallet_transactions').insert({
          user_id: currentUser.id, amount: -price, type: 'subscription', status: 'completed',
          description: 'اشتراك شهري - ' + (role === 'driver' ? 'سائق' : 'راكب')
        });
        if (sub) {
          await supabase.from('subscriptions').update({ status: 'active', end_date: new Date(Date.now() + 30*24*60*60*1000).toISOString(), auto_renew: true }).eq('id', sub.id);
        } else {
          await supabase.from('subscriptions').insert({
            user_id: currentUser.id, plan_type: role, status: 'active',
            start_date: new Date().toISOString(), end_date: new Date(Date.now() + 30*24*60*60*1000).toISOString(), auto_renew: true
          });
        }
        showToast('✅ تم تفعيل الاشتراك لمدة 30 يوم');
        loadWallet();
      }
    } catch(e) { showToast('فشل الاشتراك'); console.error(e); }
  };

  async function checkSubscription() {
    if (!supabase || !currentUser) return;
    try {
      // Expire old ones
      await supabase.rpc('check_subscription_expiry');
      var { data: sub } = await supabase.from('subscriptions').select('*').eq('user_id', currentUser.id).eq('status', 'active').order('end_date', { ascending: false }).limit(1).maybeSingle();
      // Auto-renew if balance sufficient
      if (!sub) {
        var { data: wallet } = await supabase.from('wallets').select('balance').eq('user_id', currentUser.id).single();
        var role = currentProfile && currentProfile.role === 'driver' ? 'driver' : 'passenger';
        var price = role === 'driver' ? 299 : 89;
        if (wallet && wallet.balance >= price) {
          // Try to renew
          await supabase.rpc('renew_subscription', { p_user_id: currentUser.id });
        }
      }
    } catch(e) { /* silent */ }
  }
  window.checkSubscription = checkSubscription;

  function loadReferralInfo() {
    if (!supabase || !currentUser) return;
    var role = currentProfile && currentProfile.role === 'driver' ? 'driver' : 'passenger';
    var driverRefEl = document.getElementById('driver-ref-section');
    var passengerRefEl = document.getElementById('passenger-ref-section');
    if (role === 'driver' && !driverRefEl) return;
    if (role === 'passenger' && !passengerRefEl) return;
    var targetEl = role === 'driver' ? driverRefEl : passengerRefEl;
    supabase.from('referral_codes').select('code').eq('user_id', currentUser.id).single().then(function(r) {
      if (!r.data) return;
      var code = r.data.code;
      var shareUrl = window.location.origin + '?ref=' + code;
      supabase.from('referrals').select('id, status').eq('referrer_id', currentUser.id).then(function(r2) {
        var totalRefs = r2.data ? r2.data.length : 0;
        var completedRefs = r2.data ? r2.data.filter(function(x) { return x.status !== 'pending'; }).length : 0;
        var progress = Math.min(completedRefs / 10 * 100, 100);
        targetEl.innerHTML = '<div class="ref-code-box">'
          + '<div style="font-size:12px;color:var(--meter-muted);margin-bottom:4px;">🔗 كود الإحالة الخاص بك</div>'
          + '<div class="code" id="refCodeDisplay">' + escapeHTML(code) + '</div>'
          + '<div style="display:flex;gap:8px;margin-top:8px;justify-content:center;">'
          + '<button class="btn btn-sm btn-outline" onclick="copyReferralCode()" style="padding:4px 12px;font-size:11px;"><i class="fas fa-copy"></i> نسخ</button>'
          + '<button class="btn btn-sm btn-outline" onclick="shareReferralCode()" style="padding:4px 12px;font-size:11px;"><i class="fab fa-whatsapp"></i> مشاركة</button>'
          + '</div></div>'
          + '<div class="ref-progress"><div style="font-size:12px;color:var(--meter-muted);margin-bottom:4px;">📊 إحالاتي: ' + completedRefs + ' / 10</div>'
          + '<div class="bar"><div class="bar-fill" style="width:' + progress + '%;"></div></div>'
          + '<div class="count">' + (completedRefs >= 10 ? '🎉 أحسنت! ستحصل على شهر مجاني' : (10 - completedRefs) + ' إحالات متبقية للحصول على شهر مجاني') + '</div></div>';
      });
    });
  }
  window.copyReferralCode = function() {
    var el = document.getElementById('refCodeDisplay');
    if (!el) return;
    navigator.clipboard.writeText(el.textContent).then(function() { showToast('✅ تم نسخ الكود'); }).catch(function() { showToast('فشل النسخ'); });
  };
  window.shareReferralCode = function() {
    var el = document.getElementById('refCodeDisplay');
    if (!el) return;
    var code = el.textContent;
    var url = window.location.origin + '/?ref=' + code;
    window.open('https://wa.me/?text=' + encodeURIComponent('اشترك في تطبيق "توقع أجرتك" باستخدام كود الإحالة الخاص بي: ' + code + '\n' + url));
  };

  // Hook into initSession to load wallet/ref on login
  var origShowDriverDashboard = showDriverDashboard;
  showDriverDashboard = function() {
    if (origShowDriverDashboard) origShowDriverDashboard();
    setTimeout(function() {
      loadReferralInfo();
      checkSubscription();
      supabase.rpc('check_referral_rewards').catch(function(){});
    }, 500);
  };

  var origShowPassengerDashboard = showPassengerDashboard;
  showPassengerDashboard = function() {
    if (origShowPassengerDashboard) origShowPassengerDashboard();
    setTimeout(function() {
      loadReferralInfo();
      checkSubscription();
      supabase.rpc('check_referral_rewards').catch(function(){});
    }, 500);
  };

  var SESSION_INACTIVITY_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

  function updateLastActivity() {
    try { localStorage.setItem('taweqe_last_activity', Date.now()); } catch(e) {}
  }

  function checkSessionInactivity() {
    try {
      var last = parseInt(localStorage.getItem('taweqe_last_activity'), 10);
      if (last && (Date.now() - last) > SESSION_INACTIVITY_MS) {
        // Session expired due to inactivity
        localStorage.removeItem('taweqe_last_activity');
        if (supabase) {
          supabase.auth.signOut();
        }
        showToast('⌛ انتهت صلاحية الجلسة بسبب عدم النشاط. سجل دخول مرة أخرى');
        return true;
      }
    } catch(e) {}
    return false;
  }

  // Track user activity
  function initActivityTracking() {
    var events = ['mousedown', 'keydown', 'touchstart', 'scroll', 'mousemove'];
    function handler() {
      updateLastActivity();
    }
    for (var i = 0; i < events.length; i++) {
      document.addEventListener(events[i], handler, { passive: true });
    }
    // Check periodically (every 5 minutes)
    setInterval(function() {
      if (currentUser) {
        checkSessionInactivity();
      }
    }, 5 * 60 * 1000);
  }
  initActivityTracking();
