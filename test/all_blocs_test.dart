import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taweqa_ogretk/core/config/supabase_config.dart';
import 'package:taweqa_ogretk/features/auth/bloc/auth_bloc.dart';
import 'package:taweqa_ogretk/features/auth/bloc/auth_event.dart';
import 'package:taweqa_ogretk/features/auth/bloc/auth_state.dart';
import 'package:taweqa_ogretk/core/models/vehicle_category.dart';
import 'package:taweqa_ogretk/features/auth/models/user_model.dart';
import 'package:taweqa_ogretk/features/auth/repositories/auth_repository.dart';
import 'package:taweqa_ogretk/features/driver/bloc/driver_bloc.dart';
import 'package:taweqa_ogretk/features/driver/bloc/driver_event.dart';
import 'package:taweqa_ogretk/features/driver/models/trip_model.dart';
import 'package:taweqa_ogretk/features/driver/repositories/driver_repository.dart';
import 'package:taweqa_ogretk/features/passenger/bloc/passenger_bloc.dart';
import 'package:taweqa_ogretk/features/passenger/bloc/passenger_event.dart';
import 'package:taweqa_ogretk/features/passenger/repositories/passenger_repository.dart';
import 'package:taweqa_ogretk/features/wallet/bloc/wallet_bloc.dart';
import 'package:taweqa_ogretk/features/wallet/repositories/wallet_repository.dart';
import 'package:taweqa_ogretk/features/chat/bloc/chat_bloc.dart';
import 'package:taweqa_ogretk/features/chat/repositories/chat_repository.dart';
import 'package:taweqa_ogretk/features/admin/bloc/admin_bloc.dart';
import 'package:taweqa_ogretk/features/admin/bloc/admin_event.dart';
import 'package:taweqa_ogretk/features/admin/repositories/admin_repository.dart';
import 'package:taweqa_ogretk/features/admin/models/admin_models.dart';
import 'package:taweqa_ogretk/features/subscription/bloc/subscription_bloc.dart';
import 'package:taweqa_ogretk/features/subscription/bloc/subscription_event.dart';
import 'package:taweqa_ogretk/features/subscription/repositories/subscription_repository.dart';
import 'package:taweqa_ogretk/core/models/subscription.dart';

// ---------------------------------------------------------------------------
// Mock repositories – return empty/null data, no real Supabase calls
// ---------------------------------------------------------------------------

class MockAuthRepository extends AuthRepository {
  @override
  Future<UserProfile> getCurrentProfile() async {
    return UserProfile(id: '1', fullName: 'Tester', role: 'passenger');
  }

  @override
  void dispose() {}
}

class MockDriverRepository extends DriverRepository {
  @override
  double calculateFare(double distanceKm, double durationMin, {VehicleCategory? category, double waitTimeMin = 0, bool passengerDiscount = false}) {
    final fare = 5.0 + distanceKm * 3.5 + durationMin * 0.5 + waitTimeMin * 0.25;
    return passengerDiscount ? fare * 0.85 : fare;
  }

  @override
  double calculateDriverCut(double fare, {bool premiumDriver = false}) {
    return premiumDriver ? fare * 0.90 : fare * 0.85;
  }

  @override
  Future<Trip> endTrip({
    required String tripId,
    required double endLat,
    required double endLng,
    required double distanceKm,
    required double durationMin,
    required double fare,
    required double driverCut,
  }) async {
    return Trip(
      id: tripId,
      driverId: 'driver-1',
      startLat: 0,
      startLng: 0,
      endLat: endLat,
      endLng: endLng,
      distanceKm: distanceKm,
      durationMin: durationMin,
      fare: fare,
      driverCut: driverCut,
      status: 'completed',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
  }

  @override
  Future<Trip> createTrip({
    required String driverId,
    required double startLat,
    required double startLng,
  }) async {
    return Trip(
      id: 'trip-1',
      driverId: driverId,
      startLat: startLat,
      startLng: startLng,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Trip> fetchTripById(String tripId) async {
    return Trip(
      id: tripId,
      driverId: 'driver-1',
      startLat: 0,
      startLng: 0,
      createdAt: DateTime.now(),
    );
  }
}

class MockPassengerRepository extends PassengerRepository {}

class MockWalletRepository extends WalletRepository {}

class MockChatRepository extends ChatRepository {
  @override
  void dispose() {}
}

class MockAdminRepository extends AdminRepository {
  @override
  Future<AdminStats> fetchStats() async {
    return AdminStats(
      totalDrivers: 10,
      availableDrivers: 5,
      totalPassengers: 20,
      activeTrips: 3,
      completedTrips: 50,
      pendingApplications: 2,
      totalRevenue: 5000,
    );
  }

  @override
  Future<List<AdminDriver>> fetchDrivers() async {
    return [
      AdminDriver(id: '1', fullName: 'سائق 1', isAvailable: true),
      AdminDriver(id: '2', fullName: 'سائق 2', isAvailable: false, banned: true),
    ];
  }

  @override
  Future<List<AdminDriver>> fetchPassengers() async {
    return [];
  }

  @override
  Future<List<dynamic>> fetchAllTrips() async {
    return [];
  }

  @override
  Future<List<DriverApplication>> fetchDriverApplications() async {
    return [];
  }

  @override
  Future<void> toggleDriverBan(String userId, bool banned) async {}
}

class MockSubscriptionRepository extends SubscriptionRepository {
  @override
  Future<Subscription> createSubscription({
    required String userId,
    required String tierType,
    required double price,
  }) async {
    return Subscription(
      id: 'sub-1',
      userId: userId,
      tierType: tierType,
      price: price,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<Subscription>> fetchHistory(String userId) async {
    return [];
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SupabaseConfig.initWithClient(SupabaseClient(
      'https://fake.supabase.co',
      'fake-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    ));
  });

  group('AuthBloc', () {
    late MockAuthRepository repo;

    setUp(() {
      repo = MockAuthRepository();
    });

    test('initial state is AuthInitial', () {
      final bloc = AuthBloc(repository: repo);
      expect(bloc.state, isA<AuthInitial>());
      bloc.close();
    });

    test('AppStarted emits AuthUnauthenticated when no user', () async {
      final bloc = AuthBloc(repository: repo);
      final expected = expectLater(bloc.stream, emits(isA<AuthUnauthenticated>()));
      bloc.add(AppStarted());
      await expected;
      await bloc.close();
    });

    test('LoginRequested emits AuthLoading then AuthFailure with fake client',
        () async {
      final bloc = AuthBloc(repository: repo);
      final expected = expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthFailure>()]),
      );
      bloc.add(LoginRequested(email: 'test@test.com', password: 'pass'));
      await expected;
      await bloc.close();
    });

    test('LogoutRequested emits AuthLoading then AuthUnauthenticated',
        () async {
      final bloc = AuthBloc(repository: repo);
      final expected = expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
      );
      bloc.add(LogoutRequested());
      await expected;
      await bloc.close();
    });
  });

  group('DriverBloc', () {
    late MockDriverRepository repo;

    setUp(() {
      repo = MockDriverRepository();
    });

    test('initial state has correct defaults', () {
      final bloc = DriverBloc(repository: repo);
      expect(bloc.state.isLoading, false);
      expect(bloc.state.isAvailable, false);
      expect(bloc.state.currentFare, 0);
      expect(bloc.state.distanceKm, 0);
      expect(bloc.state.durationMin, 0);
      expect(bloc.state.currentTrip, null);
      expect(bloc.state.tripHistory, isEmpty);
      bloc.close();
    });

    test('LoadDriverProfile sets isLoading to false (no user)', () async {
      final bloc = DriverBloc(repository: repo);
      bloc.add(LoadDriverProfile());
      await Future(() {});
      expect(bloc.state.isLoading, false);
      await bloc.close();
    });

    test('ToggleAvailability sets isLoading to false (no user)', () async {
      final bloc = DriverBloc(repository: repo);
      bloc.add(ToggleAvailability(isAvailable: true));
      await Future(() {});
      expect(bloc.state.isLoading, false);
      await bloc.close();
    });

    test('StartTrip sets isLoading to false (no user)', () async {
      final bloc = DriverBloc(repository: repo);
      bloc.add(StartTrip(startLat: 30.0, startLng: 31.0));
      await Future(() {});
      expect(bloc.state.isLoading, false);
      await bloc.close();
    });

    test('EndTrip calculates fare and resets trip fields', () async {
      final bloc = DriverBloc(repository: repo);
      // must have a real trip ID because _onEndTrip does not check currentUser
      bloc.add(EndTrip(
        tripId: 'trip-1',
        endLat: 30.5,
        endLng: 31.5,
        distanceKm: 10,
        durationMin: 15,
      ));
      await Future(() {});
      await Future(() {});
      await Future(() {});
      await Future(() {});
      expect(bloc.state.isLoading, false);
      expect(bloc.state.currentTrip, null);
      expect(bloc.state.distanceKm, 0);
      expect(bloc.state.durationMin, 0);
      expect(bloc.state.currentFare, 0);
      bloc.close();
    });

    test('UpdateRoute calculates fare correctly', () async {
      final bloc = DriverBloc(repository: repo);
      bloc.add(UpdateRoute(
        routePoints: [
          [30.0, 31.0],
          [30.1, 31.1]
        ],
        distanceKm: 10,
        durationMin: 15,
      ));
      await Future(() {});
      expect(bloc.state.distanceKm, 10);
      expect(bloc.state.durationMin, 15);
      expect(bloc.state.routePoints.length, 2);
      // fare = 5 + 10*3.5 + 15*0.5 = 5 + 35 + 7.5 = 47.5
      expect(bloc.state.currentFare, 47.5);
      await bloc.close();
    });
  });

  group('PassengerBloc', () {
    late MockPassengerRepository repo;

    setUp(() {
      repo = MockPassengerRepository();
    });

    test('initial state has correct defaults', () {
      final bloc = PassengerBloc(repository: repo);
      expect(bloc.state.isLoading, false);
      expect(bloc.state.pickupLat, null);
      expect(bloc.state.pickupLng, null);
      expect(bloc.state.pickupAddress, '');
      expect(bloc.state.destLat, null);
      expect(bloc.state.destLng, null);
      expect(bloc.state.activeRequest, null);
      bloc.close();
    });

    test('UpdatePickupLocation updates pickup fields', () async {
      final bloc = PassengerBloc(repository: repo);
      bloc.add(UpdatePickupLocation(
        lat: 30.0,
        lng: 31.0,
        address: 'شارع 1',
      ));
      await Future(() {});
      expect(bloc.state.pickupLat, 30.0);
      expect(bloc.state.pickupLng, 31.0);
      expect(bloc.state.pickupAddress, 'شارع 1');
      await bloc.close();
    });

    test('UpdateDestination updates destination fields', () async {
      final bloc = PassengerBloc(repository: repo);
      bloc.add(UpdateDestination(
        lat: 30.5,
        lng: 31.5,
        address: 'شارع 2',
      ));
      await Future(() {});
      expect(bloc.state.destLat, 30.5);
      expect(bloc.state.destLng, 31.5);
      expect(bloc.state.destAddress, 'شارع 2');
      await bloc.close();
    });
  });

  group('WalletBloc', () {
    test('initial state has correct defaults', () {
      final bloc = WalletBloc(repository: MockWalletRepository());
      expect(bloc.state.isLoading, false);
      expect(bloc.state.wallet, null);
      expect(bloc.state.transactions, isEmpty);
      expect(bloc.state.paymobPaymentKey, null);
      expect(bloc.state.depositSuccess, false);
      bloc.close();
    });
  });

  group('ChatBloc', () {
    test('initial state has correct defaults', () {
      final bloc = ChatBloc(repository: MockChatRepository());
      expect(bloc.state.isLoading, false);
      expect(bloc.state.messages, isEmpty);
      expect(bloc.state.conversations, isEmpty);
      expect(bloc.state.activeConversationId, null);
      bloc.close();
    });
  });

  group('AdminBloc', () {
    late MockAdminRepository repo;

    setUp(() {
      repo = MockAdminRepository();
    });

    test('initial state has correct defaults', () {
      final bloc = AdminBloc(repository: repo);
      expect(bloc.state.isLoading, false);
      expect(bloc.state.drivers, isEmpty);
      expect(bloc.state.passengers, isEmpty);
      expect(bloc.state.trips, isEmpty);
      expect(bloc.state.driverApplications, isEmpty);
      bloc.close();
    });

    test('LoadAdminStats emits stats', () async {
      final bloc = AdminBloc(repository: repo);
      bloc.add(LoadAdminStats());
      await Future(() {});
      await Future(() {});
      expect(bloc.state.stats, isNotNull);
      expect(bloc.state.stats!.totalDrivers, 10);
      expect(bloc.state.stats!.totalRevenue, 5000);
      await bloc.close();
    });

    test('LoadDrivers emits driver list', () async {
      final bloc = AdminBloc(repository: repo);
      bloc.add(LoadDrivers());
      await Future(() {});
      await Future(() {});
      expect(bloc.state.drivers.length, 2);
      expect(bloc.state.drivers[0].fullName, 'سائق 1');
      await bloc.close();
    });

    test('ToggleDriverBan fires without error', () async {
      final bloc = AdminBloc(repository: repo);
      bloc.add(ToggleDriverBan(userId: '1', banned: true));
      await Future(() {});
      expect(bloc.state.error, null);
      await bloc.close();
    });
  });

  group('SubscriptionBloc', () {
    late MockSubscriptionRepository repo;

    setUp(() {
      repo = MockSubscriptionRepository();
    });

    test('initial state has correct defaults', () {
      final bloc = SubscriptionBloc(repository: repo);
      expect(bloc.state.isLoading, false);
      expect(bloc.state.activeSubscription, null);
      expect(bloc.state.subscribeSuccess, false);
      bloc.close();
    });

    test('Subscribe sets isLoading false (no user)', () async {
      final bloc = SubscriptionBloc(repository: repo);
      bloc.add(Subscribe(tierType: 'driver_premium', price: 299));
      await Future(() {});
      await Future(() {});
      expect(bloc.state.isLoading, false);
      await bloc.close();
    });

    test('CancelSubscription fires without error', () async {
      final bloc = SubscriptionBloc(repository: repo);
      bloc.add(CancelSubscription());
      await Future(() {});
      expect(bloc.state.error, null);
      await bloc.close();
    });
  });
}
