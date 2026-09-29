import 'package:flutter/material.dart';
import '../models/environment_model.dart';
import '../utils/aqi_colors.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';
import 'hourly_forecast_strip.dart';

/// Professional AI Engineering Card: PyTorch LSTM +24h AQI Forecasting Engine
class AiForecastCard extends StatelessWidget {
  final EnvironmentResponse environment;

  const AiForecastCard({super.key, required this.environment});

  @override
  Widget build(BuildContext context) {
    final env = environment;
    final currentAqi = env.currentAqi;
    final predAqi = env.predictedAqi;
    final aqiColor = AqiColors.getColor(predAqi);
    final category = env.aiCategory.isNotEmpty ? env.aiCategory : AqiColors.getCategory(predAqi);

    final aqiDelta = (predAqi != null && currentAqi != null) ? (predAqi - currentAqi) : 0.0;
    final isWorsening = aqiDelta > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderMedium, width: 1.0),
        boxShadow: AppTheme.depthMedium,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology_outlined, size: 17, color: AppTheme.accentSecondary),
                  SizedBox(width: 8),
                  Text(
                    "AI FORECAST ENGINE",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              StatusBadge(
                label: "PYTORCH LSTM",
                variant: StatusBadgeVariant.purple,
                icon: Icons.memory,
                fontSize: 8.5,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Current vs Predicted AQI Side-by-Side 3D Comparison
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.bgCardElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderMedium),
            ),
            child: Row(
              children: [
                // Current Reading
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "CURRENT AQI",
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentAqi != null ? currentAqi.toStringAsFixed(0) : "--",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          fontFamily: "monospace",
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        env.aqiCategory,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AqiColors.getColor(currentAqi),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Divider with Delta
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderMedium),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isWorsening ? Icons.trending_up : Icons.trending_down,
                        color: isWorsening ? AppTheme.accentCritical : AppTheme.accentSuccess,
                        size: 18,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${isWorsening ? "+" : ""}${aqiDelta.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          fontFamily: "monospace",
                          color: isWorsening ? AppTheme.accentCritical : AppTheme.accentSuccess,
                        ),
                      ),
                    ],
                  ),
                ),

                // Predicted Reading
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "PREDICTED AQI (+24H)",
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        predAqi != null ? predAqi.toStringAsFixed(0) : "--",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: aqiColor,
                          fontFamily: "monospace",
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: aqiColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 24-Hour Forecast Label & Model Name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "24-HOUR FORECAST TRAJECTORY",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppTheme.textMuted,
                ),
              ),
              Text(
                env.modelName.isNotEmpty ? env.modelName : "PyTorch LSTM",
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Scrollable Forecast Strip
          HourlyForecastStrip(hourlyForecast: env.hourlyForecast),
        ],
      ),
    );
  }
}
