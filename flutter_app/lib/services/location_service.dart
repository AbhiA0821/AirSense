import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final bool isFallback;
  final String statusMessage;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.isFallback,
    required this.statusMessage,
  });
}

/// Location Service handling live GPS and graceful Delhi NCR fallback
class LocationService {
  /// Request current GPS location with comprehensive permission and error handling
  static Future<LocationResult> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          latitude: ApiConfig.defaultDelhiLat,
          longitude: ApiConfig.defaultDelhiLon,
          isFallback: true,
          statusMessage: "Location services disabled — using Delhi NCR default region",
        );
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            latitude: ApiConfig.defaultDelhiLat,
            longitude: ApiConfig.defaultDelhiLon,
            isFallback: true,
            statusMessage: "Location permission denied — using Delhi NCR default region",
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          latitude: ApiConfig.defaultDelhiLat,
          longitude: ApiConfig.defaultDelhiLon,
          isFallback: true,
          statusMessage: "Location permission permanently denied — using Delhi NCR default region",
        );
      }

      // Try acquiring high accuracy position within 5 seconds
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        isFallback: false,
        statusMessage: "GPS Active (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})",
      );
    } on TimeoutException {
      return LocationResult(
        latitude: ApiConfig.defaultDelhiLat,
        longitude: ApiConfig.defaultDelhiLon,
        isFallback: true,
        statusMessage: "GPS request timeout — using Delhi NCR default region",
      );
    } catch (e) {
      return LocationResult(
        latitude: ApiConfig.defaultDelhiLat,
        longitude: ApiConfig.defaultDelhiLon,
        isFallback: true,
        statusMessage: "GPS unavailable — using Delhi NCR default region",
      );
    }
  }
}
