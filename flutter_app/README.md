# AeroMobility AI — Flutter Android Mobile Client
### AI-Powered Environmental Intelligence & Smart Mobility Recommendation System

---

## 1. Overview

**AeroMobility AI** is a Flutter-based Android mobile application designed to interface with the FastAPI Environmental Intelligence backend. It delivers real-time air quality telemetry, PyTorch LSTM 24-hour neural forecast predictions, OpenStreetMap interactive navigation, and smart mobility recommendations based on Inverse Distance Weighting (IDW) spatial pollution interpolation and inhaled PM2.5 dosage calculations.

---

## 2. System Architecture

The Flutter client functions as a modern presentation and state orchestration layer. **No machine learning or mathematical IDW models are duplicated in Flutter**; all predictions, geospatial interpolations, and routing analytics are executed on the central FastAPI server.

```
flutter_app/
├── android/
│   ├── app/
│   │   ├── build.gradle                   # App Gradle configuration (minSdk 21, targetSdk 34)
│   │   └── src/main/AndroidManifest.xml   # Permissions (Internet, GPS, Cleartext HTTP)
│   ├── build.gradle                       # Root Gradle build script
│   └── settings.gradle                    # Gradle plugin definitions
├── lib/
│   ├── config/
│   │   └── api_config.dart                # Centralized endpoints, base URL & timeouts
│   ├── models/
│   │   ├── environment_model.dart         # /environment/current data contract
│   │   ├── prediction_model.dart          # /prediction/aqi dynamic inference contract
│   │   └── route_model.dart               # /route/analyze multi-route comparison contract
│   ├── providers/
│   │   └── app_state_provider.dart        # ChangeNotifier global state management
│   ├── screens/
│   │   ├── home_dashboard_screen.dart     # Hero AQI, weather metrics, LSTM forecast
│   │   ├── journey_planning_screen.dart   # Origin/destination input, quick chips & analysis
│   │   ├── route_map_screen.dart          # Interactive OpenStreetMap with colorized polylines
│   │   └── exposure_details_screen.dart   # PM2.5 inhaled dose table & IDW formulation
│   ├── services/
│   │   ├── api_service.dart               # HTTP client with timeouts and JSON parsing
│   │   └── location_service.dart          # GPS geolocation with Delhi NCR fallback
│   ├── theme/
│   │   └── app_theme.dart                 # Dark Command Center palette matching Web Dashboard
│   ├── utils/
│   │   └── aqi_colors.dart                # EPA-compliant AQI color mappings & categories
│   ├── widgets/
│   │   ├── aqi_gauge_card.dart            # Hero circular gauge & landmark search
│   │   ├── environmental_metrics_grid.dart# Weather & multi-pollutant telemetry grid
│   │   ├── ai_forecast_card.dart          # 24-hour LSTM prediction & uncertainty card
│   │   ├── hourly_forecast_strip.dart     # Horizontal 24-hour forecast strip
│   │   ├── route_alternative_card.dart    # Individual route alternative card
│   │   └── recommendation_card.dart       # Smart mobility recommendation card
│   └── main.dart                          # App entry point with MultiProvider & tab shell
└── pubspec.yaml                           # Flutter dependencies and assets
```

---

## 3. Prerequisites

1. **Flutter SDK**: Version 3.0.0 or higher.
2. **Android SDK & Build Tools**: Android Studio with SDK Platform 34 (minSdk 21).
3. **Active FastAPI Backend**: The backend server must be running at `http://127.0.0.1:8000` (`python -m uvicorn main:app --host 127.0.0.1 --port 8000` from `F:\Projects\Infosys\backend`).

---

## 4. Backend Network Configuration

The application base URL is configured in `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Default for Android Emulator (10.0.2.2 points to host machine's localhost):
  static String baseUrl = "http://10.0.2.2:8000";
}
```

- **Android Emulator**: `http://10.0.2.2:8000` *(Default — works automatically with standard Android AVDs)*.
- **Physical Android Device (same Wi-Fi)**: Replace `10.0.2.2` with your host PC's LAN IP, e.g. `http://192.168.1.100:8000`.
- **Windows Desktop / Web Chrome**: Change to `http://127.0.0.1:8000`.

---

## 5. Setup & Execution Instructions

Once Flutter is installed and added to PATH on your development workstation:

```bash
# 1. Navigate to the flutter_app directory
cd F:\Projects\Infosys\flutter_app

# 2. Ingest required packages
flutter pub get

# 3. Check connected devices or emulators
flutter devices

# 4. Launch in Debug Mode on connected Android emulator or device
flutter run

# 5. Build production Release APK
flutter build apk --release
```
The output APK will be generated at:
`flutter_app/build/app/outputs/flutter-apk/app-release.apk`

---

## 6. Key Screens & Capabilities

### Tab 1 — Live AQI Dashboard (`HomeDashboardScreen`)
- Live connection pulse to FastAPI backend.
- Hero circular AQI gauge with category badge and EPA color coding.
- Search bar for quick Delhi NCR landmark lookup + "Use GPS" button with automatic Delhi NCR fallback.
- 10-parameter telemetry grid: Temperature, Humidity, Wind Speed, Pressure, PM2.5, PM10, NO₂, SO₂, CO, and O₃.
- AI AQI Forecast Engine displaying +24h predicted AQI, PyTorch LSTM model attribution, and test set empirical error bounds (MAE: 34.42, RMSE: 44.69).
- Scrollable 24-hour forecast trajectory strip.

### Tab 2 — Journey Planning (`JourneyPlanningScreen`)
- Origin and Destination landmark selection with pre-populated Delhi NCR chips (Connaught Place, India Gate, Dwarka, Noida, IGI Airport, Cyber City).
- Direct call to `/route/analyze` computing route options, travel time, and pollution metrics.
- Prominently displays the **Smart Mobility Recommendation** prioritizing routes with the lowest total inhaled PM2.5 dose.
- Lists all alternative corridors with distance, duration, average AQI, and inhaled dosage.

### Tab 3 — Interactive Route Map (`RouteMapScreen`)
- Full-screen OpenStreetMap view powered by `flutter_map` and `latlong2`.
- Color-coded route polylines reflecting environmental pollution severity.
- Floating route switcher and bottom exposure card.
- Origin and destination markers.

### Tab 4 — Exposure Analysis & Scientific Formulation (`ExposureDetailsScreen`)
- Corridor comparison table displaying side-by-side metrics.
- Mathematical formulations for Inhaled PM2.5 Dose:
  $$\text{Dose } (\mu\text{g}) = \text{Ventilation Rate } (0.015\text{ m}^3/\text{min}) \times \text{PM}_{2.5}\text{ Concentration } (\mu\text{g}/\text{m}^3) \times \text{Duration (min)}$$
- Spatial Inverse Distance Weighting (IDW, $p=2$) across 27 CPCB monitoring stations.
- Explicit notation regarding traffic constraints (standard road speed profiles utilized via OSRM).

---

## 7. Android Security & Permissions

Defined in `android/app/src/main/AndroidManifest.xml`:
- `android.permission.INTERNET`: Required for backend communication and OpenStreetMap tiles.
- `android.permission.ACCESS_NETWORK_STATE`: Required for connectivity checks.
- `android.permission.ACCESS_FINE_LOCATION` & `ACCESS_COARSE_LOCATION`: Required for GPS geolocation with graceful Delhi NCR fallback.
- `android:usesCleartextTraffic="true"`: Permits communication with local development HTTP endpoints (`http://10.0.2.2:8000`).
