(function() {
  async function handlePaymobCallback() {
    var params = new URLSearchParams(window.location.search);
    var success = params.get('success');
    var intentionId = params.get('id');

    if (success !== 'true' || !intentionId) return;

    try {
      if (typeof supabase === 'undefined' || !supabase || typeof currentUser === 'undefined' || !currentUser) {
        showToast('⚠️ قم بتسجيل الدخول أولاً');
        return;
      }

      showToast('🔄 جاري تأكيد الدفع...');

      var { data, error } = await supabase.functions.invoke('paymob-charge', {
        body: { action: 'verify', intention_id: intentionId }
      });

      if (error || !data || !data.success) {
        showToast('❌ فشل تأكيد الدفع. ' + (error?.message || data?.error || ''));
      } else if (data.error === 'already_completed') {
        showToast('✅ تم شحن المحفظة بنجاح!');
      } else {
        showToast('✅ تم شحن المحفظة بنجاح!');
      }

      if (typeof loadWallet === 'function') setTimeout(loadWallet, 500);
      if (typeof checkSubscription === 'function') setTimeout(checkSubscription, 700);
      sessionStorage.removeItem('paymob_pending');
    } catch(e) {
      showToast('❌ فشل تأكيد الدفع');
      console.error(e);
    }

    window.history.replaceState({}, '', window.location.pathname);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', handlePaymobCallback);
  } else {
    handlePaymobCallback();
  }
})();
