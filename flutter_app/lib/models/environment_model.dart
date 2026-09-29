/// Environment Model parsing the /environment/current payload
class EnvironmentResponse {
  final String locationName;
  final String cityName;
  final double latitude;
  final double longitude;
  final bool isFallback;
  final String fallbackReason;

  final double? currentAqi;
  final String aqiCategory;
  final double? pm25;
  final double? pm10;
  final double? no2;
  final double? so2;
  final double? co;
  final double? o3;

  final double? temperature;
  final double? humidity;
  final double? windSpeed;
  final double? pressure;
  final String weatherCondition;

  final String dominantPollutant;
  final String dispersionCondition;
  final double? spatialSurfaceAqi;
  final String? nearestStation;

  final double? predictedAqi;
  final String aiCategory;
  final String modelName;
  final List<double> hourlyForecast;
  final String timestamp;

  EnvironmentResponse({
    required this.locationName,
    required this.cityName,
    required this.latitude,
    required this.longitude,
    this.isFallback = false,
    this.fallbackReason = "",
    this.currentAqi,
    required this.aqiCategory,
    this.pm25,
    this.pm10,
    this.no2,
    this.so2,
    this.co,
    this.o3,
    this.temperature,
    this.humidity,
    this.windSpeed,
    this.pressure,
    required this.weatherCondition,
    required this.dominantPollutant,
    required this.dispersionCondition,
    this.spatialSurfaceAqi,
    this.nearestStation,
    this.predictedAqi,
    required this.aiCategory,
    required this.modelName,
    required this.hourlyForecast,
    required this.timestamp,
  });

  factory EnvironmentResponse.fromJson(Map<String, dynamic> json, {bool isFallback = false, String fallbackReason = ""}) {
    final geo = json['location'] as Map<String, dynamic>? ?? {};
    final coords = json['coordinates'] as Map<String, dynamic>? ?? {};
    final aqi = json['live_aqi'] as Map<String, dynamic>? ?? {};
    final weather = json['live_weather'] as Map<String, dynamic>? ?? {};
    final ai = json['ai_prediction'] as Map<String, dynamic>? ?? {};
    final intel = json['environmental_intelligence'] as Map<String, dynamic>? ?? {};

    final List<dynamic> rawHourly = ai['hourly_forecast'] as List<dynamic>? ?? [];
    final List<double> hourly = rawHourly.map((e) => (e as num).toDouble()).toList();

    return EnvironmentResponse(
      locationName: geo['location']?.toString() ?? "New Delhi",
      cityName: geo['city']?.toString() ?? "New Delhi",
      latitude: (coords['latitude'] as num?)?.toDouble() ?? 28.6139,
      longitude: (coords['longitude'] as num?)?.toDouble() ?? 77.2090,
      isFallback: isFallback,
      fallbackReason: fallbackReason,
      currentAqi: (aqi['aqi'] as num?)?.toDouble(),
      aqiCategory: aqi['category']?.toString() ?? "Moderate",
      pm25: (aqi['pm25'] as num?)?.toDouble(),
      pm10: (aqi['pm10'] as num?)?.toDouble(),
      no2: (aqi['no2'] as num?)?.toDouble(),
      so2: (aqi['so2'] as num?)?.toDouble(),
      co: (aqi['co'] as num?)?.toDouble(),
      o3: (aqi['o3'] as num?)?.toDouble(),
      temperature: (weather['temperature'] as num?)?.toDouble(),
      humidity: (weather['humidity'] as num?)?.toDouble(),
      windSpeed: (weather['wind_speed'] as num?)?.toDouble(),
      pressure: (weather['pressure'] as num?)?.toDouble(),
      weatherCondition: weather['condition']?.toString() ?? "Clear Sky",
      dominantPollutant: intel['dominant_pollutant']?.toString() ?? "PM2.5",
      dispersionCondition: intel['atmospheric_dispersion']?.toString() ?? "Moderate Dispersion",
      spatialSurfaceAqi: (intel['spatial_interpolated_aqi'] as num?)?.toDouble(),
      nearestStation: intel['nearest_station']?.toString(),
      predictedAqi: (ai['predicted_aqi'] as num?)?.toDouble(),
      aiCategory: ai['category']?.toString() ?? "Inference Complete",
      modelName: ai['model_used']?.toString() ?? "PyTorch LSTM Neural Network",
      hourlyForecast: hourly,
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toString(),
    );
  }
}
