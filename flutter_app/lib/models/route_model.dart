/// Route Analysis Models parsing /route/analyze payload
class RouteAlternative {
  final int routeIndex;
  final String name;
  final double distanceKm;
  final int durationMinutes;
  final int geometryPointCount;
  final List<List<double>> polyline;
  final double averageAqi;
  final double aiPredictedAqi;
  final String exposureLevel;
  final String estimatedInhaledDose;
  final bool isRecommended;
  final String recommendationReason;

  RouteAlternative({
    required this.routeIndex,
    required this.name,
    required this.distanceKm,
    required this.durationMinutes,
    required this.geometryPointCount,
    required this.polyline,
    required this.averageAqi,
    required this.aiPredictedAqi,
    required this.exposureLevel,
    required this.estimatedInhaledDose,
    required this.isRecommended,
    required this.recommendationReason,
  });

  factory RouteAlternative.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawPoly = json['polyline'] as List<dynamic>? ?? [];
    final List<List<double>> parsedPoly = rawPoly.map((pt) {
      final list = pt as List<dynamic>;
      return [(list[0] as num).toDouble(), (list[1] as num).toDouble()];
    }).toList();

    final exp = json['exposure_analysis'] as Map<String, dynamic>? ?? {};

    return RouteAlternative(
      routeIndex: (json['route_index'] as num?)?.toInt() ?? 1,
      name: json['name']?.toString() ?? "Route",
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      geometryPointCount: (json['geometry_point_count'] as num?)?.toInt() ?? parsedPoly.length,
      polyline: parsedPoly,
      averageAqi: (json['average_aqi'] as num?)?.toDouble() ?? 100.0,
      aiPredictedAqi: (json['ai_predicted_aqi'] as num?)?.toDouble() ?? 100.0,
      exposureLevel: json['exposure_level']?.toString() ?? "Moderate Exposure",
      estimatedInhaledDose: json['estimated_inhaled_dose']?.toString() ?? "N/A",
      isRecommended: json['is_recommended'] == true,
      recommendationReason: exp['recommendation_reason']?.toString() ?? "",
    );
  }
}

class SmartRecommendation {
  final String recommendedRoute;
  final String environmentalExposure;
  final double distanceKm;
  final int durationMinutes;
  final double averageAqi;
  final double aiPredictedAqi;
  final String pm25Exposure;
  final String exposureLevel;
  final String selectionRationale;
  final String trafficLimitation;

  SmartRecommendation({
    required this.recommendedRoute,
    required this.environmentalExposure,
    required this.distanceKm,
    required this.durationMinutes,
    required this.averageAqi,
    required this.aiPredictedAqi,
    required this.pm25Exposure,
    required this.exposureLevel,
    required this.selectionRationale,
    required this.trafficLimitation,
  });

  factory SmartRecommendation.fromJson(Map<String, dynamic> json) {
    return SmartRecommendation(
      recommendedRoute: json['recommended_route']?.toString() ?? "Direct Primary Route",
      environmentalExposure: json['environmental_exposure']?.toString() ?? "Lower",
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      averageAqi: (json['average_aqi'] as num?)?.toDouble() ?? 100.0,
      aiPredictedAqi: (json['ai_predicted_aqi'] as num?)?.toDouble() ?? 100.0,
      pm25Exposure: json['pm25_exposure']?.toString() ?? "N/A",
      exposureLevel: json['exposure_level']?.toString() ?? "Moderate Exposure",
      selectionRationale: json['selection_rationale']?.toString() ?? "Selected based on minimal estimated PM2.5 inhaled dose.",
      trafficLimitation: json['traffic_limitation']?.toString() ?? "Live traffic data is unavailable from OSRM.",
    );
  }
}

class RouteAnalyzeResponse {
  final String status;
  final String routingProvider;
  final int totalRoutesFound;
  final int recommendedRouteIndex;
  final String recommendedRouteName;
  final List<RouteAlternative> routes;
  final SmartRecommendation? smartRecommendation;
  final List<Map<String, dynamic>> routeComparison;
  final String originLabel;
  final String destLabel;
  final double originLat;
  final double originLon;
  final double destLat;
  final double destLon;
  final String trafficLimitation;

  RouteAnalyzeResponse({
    required this.status,
    required this.routingProvider,
    required this.totalRoutesFound,
    required this.recommendedRouteIndex,
    required this.recommendedRouteName,
    required this.routes,
    this.smartRecommendation,
    required this.routeComparison,
    required this.originLabel,
    required this.destLabel,
    required this.originLat,
    required this.originLon,
    required this.destLat,
    required this.destLon,
    required this.trafficLimitation,
  });

  factory RouteAnalyzeResponse.fromJson(Map<String, dynamic> json) {
    final rawRoutes = json['routes'] as List<dynamic>? ?? [];
    final List<RouteAlternative> parsedRoutes = rawRoutes.map((r) => RouteAlternative.fromJson(r as Map<String, dynamic>)).toList();

    final rawComparison = json['route_comparison'] as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> comparisonList = rawComparison.map((c) => Map<String, dynamic>.from(c as Map)).toList();

    SmartRecommendation? rec;
    if (json['smart_recommendation'] != null) {
      rec = SmartRecommendation.fromJson(json['smart_recommendation'] as Map<String, dynamic>);
    }

    final origMap = json['origin_coords'] as Map<String, dynamic>? ?? json['origin'] as Map<String, dynamic>? ?? {};
    final destMap = json['destination_coords'] as Map<String, dynamic>? ?? json['destination'] as Map<String, dynamic>? ?? {};

    return RouteAnalyzeResponse(
      status: json['status']?.toString() ?? "success",
      routingProvider: json['routing_provider']?.toString() ?? "OSRM Driving Engine",
      totalRoutesFound: (json['total_routes_found'] as num?)?.toInt() ?? parsedRoutes.length,
      recommendedRouteIndex: (json['recommended_route_index'] as num?)?.toInt() ?? 1,
      recommendedRouteName: json['recommended_route_name']?.toString() ?? (parsedRoutes.isNotEmpty ? parsedRoutes[0].name : "Route 1"),
      routes: parsedRoutes,
      smartRecommendation: rec,
      routeComparison: comparisonList,
      originLabel: json['origin']?.toString() ?? "Origin",
      destLabel: json['destination']?.toString() ?? "Destination",
      originLat: (origMap['lat'] as num?)?.toDouble() ?? 28.6139,
      originLon: (origMap['lon'] as num?)?.toDouble() ?? 77.2090,
      destLat: (destMap['lat'] as num?)?.toDouble() ?? 28.6318,
      destLon: (destMap['lon'] as num?)?.toDouble() ?? 77.2194,
      trafficLimitation: json['traffic_limitation']?.toString() ?? "Live traffic data unavailable from OSRM.",
    );
  }

  SmartRecommendation? get recommendation => smartRecommendation;
  String get origin => originLabel;
  String get destination => destLabel;
}
