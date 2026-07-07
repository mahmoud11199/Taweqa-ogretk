  var GPS_FILTER = { minDistance: 0.005, waitingSpeedKmh: 1.5 };
  var meters = { 1: createEmptyMeterObject(1), 2: createEmptyMeterObject(2) };
  var activeMeterId = 1;
  var driverMap, pathLine, currentMarker;
  var globalWatchId = null;

	  function createEmptyMeterObject(id) {
	    return { id: id, isActive: false, isPaused: false, tripType: 'makhsoos', kmPrice: 5, waitPrice: 1, durationPrice: 0.50, bandira: 5, minFare: 10, totalDistance: 0, startTime: null, pausedTimeTotal: 0, lastPauseTimestamp: null, totalDurationMinutes: 0, totalWaitSeconds: 0, waitingStartedAt: null, waitingBaseSeconds: 0, lastLat: null, lastLng: null, lastAccuracy: null, lastSpeedKmh: null, lastLocationTime: null, isWaitingMode: false, shareCode: '', tripId: null, lastSupabaseSync: 0, finalFare: 0, passengerCount: 1, pathCoords: [], passengersData: [] };
	  }

  function initDriverMap() {
    if (driverMap) { driverMap.invalidateSize(); return; }
    try {
      driverMap = L.map('map').setView([30.0444, 31.2357], 13);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(driverMap);
      pathLine = L.polyline([], {color: '#22d3ee', weight: 4}).addTo(driverMap);
      currentMarker = L.marker([30.0444, 31.2357]).addTo(driverMap);
      setTimeout(function() { driverMap.invalidateSize(); }, 300);
    } catch(e) { console.error('Map init error:', e); }
  }

  function switchDriverTab(tab, btn) {
    ['meter','requests','history','profile','wallet'].forEach(function(t) {
      var el = document.getElementById('driver-' + t + '-section');
      if (el) el.style.display = t === tab ? 'block' : 'none';
    });
    document.getElementById('driver-chat-section-standalone').style.display = tab === 'chat' ? 'block' : 'none';
    var chatSection = document.getElementById('driver-chat-section');
    if (chatSection) chatSection.style.display = 'none';
    if (btn) {
      document.querySelectorAll('#driver-app .app-nav .tab-btn').forEach(function(b) { b.classList.remove('active'); });
      btn.classList.add('active');
    }
    if (tab === 'meter' && driverMap) setTimeout(function() { driverMap.invalidateSize(); }, 200);
  }
  window.switchDriverTab = switchDriverTab;

  function switchPassengerTab(tab, btn) {
    ['track','request','request-status','history','profile','wallet'].forEach(function(t) {
      var el = document.getElementById('passenger-' + t + '-section');
      if (el) el.style.display = t === tab ? 'block' : 'none';
    });
    if (btn) {
      document.querySelectorAll('#passenger-app .app-nav .tab-btn').forEach(function(b) { b.classList.remove('active'); });
      btn.classList.add('active');
    }
    if (tab !== 'request-status' && window.passengerRequestPollTimer) {
      clearInterval(window.passengerRequestPollTimer);
      window.passengerRequestPollTimer = null;
    }
    if (tab === 'request') {
      setTimeout(function() {
        if (typeof initRequestMap === 'function') initRequestMap();
        if (requestMap) requestMap.invalidateSize();
      }, 300);
    }
    if (tab === 'track') { setTimeout(autoLoadActiveTrip, 200); }
    if (tab === 'history') {
      if (typeof loadPassengerRequests === 'function') loadPassengerRequests();
      if (typeof loadPassengerHistory === 'function') loadPassengerHistory();
    }
  }
  window.switchPassengerTab = switchPassengerTab;

  function switchActiveMeterUI(id) {
    activeMeterId = id;
    document.querySelectorAll('.meter-tab').forEach(function(t) { t.classList.remove('active'); });
    document.getElementById('meterTab_' + id).classList.add('active');
    var m = meters[activeMeterId];
    document.getElementById('tripType').value = m.tripType;
    document.getElementById('kmPriceInput').value = m.kmPrice;
    document.getElementById('waitPriceInput').value = m.waitPrice;
    document.getElementById('durationPriceInput').value = m.durationPrice;
    onTripTypeChanged();
    renderMeterDataToUI();
    redrawActiveRouteLine();
  }
  window.switchActiveMeterUI = switchActiveMeterUI;

  function onTripTypeChanged() {
    var type = document.getElementById('tripType').value;
    var btnBtn = document.getElementById('dynamicActionBtn');
    if (type === 'afrad') {
      btnBtn.innerText = '\u2699\uFE0F \u0625\u062C\u0631\u0627\u0621 \u0639\u0644\u0649 \u0627\u0644\u0631\u0643\u0627\u0628';
      btnBtn.style.backgroundColor = 'var(--accent)';
      btnBtn.style.color = 'var(--meter-bg)';
    } else {
      btnBtn.innerText = '\uD83D\uDC65 \u062A\u062D\u0648\u064A\u0644 \u0644\u0623\u0641\u0631\u0627\u062F (\u0645\u0634\u062A\u0631\u0643)';
      btnBtn.style.backgroundColor = '#818cf8';
      btnBtn.style.color = 'white';
    }
    if (!meters[activeMeterId].isActive) { meters[activeMeterId].tripType = type; saveDataToStorage(); }
  }
  window.onTripTypeChanged = onTripTypeChanged;

  function updateDotsUI() {
    for (var id = 1; id <= 2; id++) {
      var dot = document.getElementById('dot_' + id);
      if (!dot) continue;
      if (meters[id].isPaused) dot.className = 'meter-status-dot paused';
      else if (meters[id].isActive) dot.className = 'meter-status-dot active';
      else dot.className = 'meter-status-dot';
    }
  }

  function renderMeterDataToUI() {
    var m = meters[activeMeterId];
    document.getElementById('totalFareDisplay').innerText = (m.finalFare || 0).toFixed(2) + ' \u062C';
    document.getElementById('distDisplay').innerText = (m.totalDistance || 0).toFixed(2);
    document.getElementById('durationDisplay').innerText = (m.totalDurationMinutes || 0).toFixed(0);
    document.getElementById('waitDisplay').innerText = ((m.totalWaitSeconds || 0) / 60).toFixed(0);
    document.getElementById('currentTypeDisplay').innerText = m.tripType === 'makhsoos' ? '\u0645\u062E\u0635\u0648\u0635' : '\u0623\u0641\u0631\u0627\u062F \u0645\u0634\u062A\u0631\u0643';
    document.getElementById('passengersBadge').innerText = '\uD83D\uDC65 \u0631\u0643\u0627\u0628: ' + (m.passengerCount || 0);
    document.getElementById('waitingBadge').style.display = (m.isWaitingMode && !m.isPaused) ? 'inline-block' : 'none';
    document.getElementById('pausedBadge').style.display = m.isPaused ? 'inline-block' : 'none';
    var pauseBtn = document.getElementById('pauseBtn');
    if (m.isActive) {
      document.getElementById('startBtn').disabled = true;
      document.getElementById('stopBtn').disabled = false;
      document.getElementById('dynamicActionBtn').disabled = m.isPaused;
      pauseBtn.disabled = false;
      pauseBtn.innerText = m.isPaused ? '\u25B6\uFE0F \u0627\u0633\u062A\u0626\u0646\u0627\u0641 \u0627\u0644\u0639\u062F\u0627\u062F' : '\uD83D\uDED1 \u0625\u064A\u0642\u0627\u0641 \u0645\u0624\u0642\u062A';
      pauseBtn.style.backgroundColor = m.isPaused ? 'var(--success)' : 'var(--accent)';
      pauseBtn.style.color = m.isPaused ? 'white' : 'var(--meter-bg)';
      document.getElementById('globalStatusText').innerText = m.isPaused ? '\u0639\u062F\u0627\u062F ' + m.id + ' \u0645\u0648\u0642\u0648\u0641 \u0645\u0624\u0642\u062A\u0627' : '\u0639\u062F\u0627\u062F ' + m.id + ' \u0634\u063A\u0627\u0644 | \u0643\u0648\u062F: ' + (m.shareCode || '');
    } else {
      document.getElementById('startBtn').disabled = false;
      document.getElementById('stopBtn').disabled = true;
      document.getElementById('dynamicActionBtn').disabled = true;
      pauseBtn.disabled = true;
      pauseBtn.innerText = '\uD83D\uDED1 \u0625\u064A\u0642\u0627\u0641 \u0645\u0624\u0642\u062A';
      pauseBtn.style.backgroundColor = 'var(--meter-card)';
      pauseBtn.style.color = 'var(--meter-muted)';
      document.getElementById('globalStatusText').innerText = '\u0639\u062F\u0627\u062F ' + m.id + ' \u062C\u0627\u0647\u0632';
    }
  }
  window.startMeterForAcceptedTrip = async function() {
    if (!acceptedTripData) { showToast('لا يوجد طلب منتظر'); return; }
    if (typeof requireSubscription === 'function' && !(await requireSubscription())) return;
    var m = meters[activeMeterId];
    if (m.isActive) { showToast('العداد شغال بالفعل'); return; }
    var selectedType = document.getElementById('tripType').value;
    m.isActive = true; m.isPaused = false; m.startTime = Date.now(); m.pausedTimeTotal = 0;
    m.tripType = selectedType;
    m.kmPrice = clampNumber(document.getElementById('kmPriceInput').value, 1, 50, 5);
    m.waitPrice = clampNumber(document.getElementById('waitPriceInput').value, 0, 20, 1);
    m.durationPrice = clampNumber(document.getElementById('durationPriceInput').value, 0, 10, 0.50);
    m.shareCode = acceptedTripData.joinCode;
    m.tripId = acceptedTripData.tripId;
    if (acceptedTripData.waypoints) m.waypoints = acceptedTripData.waypoints;
    m.lastSupabaseSync = 0;
    m.totalDistance = 0; m.totalWaitSeconds = 0; m.waitingStartedAt = null; m.waitingBaseSeconds = 0;
    m.passengerCount = 1;
    m.lastLat = null; m.lastLng = null; m.lastAccuracy = null; m.lastSpeedKmh = null; m.lastLocationTime = null;
    m.pathCoords = [];
    if (selectedType === 'afrad') {
      m.passengersData = [];
      for (var i = 1; i <= m.passengerCount; i++) {
        m.passengersData.push({ id: i, name: 'راكب رقم ' + i, startDistance: 0, startDuration: 0, startWait: 0, isInside: true, isInitial: true, individualFare: 0 });
      }
    }
    if (m.tripId) {
      try {
        await supabase.from('trips').update({ status: 'started', started_at: new Date().toISOString() }).eq('id', m.tripId);
        await invokeTripEvent('start', m);
        m.lastSupabaseSync = Date.now();
        saveDataToStorage();
        showToast('🚀 بدأت رحلة الراكب — كود: ' + m.shareCode);
      } catch(e) { console.error(e); showToast('فشل بدء الرحلة'); return; }
    }
    acceptedTripData = null;
    document.getElementById('pending-trip-banner').style.display = 'none';
    updateDotsUI(); renderMeterDataToUI(); redrawActiveRouteLine(); saveDataToStorage();
  };
  window.dismissAcceptedTrip = function() {
    acceptedTripData = null;
    document.getElementById('pending-trip-banner').style.display = 'none';
    showToast('تم إلغاء الرحلة المنتظرة');
  };

 	  async function startCurrentMeter() {
    if (typeof requireSubscription === 'function' && !(await requireSubscription())) return;
    var m = meters[activeMeterId];
    if (m.isActive) return;
    var selectedType = document.getElementById('tripType').value;
    var initialPassengers = 1;
    if (selectedType === 'afrad') {
      var seats = prompt('المشوار أفراد، كم عدد المقاعد المحجوزة الآن؟', '1');
      if (seats === null) return;
      var parsedSeats = parseInt(seats);
      if (parsedSeats >= 1 && parsedSeats <= 20) { initialPassengers = parsedSeats; }
      else { alert('يرجى إدخال عدد مقاعد صحيح'); return; }
    }
    m.isActive = true; m.isPaused = false; m.startTime = Date.now(); m.pausedTimeTotal = 0;
    m.tripType = selectedType;
	    m.kmPrice = clampNumber(document.getElementById('kmPriceInput').value, 1, 50, 5);
	    m.waitPrice = clampNumber(document.getElementById('waitPriceInput').value, 0, 20, 1);
	    m.durationPrice = clampNumber(document.getElementById('durationPriceInput').value, 0, 10, 0.50);
	    m.shareCode = Math.floor(100000 + Math.random() * 900000).toString();
	    m.tripId = null; m.lastSupabaseSync = 0;
	    m.totalDistance = 0; m.totalWaitSeconds = 0; m.waitingStartedAt = null; m.waitingBaseSeconds = 0;
    m.passengerCount = initialPassengers;
	    m.lastLat = null; m.lastLng = null; m.lastAccuracy = null; m.lastSpeedKmh = null; m.lastLocationTime = null;
    m.pathCoords = [];
    if (selectedType === 'afrad') {
      m.passengersData = [];
      for (var i = 1; i <= initialPassengers; i++) {
        m.passengersData.push({ id: i, name: 'راكب رقم ' + i, startDistance: 0, startDuration: 0, startWait: 0, isInside: true, isInitial: true, individualFare: 0 });
      }
    }
    setDriverAvailable(false);
	    await createStartedTripInSupabase(m);
	    showToast('تم تشغيل عداد رقم ' + m.id + ' - كود المشاركة: ' + m.shareCode);
    updateDotsUI(); renderMeterDataToUI(); redrawActiveRouteLine(); saveDataToStorage();
  }
  window.startCurrentMeter = startCurrentMeter;

 	  function stopCurrentMeter() {
 	    var m = meters[activeMeterId];
 	    if (!m.isActive) return;
 	    updateWaitSeconds(m);
     if (m.isPaused) { m.isPaused = false; if (m.lastPauseTimestamp) m.pausedTimeTotal += (Date.now() - m.lastPauseTimestamp); }
     if (m.tripType === 'afrad') {
       m.passengersData.forEach(function(p) {
         if (p.isInside) {
           p.isInside = false;
           var pDist = m.totalDistance - p.startDistance;
           if (p.isInitial) {
             var pDuration = m.totalDurationMinutes - (p.startDuration || 0);
             var pWait = (m.totalWaitSeconds / 60) - (p.startWait || 0);
             p.individualFare = m.bandira + (pDist * m.kmPrice) + (pDuration * m.durationPrice) + (pWait * m.waitPrice);
           } else { p.individualFare = pDist * m.kmPrice; }
         }
       });
     }
     m.isActive = false;
     calculateFare(m);
     // Save originals before any adjustment
     m._origKmPrice = m.kmPrice;
     m._origWaitPrice = m.waitPrice;
     m._origDurationPrice = m.durationPrice;
     m._origBandira = m.bandira;
     m.original_km_price = m.kmPrice;
     m.original_wait_price = m.waitPrice;
     m.original_duration_price = m.durationPrice;
     m.original_bandira = m.bandira;
     showSettlementDialog(m);
   }

   window.showSettlementDialog = function(m) {
     document.getElementById('settle-bandira').value = m.bandira;
     document.getElementById('settle-km-price').value = m.kmPrice;
     document.getElementById('settle-duration-price').value = m.durationPrice;
     document.getElementById('settle-wait-price').value = m.waitPrice;
     document.getElementById('settle-distance').textContent = (m.totalDistance || 0).toFixed(2);
     document.getElementById('settle-duration').textContent = (m.totalDurationMinutes || 0).toFixed(0);
     document.getElementById('settle-wait').textContent = ((m.totalWaitSeconds || 0) / 60).toFixed(0);
     updateSettleTotal(m);
     document.getElementById('settlementModal').style.display = 'flex';
   };

   window.updateSettleTotal = function(m) {
     var bandira = parseFloat(document.getElementById('settle-bandira').value) || 0;
     var kmPrice = parseFloat(document.getElementById('settle-km-price').value) || 0;
     var durPrice = parseFloat(document.getElementById('settle-duration-price').value) || 0;
     var waitPrice = parseFloat(document.getElementById('settle-wait-price').value) || 0;
     var total = bandira + (m.totalDistance * kmPrice) + (m.totalDurationMinutes * durPrice) + ((m.totalWaitSeconds / 60) * waitPrice);
     document.getElementById('settle-total').textContent = Math.max(total, m.minFare || 10).toFixed(2) + ' ج';
   };

   ['settle-bandira', 'settle-km-price', 'settle-duration-price', 'settle-wait-price'].forEach(function(id) {
     document.getElementById(id).addEventListener('input', function() {
       var m = meters[activeMeterId];
       if (m) updateSettleTotal(m);
     });
   });

   window.onSettlePaymentChange = function() {};

   window.confirmSettlement = async function() {
     var m = meters[activeMeterId];
     if (!m) return;
     var bandira = parseFloat(document.getElementById('settle-bandira').value) || 0;
     var kmPrice = parseFloat(document.getElementById('settle-km-price').value) || 0;
     var durPrice = parseFloat(document.getElementById('settle-duration-price').value) || 0;
     var waitPrice = parseFloat(document.getElementById('settle-wait-price').value) || 0;
     var paymentMethod = document.querySelector('input[name="settle-payment"]:checked').value;

     var pricesChanged = bandira !== m._origBandira || kmPrice !== m._origKmPrice || durPrice !== m._origDurationPrice || waitPrice !== m._origWaitPrice;

     m.bandira = bandira;
     m.kmPrice = kmPrice;
     m.durationPrice = durPrice;
     m.waitPrice = waitPrice;
     m.payment_method = paymentMethod;
     m.payment_status = paymentMethod === 'cash' ? 'paid_cash' : 'unpaid';
     m.price_adjusted = pricesChanged;

     calculateFare(m);

     if (pricesChanged) {
       try {
         await invokeTripEvent('adjust_prices', m);
       } catch(e) { console.error('Price adjust error:', e); }
     }

     document.getElementById('settlementModal').style.display = 'none';
      var receiptSnapshot = JSON.parse(JSON.stringify(m));
      generateReceipt(m);
      saveTripToHistory(m);
      await saveTripToSupabase(m);
      setDriverAvailable(true);
      window._lastReceiptData = receiptSnapshot;
      meters[activeMeterId] = createEmptyMeterObject(activeMeterId);
      updateDotsUI(); renderMeterDataToUI(); redrawActiveRouteLine(); saveDataToStorage();
   };

   window.cancelSettlement = function() {
     document.getElementById('settlementModal').style.display = 'none';
     var m = meters[activeMeterId];
     if (m) {
       m.isActive = true;
       showToast('تم إلغاء التسوية');
       renderMeterDataToUI();
     }
   };

  function togglePauseCurrentMeter() {
    var m = meters[activeMeterId];
    if (!m.isActive) return;
	    if (!m.isPaused) { m.isPaused = true; m.lastPauseTimestamp = Date.now(); setWaitingMode(m, false); showToast('تم إيقاف العداد مؤقتاً'); }
    else { m.isPaused = false; if (m.lastPauseTimestamp) m.pausedTimeTotal += (Date.now() - m.lastPauseTimestamp); m.lastLocationTime = Date.now(); showToast('تم استئناف العداد'); }
    updateDotsUI(); renderMeterDataToUI(); saveDataToStorage();
  }
	  window.togglePauseCurrentMeter = togglePauseCurrentMeter;

	  function setWaitingMode(m, isWaiting) {
	    if (!m) return;
	    if (isWaiting && !m.isWaitingMode) {
	      m.isWaitingMode = true;
	      m.waitingBaseSeconds = clampNumber(m.totalWaitSeconds, 0, 86400, 0);
	      m.waitingStartedAt = Date.now();
	    } else if (!isWaiting && m.isWaitingMode) {
	      updateWaitSeconds(m);
	      m.isWaitingMode = false;
	      m.waitingStartedAt = null;
	      m.waitingBaseSeconds = m.totalWaitSeconds;
	    }
	  }

	  function updateWaitSeconds(m) {
	    if (m && m.isWaitingMode && m.waitingStartedAt) {
	      var elapsed = (Date.now() - m.waitingStartedAt) / 1000;
	      m.totalWaitSeconds = clampNumber((m.waitingBaseSeconds || 0) + elapsed, 0, 86400, 0);
	    }
	  }

	  function handleDynamicActionButton() {
    var m = meters[activeMeterId];
    if (!m.isActive || m.isPaused) return;
    if (m.tripType === 'afrad') {
      var action = prompt('اختر الإجراء:\n1 - ركوب فرد جديد\n2 - نزول ومحاسبة فرد', '1');
      if (action === '1') {
        var pNumber = m.passengersData.length + 1;
        m.passengersData.push({ id: pNumber, name: 'راكب رقم ' + pNumber, startDistance: m.totalDistance, isInside: true, isInitial: false, individualFare: 0 });
        m.passengerCount = m.passengersData.filter(function(p) { return p.isInside; }).length;
        showToast('➕ تم إركاب فرد جديد: ' + pNumber);
      } else if (action === '2') {
        var activeList = m.passengersData.filter(function(p) { return p.isInside; });
        if (!activeList.length) { showToast('لا يوجد ركاب داخل المركبة'); return; }
        var promptText = 'اختر رقم الراكب النازل:\n';
        activeList.forEach(function(p) { promptText += p.id + ' - ' + p.name + '\n'; });
        var targetId = prompt(promptText);
        var targetPassenger = m.passengersData.find(function(p) { return p.id == targetId && p.isInside; });
        if (targetPassenger) {
          targetPassenger.isInside = false;
          m.passengerCount = m.passengersData.filter(function(p) { return p.isInside; }).length;
          var pDist = m.totalDistance - targetPassenger.startDistance;
          var pFare = targetPassenger.isInitial
            ? m.bandira + (pDist * m.kmPrice) + (m.totalDurationMinutes * m.durationPrice) + ((m.totalWaitSeconds/60) * m.waitPrice)
            : pDist * m.kmPrice;
          targetPassenger.individualFare = pFare;
          var body = document.getElementById('receiptBody');
	          body.innerHTML = '<div class="receipt-line"><span class="label">تصفية حساب</span><span class="value" style="color:var(--accent)">' + escapeHTML(targetPassenger.name) + '</span></div><div class="receipt-divider"></div><div class="receipt-line receipt-total"><span>المطلوب</span><span>' + clampNumber(pFare, 0, 100000, 0).toFixed(2) + ' ج</span></div>';
          document.getElementById('receiptModal').style.display = 'flex';
          showToast('🛑 تم تصفية حساب ' + targetPassenger.name);
        }
      }
    } else {
      if (confirm('هل تريد تحويل المخصوص إلى مشترك (أفراد)؟')) {
	        var newPrice = prompt('سعر الكيلو الجديد للمخصوص:', m.kmPrice);
	        if (newPrice !== null) {
	          m.kmPrice = clampNumber(newPrice, 1, 50, m.kmPrice);
          m.tripType = 'afrad'; m.passengerCount = 1;
          m.passengersData = [{ id: 1, name: 'راكب 1 (المخصوص)', startDistance: m.totalDistance, startDuration: m.totalDurationMinutes, startWait: m.totalWaitSeconds/60, isInside: true, isInitial: true, individualFare: 0 }];
          document.getElementById('tripType').value = 'afrad';
          onTripTypeChanged();
          showToast('🔄 تم تحويل المشوار');
        }
      }
    }
    calculateFare(m); renderMeterDataToUI(); saveDataToStorage();
  }
  window.handleDynamicActionButton = handleDynamicActionButton;

  setInterval(function() {
    var updated = false;
    for (var id in meters) {
      var m = meters[id];
      if (m.isActive && m.startTime && !m.isPaused) {
        m.totalDurationMinutes = ((Date.now() - m.startTime) - m.pausedTimeTotal) / 1000 / 60;
	        if (m.isWaitingMode) { updateWaitSeconds(m); }
	        else if (m.lastLocationTime && (Date.now() - m.lastLocationTime > 5000)) { setWaitingMode(m, true); updateWaitSeconds(m); }
	        calculateFare(m); syncStartedTripToSupabase(m, false); updated = true;
	      }
	    }
    if (updated) { renderMeterDataToUI(); saveDataToStorage(); }
    syncDriverLocation();
  }, 1000);

  // Poll active trip status to detect passenger_end_trip
  var activeTripPollTimer = setInterval(async function() {
    for (var id in meters) {
      var m = meters[id];
      if (!m.tripId || !m.isActive) continue;
      try {
        var { data: tr } = await supabase.from('trips').select('status').eq('id', m.tripId).single();
        if (tr && (tr.status === 'completed' || tr.status === 'cancelled')) {
          showToast('⏹️ تم إنهاء الرحلة بواسطة الراكب');
          m.isActive = false;
          m.isPaused = false;
          await setDriverAvailable(true);
          updateDotsUI(); renderMeterDataToUI(); redrawActiveRouteLine(); saveDataToStorage();
        }
      } catch(e) { console.error('Active trip poll error:', e); }
    }
  }, 5000);

  var lastDriverLocSync = 0;

  async function syncDriverLocation() {
    if (!supabase || !currentUser) return;
    var m = meters[activeMeterId];
    var lat = m?.lastLat;
    var lng = m?.lastLng;
    if (lat == null || lng == null) return;
    var now = Date.now();
    if (now - lastDriverLocSync < 10000) return;
    lastDriverLocSync = now;
    try {
      await supabase.from('drivers').update({ current_lat: lat, current_lng: lng }).eq('id', currentUser.id);
    } catch(e) { console.error('GPS sync error:', e); }
  }

  function initGlobalGPS() {
    if (globalWatchId !== null) return;
    if (navigator.geolocation) {
      globalWatchId = navigator.geolocation.watchPosition(handleGlobalLocation, handleGPSError, { enableHighAccuracy: true, maximumAge: 0, timeout: 10000 });
    }
  }
	  function stopGlobalGPS() {
	    if (navigator.geolocation && globalWatchId !== null) {
	      navigator.geolocation.clearWatch(globalWatchId);
	      globalWatchId = null;
	    }
	  }
	  async function handleGlobalLocation(pos) {
	    var lat = pos.coords.latitude, lng = pos.coords.longitude;
	    if (pos.coords.accuracy && pos.coords.accuracy > 75) return;
	    var speedKmh = pos.coords.speed ? (pos.coords.speed * 3.6) : null;
    var currentLatLng = L.latLng(lat, lng);
    if (driverMap) {
      currentMarker.setLatLng(currentLatLng);
      if (meters[activeMeterId].isActive && !meters[activeMeterId].isPaused) driverMap.setView(currentLatLng, 16);
    }
    for (var id in meters) {
      var m = meters[id];
	      if (!m.isActive || m.isPaused) continue;
	      var now = Date.now();
	      m.lastAccuracy = pos.coords.accuracy || null;
	      m.lastSpeedKmh = speedKmh;
      if (m.lastLat && m.lastLng) {
        var lastLatLng = L.latLng(m.lastLat, m.lastLng);
        var rawDistanceKm = lastLatLng.distanceTo(currentLatLng) / 1000;
        if (rawDistanceKm >= GPS_FILTER.minDistance) {
	          var calculatedSpeed = rawDistanceKm / ((now - m.lastLocationTime) / 1000 / 3600);
	          var finalSpeed = speedKmh !== null ? speedKmh : calculatedSpeed;
	          if (finalSpeed > 80) { m.lastLat = lat; m.lastLng = lng; m.lastLocationTime = now; continue; }
          if (finalSpeed > GPS_FILTER.waitingSpeedKmh) {
	            setWaitingMode(m, false);
            m.pathCoords.push({lat: lat, lng: lng});
            if (m.pathCoords.length >= 2) {
              try {
                var lastPoint = m.pathCoords[m.pathCoords.length - 2];
                var url = 'https://router.project-osrm.org/route/v1/driving/' + lastPoint.lng + ',' + lastPoint.lat + ';' + lng + ',' + lat + '?overview=false';
                var response = await fetch(url);
                var data = await response.json();
                if (data.code === 'Ok' && data.routes && data.routes[0]) {
                  var roadDistanceKm = data.routes[0].distance / 1000;
                  m.totalDistance += roadDistanceKm < rawDistanceKm * 3 ? roadDistanceKm : rawDistanceKm;
                } else { m.totalDistance += rawDistanceKm; }
              } catch (e) { m.totalDistance += rawDistanceKm; }
            } else { m.totalDistance += rawDistanceKm; }
	          } else { setWaitingMode(m, true); }
          m.lastLat = lat; m.lastLng = lng; m.lastLocationTime = now;
        } else {
	          if ((now - m.lastLocationTime)/1000 > 4 && (speedKmh === null || speedKmh < GPS_FILTER.waitingSpeedKmh)) setWaitingMode(m, true);
        }
      } else {
        m.lastLat = lat; m.lastLng = lng; m.lastLocationTime = now;
	        setWaitingMode(m, false);
        m.pathCoords.push({lat: lat, lng: lng});
      }
      calculateFare(m);
    }
    redrawActiveRouteLine(); renderMeterDataToUI(); saveDataToStorage();
  }

  function redrawActiveRouteLine() {
    if (!pathLine || !driverMap) return;
    var m = meters[activeMeterId];
    if (m.pathCoords && m.pathCoords.length > 0) {
      pathLine.setLatLngs(m.pathCoords.map(function(c) { return L.latLng(c.lat, c.lng); }));
    } else { pathLine.setLatLngs([]); }
  }

	  function calculateFare(m) {
	    updateWaitSeconds(m);
	    if (m.tripType === 'makhsoos') {
      var total = m.bandira + (m.totalDistance * m.kmPrice) + (m.totalDurationMinutes * m.durationPrice) + ((m.totalWaitSeconds / 60) * m.waitPrice);
      m.finalFare = total < m.minFare ? m.minFare : total;
    } else {
      var totalRevenue = 0;
      (m.passengersData || []).forEach(function(p) {
        if (!p.isInside) { totalRevenue += (p.individualFare || 0); }
        else {
          var currentPDist = m.totalDistance - p.startDistance;
          if (p.isInitial) {
            totalRevenue += m.bandira + (currentPDist * m.kmPrice) + ((m.totalDurationMinutes - (p.startDuration || 0)) * m.durationPrice) + (((m.totalWaitSeconds/60) - (p.startWait || 0)) * m.waitPrice);
          } else { totalRevenue += currentPDist * m.kmPrice; }
        }
      });
      m.finalFare = totalRevenue;
    }
  }

  function resetCurrentMeterData() {
    if (confirm('هل أنت متأكد من تصفير العداد بالكامل؟')) {
      meters[activeMeterId] = createEmptyMeterObject(activeMeterId);
      acceptedTripData = null;
      document.getElementById('pending-trip-banner').style.display = 'none';
      updateDotsUI(); renderMeterDataToUI(); redrawActiveRouteLine(); saveDataToStorage();
      showToast('تم تصفير العداد');
    }
  }
  window.resetCurrentMeterData = resetCurrentMeterData;

  function triggerManualDistance() {
    var m = meters[activeMeterId];
	    var manual = prompt('المسافة المقطوعة يدوياً (كم):', (m.totalDistance || 0).toFixed(2));
	    if (manual !== null) {
	      m.totalDistance = clampNumber(manual, 0, 1000, 0);
	      calculateFare(m); renderMeterDataToUI(); saveDataToStorage();
      showToast('تم تحديث المسافة');
    }
  }
  window.triggerManualDistance = triggerManualDistance;

  function generateReceipt(m) {
    var body = document.getElementById('receiptBody');
    var waitingMinutes = m.totalWaitSeconds / 60;
    var now = new Date().toLocaleString('ar-EG');
    var typeLabel = m.tripType === 'makhsoos' ? 'مخصوص' : 'أفراد (مشترك)';
    var code = escapeHTML(m.shareCode || '-');
    var kmP = m.kmPrice.toFixed(2), durP = m.durationPrice.toFixed(2), waitP = m.waitPrice.toFixed(2);
    var bandira = m.bandira.toFixed(2);
    var dist = m.totalDistance.toFixed(2), dur = m.totalDurationMinutes.toFixed(0), wait = waitingMinutes.toFixed(0);
    var distCost = (m.totalDistance * m.kmPrice).toFixed(2), durCost = (m.totalDurationMinutes * m.durationPrice).toFixed(2), waitCost = (waitingMinutes * m.waitPrice).toFixed(2);
    var totalFare = clampNumber(m.finalFare, 0, 100000, 0).toFixed(2);
    var paymentLabel = m.payment_method === 'cash' ? 'نقدي (يداً بيد)' : (m.payment_status === 'paid_wallet' ? 'محفظة - تم الدفع ✅' : 'محفظة - في انتظار الدفع');
    var itemsHTML = '';

    // Price adjustment banner
    var adjustmentHTML = '';
    if (m.price_adjusted && m._origKmPrice != null) {
      var origKmP = m._origKmPrice.toFixed(2), origDurP = m._origDurationPrice.toFixed(2), origWaitP = m._origWaitPrice.toFixed(2);
      var origDistCost = (m.totalDistance * m._origKmPrice).toFixed(2);
      var origDurCost = (m.totalDurationMinutes * m._origDurationPrice).toFixed(2);
      var origWaitCost = (waitingMinutes * m._origWaitPrice).toFixed(2);
      var origBandira = m._origBandira.toFixed(2);
      var origTotal = m._origBandira + (m.totalDistance * m._origKmPrice) + (m.totalDurationMinutes * m._origDurationPrice) + (waitingMinutes * m._origWaitPrice);
      var origTotalFare = Math.max(origTotal, m.minFare || 10).toFixed(2);
      adjustmentHTML = '<div style="margin-bottom:8px;padding:8px;background:rgba(245,158,11,0.1);border:1px solid rgba(245,158,11,0.3);border-radius:8px;font-size:12px;">'
        + '<div style="font-weight:700;color:var(--accent);margin-bottom:4px;">تم تعديل الأسعار بعد الاتفاق</div>'
        + '<table style="width:100%;border-collapse:collapse;">'
        + '<tr><td></td><td style="text-align:center;font-weight:600;">الأصلي</td><td style="text-align:center;font-weight:600;">المعدل</td></tr>'
        + '<tr><td>فتحة العداد</td><td style="text-align:center;">' + origBandira + '</td><td style="text-align:center;">' + bandira + '</td></tr>'
        + '<tr><td>الكيلومتر</td><td style="text-align:center;">' + origKmP + '</td><td style="text-align:center;">' + kmP + '</td></tr>'
        + '<tr><td>دقيقة الوقت</td><td style="text-align:center;">' + origDurP + '</td><td style="text-align:center;">' + durP + '</td></tr>'
        + '<tr><td>دقيقة الانتظار</td><td style="text-align:center;">' + origWaitP + '</td><td style="text-align:center;">' + waitP + '</td></tr>'
        + '<tr><td><strong>الإجمالي</strong></td><td style="text-align:center;"><strong>' + origTotalFare + '</strong></td><td style="text-align:center;"><strong style="color:var(--meter-primary);">' + totalFare + '</strong></td></tr>'
        + '</table></div>';
    }

    if (m.tripType === 'makhsoos') {
      itemsHTML = ''
        + '<div class="receipt-line"><span class="label">🔰 فتحة العداد</span><span class="value">' + bandira + ' ج</span></div>'
        + '<div class="receipt-line"><span class="label">📏 المسافة (' + dist + ' كم × ' + kmP + ')</span><span class="value">' + distCost + ' ج</span></div>'
        + '<div class="receipt-line"><span class="label">⏱ الزمن (' + dur + ' د × ' + durP + ')</span><span class="value">' + durCost + ' ج</span></div>'
        + '<div class="receipt-line"><span class="label">⏳ الانتظار (' + wait + ' د × ' + waitP + ')</span><span class="value">' + waitCost + ' ج</span></div>';
    } else {
      itemsHTML = '<div style="font-weight:700;font-size:12px;margin-bottom:8px;color:var(--meter-primary);">تفاصيل الركاب:</div>';
      (m.passengersData || []).forEach(function(p, idx) {
        var pf = clampNumber(p.individualFare, 0, 100000, 0).toFixed(2);
        var pDist = Math.max(0, m.totalDistance - clampNumber(p.startDistance, 0, 1000, 0));
        var pDur2 = Math.max(0, m.totalDurationMinutes - clampNumber(p.startDuration, 0, 1440, 0));
        var pWait2 = Math.max(0, waitingMinutes - clampNumber(p.startWait, 0, 1440, 0));
        var isInit = p.isInitial !== false;
        itemsHTML += '<div style="font-size:12px;margin-bottom:8px;padding:6px;background:rgba(255,255,255,0.03);border-radius:8px;">'
          + '<div style="font-weight:700;margin-bottom:3px;">' + escapeHTML(p.name || 'راكب ' + (idx + 1)) + '</div>'
          + (isInit ? ('<div class="receipt-sub">🔰 فتحة: ' + bandira + ' ج</div>') : '')
          + '<div class="receipt-sub">📏 مسافة: ' + pDist.toFixed(2) + ' كم × ' + kmP + ' = ' + (pDist * m.kmPrice).toFixed(2) + ' ج</div>'
          + (isInit ? '<div class="receipt-sub">⏱ زمن: ' + pDur2.toFixed(0) + ' د × ' + durP + ' = ' + (pDur2 * m.durationPrice).toFixed(2) + ' ج</div><div class="receipt-sub">⏳ انتظار: ' + pWait2.toFixed(0) + ' د × ' + waitP + ' = ' + (pWait2 * m.waitPrice).toFixed(2) + ' ج</div>' : '')
          + '<div style="font-weight:600;margin-top:2px;color:var(--meter-primary);">المجموع: ' + pf + ' ج</div>'
          + '</div>';
      });
    }

    body.innerHTML = '<div class="receipt-header2">فاتورة الرحلة</div>'
      + '<div style="padding:0 4px 8px;">'
      + '<div class="receipt-meta"><span>' + typeLabel + '</span><span>كود: ' + code + '</span></div>'
      + '<div class="receipt-meta" style="font-size:11px;">' + now + '</div>'
      + '<div class="receipt-meta" style="font-size:12px;color:var(--meter-primary);">طريقة الدفع: ' + paymentLabel + '</div>'
      + '<div class="receipt-divider"></div>'
      + adjustmentHTML
      + itemsHTML
      + '<div class="receipt-divider"></div>'
      + '<div class="receipt-line receipt-total"><span>الإجمالي</span><span>' + totalFare + ' ج</span></div>'
      + '<div class="receipt-footer">' + kmP + ' ج/كم | ' + durP + ' ج/د | ' + waitP + ' ج/د انتظار</div>'
      + '</div>';
    document.getElementById('receiptModal').style.display = 'flex';
  }

  function closeReceipt() { document.getElementById('receiptModal').style.display = 'none'; }
  window.closeReceipt = closeReceipt;

  var lastReceiptText = '';
  function shareWhatsApp() {
    var m = window._lastReceiptData || meters[activeMeterId];
    if (!m) { showToast('لا توجد بيانات رحلة'); return; }
    var waitingMinutes = m.totalWaitSeconds / 60;
    var typeLabel = m.tripType === 'makhsoos' ? 'مخصوص' : 'أفراد';
    var kmP = m.kmPrice.toFixed(2), durP = m.durationPrice.toFixed(2), waitP = m.waitPrice.toFixed(2);
    var bandira = m.bandira.toFixed(2);
    var dist = m.totalDistance.toFixed(2), dur = m.totalDurationMinutes.toFixed(0), wait = waitingMinutes.toFixed(0);
    var distCost = (m.totalDistance * m.kmPrice).toFixed(2), durCost = (m.totalDurationMinutes * m.durationPrice).toFixed(2), waitCost = (waitingMinutes * m.waitPrice).toFixed(2);
    var totalFare = clampNumber(m.finalFare, 0, 100000, 0).toFixed(2);
    var lines = [];
    lines.push('🧾 فاتورة رحلة - توقع أجرتك');
    lines.push('═══════════════════════');
    lines.push('🆔 الكود: ' + (m.shareCode || '-'));
    lines.push('🚘 النوع: ' + typeLabel);
    lines.push('📅 ' + new Date().toLocaleDateString('ar-EG') + ' ' + new Date().toLocaleTimeString('ar-EG', {hour:'2-digit',minute:'2-digit'}));
    lines.push('───────────────────────');
    if (m.tripType === 'makhsoos') {
      lines.push('🔰 فتحة: ' + bandira + ' ج');
      lines.push('📏 مسافة (' + dist + ' كم × ' + kmP + ') = ' + distCost + ' ج');
      lines.push('⏱ زمن (' + dur + ' د × ' + durP + ') = ' + durCost + ' ج');
      lines.push('⏳ انتظار (' + wait + ' د × ' + waitP + ') = ' + waitCost + ' ج');
    } else {
      (m.passengersData || []).forEach(function(p, idx) {
        var pf = clampNumber(p.individualFare, 0, 100000, 0).toFixed(2);
        var pName = p.name || ('راكب ' + (idx + 1));
        lines.push(''); lines.push('◉ ' + pName + ': ' + pf + ' ج');
        lines.push('  📏 مسافة: ' + Math.max(0, m.totalDistance - clampNumber(p.startDistance, 0, 1000, 0)).toFixed(2) + ' كم');
        lines.push('  💰 الفردي: ' + pf + ' ج');
      });
    }
    lines.push('───────────────────────');
    lines.push('💰 الإجمالي: ' + totalFare + ' ج');
    lines.push('🛞 ' + kmP + ' ج/كم | ⏱ ' + durP + ' ج/د | ⏳ ' + waitP + ' ج/د');
    lines.push('═══════════════════════');
    lines.push('توقع أجرتك - التوك توك الذكي');
    var text = lines.join('\n');
    lastReceiptText = text;
    window.open('https://wa.me/?text=' + encodeURIComponent(text));
  }
  window.shareWhatsApp = shareWhatsApp;

  // Storage
  function saveDataToStorage() { try { localStorage.setItem('smart_meter_data', JSON.stringify(meters)); } catch(e) { console.error('Storage save error:', e); } }
  function loadDataFromStorage() {
    try {
      var saved = localStorage.getItem('smart_meter_data');
      if (saved) { var parsed = JSON.parse(saved); for (var id in parsed) { meters[id] = parsed[id]; } }
    } catch(e) { console.error(e); }
  }

  function saveTripToHistory(m) {
    try {
      var history = JSON.parse(localStorage.getItem('smart_meter_history')) || [];
      history.unshift({ id: m.shareCode || Math.floor(100000 + Math.random() * 900000).toString(), meterId: m.id, date: new Date().toLocaleString('ar-EG'), tripType: m.tripType, distance: m.totalDistance, duration: m.totalDurationMinutes, wait: m.totalWaitSeconds / 60, fare: m.finalFare, savedPath: m.pathCoords, paymentMethod: m.payment_method || 'cash', paymentStatus: m.payment_status || 'unpaid' });
      localStorage.setItem('smart_meter_history', JSON.stringify(history));
    } catch(e) { console.error('History save error:', e); }
  }

  function renderDriverHistory() {
    var list = document.getElementById('driverHistoryList');
    try {
      var history = JSON.parse(localStorage.getItem('smart_meter_history')) || [];
      if (!history.length) { list.innerHTML = '<div class="empty-state">لا توجد رحلات مسجلة</div>'; return; }
      list.innerHTML = history.map(function(item, index) {
        var payLabel = '';
        if (item.paymentMethod === 'cash') payLabel = '💰 نقدي';
        else if (item.paymentStatus === 'paid_wallet') payLabel = '✅ مدفوع المحفظة';
        else payLabel = '⏳ unpaid';
        return '<div class="history-item"><div class="history-header"><span>' + escapeHTML(item.date) + '</span><span style="color:var(--meter-primary)">' + escapeHTML(item.id) + '</span></div><div class="history-details"><div>عداد ' + escapeHTML(item.meterId) + '</div><div>' + (item.tripType === 'makhsoos' ? 'مخصوص' : 'أفراد') + '</div><div>' + clampNumber(item.distance, 0, 1000, 0).toFixed(2) + ' كم</div><div>' + clampNumber(item.duration, 0, 1440, 0).toFixed(0) + ' دقيقة</div></div><div class="history-fare">الإجمالي: ' + clampNumber(item.fare, 0, 100000, 0).toFixed(2) + ' ج</div><div style="font-size:10px;color:var(--meter-muted);margin-top:2px;">' + payLabel + '</div><div id="histMap_' + index + '" class="history-map"></div></div>';
      }).join('');
      setTimeout(function() {
        history.forEach(function(item, index) {
          var mapId = 'histMap_' + index;
          var center = [30.0444, 31.2357];
          if (item.savedPath && item.savedPath.length > 0) center = [item.savedPath[0].lat, item.savedPath[0].lng];
          try {
            var hMap = L.map(mapId, { zoomControl: false, dragging: true, scrollWheelZoom: false, touchZoom: true }).setView(center, 14);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(hMap);
            if (item.savedPath && item.savedPath.length > 0) {
              var points = item.savedPath.map(function(p) { return [p.lat, p.lng]; });
              L.polyline(points, {color: '#e11d48', weight: 3, dashArray: '4, 4'}).addTo(hMap);
              L.circleMarker(points[0], {radius: 5, color: '#10b981', fillColor: '#10b981', fillOpacity: 1}).addTo(hMap);
              L.circleMarker(points[points.length-1], {radius: 5, color: '#ef4444', fillColor: '#ef4444', fillOpacity: 1}).addTo(hMap);
              try { hMap.fitBounds(L.polyline(points).getBounds(), {padding: [10, 10]}); } catch(e) { console.error('History map fitBounds error:', e); }
            }
          } catch(e) { console.error(e); }
        });
      }, 200);
    } catch(e) { list.innerHTML = '<div class="empty-state">خطأ في تحميل السجل</div>'; }
  }
  window.renderDriverHistory = renderDriverHistory;

	  function clearDriverHistory() {
	    if (confirm('هل أنت متأكد من حذف السجل بالكامل؟')) { localStorage.removeItem('smart_meter_history'); renderDriverHistory(); showToast('تم مسح السجل'); }
	  }
	  window.clearDriverHistory = clearDriverHistory;

	  function buildTripPayload(m, status) {
	    return {
	      driver_id: currentUser.id,
	      status: status,
	      classification: m.tripType === 'makhsoos' ? 'private' : 'shared',
	      distance_km: clampNumber(m.totalDistance, 0, 1000, 0),
	      duration_min: clampNumber(m.totalDurationMinutes, 0, 1440, 0),
	      wait_minutes: clampNumber(m.totalWaitSeconds / 60, 0, 1440, 0),
	      total_fare: clampNumber(m.finalFare, 0, 100000, 0),
	      meter_start_fee: clampNumber(m.bandira, 0, 1000, 5),
	      km_price_used: clampNumber(m.kmPrice, 1, 50, 5),
	      wait_price_used: clampNumber(m.waitPrice, 0, 20, 1),
	      join_code: m.shareCode,
	      passenger_count: clampNumber(m.passengerCount, 0, 20, 1),
	      passenger_breakdown: JSON.stringify(m.passengersData || [])
	    };
		  }

 	  async function invokeTripEvent(action, m) {
 	    if (!supabase || !currentUser) return null;
 	    var latestPoint = m.pathCoords && m.pathCoords.length ? m.pathCoords[m.pathCoords.length - 1] : null;
 	    var body = {
 	      action: action,
 	      tripId: m.tripId || null,
 	      meter: m,
 	      location: latestPoint ? { lat: latestPoint.lat, lng: latestPoint.lng, accuracy: m.lastAccuracy || null, speedKmh: m.lastSpeedKmh || null } : null
 	    };
 	    if (action === 'complete') {
 	      body.payment_method = m.payment_method || 'cash';
 	      body.payment_status = m.payment_status || 'unpaid';
 	    }
 	    var { data, error } = await supabase.functions.invoke('trip-events', { body: body });
 	    if (error) throw error;
 	    return data || null;
 	  }

	  async function createStartedTripInSupabase(m) {
	    if (!supabase || !currentUser) return;
	    try {
	      calculateFare(m);
	      var data = await invokeTripEvent('start', m);
	      if (data && data.tripId) { m.tripId = data.tripId; m.lastSupabaseSync = Date.now(); saveDataToStorage(); }
	    } catch (e) { console.error('Start trip error:', e); }
	  }

	  async function syncStartedTripToSupabase(m, force) {
	    if (!supabase || !currentUser || !m.tripId || !m.isActive) return;
	    var now = Date.now();
	    if (!force && now - (m.lastSupabaseSync || 0) < 5000) return;
	    try {
	      await invokeTripEvent('sync', m);
	      m.lastSupabaseSync = now;
	    } catch (e) { console.error('Live trip sync error:', e); }
	  }

	  async function saveTripToSupabase(m) {
	    if (!supabase || !currentUser) return;
	    try {
	      if (!m.tripId) await createStartedTripInSupabase(m);
	      await invokeTripEvent('complete', m);
	    } catch (e) { console.error('Save trip error:', e); }
	  }
  window.closeRating = function() {
    document.getElementById('ratingModal').style.display = 'none';
  };

  window.submitRating = async function() {
    if (!supabase || !currentUser) { showToast('يجب تسجيل الدخول أولاً'); return; }
    var activeStars = document.querySelectorAll('#ratingStars span.active').length;
    if (activeStars === 0) { showToast('اختر عدد النجوم أولاً'); return; }
    var comment = document.getElementById('ratingComment').value.trim();
    var tripId = document.getElementById('ratingTripId').value;
    var driverId = document.getElementById('ratingDriverId').value;
    if (!tripId || !driverId) { showToast('بيانات الرحلة غير متوفرة'); return; }
    try {
      var { error } = await supabase.from('ratings').upsert({
        trip_id: tripId, driver_id: driverId, passenger_id: currentUser.id,
        score: activeStars, comment: comment || null
      }, { onConflict: 'trip_id, passenger_id' });
      if (error) { showToast('فشل إرسال التقييم: ' + error.message); return; }
      document.getElementById('ratingFormContent').style.display = 'none';
      document.getElementById('ratingDoneContent').style.display = 'block';
      setTimeout(function() { document.getElementById('ratingModal').style.display = 'none'; }, 2000);
    } catch (e) { showToast('حدث خطأ'); console.error(e); }
  };

  window.showRatingModal = function(tripId, driverId) {
    document.getElementById('ratingTripId').value = tripId || '';
    document.getElementById('ratingDriverId').value = driverId || '';
    document.getElementById('ratingFormContent').style.display = 'block';
    document.getElementById('ratingDoneContent').style.display = 'none';
    document.getElementById('ratingComment').value = '';
    document.querySelectorAll('#ratingStars span').forEach(function(s) { s.classList.remove('active'); s.textContent = '☆'; });
    document.getElementById('ratingModal').style.display = 'flex';
  };

  async function loadDriverRating() {
    if (!supabase || !currentUser) return;
    try {
      var { data } = await supabase.from('ratings').select('score').eq('driver_id', currentUser.id);
      if (data && data.length) {
        var avg = data.reduce(function(s, r) { return s + r.score; }, 0) / data.length;
        document.getElementById('driver-stat-rating').textContent = avg.toFixed(1);
      } else {
        document.getElementById('driver-stat-rating').textContent = '-';
      }
    } catch (e) { console.error(e); }
  }
  window.loadDriverRequests = async function() {
    if (!supabase || !currentUser) return;
    var list = document.getElementById('driverRequestsList');
    try {
      var { data: requests, error } = await supabase.from('ride_requests').select('id, passenger_id, passenger_count, classification, status, pickup_address, destination_address, pickup_lat, pickup_lng, adult_count, child_count, created_at, waypoints, note').eq('status', 'pending').eq('offered_to', currentUser.id).order('created_at', { ascending: false }).limit(20);
      if (error || !requests || !requests.length) {
        list.innerHTML = '<div class="empty-state">لا تطلبات موجهة إليك حالياً</div>';
        return;
      }
      list.innerHTML = requests.map(function(r) {
        var typeText = r.classification === 'private' ? 'مخصوص' : 'أفراد';
        var hasLoc = r.pickup_lat && r.pickup_lng;
        var timeAgo = Math.floor((Date.now() - new Date(r.created_at).getTime()) / 1000);
        var timeText = timeAgo < 60 ? 'منذ ' + timeAgo + ' ثانية' : timeAgo < 3600 ? 'منذ ' + Math.floor(timeAgo / 60) + ' دقيقة' : 'منذ ' + Math.floor(timeAgo / 3600) + ' ساعة';
        var wpHtml = '';
        if (r.waypoints && Array.isArray(r.waypoints) && r.waypoints.length > 1) {
          var waypointIcons = ['<i class="fas fa-play" style="color:#22c55e;"></i>'];
          for (var wi = 1; wi < r.waypoints.length - 1; wi++) waypointIcons.push('<i class="fas fa-circle" style="color:#3b82f6;font-size:8px;"></i>');
          waypointIcons.push('<i class="fas fa-flag-checkered" style="color:#ef4444;"></i>');
          wpHtml = '<div class="info" style="font-size:11px;"><i class="fas fa-route"></i> ' + r.waypoints.length + ' محطة: ' + waypointIcons.join(' ') + '</div>';
        }
        var noteHtml = r.note ? '<div class="info" style="font-size:11px;color:var(--accent);"><i class="fas fa-comment"></i> ' + escapeHTML(r.note) + '</div>' : '';
        return '<div class="driver-request-item"><div class="top"><span class="name"><i class="fas fa-user"></i> راكب</span><span class="req-badge pending">جديد</span></div><div class="info"><i class="fas fa-tag"></i> ' + typeText + ' | <i class="fas fa-users"></i> ' + (r.passenger_count || 1) + ' راكب</div><div class="info"><i class="fas fa-map-pin"></i> ' + escapeHTML(r.pickup_address || 'بدون موقع') + '</div>' + (r.destination_address ? '<div class="info"><i class="fas fa-flag"></i> ' + escapeHTML(r.destination_address) + '</div>' : '') + wpHtml + noteHtml + '<div class="info"><i class="fas fa-clock"></i> ' + timeText + '</div><div class="req-actions">' + (hasLoc ? '<button class="btn btn-sm btn-outline" onclick="showPickupOnMap(' + r.pickup_lat + ', ' + r.pickup_lng + ')" style="padding:6px 10px;font-size:11px;"><i class="fas fa-map-marker-alt"></i> موقع</button>' : '') + (r.waypoints && Array.isArray(r.waypoints) && r.waypoints.length > 1 ? '<button class="btn btn-sm btn-outline" onclick="showWaypointsOnMap(\'' + r.id + '\')" style="padding:6px 10px;font-size:11px;"><i class="fas fa-route"></i> المسار</button>' : '') + '<button class="btn btn-success btn-sm" onclick="acceptRequest(\'' + r.id + '\')"><i class="fas fa-check"></i> قبول</button><button class="btn btn-danger btn-sm" onclick="rejectRequest(\'' + r.id + '\')"><i class="fas fa-times"></i> رفض</button></div></div>';
      }).join('');
      // Notify if there are new requests
      if (typeof driverLastRequestCount !== 'undefined' && requests.length > driverLastRequestCount) {
        if ('Notification' in window && Notification.permission === 'granted') {
          new Notification('🚗 طلب رحلة جديد', { body: 'لديك طلب رحلة جديد من راكب', icon: '/favicon.png' });
        }
        try { var ctx = new (window.AudioContext || window.webkitAudioContext)(); var osc = ctx.createOscillator(); osc.frequency.value = 800; osc.type = 'sine'; var gain = ctx.createGain(); gain.gain.value = 0.3; osc.connect(gain); gain.connect(ctx.destination); osc.start(); osc.stop(ctx.currentTime + 0.3); setTimeout(function() { var osc2 = ctx.createOscillator(); osc2.frequency.value = 1000; osc2.type = 'sine'; var gain2 = ctx.createGain(); gain2.gain.value = 0.3; osc2.connect(gain2); gain2.connect(ctx.destination); osc2.start(); osc2.stop(ctx.currentTime + 0.3); }, 150); } catch(e) {}
      }
      driverLastRequestCount = requests.length;
    } catch (e) { list.innerHTML = '<div class="empty-state">خطأ في تحميل الطلبات</div>'; console.error(e); }
  };
  var driverLastRequestCount = 0;
  var driverRequestPollTimer = null;

  window.showPickupOnMap = function(lat, lng) {
    if (driverMap) {
      driverMap.setView([lat, lng], 16);
      if (window._pickupMarker) driverMap.removeLayer(window._pickupMarker);
      window._pickupMarker = L.circleMarker([lat, lng], { radius: 8, color: '#f59e0b', fillColor: '#f59e0b', fillOpacity: 0.7 }).addTo(driverMap);
      showToast('📍 موقع pickup على الخريطة');
      switchDriverTab('meter', document.querySelector('#driver-app .tab-btn'));
    } else {
      showToast('الخريطة غير متاحة');
    }
  };

  window.showWaypointsOnMap = async function(requestId) {
    if (!driverMap) { showToast('الخريطة غير متاحة'); return; }
    try {
      var { data: req } = await supabase.from('ride_requests').select('waypoints').eq('id', requestId).single();
      if (!req || !req.waypoints || !Array.isArray(req.waypoints) || req.waypoints.length < 2) { showToast('لا توجد نقاط مسار'); return; }
      // Clear old waypoint layers
      if (window._wpMarkers) { window._wpMarkers.forEach(function(m) { driverMap.removeLayer(m); }); }
      if (window._wpPolyline) { driverMap.removeLayer(window._wpPolyline); }
      window._wpMarkers = [];
      var latlngs = [];
      req.waypoints.forEach(function(wp, i) {
        var ll = [wp.lat, wp.lng];
        latlngs.push(ll);
        var color = i === 0 ? '#22c55e' : (i === req.waypoints.length - 1 ? '#ef4444' : '#3b82f6');
        var m = L.circleMarker(ll, { radius: 7, color: color, fillColor: color, fillOpacity: 0.8, weight: 2 }).addTo(driverMap);
        m.bindTooltip(i === 0 ? 'انطلاق' : (i === req.waypoints.length - 1 ? 'وجهة' : String(i + 1)), { permanent: true, direction: 'top' });
        window._wpMarkers.push(m);
      });
      if (latlngs.length > 1) {
        window._wpPolyline = L.polyline(latlngs, { color: '#f59e0b', weight: 3, dashArray: '6, 8' }).addTo(driverMap);
      }
      try { driverMap.fitBounds(L.polyline(latlngs).getBounds(), { padding: [30, 30] }); } catch(e) { console.error('Driver map fitBounds error:', e); }
      showToast('📍 تم عرض مسار الرحلة');
      switchDriverTab('meter', document.querySelector('#driver-app .tab-btn'));
    } catch(e) { showToast('فشل تحميل المسار'); console.error(e); }
  };

  var acceptedTripData = null;

  window.acceptRequest = async function(requestId) {
    if (!supabase || !currentUser) return;
    if (!confirm('قبول هذا الطلب؟')) return;
    try {
      var joinCode = String(Math.floor(100000 + Math.random() * 900000));
      var { data: requestData, error: reqError } = await supabase.from('ride_requests').update({ driver_id: currentUser.id, status: 'accepted', responded_at: new Date().toISOString() }).eq('id', requestId).eq('status', 'pending').select('passenger_id, passenger_count, classification, pickup_address, destination_address, pickup_lat, pickup_lng, waypoints').single();
      if (reqError) { showToast('فشل قبول الطلب: ' + reqError.message); return; }
      var wp = requestData.waypoints || [];
      var { data: tripData, error: tripError } = await supabase.from('trips').insert({ driver_id: currentUser.id, passenger_id: requestData.passenger_id, status: 'assigned', classification: requestData.classification === 'private' ? 'private' : 'shared', passenger_count: requestData.passenger_count || 1, adult_count: requestData.passenger_count || 1, join_code: joinCode, start_address: requestData.pickup_address || '', end_address: requestData.destination_address || '', waypoints: wp }).select('id, join_code').single();
      if (tripError) { showToast('فشل إنشاء الرحلة: ' + tripError.message); return; }
      acceptedTripData = { tripId: tripData.id, joinCode: joinCode, passengerName: 'راكب', pickupAddress: requestData.pickup_address, pickupLat: requestData.pickup_lat, pickupLng: requestData.pickup_lng, waypoints: wp };
      document.getElementById('pending-trip-banner').style.display = 'block';
      document.getElementById('pending-trip-code').textContent = joinCode;
      switchDriverTab('meter', document.querySelector('#driver-app .tab-btn'));
      showToast('✅ تم قبول الطلب! كود التتبع: ' + joinCode);
      loadDriverRequests();
      // Auto-set unavailable when accepting a trip
      await setDriverAvailable(false);
    } catch (e) { showToast('حدث خطأ'); console.error(e); }
  };

  window.toggleDriverAvailability = async function() {
    if (!supabase || !currentUser) return;
    try {
      var { data: drv } = await supabase.from('drivers').select('is_available').eq('id', currentUser.id).single();
      var newStatus = !(drv && drv.is_available);
      await setDriverAvailable(newStatus);
      showToast(newStatus ? '🟢 أصبحت متاحاً للطلب' : '🔴 أصبحت غير متاح للطلب');
    } catch (e) { showToast('فشل تغيير الحالة'); }
  };
  window.toggleDriverAvailability = toggleDriverAvailability;

  async function setDriverAvailable(val) {
    if (!supabase || !currentUser) return;
    try {
      await supabase.from('drivers').update({ is_available: val }).eq('id', currentUser.id);
      setDriverAvailableUI(val);
    } catch(e) { console.error(e); }
  }
  window.setDriverAvailable = setDriverAvailable;

  function setDriverAvailableUI(val) {
    var badge = document.getElementById('driver-status-badge');
    if (!badge) return;
    if (val) { badge.textContent = '🟢 متاح للطلب'; badge.style.background = 'var(--success)'; }
    else { badge.textContent = '🔴 غير متاح'; badge.style.background = '#ef4444'; }
  }

  window.rejectRequest = async function(requestId) {
    if (!supabase) return;
    if (!confirm('رفض هذا الطلب؟')) return;
    try {
      var { data: req } = await supabase.from('ride_requests').select('offered_drivers').eq('id', requestId).eq('offered_to', currentUser.id).single();
      var excludeList = (req && req.offered_drivers) || [];
      if (!excludeList.includes(currentUser.id)) excludeList.push(currentUser.id);
      await supabase.from('ride_requests').update({ offered_to: null, offered_at: null, offered_drivers: excludeList }).eq('id', requestId).eq('offered_to', currentUser.id);
      showToast('تم رفض الطلب');
      loadDriverRequests();
    } catch (e) { showToast('فشل'); }
  };
  function handleGPSError(err) { console.warn('GPS error:', err.message); }
	  // ======================== PASSWORD STRENGTH ========================
	  document.addEventListener('visibilitychange', function() {
	    for (var id in meters) {
	      var m = meters[id];
	      if (m && m.isActive && !m.isPaused) {
	        updateWaitSeconds(m);
	        if (m.startTime) m.totalDurationMinutes = ((Date.now() - m.startTime) - m.pausedTimeTotal) / 1000 / 60;
	        calculateFare(m);
	      }
	    }
	    renderMeterDataToUI();
	    saveDataToStorage();
	  });
