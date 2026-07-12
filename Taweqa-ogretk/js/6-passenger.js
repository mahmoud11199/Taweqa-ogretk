  var trackInterval = null;
  var trackMap = null;
  var trackWaypoints = [];
  var trackCurrentTripData = null;

  var lastTrackedTripId = null;
  var lastTrackedDriverId = null;
  var lastTrackedCode = null;
  var requestWaypoints = [];
  var requestMap = null;
  var requestMarkers = [];
  var requestPolyline = null;

  window.initRequestMap = function() {
    var container = document.getElementById('request-map');
    if (!container || requestMap) return;
    try {
      requestMap = L.map('request-map').setView([30.0444, 31.2357], 14);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(requestMap);
      requestMap.on('click', onRequestMapClick);
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(function(pos) {
          if (requestMap) requestMap.setView([pos.coords.latitude, pos.coords.longitude], 15);
          if (requestWaypoints.length === 0) {
            requestWaypoints.push({ lat: pos.coords.latitude, lng: pos.coords.longitude });
            updateRequestWaypointsUI();
          }
        }, function() {}, { enableHighAccuracy: true, timeout: 10000 });
      }
      setTimeout(function() { if (requestMap) requestMap.invalidateSize(); }, 500);
    } catch(e) { console.error(e); }
  };

  function onRequestMapClick(e) {
    if (requestWaypoints.length >= 20) { showToast('الحد الأقصى 20 نقطة'); return; }
    requestWaypoints.push({ lat: e.latlng.lat, lng: e.latlng.lng });
    updateRequestWaypointsUI();
  }

  function updateRequestWaypointsUI() {
    requestMarkers.forEach(function(m) { if (requestMap) requestMap.removeLayer(m); });
    requestMarkers = [];
    if (requestPolyline) { requestMap.removeLayer(requestPolyline); requestPolyline = null; }
    if (requestWaypoints.length === 0) {
      document.getElementById('request-waypoints-count').textContent = '0 نقطة';
      document.getElementById('request-est-distance').textContent = '0';
      updateFareEstimate();
      return;
    }
    var latlngs = [];
    requestWaypoints.forEach(function(wp, i) {
      var latlng = [wp.lat, wp.lng];
      latlngs.push(latlng);
      var color = i === 0 ? '#22c55e' : '#3b82f6';
      var marker = L.circleMarker(latlng, { radius: 8, color: color, fillColor: color, fillOpacity: 0.8, weight: 2 }).addTo(requestMap);
      marker.bindTooltip(String(i + 1), { permanent: true, direction: 'top', className: 'waypoint-tooltip' });
      marker._wpIdx = i;
      marker.on('click', function() { removeRequestWaypoint(this._wpIdx); });
      requestMarkers.push(marker);
    });
    if (latlngs.length > 1) {
      requestPolyline = L.polyline(latlngs, { color: '#f59e0b', weight: 3, dashArray: '6, 8' }).addTo(requestMap);
    }
    try { requestMap.fitBounds(L.polyline(latlngs).getBounds(), { padding: [30, 30] }); } catch(e) { console.error('Request map fitBounds error:', e); }
    document.getElementById('request-waypoints-count').textContent = requestWaypoints.length + ' نقطة';
    document.getElementById('request-est-distance').textContent = calculateWaypointsDistance().toFixed(1);
    updateFareEstimate();
  }

  function calculateWaypointsDistance() {
    if (requestWaypoints.length < 2) return 0;
    var total = 0;
    for (var i = 1; i < requestWaypoints.length; i++) {
      total += haversineDistance(requestWaypoints[i-1].lat, requestWaypoints[i-1].lng, requestWaypoints[i].lat, requestWaypoints[i].lng);
    }
    return total;
  }

  function haversineDistance(lat1, lon1, lat2, lon2) {
    var R = 6371;
    var dLat = (lat2 - lat1) * Math.PI / 180;
    var dLon = (lon2 - lon1) * Math.PI / 180;
    var a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon/2) * Math.sin(dLon/2);
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
  }

  window.clearRequestWaypoints = function() {
    requestWaypoints = [];
    updateRequestWaypointsUI();
  };

  window.undoLastWaypoint = function() {
    if (requestWaypoints.length === 0) return;
    requestWaypoints.pop();
    updateRequestWaypointsUI();
  };

  function removeRequestWaypoint(idx) {
    requestWaypoints.splice(idx, 1);
    // Rebind click handlers with correct indices
    updateRequestWaypointsUI();
  }

  window.setMyLocationAsFirst = function() {
    if (!navigator.geolocation) { showToast('GPS غير متاح'); return; }
    navigator.geolocation.getCurrentPosition(function(pos) {
      var loc = { lat: pos.coords.latitude, lng: pos.coords.longitude };
      if (requestWaypoints.length === 0) {
        requestWaypoints.push(loc);
      } else {
        requestWaypoints[0] = loc;
      }
      updateRequestWaypointsUI();
      if (requestMap) requestMap.setView([loc.lat, loc.lng], 16);
      showToast('تم تحديد موقعك الحالي كنقطة انطلاق');
    }, function() { showToast('فشل تحديد الموقع'); });
  };

  window.trackTrip = async function(optCode) {
    var code = optCode || document.getElementById('track-code').value.trim();
    if (!code || code.length < 4 || code.length > 20) { showToast('يرجى إدخال كود صحيح'); return; }
    if (!supabase) { showToast('خدمة التتبع غير متاحة'); return; }
    var statusEl = document.getElementById('track-status');
    if (!optCode) statusEl.innerHTML = '<div class="spinner"></div><p style="color:var(--text-muted);font-size:13px;">جاري البحث...</p>';
    var body = code.length > 10 ? { trip_id: code } : { code: code };
    try {
      var { data, error } = await supabase.functions.invoke('track-trip', { body: body });
      if (error || !data || !data.trip) {
        if (!optCode) statusEl.innerHTML = '<p style="color:var(--error);font-size:14px;">❌ لا توجد رحلة بهذا الكود</p>';
        if (trackInterval) { clearInterval(trackInterval); trackInterval = null; }
        return;
      }
      var trip = data.trip;
      var driver = data.driver || {};
      var locations = data.locations || [];
      var waypointsList = trip.waypoints || [];
      trackCurrentTripData = data;
      trackWaypoints = waypointsList;

      document.getElementById('track-fare-display').textContent = (trip.total_fare || 0).toFixed(2) + ' ج';
      var statusText = trip.status === 'started' ? 'جارية 🟢' : trip.status === 'assigned' ? 'السائق في الطريق 🚗' : trip.status === 'completed' ? 'مكتملة ✅' : trip.status;
      document.getElementById('track-status-val').textContent = statusText;
      document.getElementById('track-distance').textContent = (trip.distance_km || 0).toFixed(2) + ' كم';
      document.getElementById('track-duration').textContent = (trip.duration_min || 0).toFixed(0) + ' د';
      document.getElementById('track-wait').textContent = (trip.wait_minutes || 0).toFixed(0) + ' د';
      document.getElementById('track-type').textContent = trip.classification === 'private' ? 'مخصوص' : 'أفراد (مشترك)';
      document.getElementById('track-passengers').textContent = (trip.passenger_count || 1) + ' راكب';
      if (trip.created_at) document.getElementById('track-start-time').textContent = new Date(trip.created_at).toLocaleString('ar-EG');
      else document.getElementById('track-start-time').textContent = '-';
      document.getElementById('track-code').value = trip.join_code || code;

      // --- Driver card ---
      document.getElementById('track-driver-name').textContent = driver.full_name || 'سائق';
      if (driver.avatar_url) document.getElementById('track-driver-avatar').src = driver.avatar_url;
      if (driver.avg_rating) {
        document.getElementById('track-driver-rating').style.display = 'inline';
        document.getElementById('track-driver-rating-val').textContent = driver.avg_rating;
        document.getElementById('track-driver-rating-count').textContent = driver.total_ratings || 0;
      } else {
        document.getElementById('track-driver-rating-val').textContent = 'جديد';
        document.getElementById('track-driver-rating-count').textContent = '';
      }
      if (driver.phone) {
        document.getElementById('track-driver-phone-row').style.display = 'block';
        document.getElementById('track-driver-phone-link').href = 'tel:' + driver.phone;
        document.getElementById('track-driver-phone-link').textContent = driver.phone;
      } else {
        document.getElementById('track-driver-phone-row').style.display = 'none';
      }
      if (driver.car_model || driver.car_plate) {
        document.getElementById('track-driver-car').style.display = 'block';
        var carText = '';
        if (driver.car_model) carText += driver.car_model;
        if (driver.car_plate) carText += (carText ? ' · ' : '') + driver.car_plate;
        if (driver.car_color) carText = driver.car_color + ' ' + carText;
        document.getElementById('track-driver-car-text').textContent = carText;
      } else {
        document.getElementById('track-driver-car').style.display = 'none';
      }
      document.getElementById('track-driver-card').style.display = 'flex';

      // --- Progress bar ---
      document.getElementById('track-progress').style.display = 'block';
      var steps = document.querySelectorAll('#trackProgressBar .progress-step');
      if (steps) steps.forEach(function(s) { s.classList.remove('active'); });
      function activateStep(step) { var el = document.querySelector('#trackProgressBar .progress-step[data-step="' + step + '"]'); if (el) el.classList.add('active'); }
      if (trip.status === 'assigned') {
        activateStep('assigned');
      } else if (trip.status === 'started') {
        activateStep('assigned');
        activateStep('started');
      } else if (trip.status === 'completed') {
        activateStep('assigned');
        activateStep('started');
        activateStep('completed');
      }

      // --- ETA ---
      updateETA(trip, driver);

      // --- Actions ---
      if (trip.status === 'assigned' || trip.status === 'started') {
        document.getElementById('track-actions').style.display = 'flex';
        document.getElementById('track-end-trip-btn').style.display = '';
        document.getElementById('track-chat-section').style.display = 'block';
        if (trip.id) { currentChatTripId = trip.id; loadChat('track', trip.id); }
      } else {
        document.getElementById('track-actions').style.display = 'none';
        document.getElementById('track-chat-section').style.display = 'none';
      }
      if (trip.status === 'completed') {
        document.getElementById('track-end-trip-btn').style.display = 'none';
        document.getElementById('track-actions').style.display = 'flex';
      }

      document.getElementById('track-info').style.display = 'block';
      document.getElementById('track-map-card').style.display = 'block';
      if (!optCode) statusEl.innerHTML = '<p style="color:var(--success);font-size:14px;">✅ تم العثور على الرحلة</p>';

      // --- Map ---
      if (trackMap) { trackMap.remove(); trackMap = null; }
      try {
        trackMap = L.map('track-map').setView([30.0444, 31.2357], 14);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(trackMap);

        // Draw waypoints if available
        if (waypointsList.length >= 2) {
          var wpLatLngs = waypointsList.map(function(wp) { return [wp.lat, wp.lng]; });
          waypointsList.forEach(function(wp, i) {
            var color = i === 0 ? '#22c55e' : '#3b82f6';
            var marker = L.circleMarker([wp.lat, wp.lng], {
              radius: 7, color: color, fillColor: color, fillOpacity: 0.8, weight: 2
            }).addTo(trackMap);
            marker.bindTooltip(i === 0 ? 'انطلاق' : String(i), { permanent: false, direction: 'top', className: 'waypoint-tooltip' });
          });
          L.polyline(wpLatLngs, { color: '#f59e0b', weight: 3, dashArray: '6, 8' }).addTo(trackMap);
          try { trackMap.fitBounds(L.polyline(wpLatLngs).getBounds(), { padding: [30, 30] }); } catch(e) { console.error('Track map waypoints fitBounds error:', e); }
        }

        // Draw live locations
        if (locations.length) {
          var locPoints = locations.map(function(p) { return [p.lat, p.lng]; });
          L.polyline(locPoints, {color: '#22d3ee', weight: 4}).addTo(trackMap);
          L.circleMarker(locPoints[locPoints.length - 1], {radius: 6, color: '#22c55e', fillColor: '#22c55e', fillOpacity: 1}).addTo(trackMap);
          try { trackMap.fitBounds(L.polyline(locPoints).getBounds(), {padding: [20, 20]}); } catch(e) { console.error('Track map locPoints fitBounds error:', e); }
        } else if (trip.last_lat && trip.last_lng) {
          trackMap.setView([trip.last_lat, trip.last_lng], 15);
          L.marker([trip.last_lat, trip.last_lng]).addTo(trackMap);
        }

        // Show driver location on map if available
        if (driver.current_lat && driver.current_lng) {
          var drvIcon = L.divIcon({ className: 'driver-marker', html: '🚗', iconSize: [24, 24], iconAnchor: [12, 12] });
          L.marker([driver.current_lat, driver.current_lng], { icon: drvIcon }).addTo(trackMap).bindTooltip('موقع السائق', { direction: 'top' });
        }

        setTimeout(function() { if (trackMap) trackMap.invalidateSize(); }, 300);
      } catch(e) { console.error(e); }

      // --- Polling or cleanup ---
      if (trip.status === 'started' || trip.status === 'assigned') {
        if (trackInterval) clearInterval(trackInterval);
        trackInterval = setInterval(function() { trackTrip(code); }, 5000);
      } else {
        if (trackInterval) { clearInterval(trackInterval); trackInterval = null; }
        if (trip.status === 'completed' && currentUser) {
          if (data.trip_id) { lastTrackedTripId = data.trip_id; }
          else if (trip.id) { lastTrackedTripId = trip.id; }
          if (data.driver_id) { lastTrackedDriverId = data.driver_id; }
          else if (trip.driver_id) { lastTrackedDriverId = trip.driver_id; }
          else { lastTrackedDriverId = data.driver?.id || driver.id || null; }
          lastTrackedCode = code;
          showTrackRating();
        }
      }
    } catch (e) { console.error(e); if (!optCode) document.getElementById('track-status').innerHTML = '<p style="color:var(--error);font-size:14px;">❌ حدث خطأ</p>'; }
  };

  var lastETA = { text: '', driverLat: 0, driverLng: 0, destLat: 0, destLng: 0, ts: 0 };
  function updateETA(trip, driver) {
    var etaRow = document.getElementById('track-eta-row');
    var etaVal = document.getElementById('track-eta-val');
    if (!etaRow || !etaVal) return;
    if (!driver || !driver.current_lat || !driver.current_lng || trip.status === 'completed') {
      etaRow.style.display = 'none';
      return;
    }
    var destLat, destLng;
    if (trip.status === 'assigned') {
      var wps = trip.waypoints || [];
      if (wps.length > 0) { destLat = wps[0].lat; destLng = wps[0].lng; }
      else if (trip.last_lat && trip.last_lng) { destLat = trip.last_lat; destLng = trip.last_lng; }
    } else if (trip.status === 'started') {
      var wps = trip.waypoints || [];
      if (wps.length > 1) { var last = wps[wps.length - 1]; destLat = last.lat; destLng = last.lng; }
      else if (trip.last_lat && trip.last_lng) { destLat = trip.last_lat; destLng = trip.last_lng; }
    }
    if (!destLat || !destLng) { etaRow.style.display = 'none'; return; }
    etaRow.style.display = 'flex';
    // Cache: reuse if positions haven't changed significantly (< 50m)
    var moved = haversineDistance(driver.current_lat, driver.current_lng, lastETA.driverLat, lastETA.driverLng) > 0.05
            || haversineDistance(destLat, destLng, lastETA.destLat, lastETA.destLng) > 0.05;
    var stale = Date.now() - lastETA.ts > 30000;
    if (!moved && !stale && lastETA.text) { etaVal.textContent = lastETA.text; return; }
    etaVal.textContent = 'جاري حساب الوقت...';
    lastETA.driverLat = driver.current_lat; lastETA.driverLng = driver.current_lng;
    lastETA.destLat = destLat; lastETA.destLng = destLng;
    var url = 'https://router.project-osrm.org/route/v1/driving/' + driver.current_lng + ',' + driver.current_lat + ';' + destLng + ',' + destLat + '?overview=false&alternatives=false';
    fetch(url).then(function(r) { return r.json(); }).then(function(data) {
      if (data.code === 'Ok' && data.routes && data.routes[0]) {
        var routeDistKm = data.routes[0].distance / 1000;
        var routeSeconds = data.routes[0].duration;
        var minutes = Math.max(1, Math.round(routeSeconds / 60));
        lastETA.text = '~' + minutes + ' دقيقة (' + routeDistKm.toFixed(1) + ' كم)';
      } else {
        var dist = haversineDistance(driver.current_lat, driver.current_lng, destLat, destLng);
        var minutes = Math.max(1, Math.round((dist / 25) * 60));
        lastETA.text = '~' + minutes + ' دقيقة (' + dist.toFixed(1) + ' كم)';
      }
      lastETA.ts = Date.now();
      etaVal.textContent = lastETA.text;
    }).catch(function() {
      var dist = haversineDistance(driver.current_lat, driver.current_lng, destLat, destLng);
      var minutes = Math.max(1, Math.round((dist / 25) * 60));
      lastETA.text = '~' + minutes + ' دقيقة (' + dist.toFixed(1) + ' كم)';
      lastETA.ts = Date.now();
      etaVal.textContent = lastETA.text;
    });
  }

  window.endTrip = async function() {
    if (!trackCurrentTripData) { showToast('لا توجد رحلة نشطة'); return; }
    var tripId = trackCurrentTripData.trip_id || (trackCurrentTripData.trip && trackCurrentTripData.trip.id);
    if (!tripId) { showToast('بيانات الرحلة غير متوفرة'); return; }
    if (!confirm('هل أنت متأكد من إنهاء الرحلة؟')) return;
    try {
      var { data, error } = await supabase.rpc('passenger_end_trip', { p_trip_id: tripId });
      if (error) { showToast('❌ فشل إنهاء الرحلة: ' + error.message); return; }
      if (data && data.success) {
        showToast('✅ تم إنهاء الرحلة بنجاح');
        trackTrip(lastTrackedCode);
      } else {
        showToast('❌ ' + (data?.error || 'فشل إنهاء الرحلة'));
      }
    } catch (e) { showToast('❌ حدث خطأ'); console.error(e); }
  };

  window.shareTripLink = function() {
    var code = document.getElementById('track-code').value;
    if (!code) { showToast('لا يوجد كود رحلة'); return; }
    var shareUrl = window.location.origin + '?track=' + encodeURIComponent(code);
    document.getElementById('share-link-input').value = shareUrl;
    document.getElementById('share-dialog').style.display = 'flex';
  };

  window.copyShareLink = function() {
    var input = document.getElementById('share-link-input');
    if (!input) return;
    input.select();
    input.setSelectionRange(0, 99999);
    try { navigator.clipboard.writeText(input.value); showToast('✅ تم نسخ الرابط'); } catch(e) { document.execCommand('copy'); showToast('✅ تم نسخ الرابط'); }
  };

  window.shareWhatsApp = function() {
    var input = document.getElementById('share-link-input');
    if (!input || !input.value) return;
    var text = encodeURIComponent('🚖 تتبع رحلتي على توقع أجرتك: ' + input.value);
    window.open('https://wa.me/?text=' + text, '_blank');
  };

  window.closeShareDialog = function() {
    document.getElementById('share-dialog').style.display = 'none';
  };

  window.sosAlert = function() {
    if (!confirm('🚨 هل تريد إرسال تنبيه SOS؟\nسيتم إشعار فريق الدعم والطوارئ.')) return;
    showToast('🆘 تم إرسال تنبيه SOS، فريق الدعم سيتم التواصل معك فوراً');
    // Attempt to log SOS event if user is logged in
    if (supabase && currentUser) {
      var tripId = trackCurrentTripData?.trip_id || trackCurrentTripData?.trip?.id;
      var code = document.getElementById('track-code').value;
      supabase.from('ride_requests').insert({
        passenger_id: currentUser.id,
        classification: 'private',
        status: 'cancelled',
        passenger_count: 1,
        note: '🚨 SOS ALERT from tracking screen' + (tripId ? ' (trip: ' + tripId + ')' : '') + (code ? ' (code: ' + code + ')' : '') + ' — user: ' + (currentUser.email || currentUser.id)
      }).then(function(r) { if (r.error) console.error('SOS log error:', r.error); else showToast('✅ تم تسجيل بلاغ SOS — سيتم التواصل معك قريباً'); }).catch(function(e) { console.error('SOS insert error:', e); showToast('❌ فشل تسجيل بلاغ SOS'); });
    }
  };

  window.triggerProcessScheduled = async function() {
    if (!supabase) { showToast('خدمة الجدولة غير متاحة'); return; }
    try {
      var { data, error } = await supabase.rpc('process_scheduled_rides');
      if (error) { showToast('❌ فشل تشغيل الجدولة: ' + error.message); return; }
      showToast('✅ تم معالجة ' + (data || 0) + ' رحلة مجدولة');
      setTimeout(loadScheduledTrips, 500);
    } catch(e) { showToast('❌ حدث خطأ'); console.error(e); }
  };

  // Click outside dialog to close
  document.addEventListener('click', function(e) {
    var dialog = document.getElementById('share-dialog');
    if (dialog && dialog.style.display === 'flex' && e.target === dialog) {
      dialog.style.display = 'none';
    }
  });

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
    if (comment.length > 1000) { showToast('التعليق طويل جداً (الحد الأقصى 1000 حرف)'); return; }
    try {
      var tripId = lastTrackedTripId;
      if (!tripId && lastTrackedCode) {
        var { data: td } = await supabase.from('trips').select('id, driver_id').eq('join_code', lastTrackedCode).order('created_at', { ascending: false }).limit(1).maybeSingle();
        if (td) { tripId = td.id; lastTrackedDriverId = td.driver_id; }
      }
      if (!lastTrackedDriverId && tripId) {
        var { data: td2 } = await supabase.from('trips').select('driver_id').eq('id', tripId).maybeSingle();
        if (td2) lastTrackedDriverId = td2.driver_id;
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
        document.getElementById('auto-track-banner').innerHTML = '<span style="flex:1"><i class="fas fa-circle" style="color:var(--success);font-size:10px;animation:pulse 1.5s infinite;"></i> لديك رحلة نشطة - <strong>' + escapeHTML(trip.join_code) + '</strong></span><button class="btn btn-sm btn-primary" onclick="trackTrip(\'' + escapeHTML(trip.join_code) + '\')" style="padding:6px 16px;font-size:12px;"><i class="fas fa-eye"></i> تتبع</button>';
      }
    } catch (e) { console.error(e); }
  }

  window.requestRide = async function() {
    if (!supabase || !currentUser) { showToast('يجب تسجيل الدخول أولاً'); return; }
    if (typeof requireSubscription === 'function' && !(await requireSubscription())) return;
    if (requestWaypoints.length < 2) { showAlert('request-alert', 'يرجى تحديد نقطتين على الأقل على الخريطة (نقطة انطلاق ووجهة)'); return; }
    var type = document.getElementById('request-type').value;
    var passengers = Math.round(clampNumber(document.getElementById('request-passengers').value, 1, 10, 1));
    var note = document.getElementById('request-note').value.trim();
    if (note.length > 500) { showAlert('request-alert', 'الملاحظة طويلة جداً (الحد الأقصى 500 حرف)'); return; }
    document.getElementById('request-btn').disabled = true;
    document.getElementById('request-loading').classList.remove('hidden-el');
    try {
      // Cancel any previous pending requests to avoid duplicates
      await supabase.from('ride_requests').update({ status: 'cancelled', offered_to: null }).eq('passenger_id', currentUser.id).eq('status', 'pending');
      if (window.passengerRequestPollTimer) { clearInterval(window.passengerRequestPollTimer); window.passengerRequestPollTimer = null; }
      var first = requestWaypoints[0];
      var last = requestWaypoints[requestWaypoints.length - 1];
      var payload = {
        passenger_id: currentUser.id, passenger_count: passengers,
        classification: type === 'private' ? 'private' : 'shared',
        status: 'pending', adult_count: passengers, child_count: 0,
        pickup_address: 'نقطة ' + first.lat.toFixed(5) + ', ' + first.lng.toFixed(5),
        destination_address: 'نقطة ' + last.lat.toFixed(5) + ', ' + last.lng.toFixed(5),
        pickup_lat: first.lat, pickup_lng: first.lng,
        waypoints: requestWaypoints,
        note: note || null
      };
      var { data, error } = await supabase.from('ride_requests').insert(payload).select('id, pickup_lat, pickup_lng').single();
      if (error) { showAlert('request-alert', error.message); document.getElementById('request-btn').disabled = false; document.getElementById('request-loading').classList.add('hidden-el'); return; }
      showAlert('request-alert', 'تم إرسال الطلب! جاري البحث عن سائق...', 'success');
      currentPassengerRequestId = data.id;
      currentPassengerRequestCreatedAt = Date.now();
      currentPassengerOfferedDrivers = [];
      if (data.pickup_lat && data.pickup_lng) {
        try {
          var { data: nearest } = await supabase.rpc('find_nearest_available_driver', { pickup_lat: data.pickup_lat, pickup_lng: data.pickup_lng, exclude_ids: [] });
          if (nearest && nearest.found && nearest.driver_id) {
            currentPassengerOfferedDrivers.push(nearest.driver_id);
            var { data: offerResult, error: offerErr } = await supabase.rpc('offer_request_to_driver', { p_request_id: data.id, p_driver_id: nearest.driver_id, p_offered_drivers: currentPassengerOfferedDrivers });
            if (offerErr) console.error('initial offer RPC error:', offerErr);
            else if (offerResult && offerResult.success === false) console.error('initial offer rejected by RPC:', offerResult.error);
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
  window.passengerRequestPollTimer = null;

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
    if (window.passengerRequestPollTimer) clearInterval(window.passengerRequestPollTimer);
    // Real-time subscription for instant status change
    if (window._passengerRequestChannel) { try { supabase.removeChannel(window._passengerRequestChannel); } catch(e) {} window._passengerRequestChannel = null; }
    try {
      window._passengerRequestChannel = supabase.channel('pass-req-' + requestId)
        .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'ride_requests', filter: 'id=eq.' + requestId }, function() { pollPassengerRequest(requestId); })
        .subscribe(function(status) { if (status !== 'SUBSCRIBED') console.warn('Passenger RT status:', status); });
    } catch(e) { console.error('Passenger Realtime error:', e); }
    // Backup polling (15s) for auto-reassign logic (Realtime handles instant status changes)
    window.passengerRequestPollTimer = setInterval(function() { pollPassengerRequest(requestId); }, 15000);
  }

  function initPassengerTripRealtime(tripId, driverId, requestId) {
    // Clean up existing subs
    if (window._tripRealtimeChannel) { try { supabase.removeChannel(window._tripRealtimeChannel); } catch(e) {} }
    if (window._driverLocChannel) { try { supabase.removeChannel(window._driverLocChannel); } catch(e) {} }
    // Subscribe to trip status changes for arrival/ongoing/completed detection
    try {
      window._tripRealtimeChannel = supabase.channel('pass-trip-' + tripId)
        .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'trips', filter: 'id=eq.' + tripId },
          function(change) {
            var trip = change.new;
            if (trip.status) updateAcceptedTripStatusUI(trip.status, trip.total_fare);
          })
        .subscribe();
    } catch(e) { console.error('Trip Realtime error:', e); }
    // Subscribe to driver location updates
    if (driverId) {
      try {
        window._driverLocChannel = supabase.channel('pass-driver-' + driverId)
          .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'drivers', filter: 'id=eq.' + driverId },
            function(change) {
              var loc = change.new;
              if (loc && loc.current_lat && loc.current_lng && window.acceptedDriverMarker) {
                window.acceptedDriverMarker.setLatLng([loc.current_lat, loc.current_lng]);
                if (window.acceptedDriverMap) window.acceptedDriverMap.setView([loc.current_lat, loc.current_lng], 15);
              }
            })
          .subscribe();
      } catch(e) { console.error('Driver loc Realtime error:', e); }
    }
  }

  window.openRatingFromAccepted = function() {
    if (currentChatTripId) {
      document.getElementById('rateTripId').value = currentChatTripId;
      document.getElementById('ratingModal').style.display = 'flex';
    } else {
      showToast('لا توجد رحلة للتقييم');
    }
  };

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
      window.acceptedDriverMarker = driverMarker;
      if (acceptedDriverLocTimer) clearInterval(acceptedDriverLocTimer);
      acceptedDriverLocTimer = setInterval(async function() {
        if (!driverId) return;
        try {
          var { data: driverLoc } = await supabase.from('drivers').select('current_lat, current_lng').eq('id', driverId).single();
          if (driverLoc && driverLoc.current_lat && driverLoc.current_lng) {
            window.acceptedDriverMarker.setLatLng([driverLoc.current_lat, driverLoc.current_lng]);
            acceptedDriverMap.setView([driverLoc.current_lat, driverLoc.current_lng], 15);
          }
        } catch(e) { console.error('Driver location poll error:', e); }
        try {
          var { data: tripUpd } = await supabase.from('trips').select('id, status').eq('join_code', tripCode).order('created_at', { ascending: false }).limit(1).maybeSingle();
          if (tripUpd) {
            if (tripUpd.status === 'started') {
              clearInterval(acceptedDriverLocTimer);
              document.getElementById('acceptedTripStatus').textContent = 'جارية 🟢';
              if (tripUpd.id) currentChatTripId = tripUpd.id;
              try { var ctx = new (window.AudioContext || window.webkitAudioContext)(); var osc = ctx.createOscillator(); osc.frequency.value = 880; osc.type = 'sine'; var gain = ctx.createGain(); gain.gain.value = 0.4; osc.connect(gain); gain.connect(ctx.destination); osc.start(); osc.stop(ctx.currentTime + 0.5); } catch(e) {}
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
        } catch(e) { console.error('Trip status poll error:', e); }
      }, 15000);
      setTimeout(function() { if (acceptedDriverMap) acceptedDriverMap.invalidateSize(); }, 300);
    } catch(e) { console.error(e); }
  }

  async function pollPassengerRequest(requestId) {
    if (!supabase || !requestId) return;
    try {
      var { data, error } = await supabase.from('ride_requests').select('id, status, driver_id, responded_at, pickup_lat, pickup_lng, offered_at').eq('id', requestId).single();
      if (error || !data) { clearInterval(window.passengerRequestPollTimer); return; }
      // Auto-cancel after 5 minutes with no acceptance
      if (currentPassengerRequestCreatedAt && Date.now() - currentPassengerRequestCreatedAt > 300000) {
        if (data.status === 'pending') {
          await supabase.from('ride_requests').update({ status: 'cancelled' }).eq('id', requestId);
          showToast('تم إلغاء الطلب تلقائياً لعدم وجود سائق');
        }
        clearInterval(window.passengerRequestPollTimer);
        document.getElementById('reqStatusIcon').textContent = '\u23F0';
        document.getElementById('reqStatusText').textContent = 'انتهى وقت الطلب';
        document.getElementById('reqStatusSub').textContent = 'لم يتم العثور على سائق، حاول مرة أخرى';
        document.getElementById('cancelRequestBtn').style.display = 'none';
        return;
      }
      // Auto-reassign if no driver offered, or offered driver hasn't responded
      var shouldReassign = false;
      if (data.status === 'pending' && data.pickup_lat && data.pickup_lng) {
        if (!data.offered_to) {
          shouldReassign = true;
          document.getElementById('reqStatusSub').textContent = 'جاري البحث عن سائق آخر...';
        } else if (data.offered_at) {
          var elapsed = Date.now() - new Date(data.offered_at).getTime();
          if (elapsed > 60000) shouldReassign = true;
        }
        if (shouldReassign) {
          try {
            // Merge server-side rejected drivers with client-side list
            var offeredOnServer = data.offered_drivers || [];
            var mergedExclude = currentPassengerOfferedDrivers.slice();
            offeredOnServer.forEach(function(did) { if (!mergedExclude.includes(did)) mergedExclude.push(did); });
            var { data: nearest } = await supabase.rpc('find_nearest_available_driver', { pickup_lat: data.pickup_lat, pickup_lng: data.pickup_lng, exclude_ids: mergedExclude });
            if (nearest && nearest.found && nearest.driver_id) {
              if (!mergedExclude.includes(nearest.driver_id)) mergedExclude.push(nearest.driver_id);
              currentPassengerOfferedDrivers = mergedExclude;
              var { data: reassignResult, error: reassignErr } = await supabase.rpc('offer_request_to_driver', { p_request_id: requestId, p_driver_id: nearest.driver_id, p_offered_drivers: currentPassengerOfferedDrivers });
              if (reassignErr) console.error('reassign RPC error:', reassignErr);
              else if (reassignResult && reassignResult.success === false) console.error('reassign rejected by RPC:', reassignResult.error);
              else document.getElementById('reqStatusSub').textContent = 'جاري عرض الطلب على سائق آخر...';
            } else {
              document.getElementById('reqStatusSub').textContent = 'لا يوجد سائقين متاحين قريباً';
            }
          } catch (e) { console.error('reassign error:', e); }
        }
      }
      if (data.status === 'accepted') {
        clearInterval(window.passengerRequestPollTimer);
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
          // Fetch driver car info
          var { data: driverCar } = await supabase.from('drivers').select('car_model, car_color, car_plate').eq('id', data.driver_id).single();
          if (driverCar) {
            var carStr = '';
            if (driverCar.car_model) carStr += driverCar.car_model;
            if (driverCar.car_color) carStr += (carStr ? ' — ' : '') + driverCar.car_color;
            if (driverCar.car_plate) carStr += (carStr ? ' | ' : '') + driverCar.car_plate;
            document.getElementById('acceptedCarInfo').textContent = carStr || 'مركبة';
          }
        }
        var { data: tripData } = await supabase.from('trips').select('id, join_code, status, total_fare').eq('passenger_id', currentUser.id).eq('driver_id', data.driver_id).order('created_at', { ascending: false }).limit(1).maybeSingle();
        if (tripData) {
          document.getElementById('acceptedTripCode').textContent = tripData.join_code || '-';
          updateAcceptedTripStatusUI(tripData.status, tripData.total_fare);
          if (data.driver_id && tripData.join_code) {
            initAcceptedDriverMap(data.driver_id, tripData.join_code);
            initPassengerTripRealtime(tripData.id, data.driver_id, data.id);
          }
          currentChatTripId = tripData.id;
          if (tripData.status === 'assigned' || tripData.status === 'arrived' || tripData.status === 'ongoing' || tripData.status === 'started') {
            document.getElementById('track-chat-section').style.display = 'block';
            loadChat('track', currentChatTripId);
          }
        }
      } else if (data.status === 'cancelled') {
        clearInterval(window.passengerRequestPollTimer);
        document.getElementById('reqStatusIcon').textContent = '\u274C';
        document.getElementById('reqStatusText').textContent = 'تم إلغاء الطلب';
        document.getElementById('reqStatusSub').textContent = 'يمكنك إرسال طلب جديد';
        document.getElementById('cancelRequestBtn').style.display = 'none';
      }
    } catch (e) { console.error(e); }
  }

  function updateAcceptedTripStatusUI(status, totalFare) {
    var statusEl = document.getElementById('acceptedTripStatus');
    var fareRow = document.getElementById('finalFareRow');
    var fareVal = document.getElementById('finalFareValue');
    var icon = document.getElementById('acceptedIcon');
    var title = document.getElementById('acceptedTitle');
    var subtitle = document.getElementById('acceptedSubtitle');
    var rateBtn = document.getElementById('rateTripBtn');
    var trackBtn = document.getElementById('trackTripBtn');
    if (!statusEl) return;
    statusEl.style.display = 'block';
    if (status === 'assigned') {
      statusEl.textContent = 'السائق في الطريق 🚗';
      statusEl.style.color = 'var(--accent)';
    } else if (status === 'arrived') {
      statusEl.textContent = '✅ وصل السائق إلى مكانك';
      statusEl.style.color = 'var(--success)';
      if (title) title.textContent = 'وصل السائق!';
      if (subtitle) subtitle.textContent = 'السائق في انتظارك';
    } else if (status === 'ongoing' || status === 'started') {
      statusEl.textContent = '🔵 الرحلة جارية';
      statusEl.style.color = '#3b82f6';
      if (title) title.textContent = 'الرحلة جارية';
      if (subtitle) subtitle.textContent = 'أنت في رحلة آمنة';
    } else if (status === 'completed') {
      statusEl.textContent = '✅ تمت الرحلة بنجاح';
      statusEl.style.color = 'var(--success)';
      if (icon) icon.innerHTML = '&#x1F3C1;';
      if (title) title.textContent = 'تمت الرحلة بنجاح!';
      if (subtitle) subtitle.textContent = 'شكراً لاستخدامك توقع أجرتك';
      if (fareRow) { fareRow.style.display = 'flex'; }
      if (fareVal && totalFare != null) { fareVal.textContent = totalFare + ' ج'; }
      if (rateBtn) rateBtn.style.display = 'flex';
      if (trackBtn) trackBtn.style.display = 'none';
      // Clean up realtime subs
      if (window._tripRealtimeChannel) { try { supabase.removeChannel(window._tripRealtimeChannel); } catch(e) {} window._tripRealtimeChannel = null; }
      if (window._driverLocChannel) { try { supabase.removeChannel(window._driverLocChannel); } catch(e) {} window._driverLocChannel = null; }
      // Open rating modal after short delay
      setTimeout(function() { openRatingFromAccepted(); }, 1500);
    }
  }
  window.updateFareEstimate = function() {
    var type = document.getElementById('request-type').value;
    var count = parseInt(document.getElementById('request-passengers').value) || 1;
    var el = document.getElementById('fareEstimateValue');
    var distKm = calculateWaypointsDistance();
    if (distKm > 0 && requestWaypoints.length >= 2) {
      var baseFare = type === 'private' ? 10 : 5;
      var perKm = type === 'private' ? 3.5 : 2;
      var minFare = baseFare + distKm * perKm;
      var maxFare = minFare * 1.3;
      el.textContent = minFare.toFixed(0) + ' - ' + maxFare.toFixed(0) + ' ج.م' + (type === 'shared' ? ' للفرد' : '');
    } else {
      el.textContent = type === 'private' ? '15 - 35 ج.م' : (count * 3) + ' - ' + (count * 8) + ' ج.م للفرد';
    }
  };

  window.getCurrentLocation = function() {
    setMyLocationAsFirst();
  };

  async function loadPassengerHistory() {
    if (!supabase || !currentUser) return;
    var list = document.getElementById('passengerHistoryList');
    try {
      var { data: trips, error } = await supabase.from('trips').select('*').eq('passenger_id', currentUser.id).order('created_at', { ascending: false }).limit(20);
      if (error || !trips || !trips.length) { list.innerHTML = '<div class="empty-state">لا توجد رحلات سابقة</div>'; return; }
      list.innerHTML = trips.map(function(t) {
        var isCompleted = t.status === 'completed';
        var hasPendingProposal = t.passenger_proposed_fare != null && t.passenger_price_accepted !== true;
        var proposalAccepted = t.passenger_price_accepted === true;
        var fare = proposalAccepted ? t.total_fare : t.total_fare;
        var priceActions = '';
        if (isCompleted && !proposalAccepted) {
          priceActions = '<button class="btn btn-sm btn-outline" onclick="showPassengerPriceProposal(\'' + escapeHTML(t.id) + '\', ' + (t.total_fare || 0) + ')" style="padding:4px 10px;font-size:11px;margin-top:4px;"><i class="fas fa-edit"></i> ' + (hasPendingProposal ? 'تعديل الاقتراح' : 'تعديل السعر') + '</button>';
        }
        if (hasPendingProposal) {
          priceActions += '<div style="font-size:10px;color:var(--accent);margin-top:2px;">⏳ بانتظار موافقة السائق على ' + t.passenger_proposed_fare.toFixed(2) + ' ج</div>';
        }
        if (proposalAccepted) {
          priceActions += '<div style="font-size:10px;color:var(--success);margin-top:2px;">✅ تم الاتفاق على السعر</div>';
        }
        // Payment button for unpaid wallet trips
        if (isCompleted && t.payment_method === 'wallet' && (t.payment_status === 'unpaid' || t.payment_status === null)) {
          priceActions += '<button class="btn btn-sm btn-success" onclick="payTripFromWallet(\'' + escapeHTML(t.id) + '\', ' + fare + ')" style="padding:4px 10px;font-size:11px;margin-top:4px;"><i class="fas fa-wallet"></i> ادفع ' + fare.toFixed(2) + ' ج من المحفظة</button>';
        }
        if (t.payment_status === 'paid_wallet') {
          priceActions += '<div style="font-size:10px;color:var(--success);margin-top:2px;">✅ مدفوع عن طريق المحفظة</div>';
        }
        if (t.payment_status === 'paid_cash') {
          priceActions += '<div style="font-size:10px;color:var(--meter-muted);margin-top:2px;">💰 نقدي (يداً بيد)</div>';
        }
        return '<div class="history-item"><div class="history-header"><span>' + escapeHTML(new Date(t.created_at).toLocaleDateString('ar-EG')) + '</span><span style="color:var(--meter-primary)">' + escapeHTML(t.join_code || '-') + '</span></div><div class="history-details"><div>' + (t.classification === 'private' ? 'مخصوص' : 'أفراد') + '</div><div>' + clampNumber(t.distance_km, 0, 1000, 0).toFixed(2) + ' كم</div><div>' + clampNumber(t.duration_min, 0, 1440, 0).toFixed(0) + ' د</div><div>' + clampNumber(t.passenger_count, 1, 20, 1) + ' راكب</div></div><div class="history-fare">' + clampNumber(fare, 0, 100000, 0).toFixed(2) + ' ج</div>' + priceActions + '</div>';
      }).join('');
    } catch (e) { list.innerHTML = '<div class="empty-state">خطأ في التحميل</div>'; }
  }
  window.loadPassengerHistory = loadPassengerHistory;

  async function loadPassengerRequests() {
    if (!supabase || !currentUser) return;
    var list = document.getElementById('passengerRequestList');
    try {
      var { data: requests, error } = await supabase.from('ride_requests').select('*').eq('passenger_id', currentUser.id).order('created_at', { ascending: false }).limit(30);
      if (error || !requests || !requests.length) { list.innerHTML = '<div class="empty-state">لا توجد طلبات سابقة</div>'; return; }
      list.innerHTML = requests.map(function(r) {
        var statusText = r.status === 'pending' ? '🟡 قيد الانتظار' : r.status === 'accepted' ? '🟢 تم القبول' : r.status === 'cancelled' ? '🔴 ملغي' : r.status;
        var timeAgo = Math.floor((Date.now() - new Date(r.created_at).getTime()) / 1000);
        var timeText = timeAgo < 60 ? 'منذ ' + timeAgo + ' ثانية' : timeAgo < 3600 ? 'منذ ' + Math.floor(timeAgo / 60) + ' دقيقة' : 'منذ ' + Math.floor(timeAgo / 3600) + ' ساعة';
        var cancelBtn = r.status === 'pending' ? '<button class="btn btn-danger btn-sm" onclick="cancelRequestFromHistory(\'' + escapeHTML(r.id) + '\')" style="padding:4px 10px;font-size:11px;"><i class="fas fa-times"></i> إلغاء</button>' : '';
        var driverInfo = r.driver_id ? '<div style="font-size:10px;color:var(--meter-muted);">السائق: ' + r.driver_id.slice(0,8) + '...</div>' : '';
        return '<div class="history-item"><div class="history-header"><span>' + escapeHTML(timeText) + '</span><span style="color:var(--meter-primary)">' + statusText + '</span></div><div class="history-details"><div>' + (r.classification === 'private' ? 'مخصوص' : 'أفراد') + '</div><div>' + (r.passenger_count || 1) + ' راكب</div><div style="font-size:10px;">' + escapeHTML(r.pickup_address || '-') + '</div></div><div style="display:flex;gap:6px;margin-top:4px;">' + cancelBtn + driverInfo + '</div></div>';
      }).join('');
    } catch (e) { list.innerHTML = '<div class="empty-state">خطأ في التحميل</div>'; console.error(e); }
  }
  window.loadPassengerRequests = loadPassengerRequests;

  window.cancelRequestFromHistory = async function(requestId) {
    if (!confirm('هل أنت متأكد من إلغاء هذا الطلب؟')) return;
    try {
      var { data: req } = await supabase.from('ride_requests').select('status, driver_id, passenger_id').eq('id', requestId).single();
      if (!req || req.status !== 'pending') { showToast('لا يمكن إلغاء طلب في هذه الحالة'); return; }
      await supabase.from('ride_requests').update({ status: 'cancelled', offered_to: null }).eq('id', requestId);
      showToast('✅ تم إلغاء الطلب');
      loadPassengerRequests();
    } catch (e) { showToast('فشل الإلغاء'); console.error(e); }
  };

  window.payTripFromWallet = async function(tripId, amount) {
    if (!confirm('تأكيد دفع ' + amount.toFixed(2) + ' ج من محفظتك لهذه الرحلة؟')) return;
    try {
      var { data, error } = await supabase.rpc('pay_trip_from_wallet', { p_trip_id: tripId });
      if (error) { showToast('❌ فشل: ' + error.message); return; }
      if (data && data.success) {
        showToast('✅ تم الدفع بنجاح: ' + data.amount.toFixed(2) + ' ج');
        loadPassengerHistory();
        if (typeof loadWallet === 'function') setTimeout(loadWallet, 500);
      } else {
        var msg = data?.error || 'فشل الدفع';
        if (data?.required) {
          msg = '❌ الرصيد غير كافٍ. المطلوب: ' + data.required.toFixed(2) + ' ج، رصيدك: ' + (data.balance || 0).toFixed(2) + ' ج';
        }
        showToast(msg);
      }
    } catch(e) { showToast('❌ حدث خطأ'); console.error(e); }
  };

  window.showPassengerPriceProposal = async function(tripId, currentFare) {
    var vals = await showPromptModal({ title: 'تعديل السعر (الحد الأقصى: ' + currentFare.toFixed(2) + ' ج)', fields: [{ key: 'fare', label: 'السعر المقترح', placeholder: currentFare.toFixed(2), defaultValue: currentFare.toFixed(2), type: 'text' }, { key: 'note', label: 'سبب التعديل (اختياري)', placeholder: 'السبب...', type: 'text' }], confirmText: 'إرسال', validator: function(v) { var n = parseFloat(v.fare); if (isNaN(n) || n < 0 || n > 100000) return 'قيمة غير صالحة'; if (n > currentFare) return 'السعر لا يزيد عن السعر الحالي'; } });
    if (!vals) return;
    var fareNum = parseFloat(vals.fare);
    supabase.rpc('propose_trip_price', { p_trip_id: tripId, p_proposed_fare: fareNum, p_note: vals.note || '' }).then(function(r) {
      if (r.error) { showToast('❌ فشل: ' + r.error.message); return; }
      if (r.data && r.data.success) {
        showToast('✅ تم اقتراح السعر. بانتظار موافقة السائق');
        loadPassengerHistory();
      } else {
        showToast('❌ ' + (r.data?.error || 'فشل'));
      }
    }).catch(function(e) { console.error('Price proposal error:', e); showToast('❌ فشل اقتراح السعر'); });
  };

  // ======================== SCHEDULED RIDES ========================
  var scheduleWaypoints = [];
  var scheduleMap = null;

  window.initScheduleMap = function() {
    var el = document.getElementById('schedule-map');
    if (!el) return;
    if (scheduleMap) { scheduleMap.invalidateSize(); return; }
    try {
      scheduleMap = L.map('schedule-map').setView([30.0444, 31.2357], 13);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(scheduleMap);
      scheduleWaypoints = [];
      scheduleMap.on('click', function(e) {
        scheduleWaypoints.push({ lat: e.latlng.lat, lng: e.latlng.lng });
        redrawScheduleWaypoints();
      });
      setTimeout(function() { if (scheduleMap) scheduleMap.invalidateSize(); }, 300);
    } catch(e) { console.error('Schedule map init error:', e); }
  };

  function redrawScheduleWaypoints() {
    if (!scheduleMap) return;
    scheduleMap.eachLayer(function(layer) {
      if (layer._isScheduleWp) scheduleMap.removeLayer(layer);
      if (layer._isScheduleLine) scheduleMap.removeLayer(layer);
    });
    if (scheduleWaypoints.length === 0) return;
    var markers = [];
    scheduleWaypoints.forEach(function(wp, i) {
      var color = i === 0 ? '#22c55e' : i === scheduleWaypoints.length - 1 ? '#ef4444' : '#3b82f6';
      var m = L.circleMarker([wp.lat, wp.lng], { radius: 7, color: color, fillColor: color, fillOpacity: 0.7 });
      m._isScheduleWp = true;
      m.bindTooltip(i === 0 ? '🔵 انطلاق' : i === scheduleWaypoints.length - 1 ? '🔴 وجهة' : 'محطة ' + (i + 1), { direction: 'top' });
      m.addTo(scheduleMap);
      markers.push(m);
    });
    if (scheduleWaypoints.length >= 2) {
      var latlngs = scheduleWaypoints.map(function(wp) { return [wp.lat, wp.lng]; });
      var line = L.polyline(latlngs, { color: '#f59e0b', weight: 3, dashArray: '8,6' });
      line._isScheduleLine = true;
      line.addTo(scheduleMap);
      scheduleMap.fitBounds(line.getBounds().pad(0.1));
    }
  }

  window.clearScheduleWaypoints = function() {
    scheduleWaypoints = [];
    redrawScheduleWaypoints();
  };

  window.undoScheduleWaypoint = function() {
    scheduleWaypoints.pop();
    redrawScheduleWaypoints();
  };

  window.createScheduledTrip = async function() {
    if (!supabase || !currentUser) { showToast('يجب تسجيل الدخول أولاً'); return; }
    if (scheduleWaypoints.length < 2) { showAlert('schedule-alert', 'يرجى تحديد نقطتين على الأقل (نقطة انطلاق ووجهة)'); return; }
    var dt = document.getElementById('schedule-datetime').value;
    if (!dt) { showAlert('schedule-alert', 'يرجى اختيار تاريخ ووقت الرحلة'); return; }
    var scheduledTime = new Date(dt + ':00').toISOString();
    if (new Date(scheduledTime).getTime() <= Date.now() + 60000) { showAlert('schedule-alert', 'يجب أن يكون الوقت المحدد بعد دقيقة على الأقل من الآن'); return; }
    var first = scheduleWaypoints[0];
    var last = scheduleWaypoints[scheduleWaypoints.length - 1];
    var count = parseInt(document.getElementById('schedule-passengers').value) || 1;
    var note = document.getElementById('schedule-note').value.trim();
    var btn = document.getElementById('schedule-btn');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> جاري الجدولة...';
    try {
      showAlert('schedule-alert', '', 'success');
      var { data, error } = await supabase.from('scheduled_trips').insert({
        passenger_id: currentUser.id,
        pickup_address: 'نقطة ' + first.lat.toFixed(5) + ', ' + first.lng.toFixed(5),
        destination_address: 'نقطة ' + last.lat.toFixed(5) + ', ' + last.lng.toFixed(5),
        pickup_lat: first.lat, pickup_lng: first.lng,
        destination_lat: last.lat, destination_lng: last.lng,
        waypoints: scheduleWaypoints,
        passenger_count: count,
        note: note || null,
        scheduled_time: scheduledTime,
        status: 'scheduled'
      }).select('id').single();
      if (error) { showAlert('schedule-alert', error.message); btn.disabled = false; btn.innerHTML = '<i class="fas fa-calendar-check"></i> جدولة الرحلة'; return; }
      showAlert('schedule-alert', '✅ تم جدولة الرحلة بنجاح! سيتم إرسالها تلقائياً في الوقت المحدد', 'success');
      scheduleWaypoints = [];
      redrawScheduleWaypoints();
      document.getElementById('schedule-datetime').value = '';
      document.getElementById('schedule-note').value = '';
      loadScheduledTrips();
    } catch(e) { showAlert('schedule-alert', e.message); }
    btn.disabled = false;
    btn.innerHTML = '<i class="fas fa-calendar-check"></i> جدولة الرحلة';
  };

  window.loadScheduledTrips = async function() {
    if (!supabase || !currentUser) return;
    var list = document.getElementById('scheduled-trips-list');
    if (!list) return;
    try {
      var { data, error } = await supabase.from('scheduled_trips').select('*').eq('passenger_id', currentUser.id).order('scheduled_time', { ascending: false }).limit(20);
      if (error || !data || !data.length) {
        list.innerHTML = '<div class="empty-state">لا توجد رحلات مجدولة</div>';
        return;
      }
      list.innerHTML = data.map(function(t) {
        var timeStr = new Date(t.scheduled_time).toLocaleString('ar-EG', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
        var isPast = new Date(t.scheduled_time).getTime() < Date.now();
        var statusClass = t.status === 'cancelled' ? 'cancelled' : t.status === 'active' || t.status === 'completed' ? 'completed' : '';
        var statusText = t.status === 'scheduled' ? '⏳ في الانتظار' : t.status === 'processing' ? '🔄 قيد المعالجة' : t.status === 'active' ? '✅ نشطة' : t.status === 'completed' ? '✅ مكتملة' : t.status === 'cancelled' ? '❌ ملغية' : t.status;
        return '<div class="driver-request-item" style="opacity:' + (t.status === 'cancelled' ? 0.6 : 1) + '">' +
          '<div class="top"><span class="name"><i class="fas fa-calendar"></i> ' + timeStr + '</span><span class="req-badge ' + statusClass + '">' + statusText + '</span></div>' +
          '<div class="info"><i class="fas fa-map-pin"></i> ' + escapeHTML(t.pickup_address || '-') + '</div>' +
          (t.destination_address ? '<div class="info"><i class="fas fa-flag"></i> ' + escapeHTML(t.destination_address) + '</div>' : '') +
          (t.note ? '<div class="info" style="color:var(--accent);"><i class="fas fa-comment"></i> ' + escapeHTML(t.note) + '</div>' : '') +
          (t.status === 'scheduled' && !isPast ? '<div class="req-actions"><button class="btn btn-danger btn-sm" onclick="cancelScheduledTrip(\'' + escapeHTML(t.id) + '\')"><i class="fas fa-times"></i> إلغاء</button></div>' : '') +
          '</div>';
      }).join('');
    } catch(e) { list.innerHTML = '<div class="empty-state">خطأ في التحميل</div>'; console.error(e); }
  };

  window.cancelScheduledTrip = async function(tripId) {
    if (!confirm('هل أنت متأكد من إلغاء هذه الرحلة المجدولة؟')) return;
    try {
      var { error } = await supabase.from('scheduled_trips').update({ status: 'cancelled', updated_at: new Date().toISOString() }).eq('id', tripId).eq('passenger_id', currentUser.id);
      if (error) { showToast('❌ فشل الإلغاء: ' + error.message); return; }
      showToast('✅ تم إلغاء الرحلة المجدولة');
      loadScheduledTrips();
    } catch(e) { showToast('❌ فشل'); console.error(e); }
  };
