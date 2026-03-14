# PrithviNet Flutter App
### Field Monitoring Companion — Environment Department, CG Govt.

---

## Overview
This Flutter app is the **Monitoring Team field companion** for PrithviNet. It allows field officers to submit Air, Water, and Noise monitoring reports directly from the field — with GPS auto-capture, offline draft mode, and real-time sync to the same Firebase backend as the web app.

**Primary color:** `#1A5276`

---

## File Structure

```
lib/
├── main.dart                          # App entry, Firebase init, auth wrapper
├── utils/
│   ├── theme.dart                     # Full Material3 theme — primary #1A5276
│   └── aqi_calculator.dart            # CPCB sub-index AQI calculation
├── models/
│   └── reading_models.dart            # AirReading, WaterReading, NoiseReading, row models
├── services/
│   ├── auth_service.dart              # Firebase Auth + UserModel
│   ├── firestore_service.dart         # All Firestore reads/writes
│   └── location_service.dart         # GPS capture + proximity sorting
├── widgets/
│   └── form_widgets.dart              # Shared: FormCard, LabeledDropdown, ParameterInput,
│                                      #         GpsLocationTile, ViolationBadge, etc.
├── screens/
│   ├── auth/
│   │   └── login_screen.dart          # Email/password login
│   ├── home/
│   │   └── home_screen.dart           # Dashboard, monthly stats, quick submit
│   ├── air/
│   │   ├── air_monitoring_form.dart   # Full air report form (matches web app)
│   │   └── air_monitoring_list.dart   # List of past air submissions
│   ├── water/
│   │   ├── water_monitoring_form.dart # Natural + waste water form (tabbed)
│   │   └── water_monitoring_list.dart # List with type selector bottom sheet
│   └── noise/
│       ├── noise_monitoring_form.dart # Noise form with prescribed limits table
│       └── noise_monitoring_list.dart # List of past noise submissions
└── pubspec.yaml
```

---

## Setup Instructions

### 1. Firebase Configuration
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```
This generates `lib/firebase_options.dart` which is auto-imported by `main.dart`.

### 2. Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
```

### 3. iOS Permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>PrithviNet needs location to auto-capture GPS coordinates for monitoring reports.</string>
<key>NSCameraUsageDescription</key>
<string>Attach a photo to your monitoring report for evidence-based compliance tracking.</string>
```

### 4. Install & Run
```bash
flutter pub get
flutter run
```

---

## Key Features

| Feature | Implementation |
|---|---|
| Air Monitoring Form | Stack emissions table (add/remove rows) + 8-parameter ambient section with real-time AQI calculation |
| Water Monitoring Form | Tabbed Natural/Waste; up to 4 sample cards; waste water adds BOD/COD/dissolved solids |
| Noise Monitoring Form | Dynamic rows; prescribed limits reference table always visible; auto H/L flags |
| GPS Capture | Single tap captures current coordinates; attached to every report |
| Violation Detection | Real-time red border + warning icon when any value exceeds prescribed limit |
| AQI Calculation | CPCB sub-index method, computed live as user types PM10/PM2.5/SO₂/NO₂ |
| Offline Support | Firestore SDK offline persistence — reports queue as "Pending Sync" |
| Monthly Deadline | Home screen countdown; warning banner when ≤5 days remain |

---

## Firestore Collections Written
All writes use the **same schema** as the web app:
- `/airReadings/{id}` — `isSimulated: false`, same fields as web
- `/waterReadings/{id}` — same
- `/noiseReadings/{id}` — same

The existing Cloud Function triggers (`onAirReadingCreated`, `onWaterReadingCreated`, `onNoiseReadingCreated`) will **automatically fire** on mobile submissions — no extra backend work needed.

---

## Color Theme

| Token | Hex | Usage |
|---|---|---|
| `primaryColor` | `#1A5276` | AppBar, buttons, section headers |
| `primaryLight` | `#2E86C1` | Gradient, accents |
| `primaryDark` | `#154360` | Login gradient dark end |
| `accentColor` | `#27AE60` | Success states, GPS captured, AQI Good |
| `errorColor` | `#E74C3C` | Violations, errors |
| `warningColor` | `#F39C12` | Deadline reminders, offline banner |

---

*PrithviNet Flutter App — v1.0.0*
*Tech Stack: Flutter 3.x + Firebase (Auth + Firestore + Storage + FCM)*
