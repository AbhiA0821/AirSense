import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/environment_model.dart';
import '../models/prediction_model.dart';
import '../models/route_model.dart';

/// Centralized API Service communicating with the FastAPI Backend
class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Check whether FastAPI Backend is reachable
  Future<bool> isBackendOnline() async {
    try {
      final res = await _client.get(Uri.parse(ApiConfig.health)).timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Ingest real-time AQI, weather, and AI forecast from /environment/current
  Future<EnvironmentResponse> getCurrentEnvironment({
    required double latitude,
    required double longitude,
    bool isFallback = false,
    String fallbackReason = "",
  }) async {
    final uri = Uri.parse("${ApiConfig.currentEnvironment}?latitude=$latitude&longitude=$longitude");
    try {
      final res = await _client.get(uri).timeout(ApiConfig.receiveTimeout);
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        return EnvironmentResponse.fromJson(data, isFallback: isFallback, fallbackReason: fallbackReason);
      } else {
        throw Exception("Server responded with HTTP ${res.statusCode}");
      }
    } on TimeoutException {
      throw Exception("Connection timed out connecting to backend (${ApiConfig.baseUrl}). Ensure FastAPI is running.");
    } catch (e) {
      throw Exception("Failed to fetch environmental telemetry: $e");
    }
  }

  /// Request 24-hour historical AQI trend
  Future<List<Map<String, dynamic>>> getHistoricalAqi({double currentAqi = 120.0}) async {
    final uri = Uri.parse("${ApiConfig.aqiHistorical}?current_aqi=$currentAqi");
    try {
      final res = await _client.get(uri).timeout(ApiConfig.receiveTimeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final raw = data['historical_trend'] as List<dynamic>? ?? [];
        return raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Execute PyTorch LSTM dynamic inference
  Future<PredictionResponse> predictAqi(Map<String, dynamic> requestBody) async {
    final uri = Uri.parse(ApiConfig.aqiPrediction);
    try {
      final res = await _client.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      ).timeout(ApiConfig.receiveTimeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return PredictionResponse.fromJson(data);
      } else {
        throw Exception("Inference failed with status ${res.statusCode}");
      }
    } on TimeoutException {
      throw Exception("Prediction request timed out.");
    } catch (e) {
      throw Exception("AI Prediction Error: $e");
    }
  }

  /// Execute OSRM route analysis, spatial pollution exposure & recommendations
  Future<RouteAnalyzeResponse> analyzeRoute({
    String? origin,
    double? originLat,
    double? originLon,
    required String destination,
    double? destLat,
    double? destLon,
    double currentAqi = 120.0,
  }) async {
    final uri = Uri.parse(ApiConfig.routeAnalyze);
    final Map<String, dynamic> body = {
      "destination": destination,
      "current_aqi": currentAqi,
    };

    if (origin != null && origin.isNotEmpty) body["origin"] = origin;
    if (originLat != null) body["origin_lat"] = originLat;
    if (originLon != null) body["origin_lon"] = originLon;
    if (destLat != null) body["dest_lat"] = destLat;
    if (destLon != null) body["dest_lon"] = destLon;

    try {
      final res = await _client.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return RouteAnalyzeResponse.fromJson(data);
      } else {
        throw Exception("Route analysis error: HTTP ${res.statusCode}");
      }
    } on TimeoutException {
      throw Exception("Routing service timed out. Ensure backend and internet connection are active.");
    } catch (e) {
      throw Exception("Route Analysis Error: $e");
    }
  }

  /// Geocode address to lat/lon via backend geocoding endpoint
  Future<Map<String, dynamic>?> geocodeLocation(String locationQuery) async {
    final uri = Uri.parse("${ApiConfig.geocode}?location=${Uri.encodeComponent(locationQuery)}");
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          return {
            "lat": (data['lat'] as num).toDouble(),
            "lon": (data['lon'] as num).toDouble(),
            "display_name": data['display_name']?.toString() ?? locationQuery,
            "city_label": data['city_label']?.toString() ?? locationQuery,
          };
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
