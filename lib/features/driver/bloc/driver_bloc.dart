import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/models/trip_passenger.dart';
import '../../../core/services/background_location_service.dart';
import '../../../core/services/in_app_notification_service.dart';
import '../../auth/models/user_model.dart';
import '../repositories/driver_repository.dart';
import 'driver_event.dart';
import 'driver_state.dart';

class DriverBloc extends Bloc<DriverEvent, DriverState> {
  final DriverRepository _repository;

  DriverBloc({required DriverRepository repository})
      : _repository = repository,
        super(const DriverState()) {
    on<LoadDriverProfile>(_onLoadDriverProfile);
    on<ToggleAvailability>(_onToggleAvailability);
    on<UpdateDriverLocation>(_onUpdateDriverLocation);
    on<StartTrip>(_onStartTrip);
    on<EndTrip>(_onEndTrip);
    on<CancelTrip>(_onCancelTrip);
    on<UpdateRoute>(_onUpdateRoute);
    on<FetchTripHistory>(_onFetchTripHistory);
    on<FetchEarnings>(_onFetchEarnings);
    on<UpdateDriverProfile>(_onUpdateDriverProfile);
    on<ToggleWaitTime>(_onToggleWaitTime);
    on<LoadTripPassengers>(_onLoadTripPassengers);
    on<GenerateShareCode>(_onGenerateShareCode);
    on<UpdatePassengerStatus>(_onUpdatePassengerStatus);
    on<FetchScheduledTrips>(_onFetchScheduledTrips);
    on<AcceptScheduledTrip>(_onAcceptScheduledTrip);
  }

  Future<void> _onLoadDriverProfile(
      LoadDriverProfile event, Emitter<DriverState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false)); return; }
      final data = await _repository.fetchDriverProfile(user.id);
      final driverInfo = DriverInfo.fromMap(data);
      emit(state.copyWith(
        isLoading: false,
        driverInfo: driverInfo,
        isAvailable: driverInfo.isAvailable,
        currentLat: driverInfo.currentLat ?? 0,
        currentLng: driverInfo.currentLng ?? 0,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onToggleAvailability(
      ToggleAvailability event, Emitter<DriverState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false)); return; }
      await _repository.updateAvailability(user.id, event.isAvailable);
      if (event.isAvailable) {
        await BackgroundLocationService.start();
      } else {
        await BackgroundLocationService.stop();
      }
      emit(state.copyWith(isLoading: false, isAvailable: event.isAvailable));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onUpdateDriverLocation(
      UpdateDriverLocation event, Emitter<DriverState> emit) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;
      await _repository.updateLocation(user.id, event.lat, event.lng);
      emit(state.copyWith(currentLat: event.lat, currentLng: event.lng));
    } catch (e) {
      // Location update failed (GPS error, network issue) — silently skipped
    }
  }

  Future<void> _onStartTrip(
      StartTrip event, Emitter<DriverState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false)); return; }
      final trip = await _repository.createTrip(
        driverId: user.id,
        startLat: event.startLat,
        startLng: event.startLng,
      );
      emit(state.copyWith(isLoading: false, currentTrip: trip));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onEndTrip(
      EndTrip event, Emitter<DriverState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final fare = _repository.calculateFare(event.distanceKm, event.durationMin, waitTimeMin: event.waitTimeMin);
      final driverCut = _repository.calculateDriverCut(fare);
      final trip = await _repository.endTrip(
        tripId: event.tripId,
        endLat: event.endLat,
        endLng: event.endLng,
        distanceKm: event.distanceKm,
        durationMin: event.durationMin,
        fare: fare,
        driverCut: driverCut,
      );
      if (trip.passengerId != null) {
        await InAppNotificationService.sendNotification(
          userId: trip.passengerId!,
          title: 'انتهت الرحلة',
          body: 'تم إنهاء الرحلة بنجاح، شكراً لاستخدامك عدادِي مَرِنْ',
        );
      }
      emit(state.copyWith(
        isLoading: false,
        currentTrip: null,
        distanceKm: 0,
        durationMin: 0,
        waitTimeMin: 0,
        currentFare: 0,
        routePoints: [],
        isWaiting: false,
        tripPassengers: [],
        shareCode: null,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCancelTrip(
      CancelTrip event, Emitter<DriverState> emit) async {
    try {
      await SupabaseConfig.client.from('trips').update({'status': 'cancelled'}).eq('id', event.tripId);
      final trip = await _repository.fetchTripById(event.tripId);
      if (trip.passengerId != null) {
        await InAppNotificationService.sendNotification(
          userId: trip.passengerId!,
          title: 'تم إلغاء الرحلة',
          body: 'تم إلغاء الرحلة من قبل السائق',
        );
      }
      emit(state.copyWith(
        currentTrip: null,
        distanceKm: 0,
        durationMin: 0,
        waitTimeMin: 0,
        currentFare: 0,
        routePoints: [],
        isWaiting: false,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUpdateRoute(
      UpdateRoute event, Emitter<DriverState> emit) async {
    final fare = _repository.calculateFare(event.distanceKm, event.durationMin, waitTimeMin: state.waitTimeMin);
    emit(state.copyWith(
      routePoints: event.routePoints,
      distanceKm: event.distanceKm,
      durationMin: event.durationMin,
      currentFare: fare,
    ));
  }

  Future<void> _onFetchTripHistory(
      FetchTripHistory event, Emitter<DriverState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false)); return; }
      final trips = await _repository.fetchTripHistory(user.id);
      emit(state.copyWith(isLoading: false, tripHistory: trips));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onFetchEarnings(
      FetchEarnings event, Emitter<DriverState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false)); return; }
      final earnings = await _repository.fetchEarnings(user.id);
      emit(state.copyWith(isLoading: false, earnings: earnings));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onFetchScheduledTrips(
      FetchScheduledTrips event, Emitter<DriverState> emit) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;
      final trips = await _repository.fetchScheduledTrips(user.id);
      emit(state.copyWith(tripHistory: trips));
    } catch (_) {}
  }

  Future<void> _onAcceptScheduledTrip(
      AcceptScheduledTrip event, Emitter<DriverState> emit) async {
    try {
      await _repository.acceptScheduledTrip(event.tripId);
      final trip = await _repository.fetchTripById(event.tripId);
      if (trip.passengerId != null) {
        await InAppNotificationService.sendNotification(
          userId: trip.passengerId!,
          title: 'تم قبول رحلتك المجدولة',
          body: 'قام السائق بقبول رحلتك المجدولة، سيكون في انتظارك في الموعد المحدد',
        );
      }
      emit(state.copyWith(currentTrip: trip));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUpdateDriverProfile(
      UpdateDriverProfile event, Emitter<DriverState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false)); return; }
      final updates = <String, dynamic>{};
      if (event.driverType != null) updates['driver_type'] = event.driverType;
      if (event.carModel != null) updates['car_model'] = event.carModel;
      if (event.carPlate != null) updates['car_plate'] = event.carPlate;
      if (event.carColor != null) updates['car_color'] = event.carColor;
      if (updates.isNotEmpty) {
        await SupabaseConfig.client.from('drivers').update(updates).eq('id', user.id);
      }
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onToggleWaitTime(
      ToggleWaitTime event, Emitter<DriverState> emit) async {
    if (event.isWaiting && !state.isWaiting) {
      emit(state.copyWith(isWaiting: true));
    } else if (!event.isWaiting && state.isWaiting) {
      emit(state.copyWith(isWaiting: false, waitTimeMin: state.waitTimeMin + 1));
    }
  }

  Future<void> _onLoadTripPassengers(
      LoadTripPassengers event, Emitter<DriverState> emit) async {
    try {
      final passengers = await _repository.fetchTripPassengers(event.tripId);
      emit(state.copyWith(tripPassengers: passengers));
    } catch (_) {}
  }

  Future<void> _onGenerateShareCode(
      GenerateShareCode event, Emitter<DriverState> emit) async {
    try {
      final code = await _repository.generateShareCode(event.tripId);
      emit(state.copyWith(shareCode: code));
    } catch (_) {}
  }

  Future<void> _onUpdatePassengerStatus(
      UpdatePassengerStatus event, Emitter<DriverState> emit) async {
    try {
      await _repository.updatePassengerStatus(event.tripPassengerId, event.status);
      if (event.status == 'arrived') {
        final tp = state.tripPassengers.where((t) => t.id == event.tripPassengerId).firstOrNull;
        if (tp != null) {
          await InAppNotificationService.sendNotification(
            userId: tp.passengerId,
            title: 'السائق وصل',
            body: 'وصل السائق إلى موقع التوصيل، يرجى التوجه إليه',
          );
        }
      }
      final updated = state.tripPassengers.map((tp) {
        if (tp.id == event.tripPassengerId) {
          return TripPassenger(
            id: tp.id,
            tripId: tp.tripId,
            passengerId: tp.passengerId,
            passengerName: tp.passengerName,
            passengerPhone: tp.passengerPhone,
            passengerRating: tp.passengerRating,
            pickupLat: tp.pickupLat,
            pickupLng: tp.pickupLng,
            pickupAddress: tp.pickupAddress,
            dropoffLat: tp.dropoffLat,
            dropoffLng: tp.dropoffLng,
            dropoffAddress: tp.dropoffAddress,
            status: event.status,
            fare: tp.fare,
            createdAt: tp.createdAt,
          );
        }
        return tp;
      }).toList();
      emit(state.copyWith(tripPassengers: updated));
    } catch (_) {}
  }
}
