import 'package:flutter/material.dart';
import '../models/environment_model.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class _TelemetryItem {
  final String label;
  final String value;
  final String unit;
  final String statusText;
  final Color statusColor;
  final IconData icon;

  const _TelemetryItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.statusText,
    required this.statusColor,
    required this.icon,
  });
}

/// Compact 3D Environmental Telemetry Console
/// Complies with Part 19: Compact, non-stretching telemetry cards
class EnvironmentalMetricsGrid extends StatelessWidget {
  final EnvironmentResponse environment;

  const EnvironmentalMetricsGrid({super.key, required this.environment});

  @override
  Widget build(BuildContext context) {
    final env = environment;

    // Evaluate health benchmarks for status indicators
    final pm25Status = (env.pm25 ?? 0) <= 30
        ? ("NORMAL", AppTheme.accentSuccess)
        : ((env.pm25 ?? 0) <= 60 ? ("MODERATE", AppTheme.accentWarning) : ("ELEVATED", AppTheme.accentCritical));

    final pm10Status = (env.pm10 ?? 0) <= 50
        ? ("NORMAL", AppTheme.accentSuccess)
        : ((env.pm10 ?? 0) <= 100 ? ("MODERATE", AppTheme.accentWarning) : ("ELEVATED", AppTheme.accentCritical));

    final no2Status = (env.no2 ?? 0) <= 40
        ? ("NORMAL", AppTheme.accentSuccess)
        : ((env.no2 ?? 0) <= 80 ? ("MODERATE", AppTheme.accentWarning) : ("ELEVATED", AppTheme.accentCritical));

    final so2Status = (env.so2 ?? 0) <= 40
        ? ("NORMAL", AppTheme.accentSuccess)
        : ("ELEVATED", AppTheme.accentWarning);

    final coStatus = (env.co ?? 0) <= 2.0
        ? ("NORMAL", AppTheme.accentSuccess)
        : ("ELEVATED", AppTheme.accentWarning);

    final o3Status = (env.o3 ?? 0) <= 50
        ? ("NORMAL", AppTheme.accentSuccess)
        : ("ELEVATED", AppTheme.accentWarning);

    // Weather status evaluations
    final tempStatus = (env.temperature ?? 25) > 35
        ? ("WARM", AppTheme.accentWarning)
        : ((env.temperature ?? 25) < 15 ? ("COOL", AppTheme.accentBlue) : ("MODERATE", AppTheme.accentSuccess));

    final humStatus = (env.humidity ?? 50) > 75
        ? ("HUMID", AppTheme.accentBlue)
        : ((env.humidity ?? 50) < 30 ? ("DRY", AppTheme.accentWarning) : ("OPTIMAL", AppTheme.accentSuccess));

    final windStatus = (env.windSpeed ?? 10) >= 15
        ? ("VENTILATED", AppTheme.accentSuccess)
        : ((env.windSpeed ?? 10) >= 7 ? ("LIGHT BREEZE", AppTheme.accentBlue) : ("STAGNANT", AppTheme.accentWarning));

    const pressStatus = ("STABLE", AppTheme.textSecondary);

    final List<_TelemetryItem> pollutants = [
      _TelemetryItem(
        label: "PM2.5",
        value: env.pm25 != null ? env.pm25!.toStringAsFixed(1) : "--",
        unit: "µg/m³",
        statusText: pm25Status.$1,
        statusColor: pm25Status.$2,
        icon: Icons.grain,
      ),
      _TelemetryItem(
        label: "PM10",
        value: env.pm10 != null ? env.pm10!.toStringAsFixed(1) : "--",
        unit: "µg/m³",
        statusText: pm10Status.$1,
        statusColor: pm10Status.$2,
        icon: Icons.scatter_plot,
      ),
      _TelemetryItem(
        label: "NO₂",
        value: env.no2 != null ? env.no2!.toStringAsFixed(1) : "--",
        unit: "ppb",
        statusText: no2Status.$1,
        statusColor: no2Status.$2,
        icon: Icons.science_outlined,
      ),
      _TelemetryItem(
        label: "CO",
        value: env.co != null ? env.co!.toStringAsFixed(2) : "--",
        unit: "ppm",
        statusText: coStatus.$1,
        statusColor: coStatus.$2,
        icon: Icons.directions_car_outlined,
      ),
      _TelemetryItem(
        label: "SO₂",
        value: env.so2 != null ? env.so2!.toStringAsFixed(1) : "--",
        unit: "ppb",
        statusText: so2Status.$1,
        statusColor: so2Status.$2,
        icon: Icons.factory_outlined,
      ),
      _TelemetryItem(
        label: "O₃",
        value: env.o3 != null ? env.o3!.toStringAsFixed(1) : "--",
        unit: "ppb",
        statusText: o3Status.$1,
        statusColor: o3Status.$2,
        icon: Icons.wb_sunny_outlined,
      ),
    ];

    final List<_TelemetryItem> weather = [
      _TelemetryItem(
        label: "Temperature",
        value: env.temperature != null ? env.temperature!.toStringAsFixed(1) : "--",
        unit: "°C",
        statusText: tempStatus.$1,
        statusColor: tempStatus.$2,
        icon: Icons.thermostat,
      ),
      _TelemetryItem(
        label: "Humidity",
        value: env.humidity != null ? env.humidity!.toStringAsFixed(0) : "--",
        unit: "%",
        statusText: humStatus.$1,
        statusColor: humStatus.$2,
        icon: Icons.water_drop_outlined,
      ),
      _TelemetryItem(
        label: "Wind Speed",
        value: env.windSpeed != null ? env.windSpeed!.toStringAsFixed(1) : "--",
        unit: "km/h",
        statusText: windStatus.$1,
        statusColor: windStatus.$2,
        icon: Icons.air,
      ),
      _TelemetryItem(
        label: "Pressure",
        value: env.pressure != null ? env.pressure!.toStringAsFixed(0) : "--",
        unit: "hPa",
        statusText: pressStatus.$1,
        statusColor: pressStatus.$2,
        icon: Icons.speed,
      ),
    ];

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
          // Section Title
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, size: 16, color: AppTheme.accentPrimary),
                  SizedBox(width: 8),
                  Text(
                    "COMPACT ENVIRONMENTAL TELEMETRY",
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
                label: "CPCB & METEO",
                variant: StatusBadgeVariant.info,
                fontSize: 8.5,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Sub-Header: Air Pollutants
          const Text(
            "PRIMARY AIR POLLUTANTS",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),

          // Compact Pollutants Grid (Responsive 2 to 3 columns)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth >= 700 ? 6 : (constraints.maxWidth >= 450 ? 3 : 2);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pollutants.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 76,
                ),
                itemBuilder: (context, i) => _buildCompactCard(pollutants[i]),
              );
            },
          ),

          const SizedBox(height: 14),

          // Sub-Header: Meteorological Conditions
          const Text(
            "METEOROLOGICAL TELEMETRY",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),

          // Compact Weather Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth >= 700 ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: weather.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 76,
                ),
                itemBuilder: (context, i) => _buildCompactCard(weather[i]),
              );
            },
          ),

          const SizedBox(height: 14),

          // Atmospheric Dispersion & Environmental Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.bgCardElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderMedium),
            ),
            child: Row(
              children: [
                const Icon(Icons.waves, size: 15, color: AppTheme.accentPrimary),
                const SizedBox(width: 8),
                const Text(
                  "Dispersion Condition:",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    env.dispersionCondition,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (env.spatialSurfaceAqi != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    "IDW: ${env.spatialSurfaceAqi!.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentBlue,
                      fontFamily: "monospace",
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact Telemetry Card Widget matching Part 19 specification:
  /// ┌──────────────┐
  /// │ PM2.5        │
  /// │ 13.0 µg/m³   │
  /// │ ● NORMAL     │
  /// └──────────────┘
  Widget _buildCompactCard(_TelemetryItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.bgCardElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderMedium, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Row 1: Parameter Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              Icon(item.icon, size: 13, color: AppTheme.textMuted),
            ],
          ),

          // Row 2: Value + Unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                item.value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  fontFamily: "monospace",
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                item.unit,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Row 3: Status Dot + Status Text
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.statusColor,
                  boxShadow: [
                    BoxShadow(color: item.statusColor.withValues(alpha: 0.6), blurRadius: 3),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                item.statusText,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: item.statusColor,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
