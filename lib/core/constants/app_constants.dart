import 'dart:math';
import '../config/secrets.dart';

class AppConstants {
  // ── Supabase (public keys — safe to commit) ──
  static const String supabaseUrl =
      'https://hhuiseftzbqssswnuwrv.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhodWlzZWZ0emJxc3Nzd251d3J2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExMDE5NjEsImV4cCI6MjA5NjY3Nzk2MX0.HSfq7SDEnuoK6ERAV_mINDN49ZJntiBRkVc8L7RsAYY';

  // ── Paymob (secret keys — NEVER commit real values) ──
  // Priority: 1) --dart-define (CI/CD), 2) lib/core/config/secrets.dart (local)

  /// Paymob API Key
  static String get paymobApiKey {
    const env = String.fromEnvironment('PAYMOB_API_KEY');
    if (env.isNotEmpty) return env;
    if (Secrets.paymobApiKey.isNotEmpty) return Secrets.paymobApiKey;
    return '';
  }

  /// Paymob Integration ID
  static String get paymobIntegrationId {
    const env = String.fromEnvironment('PAYMOB_INTEGRATION_ID');
    if (env.isNotEmpty) return env;
    if (Secrets.paymobIntegrationId.isNotEmpty) return Secrets.paymobIntegrationId;
    return '';
  }

  /// Paymob Iframe ID
  static String get paymobIframeId {
    const env = String.fromEnvironment('PAYMOB_IFRAME_ID');
    if (env.isNotEmpty) return env;
    if (Secrets.paymobIframeId.isNotEmpty) return Secrets.paymobIframeId;
    return '';
  }

  // ── GPS & Limits ──
  static const double maxDistanceKm = 1000;
  static const double maxFare = 100000;
  static const int maxDurationMin = 1440;
  static const double gpsFilterMinDistance = 0.001;
  static const double gpsWaitingSpeedKmh = 5;
  static const double gpsMaxAccuracy = 75;

  // ── Pricing ──
  static const double pricingBaseFare = 5;
  static const double pricingPerKm = 3.5;
  static const double pricingPerMin = 0.5;
  static const double appCommissionRate = 0.15;
  static const double nightFareMultiplier = 1.5;
  static const int nightStartHour = 22;
  static const int nightEndHour = 6;
  static const double waitingFarePerMin = 0.25;

  // ── Subscriptions ──
  static const int passengerSubPrice = 89;
  static const int driverSubPrice = 299;
  static const int referralTarget = 10;

  // ── GitHub ──
  static const String githubRepo = 'mahmoud11199/Taweqa-ogretk';
  static const String gitHubReleasesApi =
      'https://api.github.com/repos/mahmoud11199/Taweqa-ogretk/releases';

  static String generateReferralCode() {
    final rng = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      List.generate(10, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
  }
}
