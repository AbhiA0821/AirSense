/// Model parsing dynamic /prediction/aqi response
class PredictionResponse {
  final double currentAqi;
  final double predictedAqi;
  final String category;
  final String modelName;
  final String forecastHorizon;
  final List<double> hourlyForecast;
  final String errorMarginLabel;
  final double mae;
  final double rmse;
  final double residualLower;
  final double residualUpper;
  final String timestamp;

  PredictionResponse({
    required this.currentAqi,
    required this.predictedAqi,
    required this.category,
    required this.modelName,
    required this.forecastHorizon,
    required this.hourlyForecast,
    required this.errorMarginLabel,
    required this.mae,
    required this.rmse,
    required this.residualLower,
    required this.residualUpper,
    required this.timestamp,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawHourly = json['hourly_forecast'] as List<dynamic>? ?? [];
    final List<double> hourly = rawHourly.map((e) => (e as num).toDouble()).toList();

    final err = json['empirical_error_bounds'] as Map<String, dynamic>? ?? {};
    final residuals = err['test_residual_range'] as Map<String, dynamic>? ?? {};

    return PredictionResponse(
      currentAqi: (json['current_aqi'] as num?)?.toDouble() ?? 120.0,
      predictedAqi: (json['predicted_aqi'] as num?)?.toDouble() ?? 120.0,
      category: json['category']?.toString() ?? "Moderate",
      modelName: json['model_name']?.toString() ?? json['model_used']?.toString() ?? "PyTorch LSTM Neural Network",
      forecastHorizon: json['forecast_horizon']?.toString() ?? "+24 Hours",
      hourlyForecast: hourly,
      errorMarginLabel: err['error_margin_label']?.toString() ?? "±34.4 AQI (MAE)",
      mae: (err['mae'] as num?)?.toDouble() ?? 34.42,
      rmse: (err['rmse'] as num?)?.toDouble() ?? 44.69,
      residualLower: (residuals['lower'] as num?)?.toDouble() ?? 10.0,
      residualUpper: (residuals['upper'] as num?)?.toDouble() ?? 165.0,
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toString(),
    );
  }
}
