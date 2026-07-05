  window.loadWallet = async function() {
    if (!supabase || !currentUser) return;
    var role = currentProfile && currentProfile.role === 'driver' ? 'driver' : 'passenger';
    if (typeof checkPaymobReturn === 'function') checkPaymobReturn();
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
      var btn = document.getElementById('charge-btn-' + role);
      if (btn) btn.disabled = true;

      var { data, error } = await supabase.functions.invoke('paymob-charge', {
        body: { action: 'create', amount: amount }
      });

      if (error || !data || !data.redirect_url) {
        showToast('❌ فشل الاتصال ببوابة الدفع. ' + (error?.message || ''));
        if (btn) btn.disabled = false;
        return;
      }

      // Save return URL in session storage
      try {
        sessionStorage.setItem('paymob_pending', JSON.stringify({ amount: amount, intention_id: data.intention_id }));
      } catch(e) {}

      showToast('🔄 جاري تحويلك إلى بوابة الدفع...');
      window.location.href = data.redirect_url;
    } catch(e) { showToast('❌ فشل الشحن'); console.error(e); }
  };

  // Check for Paymob return
  window.checkPaymobReturn = async function() {
    var params = new URLSearchParams(window.location.search);
    var paymobStatus = params.get('paymob');
    if (paymobStatus === 'success') {
      showToast('✅ تم شحن المحفظة بنجاح!');
      loadWallet();
      checkSubscription();
      // Clean URL
      window.history.replaceState({}, '', window.location.pathname);
    } else if (paymobStatus === 'failed') {
      showToast('❌ فشلت عملية الدفع. حاول مرة أخرى');
      window.history.replaceState({}, '', window.location.pathname);
    }
  };

  // Withdrawal
  window.showWithdrawForm = function(role) {
    document.getElementById('withdraw-form-' + role).style.display = 'block';
  };
  window.hideWithdrawForm = function(role) {
    document.getElementById('withdraw-form-' + role).style.display = 'none';
  };
  window.processWithdrawal = async function(role) {
    if (!supabase || !currentUser) return;
    var amount = parseFloat(document.getElementById('withdraw-amount-' + role).value);
    if (!amount || amount < 20) { showToast('أقل مبلغ للسحب 20 جنيه'); return; }
    try {
      var { data: wallet } = await supabase.from('wallets').select('balance').eq('user_id', currentUser.id).single();
      if (!wallet || wallet.balance < amount) { showToast('❌ الرصيد غير كافٍ'); return; }
      if (!confirm('تأكيد سحب ' + amount.toFixed(2) + ' ج من المحفظة؟')) return;

      var { data, error } = await supabase.rpc('process_user_withdrawal', { p_user_id: currentUser.id, p_amount: amount });
      if (error || !data || !data.success) {
        showToast('❌ فشل السحب: ' + (data?.error || error?.message || ''));
        return;
      }
      showToast('✅ تم تقديم طلب السحب. سنقوم بمعالجته قريباً');
      hideWithdrawForm(role);
      loadWallet();
    } catch(e) { showToast('❌ فشل السحب'); console.error(e); }
  };

  window.showSubscription = async function(role) {
    if (!supabase || !currentUser) return;
    var price = role === 'driver' ? 299 : 89;
    var planName = role === 'driver' ? 'باقة السائق' : 'باقة الراكب';
    try {
      var { data: wallet } = await supabase.from('wallets').select('balance').eq('user_id', currentUser.id).single();
      var balance = wallet ? wallet.balance : 0;
      var { data: sub } = await supabase.from('subscriptions').select('*').eq('user_id', currentUser.id).eq('status', 'active').order('end_date', { ascending: false }).limit(1).maybeSingle();
      var subStatus = sub ? 'نشط حتى ' + new Date(sub.end_date).toLocaleDateString('ar-EG') : 'غير مشترك';
      var isActive = !!sub;
      if (!confirm(
        planName + '\nالسعر: ' + price + ' ج/شهر\n'
        + 'رصيدك: ' + balance.toFixed(2) + ' ج\n'
        + 'الحالة: ' + subStatus + '\n\n'
        + (isActive ? 'هل تريد تجديد الاشتراك؟' : 'هل تريد الاشتراك؟')
      )) return;

      if (balance < price) {
        showToast('❌ الرصيد غير كافٍ. اشحن المحفظة أولاً');
        return;
      }

      var { data, error } = await supabase.rpc('renew_subscription', { p_user_id: currentUser.id });
      if (error || !data || !data.success) {
        showToast('❌ فشل الاشتراك: ' + (data?.error || error?.message || ''));
        return;
      }
      showToast('✅ تم تفعيل الاشتراك لمدة 30 يوم');
      loadWallet();
    } catch(e) { showToast('فشل الاشتراك'); console.error(e); }
  };

  async function checkSubscription() {
    if (!supabase || !currentUser) return;
    try {
      await supabase.rpc('check_subscription_expiry');
      var { data: lastSub } = await supabase.from('subscriptions').select('auto_renew').eq('user_id', currentUser.id).order('end_date', { ascending: false }).limit(1).maybeSingle();
      var shouldAutoRenew = !lastSub || lastSub.auto_renew === true;
      if (!shouldAutoRenew) return;

      var { data: sub } = await supabase.from('subscriptions').select('*').eq('user_id', currentUser.id).eq('status', 'active').order('end_date', { ascending: false }).limit(1).maybeSingle();
      if (!sub) {
        var { data: wallet } = await supabase.from('wallets').select('balance').eq('user_id', currentUser.id).single();
        var role = currentProfile && currentProfile.role === 'driver' ? 'driver' : 'passenger';
        var price = role === 'driver' ? 299 : 89;
        if (wallet && wallet.balance >= price) {
          await supabase.rpc('renew_subscription', { p_user_id: currentUser.id });
        }
      }
    } catch(e) {}
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

  window.requireSubscription = async function() {
    if (!supabase || !currentUser) return false;
    try {
      await supabase.rpc('check_subscription_expiry');
      var { data: sub } = await supabase.from('subscriptions').select('id, end_date').eq('user_id', currentUser.id).eq('status', 'active').order('end_date', { ascending: false }).limit(1).maybeSingle();
      if (!sub) {
        var role = currentProfile && currentProfile.role === 'driver' ? 'driver' : 'passenger';
        var price = role === 'driver' ? 299 : 89;
        showToast('⚠️ يجب الاشتراك أولاً (' + price + ' ج/شهر)');
        return false;
      }
      return true;
    } catch(e) { return false; }
  };

  window.checkPendingPriceProposals = async function() {
    if (!supabase || !currentUser) return;
    try {
      var { data: proposals } = await supabase.from('trips')
        .select('id, join_code, passenger_proposed_fare, passenger_adjustment_note, total_fare, passenger_id')
        .eq('driver_id', currentUser.id)
        .not('passenger_proposed_fare', 'is', null)
        .eq('passenger_price_accepted', false)
        .order('created_at', { ascending: false })
        .limit(5);
      if (!proposals || !proposals.length) {
        var existingBanner = document.getElementById('price-proposal-banner');
        if (existingBanner) existingBanner.style.display = 'none';
        return;
      }
      var banner = document.getElementById('price-proposal-banner');
      if (!banner) {
        var meterSection = document.getElementById('driver-meter-section');
        if (!meterSection) return;
        banner = document.createElement('div');
        banner.id = 'price-proposal-banner';
        banner.style.cssText = 'background:rgba(245,158,11,0.1);border:1px solid var(--accent);border-radius:12px;padding:10px 14px;margin-bottom:12px;';
        meterSection.insertBefore(banner, meterSection.firstChild);
      }
      banner.innerHTML = proposals.map(function(p) {
        return '<div style="display:flex;align-items:center;gap:8px;margin-bottom:4px;font-size:13px;"><span style="flex:1;">💬 الراكب يقترح <strong>' + p.passenger_proposed_fare.toFixed(2) + ' ج</strong> بدلاً من ' + (p.total_fare || 0).toFixed(2) + ' ج (كود: ' + escapeHTML(p.join_code || '-') + ')' + (p.passenger_adjustment_note ? '<br><span style="font-size:11px;color:var(--meter-muted);">السبب: ' + escapeHTML(p.passenger_adjustment_note) + '</span>' : '') + '</span><button class="btn btn-sm btn-success" onclick="acceptPriceProposal(\'' + p.id + '\')" style="padding:4px 10px;font-size:11px;">قبول</button><button class="btn btn-sm btn-outline" onclick="rejectPriceProposal(\'' + p.id + '\')" style="padding:4px 10px;font-size:11px;">رفض</button></div>';
      }).join('');
      banner.style.display = 'block';
    } catch(e) { console.error(e); }
  };

  window.acceptPriceProposal = async function(tripId) {
    if (!confirm('قبول السعر المقترح من الراكب؟')) return;
    var { data, error } = await supabase.rpc('accept_passenger_price', { p_trip_id: tripId });
    if (error) { showToast('❌ ' + error.message); return; }
    if (data && data.success) {
      showToast('✅ تم قبول السعر الجديد: ' + data.new_fare.toFixed(2) + ' ج');
      checkPendingPriceProposals();
    }
  };

  window.rejectPriceProposal = async function(tripId) {
    if (!confirm('رفض السعر المقترح؟')) return;
    var { data, error } = await supabase.rpc('reject_passenger_price', { p_trip_id: tripId });
    if (error) { showToast('❌ ' + error.message); return; }
    showToast('تم رفض الاقتراح');
    checkPendingPriceProposals();
  };

  // Hook into initSession to load wallet/ref on login
  var origShowDriverDashboard = showDriverDashboard;
  showDriverDashboard = function() {
    if (origShowDriverDashboard) origShowDriverDashboard();
    setTimeout(function() {
      loadReferralInfo();
      checkSubscription();
      supabase.rpc('check_referral_rewards').catch(function(){});
      checkPendingPriceProposals();
    }, 500);
    // Poll for proposals every 30s
    if (window._priceProposalInterval) clearInterval(window._priceProposalInterval);
    window._priceProposalInterval = setInterval(function() {
      if (currentUser) checkPendingPriceProposals();
    }, 30000);
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
