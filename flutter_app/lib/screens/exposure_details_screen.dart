import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state_view.dart';
import '../utils/aqi_colors.dart';
import '../theme/app_theme.dart';

/// Screen 4 — Dedicated Pollution Exposure Analysis & Environmental Science
class ExposureDetailsScreen extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const ExposureDetailsScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, state, child) {
        final routeData = state.routeData;
        final selectedRoute = state.selectedRoute;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Screen Header
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ROUTE EXPOSURE ANALYSIS",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Spatial IDW pollution exposure & physiological PM2.5 dosage.",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(
                    label: "IDW MODEL",
                    variant: StatusBadgeVariant.info,
                    fontSize: 8.5,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (routeData == null || routeData.routes.isEmpty || selectedRoute == null) ...[
                EmptyStateView(
                  icon: Icons.science_outlined,
                  title: "No Route Exposure Evaluated",
                  description:
                      "Analyze Delhi driving corridors in the Routes screen to compute corridor exposure and inhaled PM2.5 dosage.",
                  actionLabel: "PLAN DELHI ROUTE",
                  onAction: () {
                    if (onNavigateToTab != null) {
                      onNavigateToTab!(1); // Go to Routes Tab
                    }
                  },
                ),
              ] else ...[
                // -------------------------------------------------------------
                // 1. SELECTED ROUTE HERO TELEMETRY (Distance, Duration, AQI, Dose)
                // -------------------------------------------------------------
                Container(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.analytics_outlined, size: 16, color: AppTheme.accentPrimary),
                              const SizedBox(width: 8),
                              Text(
                                "CORRIDOR: ${selectedRoute.name.toUpperCase()}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          StatusBadge(
                            label: selectedRoute.isRecommended ? "RECOMMENDED" : "ALTERNATIVE",
                            variant: selectedRoute.isRecommended
                                ? StatusBadgeVariant.success
                                : StatusBadgeVariant.warning,
                            fontSize: 8.5,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Metrics 4-Box Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              label: "DISTANCE",
                              value: "${selectedRoute.distanceKm.toStringAsFixed(1)} km",
                              sub: "Total Path",
                              color: AppTheme.accentPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricTile(
                              label: "DURATION",
                              value: "${selectedRoute.durationMinutes} min",
                              sub: "Transit Time",
                              color: AppTheme.accentPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              label: "ROUTE AQI",
                              value: selectedRoute.averageAqi.toStringAsFixed(0),
                              sub: "Spatial IDW Avg",
                              color: AqiColors.getColor(selectedRoute.averageAqi),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricTile(
                              label: "PREDICTED AQI",
                              value: selectedRoute.aiPredictedAqi.toStringAsFixed(0),
                              sub: "PyTorch LSTM",
                              color: AqiColors.getColor(selectedRoute.aiPredictedAqi),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Inhaled Dose Highlight Container
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCardElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedRoute.isRecommended
                                ? AppTheme.accentSuccess.withValues(alpha: 0.4)
                                : AppTheme.borderMedium,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.masks_outlined, size: 18, color: AppTheme.accentPrimary),
                                SizedBox(width: 8),
                                Text(
                                  "Estimated Inhaled PM2.5 Dose:",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              selectedRoute.estimatedInhaledDose,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                fontFamily: "monospace",
                                color: selectedRoute.isRecommended
                                    ? AppTheme.accentSuccess
                                    : AppTheme.accentWarning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // -------------------------------------------------------------
                // 2. CORRIDOR COMPARISON TABLE
                // -------------------------------------------------------------
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderMedium),
                    boxShadow: AppTheme.depthMedium,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.compare_arrows, size: 16, color: AppTheme.accentPrimary),
                          SizedBox(width: 8),
                          Text(
                            "CORRIDOR COMPARISON",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppTheme.bgCardElevated),
                          dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppTheme.bgCardHover;
                            }
                            return AppTheme.bgCard;
                          }),
                          columnSpacing: 18,
                          horizontalMargin: 12,
                          columns: const [
                            DataColumn(label: Text("Route", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted))),
                            DataColumn(label: Text("Distance", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted))),
                            DataColumn(label: Text("Time", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted))),
                            DataColumn(label: Text("Route AQI", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted))),
                            DataColumn(label: Text("Predicted", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted))),
                            DataColumn(label: Text("PM2.5 Dose", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted))),
                          ],
                          rows: routeData.routes.map((r) {
                            final isSel = r.routeIndex == selectedRoute.routeIndex;
                            return DataRow(
                              selected: isSel,
                              onSelectChanged: (_) {
                                state.selectRoute(r.routeIndex - 1);
                              },
                              cells: [
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (r.isRecommended)
                                        const Icon(Icons.star, size: 13, color: AppTheme.accentSuccess),
                                      if (r.isRecommended) const SizedBox(width: 4),
                                      Text(
                                        r.name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                          color: isSel ? AppTheme.accentPrimary : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Text("${r.distanceKm.toStringAsFixed(1)} km", style: const TextStyle(fontSize: 11, fontFamily: "monospace"))),
                                DataCell(Text("${r.durationMinutes} min", style: const TextStyle(fontSize: 11, fontFamily: "monospace"))),
                                DataCell(Text(
                                  r.averageAqi.toStringAsFixed(0),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AqiColors.getColor(r.averageAqi), fontFamily: "monospace"),
                                )),
                                DataCell(Text(
                                  r.aiPredictedAqi.toStringAsFixed(0),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AqiColors.getColor(r.aiPredictedAqi), fontFamily: "monospace"),
                                )),
                                DataCell(Text(
                                  r.estimatedInhaledDose,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: r.isRecommended ? AppTheme.accentSuccess : AppTheme.textPrimary,
                                    fontFamily: "monospace",
                                  ),
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // -------------------------------------------------------------
                // 3. PM2.5 EXPOSURE & INHALED DOSAGE METHODOLOGY
                // -------------------------------------------------------------
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderMedium),
                    boxShadow: AppTheme.depthMedium,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.biotech_outlined, size: 16, color: AppTheme.accentPrimary),
                          SizedBox(width: 8),
                          Text(
                            "PM2.5 EXPOSURE METHODOLOGY",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Inhaled PM2.5 dose is calculated along the driving polyline using cumulative transit time and spatial pollution density:",
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCardElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderMedium),
                        ),
                        child: const Text(
                          "Dose (µg) = Mean PM2.5 Conc. (µg/m³) × Breathing Rate (0.014 m³/min) × Travel Time (mins)",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: "monospace",
                            color: AppTheme.accentPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "A route that is slightly longer in distance but avoids severe pollution hotspots can deliver a lower total inhaled dose, minimizing health risks for commuters.",
                        style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // -------------------------------------------------------------
                // 4. IDW SPATIAL AQI INTERPOLATION
                // -------------------------------------------------------------
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderMedium),
                    boxShadow: AppTheme.depthMedium,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.hub_outlined, size: 16, color: AppTheme.accentPrimary),
                          SizedBox(width: 8),
                          Text(
                            "IDW SPATIAL INTERPOLATION",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Inverse Distance Weighting (IDW with power p=2.0) computes continuous surface pollution estimates along every OSRM polyline point using real-time feeds from CPCB Delhi monitoring stations (Anand Vihar, RK Puram, Punjabi Bagh, IGI Airport, Mandir Marg, etc.).",
                        style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // -------------------------------------------------------------
                // 5. TRAFFIC DATA TRANSPARENT DISCLOSURE
                // -------------------------------------------------------------
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderMedium),
                    boxShadow: AppTheme.depthMedium,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "TRAFFIC DATA DISCLOSURE",
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              routeData.trafficLimitation,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCardElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
              fontFamily: "monospace",
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
