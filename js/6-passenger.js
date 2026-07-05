  var trackInterval = null;
  var trackMap = null;

  var lastTrackedTripId = null;
  var lastTrackedDriverId = null;
  var lastTrackedCode = null;

  window.trackTrip = async function(optCode) {
    var code = optCode || document.getElementById('track-code').value.trim();
    if (!code || (code.length < 4 && code.length < 20)) { showToast('يرجى إدخال كود صحيح'); return; }
    if (!supabase) { showToast('خدمة التتبع غير متاحة'); return; }
    var statusEl = document.getElementById('track-status');
    statusEl.innerHTML = '<div class="spinner"></div><p style="color:var(--text-muted);font-size:13px;">جاري البحث...</p>';
    var body = code.length > 10 ? { trip_id: code } : { code: code };
    try {
      var { data, error } = await supabase.functions.invoke('track-trip', { body: body });
      if (error || !data || !data.trip) { statusEl.innerHTML = '<p style="color:var(--error);font-size:14px;">❌ لا توجد رحلة بهذا الكود</p>'; return; }
      var trip = data.trip;
      var locations = data.locations || [];
      document.getElementById('track-fare-display').textContent = (trip.total_fare || 0).toFixed(2) + ' ج';
      document.getElementById('track-status-val').textContent = trip.status === 'started' ? 'جارية 🟢' : trip.status === 'assigned' ? 'السائق في الطريق 🚗' : trip.status === 'completed' ? 'مكتملة ✅' : trip.status;
      document.getElementById('track-driver-name').textContent = trip.driver_name || 'سائق';
      document.getElementById('track-distance').textContent = (trip.distance_km || 0).toFixed(2) + ' كم';
      document.getElementById('track-duration').textContent = (trip.duration_min || 0).toFixed(0) + ' د';
      document.getElementById('track-wait').textContent = (trip.wait_minutes || 0).toFixed(0) + ' د';
      document.getElementById('track-type').textContent = trip.classification === 'private' ? 'مخصوص' : 'أفراد (مشترك)';
      document.getElementById('track-passengers').textContent = (trip.passenger_count || 1) + ' راكب';
      if (trip.created_at) document.getElementById('track-start-time').textContent = new Date(trip.created_at).toLocaleString('ar-EG');
      else document.getElementById('track-start-time').textContent = '-';
      document.getElementById('track-info').style.display = 'block';
      document.getElementById('track-map-card').style.display = 'block';
      document.getElementById('track-code').value = trip.join_code || code;
      statusEl.innerHTML = '<p style="color:var(--success);font-size:14px;">✅ تم العثور على الرحلة</p>';
      if (trackMap) { trackMap.remove(); trackMap = null; }
      try {
        trackMap = L.map('track-map').setView([30.0444, 31.2357], 14);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(trackMap);
        if (locations.length) {
          var points = locations.map(function(p) { return [p.lat, p.lng]; });
          L.polyline(points, {color: '#22d3ee', weight: 4}).addTo(trackMap);
          L.circleMarker(points[points.length - 1], {radius: 6, color: '#22c55e', fillColor: '#22c55e', fillOpacity: 1}).addTo(trackMap);
          try { trackMap.fitBounds(L.polyline(points).getBounds(), {padding: [20, 20]}); } catch(e) {}
        } else if (trip.last_lat && trip.last_lng) {
          trackMap.setView([trip.last_lat, trip.last_lng], 15);
          L.marker([trip.last_lat, trip.last_lng]).addTo(trackMap);
        }
        setTimeout(function() { if (trackMap) trackMap.invalidateSize(); }, 300);
      } catch(e) { console.error(e); }
      if (trip.status === 'started' || trip.status === 'assigned') {
        if (trackInterval) clearInterval(trackInterval);
        trackInterval = setInterval(function() { trackTrip(code); }, 5000);
      } else {
        if (trackInterval) { clearInterval(trackInterval); trackInterval = null; }
        if (trip.status === 'completed' && currentUser) {
          if (data.trip_id) { lastTrackedTripId = data.trip_id; }
          else if (trip.id) { lastTrackedTripId = trip.id; }
          if (data.driver_id) { lastTrackedDriverId = data.driver_id; }
          else { lastTrackedDriverId = trip.driver_id || null; }
          lastTrackedCode = code;
          showTrackRating();
        }
      }
    } catch (e) { console.error(e); document.getElementById('track-status').innerHTML = '<p style="color:var(--error);font-size:14px;">❌ حدث خطأ</p>'; }
  };

  function showTrackRating() {
    var section = document.getElementById('track-rating-section');
    if (!section) return;
    document.getElementById('trackRatingForm').style.display = 'block';
    document.getElementById('trackRatingDone').style.display = 'none';
    document.getElementById('trackRatingComment').value = '';
    resetTrackStars();
    section.style.display = 'block';
  }

  function resetTrackStars() {
    document.querySelectorAll('#trackRatingStars span').forEach(function(s) { s.classList.remove('active'); s.textContent = '☆'; });
  }

  document.querySelectorAll('#trackRatingStars span').forEach(function(s) {
    s.addEventListener('click', function() {
      var val = parseInt(this.getAttribute('data-star'));
      document.querySelectorAll('#trackRatingStars span').forEach(function(s2, i2) {
        if (i2 < val) { s2.classList.add('active'); s2.textContent = '★'; }
        else { s2.classList.remove('active'); s2.textContent = '☆'; }
      });
    });
  });

  document.querySelectorAll('#ratingStars span').forEach(function(s) {
    s.addEventListener('click', function() {
      var val = parseInt(this.getAttribute('data-star'));
      document.querySelectorAll('#ratingStars span').forEach(function(s2, i2) {
        if (i2 < val) { s2.classList.add('active'); s2.textContent = '★'; }
        else { s2.classList.remove('active'); s2.textContent = '☆'; }
      });
    });
  });

  window.submitTrackRating = async function() {
    if (!supabase || !currentUser) { showToast('يجب تسجيل الدخول أولاً'); return; }
    var activeStars = document.querySelectorAll('#trackRatingStars span.active').length;
    if (activeStars === 0) { showToast('اختر عدد النجوم أولاً'); return; }
    var comment = document.getElementById('trackRatingComment').value.trim();
    try {
      var tripId = lastTrackedTripId;
      if (!tripId && lastTrackedCode) {
        var { data: td } = await supabase.from('trips').select('id, driver_id').eq('join_code', lastTrackedCode).order('created_at', { ascending: false }).limit(1).single();
        if (td) { tripId = td.id; lastTrackedDriverId = td.driver_id; }
      }
      if (!tripId || !lastTrackedDriverId) { showToast('بيانات الرحلة غير متوفرة'); return; }
      var { error } = await supabase.from('ratings').upsert({
        trip_id: tripId, driver_id: lastTrackedDriverId, passenger_id: currentUser.id,
        score: activeStars, comment: comment || null
      }, { onConflict: 'trip_id, passenger_id' });
      if (error) { showToast('فشل إرسال التقييم: ' + error.message); return; }
      document.getElementById('trackRatingForm').style.display = 'none';
      document.getElementById('trackRatingDone').style.display = 'block';
      showToast('✅ تم إرسال تقييمك');
    } catch (e) { showToast('حدث خطأ'); console.error(e); }
  };

  window.dismissTrackRating = function() {
    document.getElementById('track-rating-section').style.display = 'none';
  };



  window.startTrackingFromRequest = function() {
    var code = document.getElementById('acceptedTripCode').textContent;
    if (code && code !== '-') {
      switchPassengerTab('track', document.querySelector('#passenger-app .tab-btn'));
      document.getElementById('track-code').value = code;
      setTimeout(function() { trackTrip(code); }, 300);
    } else {
      switchPassengerTab('track', document.querySelector('#passenger-app .tab-btn'));
    }
  };

  async function autoLoadActiveTrip() {
    if (!supabase || !currentUser) return;
    try {
      var { data: trip } = await supabase.from('trips').select('join_code, id, status').eq('passenger_id', currentUser.id).in('status', ['assigned', 'started']).order('created_at', { ascending: false }).limit(1).maybeSingle();
      if (trip && trip.join_code) {
        document.getElementById('track-code').value = trip.join_code;
        document.getElementById('auto-track-banner').style.display = 'flex';
        document.getElementById('auto-track-banner').innerHTML = '<span style="flex:1"><i class="fas fa-circle" style="color:var(--success);font-size:10px;animation:pulse 1.5s infinite;"></i> لديك رحلة نشطة - <strong>' + escapeHTML(trip.join_code) + '</strong></span><button class="btn btn-sm btn-primary" onclick="trackTrip(\'' + trip.join_code + '\')" style="padding:6px 16px;font-size:12px;"><i class="fas fa-eye"></i> تتبع</button>';
      }
    } catch (e) { console.error(e); }
  }

  window.requestRide = async function() {
    if (!supabase || !currentUser) { showToast('يجب تسجيل الدخول أولاً'); return; }
    if (typeof requireSubscription === 'function' && !(await requireSubscription())) return;
    var pickup = document.getElementById('request-pickup').value.trim();
    var destination = document.getElementById('request-destination').value.trim();
    var type = document.getElementById('request-type').value;
    var passengers = Math.round(clampNumber(document.getElementById('request-passengers').value, 1, 10, 1));
    if (!pickup) { showAlert('request-alert', 'يرجى إدخال موقع pickup'); return; }
    document.getElementById('request-btn').disabled = true;
    document.getElementById('request-loading').classList.remove('hidden-el');
    try {
      var payload = { passenger_id: currentUser.id, passenger_count: passengers, classification: type === 'private' ? 'private' : 'shared', status: 'pending', adult_count: passengers, child_count: 0, pickup_address: pickup };
      if (destination) payload.destination_address = destination;
      if (navigator.geolocation) {
        try {
          var pos = await new Promise(function(res, rej) { navigator.geolocation.getCurrentPosition(res, rej, { timeout: 5000 }); });
          payload.pickup_lat = pos.coords.latitude;
          payload.pickup_lng = pos.coords.longitude;
        } catch (e) {}
      }
      var { data, error } = await supabase.from('ride_requests').insert(payload).select('id, pickup_lat, pickup_lng').single();
      if (error) { showAlert('request-alert', error.message); document.getElementById('request-btn').disabled = false; document.getElementById('request-loading').classList.add('hidden-el'); return; }
      showAlert('request-alert', 'تم إرسال الطلب! جاري البحث عن سائق...', 'success');
      currentPassengerRequestId = data.id;
      currentPassengerRequestCreatedAt = Date.now();
      currentPassengerOfferedDrivers = [];
      if (data.pickup_lat && data.pickup_lng) {
        try {
          var { data: nearest } = await supabase.rpc('find_nearest_available_driver', { pickup_lat: data.pickup_lat, pickup_lng: data.pickup_lng, exclude_ids: [] });
          if (nearest && nearest.found) {
            currentPassengerOfferedDrivers.push(nearest.driver_id);
            await supabase.from('ride_requests').update({ offered_to: nearest.driver_id, offered_at: new Date().toISOString(), offered_drivers: currentPassengerOfferedDrivers }).eq('id', data.id);
          } else {
            document.getElementById('reqStatusSub').textContent = 'لا يوجد سائقين قريبين حالياً، سيتم التحقق مرة أخرى';
          }
        } catch (e) { console.error('auto-assign error:', e); }
      }
      showPassengerRequestStatus(data.id, payload);
    } catch (e) { showAlert('request-alert', e.message); }
    document.getElementById('request-btn').disabled = false;
    document.getElementById('request-loading').classList.add('hidden-el');
  };
  var currentPassengerRequestCreatedAt = null;
  var currentPassengerOfferedDrivers = [];

  var currentPassengerRequestId = null;
  var passengerRequestPollTimer = null;

  function showPassengerRequestStatus(requestId, payload) {
    document.getElementById('reqTypeDisplay').textContent = payload.classification === 'private' ? 'مخصوص' : 'أفراد';
    document.getElementById('reqPassengersDisplay').textContent = payload.passenger_count + ' راكب';
    document.getElementById('reqPickupDisplay').textContent = payload.pickup_address || '-';
    document.getElementById('reqStatusIcon').textContent = '\u23F3';
    document.getElementById('reqStatusText').textContent = 'جاري البحث عن سائق...';
    document.getElementById('reqStatusSub').textContent = 'سيتم إشعارك عند قبول طلبك';
    document.getElementById('requestAcceptedContent').style.display = 'none';
    document.getElementById('requestStatusCard').style.display = 'block';
    document.getElementById('cancelRequestBtn').style.display = 'block';
    switchPassengerTab('request-status', document.querySelector('#passenger-app .tab-btn'));
    if (passengerRequestPollTimer) clearInterval(passengerRequestPollTimer);
    passengerRequestPollTimer = setInterval(function() { pollPassengerRequest(requestId); }, 3000);
  }

  var acceptedDriverMap = null;
  var acceptedDriverLocTimer = null;

  function initAcceptedDriverMap(driverId, tripCode) {
    var container = document.getElementById('accepted-driver-map-container');
    if (!container) return;
    container.innerHTML = '<div id="accepted-driver-map" style="height:140px;border-radius:12px;"></div>';
    if (acceptedDriverMap) { acceptedDriverMap.remove(); acceptedDriverMap = null; }
    try {
      acceptedDriverMap = L.map('accepted-driver-map').setView([30.0444, 31.2357], 14);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(acceptedDriverMap);
      var driverMarker = L.marker([30.0444, 31.2357], { icon: L.divIcon({ className: 'driver-marker', html: '🚗', iconSize: [24, 24], iconAnchor: [12, 12] }) }).addTo(acceptedDriverMap);
      if (acceptedDriverLocTimer) clearInterval(acceptedDriverLocTimer);
      acceptedDriverLocTimer = setInterval(async function() {
        if (!driverId) return;
        try {
          var { data: driverLoc } = await supabase.from('drivers').select('current_lat, current_lng').eq('id', driverId).single();
          if (driverLoc && driverLoc.current_lat && driverLoc.current_lng) {
            driverMarker.setLatLng([driverLoc.current_lat, driverLoc.current_lng]);
            acceptedDriverMap.setView([driverLoc.current_lat, driverLoc.current_lng], 15);
          }
        } catch(e) {}
        var { data: tripUpd } = await supabase.from('trips').select('id, status').eq('join_code', tripCode).order('created_at', { ascending: false }).limit(1).maybeSingle();
        if (tripUpd) {
          if (tripUpd.status === 'started') {
            clearInterval(acceptedDriverLocTimer);
            document.getElementById('acceptedTripStatus').textContent = 'جارية 🟢';
            if (tripUpd.id) currentChatTripId = tripUpd.id;
            // Auto-redirect to tracking view after 1.5s
            setTimeout(function() {
              switchPassengerTab('track', document.querySelector('#passenger-app .tab-btn'));
              document.getElementById('track-code').value = tripCode;
              trackTrip(tripCode);
            }, 1500);
          } else if (tripUpd.status === 'completed') {
            clearInterval(acceptedDriverLocTimer);
            showToast('✅ تم إنهاء الرحلة');
            setTimeout(function() {
              switchPassengerTab('track', document.querySelector('#passenger-app .tab-btn'));
              document.getElementById('track-code').value = tripCode;
              trackTrip(tripCode);
            }, 1000);
          }
        }
      }, 4000);
      setTimeout(function() { if (acceptedDriverMap) acceptedDriverMap.invalidateSize(); }, 300);
    } catch(e) { console.error(e); }
  }

  async function pollPassengerRequest(requestId) {
    if (!supabase || !requestId) return;
    try {
      var { data, error } = await supabase.from('ride_requests').select('id, status, driver_id, responded_at, pickup_lat, pickup_lng, offered_at').eq('id', requestId).single();
      if (error || !data) { clearInterval(passengerRequestPollTimer); return; }
      // Auto-cancel after 5 minutes with no acceptance
      if (currentPassengerRequestCreatedAt && Date.now() - currentPassengerRequestCreatedAt > 300000) {
        if (data.status === 'pending') {
          await supabase.from('ride_requests').update({ status: 'cancelled' }).eq('id', requestId);
          showToast('تم إلغاء الطلب تلقائياً لعدم وجود سائق');
        }
        clearInterval(passengerRequestPollTimer);
        document.getElementById('reqStatusIcon').textContent = '\u23F0';
        document.getElementById('reqStatusText').textContent = 'انتهى وقت الطلب';
        document.getElementById('reqStatusSub').textContent = 'لم يتم العثور على سائق، حاول مرة أخرى';
        document.getElementById('cancelRequestBtn').style.display = 'none';
        return;
      }
      // Auto-reassign if no driver offered, or offered driver hasn't responded within 50 seconds
      var shouldReassign = false;
      if (data.status === 'pending' && data.pickup_lat && data.pickup_lng) {
        if (!data.offered_to) {
          shouldReassign = true;
          document.getElementById('reqStatusSub').textContent = 'جاري البحث عن سائق آخر...';
        } else if (data.offered_at) {
          var elapsed = Date.now() - new Date(data.offered_at).getTime();
          if (elapsed > 50000) shouldReassign = true;
        }
        if (shouldReassign) {
          try {
            var { data: nearest } = await supabase.rpc('find_nearest_available_driver', { pickup_lat: data.pickup_lat, pickup_lng: data.pickup_lng, exclude_ids: currentPassengerOfferedDrivers });
            if (nearest && nearest.found) {
              currentPassengerOfferedDrivers.push(nearest.driver_id);
              await supabase.from('ride_requests').update({ offered_to: nearest.driver_id, offered_at: new Date().toISOString(), offered_drivers: currentPassengerOfferedDrivers }).eq('id', requestId);
              document.getElementById('reqStatusSub').textContent = 'جاري عرض الطلب على سائق آخر...';
            } else {
              document.getElementById('reqStatusSub').textContent = 'لا يوجد سائقين متاحين قريباً';
            }
          } catch (e) { console.error('reassign error:', e); }
        }
      }
      if (data.status === 'accepted') {
        clearInterval(passengerRequestPollTimer);
        document.getElementById('reqStatusIcon').textContent = '\u2705';
        document.getElementById('reqStatusText').textContent = 'تم قبول طلبك!';
        document.getElementById('reqStatusSub').textContent = 'السائق في طريقه إليك';
        document.getElementById('cancelRequestBtn').style.display = 'none';
        document.getElementById('requestAcceptedContent').style.display = 'block';
        document.getElementById('requestStatusCard').style.display = 'none';
        var driverName = 'سائق';
        if (data.driver_id) {
          var { data: driverData } = await supabase.from('profiles').select('full_name').eq('id', data.driver_id).single();
          if (driverData) driverName = driverData.full_name || 'سائق';
          document.getElementById('acceptedDriverName').textContent = driverName;
        }
        var { data: tripData } = await supabase.from('trips').select('join_code, status').eq('passenger_id', currentUser.id).eq('driver_id', data.driver_id).order('created_at', { ascending: false }).limit(1).maybeSingle();
        if (tripData) {
          document.getElementById('acceptedTripCode').textContent = tripData.join_code || '-';
          document.getElementById('acceptedTripStatus').textContent = tripData.status === 'started' ? 'جارية 🟢' : tripData.status === 'assigned' ? 'السائق في الطريق 🚗' : tripData.status;
          if (data.driver_id && tripData.join_code) {
            initAcceptedDriverMap(data.driver_id, tripData.join_code);
          }
          currentChatTripId = tripData.id;
          if (tripData.status === 'assigned' || tripData.status === 'started') {
            document.getElementById('track-chat-section').style.display = 'block';
            loadChat('track', currentChatTripId);
          }
        }
      } else if (data.status === 'cancelled') {
        clearInterval(passengerRequestPollTimer);
        document.getElementById('reqStatusIcon').textContent = '\u274C';
        document.getElementById('reqStatusText').textContent = 'تم إلغاء الطلب';
        document.getElementById('reqStatusSub').textContent = 'يمكنك إرسال طلب جديد';
        document.getElementById('cancelRequestBtn').style.display = 'none';
      }
    } catch (e) { console.error(e); }
  }
  window.updateFareEstimate = function() {
    var type = document.getElementById('request-type').value;
    var count = parseInt(document.getElementById('request-passengers').value) || 1;
    var el = document.getElementById('fareEstimateValue');
    if (type === 'private') {
      el.textContent = '15 - 35 ج.م';
    } else {
      el.textContent = (count * 3) + ' - ' + (count * 8) + ' ج.م للفرد';
    }
  };

  window.getCurrentLocation = function() {
    if (!navigator.geolocation) { showToast('GPS غير متاح'); return; }
    navigator.geolocation.getCurrentPosition(function(pos) {
      document.getElementById('request-pickup').value = pos.coords.latitude.toFixed(5) + ', ' + pos.coords.longitude.toFixed(5);
      showToast('تم تحديد الموقع الحالي');
    }, function() { showToast('فشل تحديد الموقع'); });
  };

  async function loadPassengerHistory() {
    if (!supabase || !currentUser) return;
    var list = document.getElementById('passengerHistoryList');
    try {
      var { data: trips, error } = await supabase.from('trips').select('*').eq('passenger_id', currentUser.id).order('created_at', { ascending: false }).limit(20);
      if (error || !trips || !trips.length) { list.innerHTML = '<div class="empty-state">لا توجد رحلات سابقة</div>'; return; }
	      list.innerHTML = trips.map(function(t) {
	        return '<div class="history-item"><div class="history-header"><span>🗓️ ' + escapeHTML(new Date(t.created_at).toLocaleDateString('ar-EG')) + '</span><span style="color:var(--meter-primary)">' + escapeHTML(t.join_code || '-') + '</span></div><div class="history-details"><div>' + (t.classification === 'private' ? 'مخصوص' : 'أفراد') + '</div><div>' + clampNumber(t.distance_km, 0, 1000, 0).toFixed(2) + ' كم</div><div>' + clampNumber(t.duration_min, 0, 1440, 0).toFixed(0) + ' د</div><div>' + clampNumber(t.passenger_count, 1, 20, 1) + ' راكب</div></div><div class="history-fare">' + clampNumber(t.total_fare, 0, 100000, 0).toFixed(2) + ' ج</div></div>';
	      }).join('');
    } catch (e) { list.innerHTML = '<div class="empty-state">خطأ في التحميل</div>'; }
  }
  window.loadPassengerHistory = loadPassengerHistory;
