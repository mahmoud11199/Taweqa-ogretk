// ═══════════════════════════════════════════════════════════════
//  secrets.example.dart  ←  انسخ هذا الملف وأعد تسميته secrets.dart
//  ثم املأ المفاتيح الحقيقية فيه. secrets.dart مستثنى من Git.
// ═══════════════════════════════════════════════════════════════
//
//  Alternativly, you can pass these via --dart-define at build time:
//    flutter build --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=xxx ...
//  No secrets file needed in that case.

class Secrets {
  /// Supabase URL — املأها لو عاوز تتجاوز القيمة الافتراضية
  static const String supabaseUrl = '';

  /// Supabase Anon Key — املأها لو عاوز تتجاوز القيمة الافتراضية
  static const String supabaseAnonKey = '';
}
