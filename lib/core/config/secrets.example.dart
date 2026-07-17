// ═══════════════════════════════════════════════════════════════
//  secrets.example.dart  ←  انسخ هذا الملف وأعد تسميته secrets.dart
//  ثم املأ المفاتيح الحقيقية فيه. secrets.dart مستثنى من Git.
// ═══════════════════════════════════════════════════════════════
//
//  Alternativly, you can pass these via --dart-define at build time:
//    flutter build --dart-define=PAYMOB_API_KEY=xxx ...
//  No secrets file needed in that case.

class Secrets {
  /// Paymob API Key — من حساب Paymob
  static const String paymobApiKey = 'YOUR_PAYMOB_API_KEY';

  /// Paymob Integration ID — رقم الدمج من Paymob Dashboard
  static const String paymobIntegrationId = 'YOUR_INTEGRATION_ID';

  /// Paymob Iframe ID — رقم الـ iframe من Paymob Dashboard
  static const String paymobIframeId = 'YOUR_IFRAME_ID';

  /// Supabase URL — املأها لو عاوز تتجاوز القيمة الافتراضية
  static const String supabaseUrl = '';

  /// Supabase Anon Key — املأها لو عاوز تتجاوز القيمة الافتراضية
  static const String supabaseAnonKey = '';
}
