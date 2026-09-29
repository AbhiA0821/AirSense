import 'package:flutter/foundation.dart';

/// Centralized API Configuration for AeroMobility AI Flutter Client
/// Connects to the FastAPI backend service.
class ApiConfig {
  /// Default base URL:
  /// - Android Emulator: 10.0.2.2 maps to host 127.0.0.1
  /// - Web / Windows Desktop: 127.0.0.1:8000
  /// - Physical Devices on same Wi-Fi: use PC LAN IP (e.g. http://192.168.X.X:8000)
  static String baseUrl = kIsWeb
      ? "http://127.0.0.1:8000"
      : (defaultTargetPlatform == TargetPlatform.android
          ? "http://10.0.2.2:8000"
          : "http://127.0.0.1:8000");

  /// Method to switch base URL at runtime (e.g., from settings or auto-detection)
  static void setBaseUrl(String newUrl) {
    if (newUrl.endsWith('/')) {
      baseUrl = newUrl.substring(0, newUrl.length - 1);
    } else {
      baseUrl = newUrl;
    }
  }

  // Endpoints
  static String get health => "$baseUrl/";
  static String get currentEnvironment => "$baseUrl/environment/current";
  static String get aqiHistorical => "$baseUrl/aqi/historical";
  static String get aqiPrediction => "$baseUrl/prediction/aqi";
  static String get routeAnalyze => "$baseUrl/route/analyze";
  static String get geocode => "$baseUrl/geocode";
  static String get reverseGeocode => "$baseUrl/reverse-geocode";
  static String get spatialInterpolate => "$baseUrl/spatial/interpolate";

  // Request Timeouts
  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 25);

  // Default Delhi Fallback Coordinates
  static const double defaultDelhiLat = 28.6139;
  static const double defaultDelhiLon = 77.2090;
  static const String defaultRegionLabel = "Delhi NCR (Default Region)";
}
