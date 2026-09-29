import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../widgets/status_badge.dart';
import '../widgets/aqi_gauge_card.dart';
import '../widgets/environmental_metrics_grid.dart';
import '../widgets/ai_forecast_card.dart';
import '../widgets/empty_state_view.dart';
import '../theme/app_theme.dart';

/// Screen 1 — AI Environmental Intelligence Overview Dashboard
class HomeDashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const HomeDashboardScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, state, child) {
        final nowStr = DateFormat('HH:mm:ss').format(DateTime.now());

        if (state.isLoadingEnvironment && state.environment == null) {
          return const LoadingStateView(
            message: "Acquiring coordinates & running PyTorch LSTM AI inference...",
          );
        }

        if (state.environmentError != null && state.environment == null) {
          return EmptyStateView(
            icon: Icons.cloud_off,
            iconColor: AppTheme.accentWarning,
            title: "Telemetry Feed Offline",
            description:
                "Unable to connect to FastAPI Environmental Gateway.\n${state.environmentError}",
            actionLabel: "RECONNECT GATEWAY",
            onAction: () => state.loadEnvironment(useGps: true),
          );
        }

        final env = state.environment;
        if (env == null) {
          return EmptyStateView(
            icon: Icons.sensors_off,
            title: "Telemetry Standby",
            description: "Request live GPS coordinates or search a location to begin monitoring.",
            actionLabel: "ACQUIRE TELEMETRY",
            onAction: () => state.loadEnvironment(useGps: true),
          );
        }

        return RefreshIndicator(
          color: AppTheme.accentPrimary,
          backgroundColor: AppTheme.bgCard,
          onRefresh: () => state.loadEnvironment(useGps: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -------------------------------------------------------------
                // OVERVIEW HEADER & STATUS ROW
                // -------------------------------------------------------------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ENVIRONMENTAL INTELLIGENCE",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Live environmental monitoring and AI forecasting.",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    StatusBadge(
                      label: state.isBackendOnline ? "GATEWAY ONLINE" : "CONNECTING",
                      variant: state.isBackendOnline ? StatusBadgeVariant.success : StatusBadgeVariant.warning,
                      icon: state.isBackendOnline ? Icons.cloud_done : Icons.cloud_queue,
                      fontSize: 9,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Live Location & Telemetry Status Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCardElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderMedium),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            env.isFallback ? Icons.location_city : Icons.my_location,
                            size: 13,
                            color: env.isFallback ? AppTheme.accentWarning : AppTheme.accentSuccess,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            env.isFallback
                                ? "FALLBACK: ${env.cityName}"
                                : "LOCATION: ${env.cityName}",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: env.isFallback ? AppTheme.accentWarning : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 5),
                          Text(
                            "Updated: $nowStr IST",
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                              fontFamily: "monospace",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // -------------------------------------------------------------
                // 1. PRIMARY HERO PANEL: LIVE AIR QUALITY (AQI, SEVERITY, POLLUTANTS)
                // -------------------------------------------------------------
                AqiGaugeCard(
                  environment: env,
                  onSearch: (query) => state.searchLocation(query),
                  onUseGps: () => state.loadEnvironment(useGps: true),
                ),
                const SizedBox(height: 14),

                // -------------------------------------------------------------
                // 2. COMPACT ENVIRONMENTAL TELEMETRY (PART 19 COMPLIANT)
                // -------------------------------------------------------------
                EnvironmentalMetricsGrid(environment: env),
                const SizedBox(height: 14),

                // -------------------------------------------------------------
                // 3. AI FORECAST ENGINE: PYTORCH LSTM (+24H FORECAST)
                // -------------------------------------------------------------
                AiForecastCard(environment: env),
                const SizedBox(height: 14),

                // -------------------------------------------------------------
                // 4. SMART MOBILITY CALLOUT BANNER
                // -------------------------------------------------------------
                InkWell(
                  onTap: () {
                    if (onNavigateToTab != null) {
                      onNavigateToTab!(1); // Go to Delhi Routes
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderMedium),
                      boxShadow: AppTheme.depthLow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.accentPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.accentPrimary.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.alt_route, color: AppTheme.accentPrimary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Delhi Smart Route Planning",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Analyze OSRM driving corridors by spatial IDW PM2.5 exposure and AI forecasts.",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
