import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/services/in_app_notification_service.dart';
import '../repositories/passenger_repository.dart';
import 'passenger_event.dart';
import 'passenger_state.dart';

class PassengerBloc extends Bloc<PassengerEvent, PassengerState> {
  final PassengerRepository _repository;

  PassengerBloc({required PassengerRepository repository})
      : _repository = repository,
        super(const PassengerState()) {
    on<LoadNearbyDrivers>(_onLoadNearbyDrivers);
    on<RequestRide>(_onRequestRide);
    on<EstimateFare>(_onEstimateFare);
    on<CancelRide>(_onCancelRide);
    on<FetchActiveRequest>(_onFetchActiveRequest);
    on<FetchRideHistory>(_onFetchRideHistory);
    on<RateDriver>(_onRateDriver);
    on<UpdatePickupLocation>(_onUpdatePickupLocation);
    on<UpdateDestination>(_onUpdateDestination);
    on<JoinSharedRide>(_onJoinSharedRide);
    on<ScheduleRide>(_onScheduleRide);
    on<FetchMyScheduledTrips>(_onFetchMyScheduledTrips);
    on<CancelScheduledTrip>(_onCancelScheduledTrip);
  }

  Future<void> _onLoadNearbyDrivers(
      LoadNearbyDrivers event, Emitter<PassengerState> emit) async {
    try {
      final drivers = await _repository.fetchNearbyDrivers(event.lat, event.lng);
      emit(state.copyWith(nearbyDrivers: drivers));
    } catch (e) {
      // Nearby drivers fetch failed — silently skipped
    }
  }

  Future<void> _onRequestRide(
      RequestRide event, Emitter<PassengerState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false)); return; }
      final request = await _repository.requestRide(
        passengerId: user.id,
        pickupLat: event.pickupLat,
        pickupLng: event.pickupLng,
        pickupAddress: event.pickupAddress,
        destLat: event.destLat,
        destLng: event.destLng,
        destAddress: event.destAddress,
      );
      emit(state.copyWith(isLoading: false, activeRequest: request));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onEstimateFare(
      EstimateFare event, Emitter<PassengerState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final estimate = await _repository.estimateFare(
        event.pickupLat, event.pickupLng, event.destLat, event.destLng,
      );
      emit(state.copyWith(
        isLoading: false,
        estimatedFare: estimate['estimated_fare'] as double,
        estimatedDistance: estimate['distance_km'] as double,
        estimatedDuration: estimate['duration_min'] as double,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCancelRide(
      CancelRide event, Emitter<PassengerState> emit) async {
    try {
      final req = await _repository.fetchRideRequestById(event.requestId);
      await _repository.cancelRequest(event.requestId);
      if (req?.driverId != null) {
        await InAppNotificationService.sendNotification(
          userId: req!.driverId!,
          title: 'تم إلغاء الرحلة',
          body: 'قام الراكب بإلغاء الرحلة',
        );
      }
      emit(state.copyWith(activeRequest: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onFetchActiveRequest(
      FetchActiveRequest event, Emitter<PassengerState> emit) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;
      final request = await _repository.fetchActiveRequest(user.id);
      emit(state.copyWith(activeRequest: request));
    } catch (_) {
      emit(state.copyWith(activeRequest: null));
    }
  }

  Future<void> _onFetchRideHistory(
      FetchRideHistory event, Emitter<PassengerState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false)); return; }
      final history = await _repository.fetchHistory(user.id);
      emit(state.copyWith(isLoading: false, rideHistory: history));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onRateDriver(
      RateDriver event, Emitter<PassengerState> emit) async {
    try {
      await _repository.rateDriver(event.requestId, event.rating, review: event.review);
    } catch (e) {
      // Rating submission failed — silently skipped
    }
  }

  void _onUpdatePickupLocation(
      UpdatePickupLocation event, Emitter<PassengerState> emit) {
    emit(state.copyWith(
      pickupLat: event.lat,
      pickupLng: event.lng,
      pickupAddress: event.address,
    ));
  }

  void _onUpdateDestination(
      UpdateDestination event, Emitter<PassengerState> emit) {
    emit(state.copyWith(
      destLat: event.lat,
      destLng: event.lng,
      destAddress: event.address,
    ));
  }

  Future<void> _onScheduleRide(
      ScheduleRide event, Emitter<PassengerState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false)); return; }
      await _repository.scheduleRide(
        passengerId: user.id,
        pickupLat: event.pickupLat,
        pickupLng: event.pickupLng,
        pickupAddress: event.pickupAddress,
        destLat: event.destLat,
        destLng: event.destLng,
        destAddress: event.destAddress,
        scheduledAt: event.scheduledAt,
      );
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onFetchMyScheduledTrips(
      FetchMyScheduledTrips event, Emitter<PassengerState> emit) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;
      final trips = await _repository.fetchScheduledTrips(user.id);
      emit(state.copyWith(scheduledTrips: trips));
    } catch (_) {}
  }

  Future<void> _onCancelScheduledTrip(
      CancelScheduledTrip event, Emitter<PassengerState> emit) async {
    try {
      final req = await _repository.fetchRideRequestById(event.tripId);
      await _repository.cancelRequest(event.tripId);
      if (req?.driverId != null) {
        await InAppNotificationService.sendNotification(
          userId: req!.driverId!,
          title: 'تم إلغاء الرحلة المجدولة',
          body: 'قام الراكب بإلغاء الرحلة المجدولة',
        );
      }
      emit(state.copyWith(
        scheduledTrips: state.scheduledTrips.where((t) => t.id != event.tripId).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onJoinSharedRide(
      JoinSharedRide event, Emitter<PassengerState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false)); return; }
      final tp = await _repository.joinSharedRide(
        shareCode: event.shareCode,
        passengerId: user.id,
        pickupLat: event.pickupLat,
        pickupLng: event.pickupLng,
        pickupAddress: event.pickupAddress,
        destLat: event.destLat,
        destLng: event.destLng,
        destAddress: event.destAddress,
      );
      emit(state.copyWith(
        isLoading: false,
        joinedTripId: tp.tripId,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
