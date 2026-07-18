import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/supabase_config.dart';
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
      final fare = _repository.calculateFare(event.distanceKm, event.durationMin);
      final driverCut = _repository.calculateDriverCut(fare);
      await _repository.endTrip(
        tripId: event.tripId,
        endLat: event.endLat,
        endLng: event.endLng,
        distanceKm: event.distanceKm,
        durationMin: event.durationMin,
        fare: fare,
        driverCut: driverCut,
      );
      emit(state.copyWith(
        isLoading: false,
        currentTrip: null,
        distanceKm: 0,
        durationMin: 0,
        currentFare: 0,
        routePoints: [],
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCancelTrip(
      CancelTrip event, Emitter<DriverState> emit) async {
    try {
      await SupabaseConfig.client.from('trips').update({'status': 'cancelled'}).eq('id', event.tripId);
      emit(state.copyWith(
        currentTrip: null,
        distanceKm: 0,
        durationMin: 0,
        currentFare: 0,
        routePoints: [],
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUpdateRoute(
      UpdateRoute event, Emitter<DriverState> emit) async {
    final fare = _repository.calculateFare(event.distanceKm, event.durationMin);
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
}
