import '../models/admin_models.dart';

class AdminState {
  final bool isLoading;
  final String? error;
  final AdminStats? stats;
  final List<AdminDriver> drivers;
  final List<dynamic> passengers;
  final List<dynamic> trips;
  final List<DriverApplication> driverApplications;
  final Map<String, double>? appSettings;

  const AdminState({
    this.isLoading = false,
    this.error,
    this.stats,
    this.drivers = const [],
    this.passengers = const [],
    this.trips = const [],
    this.driverApplications = const [],
    this.appSettings,
  });

  AdminState copyWith({
    bool? isLoading,
    String? error,
    AdminStats? stats,
    List<AdminDriver>? drivers,
    List<dynamic>? passengers,
    List<dynamic>? trips,
    List<DriverApplication>? driverApplications,
    Map<String, double>? appSettings,
    bool clearError = false,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      stats: stats ?? this.stats,
      drivers: drivers ?? this.drivers,
      passengers: passengers ?? this.passengers,
      trips: trips ?? this.trips,
      driverApplications: driverApplications ?? this.driverApplications,
      appSettings: appSettings ?? this.appSettings,
    );
  }
}
