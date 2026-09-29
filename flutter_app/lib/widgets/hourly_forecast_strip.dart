import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/aqi_colors.dart';
import '../theme/app_theme.dart';

/// Professional 24-Hour PyTorch LSTM AQI Trajectory Chart & Strip
class HourlyForecastStrip extends StatelessWidget {
  final List<double> hourlyForecast;

  const HourlyForecastStrip({super.key, required this.hourlyForecast});

  @override
  Widget build(BuildContext context) {
    if (hourlyForecast.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const Text(
          "24-Hour AI Forecast Data Ingesting...",
          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      );
    }

    final now = DateTime.now();

    // Determine min/max for relative bar visualization
    double maxAqi = 150.0;
    for (final val in hourlyForecast) {
      if (val > maxAqi) maxAqi = val;
    }

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: hourlyForecast.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final aqi = hourlyForecast[index];
          final color = AqiColors.getColor(aqi);
          final hourOffset = index + 1;
          final forecastTime = DateFormat('h a').format(now.add(Duration(hours: hourOffset)));
          final barPercent = (aqi / maxAqi).clamp(0.18, 1.0);
          final isImmediate = index == 0;

          return Container(
            width: 68,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: isImmediate ? AppTheme.bgCardHover : AppTheme.bgCardElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isImmediate ? AppTheme.accentPrimary : AppTheme.borderMedium,
                width: isImmediate ? 1.4 : 1.0,
              ),
              boxShadow: isImmediate
                  ? [
                      BoxShadow(
                        color: AppTheme.accentPrimary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Timestamp
                Column(
                  children: [
                    Text(
                      forecastTime,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isImmediate ? AppTheme.accentPrimary : AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      "+${hourOffset}h",
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                        color: isImmediate ? AppTheme.accentPrimary : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),

                // Vertical relative gauge indicator
                Container(
                  width: 14,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppTheme.borderMedium, width: 0.8),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 14,
                    height: 36 * barPercent,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.7), color],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                // Value Readout
                Text(
                  aqi.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFamily: "monospace",
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
