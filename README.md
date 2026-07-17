# توقع أجرتك - Towqe3 Ogretk

> التوك توك الذكي — احسب أجرتك بسهولة، تتبع رحلاتك، واستلم مدفوعاتك بدون تعقيد.

Smart tuktuk fare calculator & ride management app built with **Flutter** + **Supabase**.

## Features

- **Driver Meter**: Real-time fare calculation with OSRM routing, GPS tracking, per-km pricing, waiting time, and night fare multiplier.
- **Passenger App**: Request rides, track driver location, rate drivers, fare estimates.
- **Wallet**: In-app wallet with Paymob payment gateway integration (cards, wallets, USSD, bank transfers).
- **Live Chat**: Real-time messaging between drivers and passengers via Supabase Realtime.
- **Admin Panel**: Manage drivers (approve/reject applications), passengers, monitor trips, manage wallets & settings.
- **Driver Application**: Document upload (licence, car licence, national ID), admin approval flow.
- **Analytics**: Driver trip history, earnings charts, passenger ride history.
- **Referral System**: Share referral codes, earn rewards.
- **Landing Page**: Auto-fetches latest APK/iOS download links from GitHub Releases.

## Tech Stack

| Layer        | Technology                                     |
| ------------ | ---------------------------------------------- |
| Framework    | Flutter 3.27+ (Dart 3.x)                       |
| Architecture | Feature-First + Bloc (Cubit for simple states) |
| Backend      | Supabase (Auth, PostgreSQL, Realtime, Storage) |
| Payments     | Paymob (cards, wallets, USSD, transfers)       |
| Maps         | flutter_map (OpenStreetMap) + OSRM API         |
| CI/CD        | GitHub Actions → GitHub Pages + Releases       |
| Distribution | GitHub Releases (APK/IPA), GitHub Pages (Web)  |

## Project Structure

```
lib/
├── main.dart                     # Entry point, Supabase init, Bloc providers
├── app.dart                      # MaterialApp, routing, theme
├── core/
│   ├── config/
│   │   ├── routes.dart           # Route name constants
│   │   └── supabase_config.dart  # Supabase init wrapper
│   ├── constants/
│   │   └── app_constants.dart    # API URLs, GPS limits, prices, GitHub URLs
│   ├── theme/
│   │   └── app_theme.dart        # Dark high-contrast theme
│   ├── utils/
│   │   ├── helpers.dart          # formatCurrency, timeAgo, generateCode, etc.
│   │   └── validators.dart       # Phone, email, password, plate validators
│   └── widgets/
│       ├── toast_widget.dart     # Overlay toast with animation
│       └── loading_widget.dart   # Loading overlay & full-screen loader
└── features/
    ├── auth/         # Login, register, forgot/reset password, role selection
    ├── landing/      # Landing screen with GitHub Releases download
    ├── driver/       # Driver meter, trip history, earnings, settings
    ├── passenger/    # Ride request, tracking, history, favourites
    ├── wallet/       # Wallet balance, Paymob integration, transactions
    ├── chat/         # Real-time messaging (Supabase Realtime)
    └── admin/        # Manage drivers, passengers, trips, wallets, settings
    # Each feature follows: bloc/, models/, repositories/, screens/, widgets/
```

## Getting Started

### Prerequisites

- Flutter SDK 3.27+ (stable channel)
- Dart 3.x
- A Supabase project (or use the existing one — keys in `AppConstants`)
- Android Studio or Xcode for device builds

### Setup

```bash
# Clone the repo
git clone https://github.com/mahmoud11199/Taweqa-ogretk.git
cd Taweqa-ogretk

# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# For web
flutter run -d chrome
```

### 🔑 Secrets (Paymob — لا ترفع على GitHub)

مفاتيح Paymob **ممنوع** رفعها على GitHub. توجد 3 طرق لتزويدها:

#### الطريقة 1 (موصى بها — CI/CD): `--dart-define`
```bash
flutter run --dart-define=PAYMOB_API_KEY=xxx \
  --dart-define=PAYMOB_INTEGRATION_ID=xxx \
  --dart-define=PAYMOB_IFRAME_ID=xxx
```

#### الطريقة 2 (تطوير محلي): ملف `secrets.dart`
انسخ `lib/core/config/secrets.example.dart` ← `lib/core/config/secrets.dart`  
املأ المفاتيح فيه. هذا الملف **مستثنى من Git** (`.gitignore`).

```bash
cp lib/core/config/secrets.example.dart lib/core/config/secrets.dart
# ثم افتح secrets.dart واملأ المفاتيح
```

#### الطريقة 3 (GitHub Actions — فقط CI/CD)
أضف الـ Secrets التالية في `Settings → Secrets and variables → Actions`:

| Secret | القيمة |
|--------|--------|
| `PAYMOB_API_KEY` | من حساب Paymob |
| `PAYMOB_INTEGRATION_ID` | من Paymob Dashboard |
| `PAYMOB_IFRAME_ID` | من Paymob Dashboard |
| `SUPABASE_ACCESS_TOKEN` | من `supabase.com/dashboard/account/tokens` |
| `SUPABASE_DB_PASSWORD` | باسورد قاعدة البيانات |

> **ترتيب الأولوية**: `--dart-define` > `secrets.dart` > القيم الافتراضية (للمفاتيح العامة فقط).

## Build & Release

### Local Builds

```bash
# 1. أول مرة: نزّل خطوط Cairo
.\scripts\download_fonts.ps1

# 2. شغّل مع مفاتيح Paymob
flutter run --dart-define=PAYMOB_API_KEY=xxx \
  --dart-define=PAYMOB_INTEGRATION_ID=xxx \
  --dart-define=PAYMOB_IFRAME_ID=xxx

# Android split APKs
flutter build apk --split-per-abi --release

# iOS (requires macOS + Xcode)
flutter build ios --release
flutter build ios --release --no-codesign  # without signing

# Web
flutter build web --release
```

### CI/CD (GitHub Actions)

On every push to `main`, the `release.yml` workflow:

1. Builds Android APKs (arm64-v8a, armeabi-v7a, x86_64)
2. Builds iOS IPA (unsigned; manual signing required for App Store)
3. Builds Web app
4. Deploys web build to **GitHub Pages**
5. Creates a **GitHub Release** with all APKs + IPA attached

Release tag format: `v2024.07.14-<short-sha>`

## License

Private — All rights reserved.
