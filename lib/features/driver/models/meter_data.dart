class PassengerData {
  String name;
  double startDistance;
  double startDuration;
  double startWait;
  double fare;
  bool exited;

  PassengerData({
    this.name = '',
    this.startDistance = 0,
    this.startDuration = 0,
    this.startWait = 0,
    this.fare = 0,
    this.exited = false,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'startDistance': startDistance,
    'startDuration': startDuration,
    'startWait': startWait,
    'fare': fare,
    'exited': exited,
  };
}

class MeterData {
  final int id;
  bool isActive;
  bool isPaused;
  String tripType; // 'makhsoos' or 'afrad'
  double kmPrice;
  double waitPrice;
  double durationPrice;
  double bandira;
  double minFare;
  double totalDistance;
  double totalDistanceCounter;
  DateTime? startTime;
  Duration pausedDurationTotal;
  DateTime? pauseStartedAt;
  double totalDurationMinutes;
  int totalWaitSeconds;
  DateTime? waitingStartedAt;
  int waitingBaseSeconds;
  double lastLat;
  double lastLng;
  double lastAccuracy;
  double lastSpeedKmh;
  bool isWaitingMode;
  String? shareCode;
  String? tripId;
  double finalFare;
  int passengerCount;
  List<List<double>> pathCoords;
  List<List<double>> routeCoords;
  List<PassengerData> passengers;

  MeterData({
    required this.id,
    this.isActive = false,
    this.isPaused = false,
    this.tripType = 'makhsoos',
    this.kmPrice = 5,
    this.waitPrice = 1,
    this.durationPrice = 0.5,
    this.bandira = 5,
    this.minFare = 5,
    this.totalDistance = 0,
    this.totalDistanceCounter = 0,
    this.startTime,
    this.pausedDurationTotal = Duration.zero,
    this.pauseStartedAt,
    this.totalDurationMinutes = 0,
    this.totalWaitSeconds = 0,
    this.waitingStartedAt,
    this.waitingBaseSeconds = 0,
    this.lastLat = 0,
    this.lastLng = 0,
    this.lastAccuracy = 0,
    this.lastSpeedKmh = 0,
    this.isWaitingMode = false,
    this.shareCode,
    this.tripId,
    this.finalFare = 0,
    this.passengerCount = 1,
    this.pathCoords = const [],
    this.routeCoords = const [],
    this.passengers = const [],
  });

  double get effectiveDurationMinutes {
    if (startTime == null) return 0;
    final total = DateTime.now().difference(startTime!);
    final paused = pausedDurationTotal +
        (isPaused && pauseStartedAt != null
            ? DateTime.now().difference(pauseStartedAt!)
            : Duration.zero);
    return (total - paused).inSeconds / 60.0;
  }

  double get effectiveWaitMinutes {
    final base = waitingBaseSeconds / 60.0;
    if (isWaitingMode && waitingStartedAt != null) {
      final added = DateTime.now().difference(waitingStartedAt!).inSeconds / 60.0;
      return base + added;
    }
    return base;
  }

  double calculateFare() {
    final fare = bandira +
        (totalDistance * kmPrice) +
        (effectiveDurationMinutes * durationPrice) +
        (effectiveWaitMinutes * waitPrice);
    return fare < minFare ? minFare : fare;
  }

  double calculateAfradFare() {
    double totalFare = bandira;
    for (final p in passengers) {
      if (p.exited) {
        totalFare += p.fare;
      } else {
        final passFare = (totalDistance - p.startDistance) * kmPrice +
            (effectiveDurationMinutes - p.startDuration) * durationPrice +
            (effectiveWaitMinutes - p.startWait) * waitPrice;
        totalFare += passFare;
      }
    }
    return totalFare < minFare ? minFare : totalFare;
  }

  void addPassenger(String name) {
    passengers = [
      ...passengers,
      PassengerData(
        name: name,
        startDistance: totalDistance,
        startDuration: effectiveDurationMinutes,
        startWait: effectiveWaitMinutes,
      ),
    ];
  }

  void exitPassenger(int index) {
    if (index >= passengers.length) return;
    final p = passengers[index];
    p.fare = (totalDistance - p.startDistance) * kmPrice +
        (effectiveDurationMinutes - p.startDuration) * durationPrice +
        (effectiveWaitMinutes - p.startWait) * waitPrice;
    p.exited = true;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'isActive': isActive,
    'isPaused': isPaused,
    'tripType': tripType,
    'kmPrice': kmPrice,
    'waitPrice': waitPrice,
    'durationPrice': durationPrice,
    'bandira': bandira,
    'minFare': minFare,
    'totalDistance': totalDistance,
    'totalDurationMinutes': totalDurationMinutes,
    'totalWaitSeconds': totalWaitSeconds,
    'shareCode': shareCode,
    'tripId': tripId,
    'finalFare': finalFare,
    'passengerCount': passengerCount,
  };

  MeterData copyWith({
    bool? isActive,
    bool? isPaused,
    String? tripType,
    double? kmPrice,
    double? waitPrice,
    double? durationPrice,
    double? bandira,
    double? minFare,
    double? totalDistance,
    double? totalDistanceCounter,
    DateTime? startTime,
    Duration? pausedDurationTotal,
    DateTime? pauseStartedAt,
    double? totalDurationMinutes,
    int? totalWaitSeconds,
    DateTime? waitingStartedAt,
    int? waitingBaseSeconds,
    double? lastLat,
    double? lastLng,
    double? lastAccuracy,
    double? lastSpeedKmh,
    bool? isWaitingMode,
    String? shareCode,
    String? tripId,
    double? finalFare,
    int? passengerCount,
    List<List<double>>? pathCoords,
    List<List<double>>? routeCoords,
    List<PassengerData>? passengers,
  }) {
    return MeterData(
      id: id,
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      tripType: tripType ?? this.tripType,
      kmPrice: kmPrice ?? this.kmPrice,
      waitPrice: waitPrice ?? this.waitPrice,
      durationPrice: durationPrice ?? this.durationPrice,
      bandira: bandira ?? this.bandira,
      minFare: minFare ?? this.minFare,
      totalDistance: totalDistance ?? this.totalDistance,
      totalDistanceCounter: totalDistanceCounter ?? this.totalDistanceCounter,
      startTime: startTime ?? this.startTime,
      pausedDurationTotal: pausedDurationTotal ?? this.pausedDurationTotal,
      pauseStartedAt: pauseStartedAt ?? this.pauseStartedAt,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      totalWaitSeconds: totalWaitSeconds ?? this.totalWaitSeconds,
      waitingStartedAt: waitingStartedAt ?? this.waitingStartedAt,
      waitingBaseSeconds: waitingBaseSeconds ?? this.waitingBaseSeconds,
      lastLat: lastLat ?? this.lastLat,
      lastLng: lastLng ?? this.lastLng,
      lastAccuracy: lastAccuracy ?? this.lastAccuracy,
      lastSpeedKmh: lastSpeedKmh ?? this.lastSpeedKmh,
      isWaitingMode: isWaitingMode ?? this.isWaitingMode,
      shareCode: shareCode ?? this.shareCode,
      tripId: tripId ?? this.tripId,
      finalFare: finalFare ?? this.finalFare,
      passengerCount: passengerCount ?? this.passengerCount,
      pathCoords: pathCoords ?? this.pathCoords,
      routeCoords: routeCoords ?? this.routeCoords,
      passengers: passengers ?? this.passengers,
    );
  }
}