import 'package:flutter/foundation.dart';
import '../models/environment_model.dart';
import '../models/route_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class AppStateProvider extends ChangeNotifier {
  final ApiService _apiService;

  EnvironmentResponse? _environment;
  bool _isLoadingEnvironment = false;
  String? _environmentError;

  RouteAnalyzeResponse? _routeData;
  int _selectedRouteIndex = 0;
  bool _isAnalyzingRoute = false;
  String? _routeError;

  bool _isBackendOnline = false;

  AppStateProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  EnvironmentResponse? get environment => _environment;
  bool get isLoadingEnvironment => _isLoadingEnvironment;
  String? get environmentError => _environmentError;

  RouteAnalyzeResponse? get routeData => _routeData;
  int get selectedRouteIndex => _selectedRouteIndex;
  RouteAlternative? get selectedRoute =>
      (_routeData != null && _routeData!.routes.isNotEmpty && _selectedRouteIndex < _routeData!.routes.length)
          ? _routeData!.routes[_selectedRouteIndex]
          : null;
  bool get isAnalyzingRoute => _isAnalyzingRoute;
  String? get routeError => _routeError;

  bool get isBackendOnline => _isBackendOnline;

  /// Load initial environmental telemetry using device GPS or Delhi NCR fallback
  Future<void> loadEnvironment({bool useGps = true}) async {
    _isLoadingEnvironment = true;
    _environmentError = null;
    notifyListeners();

    _isBackendOnline = await _apiService.isBackendOnline();

    try {
      double lat;
      double lon;
      bool isFallback = false;
      String fallbackReason = "";

      if (useGps) {
        final loc = await LocationService.getCurrentLocation();
        lat = loc.latitude;
        lon = loc.longitude;
        isFallback = loc.isFallback;
        fallbackReason = loc.statusMessage;
      } else {
        lat = _environment?.latitude ?? 28.6139;
        lon = _environment?.longitude ?? 77.2090;
      }

      final env = await _apiService.getCurrentEnvironment(
        latitude: lat,
        longitude: lon,
        isFallback: isFallback,
        fallbackReason: fallbackReason,
      );

      _environment = env;
      _environmentError = null;
      _isBackendOnline = true;
    } catch (e) {
      _environmentError = e.toString();
    } finally {
      _isLoadingEnvironment = false;
      notifyListeners();
    }
  }

  /// Search a location by name in Delhi NCR and update live environment
  Future<void> searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    _isLoadingEnvironment = true;
    _environmentError = null;
    notifyListeners();

    try {
      final geo = await _apiService.geocodeLocation(query);
      if (geo != null) {
        final lat = geo['lat'] as double;
        final lon = geo['lon'] as double;
        final env = await _apiService.getCurrentEnvironment(
          latitude: lat,
          longitude: lon,
          isFallback: false,
          fallbackReason: "Location: ${geo['city_label']}",
        );
        _environment = env;
        _environmentError = null;
      } else {
        _environmentError = "Location '$query' not found. Please try another Delhi landmark.";
      }
    } catch (e) {
      _environmentError = e.toString();
    } finally {
      _isLoadingEnvironment = false;
      notifyListeners();
    }
  }

  /// Request route calculation, spatial IDW exposure and smart mobility recommendations
  Future<bool> analyzeRoute({
    required String origin,
    required String destination,
  }) async {
    _isAnalyzingRoute = true;
    _routeError = null;
    notifyListeners();

    try {
      double? origLat;
      double? origLon;

      if (origin.toLowerCase().contains("current") || origin.toLowerCase().contains("gps")) {
        origLat = _environment?.latitude;
        origLon = _environment?.longitude;
      }

      final res = await _apiService.analyzeRoute(
        origin: origin,
        originLat: origLat,
        originLon: origLon,
        destination: destination,
        currentAqi: _environment?.currentAqi ?? 120.0,
      );

      _routeData = res;
      _selectedRouteIndex = (res.recommendedRouteIndex > 0 && res.recommendedRouteIndex <= res.routes.length)
          ? res.recommendedRouteIndex - 1
          : 0;
      _routeError = null;
      return true;
    } catch (e) {
      _routeError = e.toString();
      return false;
    } finally {
      _isAnalyzingRoute = false;
      notifyListeners();
    }
  }

  void selectRoute(int index) {
    if (_routeData != null && index >= 0 && index < _routeData!.routes.length) {
      _selectedRouteIndex = index;
      notifyListeners();
    }
  }
}
