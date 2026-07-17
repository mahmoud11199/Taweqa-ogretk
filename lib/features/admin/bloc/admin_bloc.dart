import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/admin_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _repository;

  AdminBloc({required AdminRepository repository})
      : _repository = repository,
        super(const AdminState()) {
    on<LoadAdminStats>(_onLoadAdminStats);
    on<LoadDrivers>(_onLoadDrivers);
    on<LoadPassengers>(_onLoadPassengers);
    on<LoadTrips>(_onLoadTrips);
    on<LoadDriverApplications>(_onLoadDriverApplications);
    on<ApproveDriver>(_onApproveDriver);
    on<RejectDriver>(_onRejectDriver);
    on<ToggleDriverBan>(_onToggleDriverBan);
    on<LoadAppSettings>(_onLoadAppSettings);
    on<UpdateAppSettings>(_onUpdateAppSettings);
  }

  Future<void> _onLoadAdminStats(
      LoadAdminStats event, Emitter<AdminState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final stats = await _repository.fetchStats();
      emit(state.copyWith(isLoading: false, stats: stats));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadDrivers(
      LoadDrivers event, Emitter<AdminState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final drivers = await _repository.fetchDrivers();
      emit(state.copyWith(isLoading: false, drivers: drivers));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadPassengers(
      LoadPassengers event, Emitter<AdminState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final passengers = await _repository.fetchPassengers();
      emit(state.copyWith(isLoading: false, passengers: passengers));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadTrips(
      LoadTrips event, Emitter<AdminState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final trips = await _repository.fetchAllTrips();
      emit(state.copyWith(isLoading: false, trips: trips));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadDriverApplications(
      LoadDriverApplications event, Emitter<AdminState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final applications = await _repository.fetchDriverApplications();
      emit(state.copyWith(isLoading: false, driverApplications: applications));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onApproveDriver(
      ApproveDriver event, Emitter<AdminState> emit) async {
    try {
      await _repository.approveDriver(event.userId);
      add(LoadDriverApplications());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onRejectDriver(
      RejectDriver event, Emitter<AdminState> emit) async {
    try {
      await _repository.rejectDriver(event.userId);
      add(LoadDriverApplications());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onToggleDriverBan(
      ToggleDriverBan event, Emitter<AdminState> emit) async {
    try {
      await _repository.toggleDriverBan(event.userId, event.banned);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onLoadAppSettings(
      LoadAppSettings event, Emitter<AdminState> emit) async {
    try {
      final settings = await _repository.fetchAppSettings();
      emit(state.copyWith(appSettings: settings));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUpdateAppSettings(
      UpdateAppSettings event, Emitter<AdminState> emit) async {
    try {
      await _repository.updateAppSettings(event.settings);
      emit(state.copyWith(appSettings: event.settings));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
