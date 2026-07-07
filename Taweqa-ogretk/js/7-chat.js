  var currentChatTripId = null;
  var chatPollTimer = null;

  window.cancelPassengerRequest = async function() {
    if (!supabase || !currentPassengerRequestId) return;
    if (!confirm('هل أنت متأكد من إلغاء الطلب؟')) return;
    try {
      var { data: req } = await supabase.from('ride_requests').select('status, driver_id, passenger_id').eq('id', currentPassengerRequestId).single();
      if (!req) { showToast('الطلب غير موجود'); return; }
      if (req.status === 'accepted' && req.driver_id) {
        var fine = 10;
        var { data: wal } = await supabase.from('wallets').select('balance').eq('user_id', req.passenger_id).single();
        if (!wal || wal.balance < fine) {
          if (!confirm('رصيد محفظتك غير كافٍ (' + (wal ? wal.balance : 0) + ' ج). الغرامة ' + fine + ' ج. سيتم خصمها عند شحن المحفظة. هل تريد الإلغاء؟')) return;
        } else {
          await supabase.rpc('apply_wallet_charge', { p_user_id: req.passenger_id, p_amount: -fine });
          showToast('تم خصم غرامة ' + fine + ' ج من المحفظة');
        }
        await supabase.from('ride_requests').update({ status: 'cancelled', driver_id: null, offered_to: null }).eq('id', currentPassengerRequestId);
        await supabase.from('trips').update({ status: 'cancelled' }).eq('passenger_id', req.passenger_id).eq('driver_id', req.driver_id).in('status', ['assigned', 'started']).limit(1);
      } else {
        await supabase.from('ride_requests').update({ status: 'cancelled', offered_to: null }).eq('id', currentPassengerRequestId);
      }
      clearInterval(window.passengerRequestPollTimer);
      window.passengerRequestPollTimer = null;
      showToast('✅ تم إلغاء الطلب');
      switchPassengerTab('request', document.querySelector('#passenger-app .tab-btn'));
    } catch (e) { showToast('فشل الإلغاء'); console.error(e); }
  };

  function openDriverChat() {
    if (!currentChatTripId) {
      showToast('لا توجد رحلة نشطة حالياً');
      return;
    }
    loadChat('driverSA', currentChatTripId);
  }
  window.openDriverChat = openDriverChat;

  async function loadChat(prefix, tripId) {
    var container = document.getElementById('chatMessages' + prefix.charAt(0).toUpperCase() + prefix.slice(1));
    if (!container) return;
    try {
      var { data: msgs, error } = await supabase.from('trip_chat_messages').select('*').eq('trip_id', tripId).order('created_at', { ascending: true }).limit(100);
      if (error) return;
      container.innerHTML = (msgs || []).map(function(m) {
        var role = m.sender_role === 'driver' ? 'driver' : 'passenger';
        var name = m.sender_role === 'driver' ? 'السائق' : 'الراكب';
        var time = new Date(m.created_at).toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit' });
        return '<div class="chat-msg ' + role + '">' + escapeHTML(m.message) + '<div class="meta">' + name + ' - ' + time + '</div></div>';
      }).join('');
      container.scrollTop = container.scrollHeight;
    } catch(e) { console.error(e); }
  }
  window.loadChat = loadChat;

  async function sendChatMessage(prefix) {
    if (!supabase || !currentUser || !currentChatTripId) { showToast('لا توجد محادثة نشطة'); return; }
    var input = document.getElementById('chatInput' + prefix.charAt(0).toUpperCase() + prefix.slice(1));
    var msg = (input ? input.value : '').trim();
    if (!msg) return;
    input.value = '';
    try {
      var role = currentProfile && currentProfile.role === 'driver' ? 'driver' : 'passenger';
      var { error } = await supabase.from('trip_chat_messages').insert({
        trip_id: currentChatTripId, sender_id: currentUser.id, sender_role: role, message: msg
      });
      if (error) { showToast('فشل الإرسال'); console.error(error); return; }
      loadChat(prefix, currentChatTripId);
    } catch(e) { console.error(e); }
  }
  window.sendChatMessage = sendChatMessage;

  function isVisible(el) {
    return el && el.offsetParent !== null;
  }

  function startChatPoll(tripId) {
    currentChatTripId = tripId;
    if (chatPollTimer) clearInterval(chatPollTimer);
    chatPollTimer = setInterval(function() {
      var trackChat = document.getElementById('track-chat-section');
      if (isVisible(trackChat)) {
        loadChat('track', currentChatTripId);
      }
      var driverChatSection = document.getElementById('driver-chat-section');
      if (isVisible(driverChatSection)) {
        loadChat('driver', currentChatTripId);
      }
      var driverChatSASection = document.getElementById('driver-chat-section-standalone');
      if (isVisible(driverChatSASection)) {
        loadChat('driverSA', currentChatTripId);
      }
    }, 3500);
  }
  window.startChatPoll = startChatPoll;

  // Hook into trackTrip to show chat when trip is active
  var origTrackTrip = window.trackTrip;
  window.trackTrip = async function(optCode) {
    if (origTrackTrip) await origTrackTrip(optCode);
    var statusEl = document.getElementById('track-status-val');
    if (statusEl && (statusEl.textContent.includes('جارية') || statusEl.textContent.includes('الطريق'))) {
      if (!currentChatTripId && currentUser) {
        var code = optCode || document.getElementById('track-code').value.trim();
        if (code) {
          try {
            var { data: userTrip } = await supabase.from('trips').select('id').eq('join_code', code).eq('passenger_id', currentUser.id).maybeSingle();
            if (userTrip) currentChatTripId = userTrip.id;
          } catch(e) { console.error('Trip lookup error:', e); }
        }
      }
      if (currentChatTripId) {
        document.getElementById('track-chat-section').style.display = 'block';
        loadChat('track', currentChatTripId);
        if (!chatPollTimer) startChatPoll(currentChatTripId);
      }
    }
  };

  // Hook into autoLoadActiveTrip to set chat trip id
  var origAutoLoad = autoLoadActiveTrip;
  autoLoadActiveTrip = async function() {
    if (origAutoLoad) await origAutoLoad();
    if (!supabase || !currentUser) return;
    try {
      var { data: trip } = await supabase.from('trips').select('id, join_code, status').eq('passenger_id', currentUser.id).in('status', ['assigned', 'started']).order('created_at', { ascending: false }).limit(1).maybeSingle();
      if (trip) {
        currentChatTripId = trip.id;
        if (trip.status === 'assigned' || trip.status === 'started') {
          document.getElementById('track-chat-section').style.display = 'block';
          loadChat('track', trip.id);
          startChatPoll(trip.id);
        }
      }
    } catch(e) { console.error(e); }
  };

  // Hook into startMeterForAcceptedTrip to set driver chat
  window.startMeterForAcceptedTrip = (function(orig) {
    return async function() {
      if (orig) await orig();
      if (currentChatTripId) {
        document.getElementById('driver-chat-section').style.display = 'block';
        loadChat('driver', currentChatTripId);
        startChatPoll(currentChatTripId);
      }
    };
  })(window.startMeterForAcceptedTrip);

  // Hook into acceptRequest to set chat
  window.acceptRequest = (function(orig) {
    return async function(requestId) {
      await orig(requestId);
      if (acceptedTripData && acceptedTripData.tripId) {
        currentChatTripId = acceptedTripData.tripId;
        document.getElementById('driver-chat-section').style.display = 'block';
        loadChat('driver', currentChatTripId);
        startChatPoll(currentChatTripId);
      }
    };
  })(window.acceptRequest);
