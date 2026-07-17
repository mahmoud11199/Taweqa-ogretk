class Validators {
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'يرجى إدخال رقم الهاتف';
    final phoneRegex = RegExp(r'^01[0-9]{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'رقم هاتف مصري صحيح (01XXXXXXXXX)';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'بريد إلكتروني غير صالح';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'يرجى إدخال كلمة السر';
    if (value.length < 6) return 'كلمة السر يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'كلمة السر غير متطابقة';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.isEmpty) return 'يرجى إدخال الاسم الكامل';
    return null;
  }

  static String? plateNumber(String? value) {
    if (value == null || value.isEmpty) return 'يرجى إدخال رقم اللوحة';
    return null;
  }

  static String? model(String? value) {
    if (value == null || value.isEmpty) return 'يرجى إدخال الموديل';
    return null;
  }

  static String? year(String? value) {
    if (value == null || value.isEmpty) return 'يرجى إدخال سنة الصنع';
    final n = int.tryParse(value);
    if (n == null || n < 2000 || n > 2030) return 'سنة غير صالحة';
    return null;
  }
}
