import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/app_state_provider.dart';
import '../widgets/status_badge.dart';
import '../utils/aqi_colors.dart';
import '../theme/app_theme.dart';

/// Screen 3 — Dedicated Full-Screen Interactive Delhi Route Map
class RouteMapScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const RouteMapScreen({super.key, this.onNavigateToTab});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final MapController _mapController = MapController();

  void _centerOnRoute(List<List<double>> polyline) {
    if (polyline.isEmpty) return;
    final mid = polyline[polyline.length ~/ 2];
    _mapController.move(LatLng(mid[0], mid[1]), 12.0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, state, child) {
        final routeData = state.routeData;
        final selectedRoute = state.selectedRoute;

        // Default Delhi Center coordinates
        LatLng initialCenter = const LatLng(28.6139, 77.2090);
        if (selectedRoute != null && selectedRoute.polyline.isNotEmpty) {
          final mid = selectedRoute.polyline[selectedRoute.polyline.length ~/ 2];
          initialCenter = LatLng(mid[0], mid[1]);
        } else if (state.environment != null) {
          initialCenter = LatLng(state.environment!.latitude, state.environment!.longitude);
        }

        // Build Polylines & Markers from actual backend results
        final List<Polyline> polylines = [];
        final List<Marker> markers = [];

        if (routeData != null && routeData.routes.isNotEmpty) {
          // 1. Unselected routes (muted technical grey/slate)
          for (int i = 0; i < routeData.routes.length; i++) {
            if (i == state.selectedRouteIndex) continue;
            final r = routeData.routes[i];
            polylines.add(
              Polyline(
                points: r.polyline.map((p) => LatLng(p[0], p[1])).toList(),
                strokeWidth: 4.0,
                color: const Color(0x6664748B),
              ),
            );
          }

          // 2. Selected route (prominent line colored by AQI severity)
          if (selectedRoute != null && selectedRoute.polyline.isNotEmpty) {
            final aqiColor = AqiColors.getColor(selectedRoute.averageAqi);
            polylines.add(
              Polyline(
                points: selectedRoute.polyline.map((p) => LatLng(p[0], p[1])).toList(),
                strokeWidth: 5.5,
                color: aqiColor,
              ),
            );

            // Origin Marker (Cyan)
            final origPt = selectedRoute.polyline.first;
            markers.add(
              Marker(
                point: LatLng(origPt[0], origPt[1]),
                width: 34,
                height: 34,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
                  ),
                  child: const Icon(Icons.my_location, color: Color(0xFF060A12), size: 18),
                ),
              ),
            );

            // Destination Marker (Critical Red)
            final destPt = selectedRoute.polyline.last;
            markers.add(
              Marker(
                point: LatLng(destPt[0], destPt[1]),
                width: 34,
                height: 34,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.accentCritical,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
                  ),
                  child: const Icon(Icons.place, color: Colors.white, size: 20),
                ),
              ),
            );
          }
        }

        return Stack(
          children: [
            // -------------------------------------------------------------
            // FULL-SCREEN FLUTTER MAP
            // -------------------------------------------------------------
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 11.5,
                minZoom: 8.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.aeromobility.ai',
                ),
                PolylineLayer(polylines: polylines),
                MarkerLayer(markers: markers),
              ],
            ),

            // -------------------------------------------------------------
            // FLOATING TOP INFORMATION PANEL
            // -------------------------------------------------------------
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderMedium, width: 1.0),
                  boxShadow: AppTheme.depthMedium,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions, size: 14, color: AppTheme.accentPrimary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  routeData != null
                                      ? "${routeData.origin} → ${routeData.destination}"
                                      : "Delhi Corridor Map (OSRM)",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (selectedRoute != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              "${selectedRoute.name} • ${selectedRoute.distanceKm.toStringAsFixed(1)} km • ${selectedRoute.durationMinutes} mins",
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppTheme.textSecondary,
                                fontFamily: "monospace",
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (routeData == null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        icon: const Icon(Icons.alt_route, size: 14, color: AppTheme.accentPrimary),
                        label: const Text(
                          "PLAN ROUTE",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accentPrimary),
                        ),
                        onPressed: () {
                          if (widget.onNavigateToTab != null) {
                            widget.onNavigateToTab!(1); // Go to Routes Tab
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),

            // -------------------------------------------------------------
            // FLOATING MAP CONTROLS (RIGHT SIDE)
            // -------------------------------------------------------------
            Positioned(
              right: 14,
              top: 80,
              child: Column(
                children: [
                  _buildMapButton(
                    icon: Icons.add,
                    tooltip: "Zoom In",
                    onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildMapButton(
                    icon: Icons.remove,
                    tooltip: "Zoom Out",
                    onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildMapButton(
                    icon: Icons.center_focus_strong,
                    tooltip: "Fit Route",
                    onTap: () {
                      if (selectedRoute != null) {
                        _centerOnRoute(selectedRoute.polyline);
                      }
                    },
                  ),
                ],
              ),
            ),

            // -------------------------------------------------------------
            // FLOATING BOTTOM ROUTE TELEMETRY & CORRIDOR SWITCHER
            // -------------------------------------------------------------
            if (routeData != null && routeData.routes.isNotEmpty && selectedRoute != null)
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderMedium, width: 1.0),
                    boxShadow: AppTheme.depthHigh,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Route Switcher Horizontal Strip
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(routeData.routes.length, (idx) {
                            final r = routeData.routes[idx];
                            final isSel = idx == state.selectedRouteIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(
                                  r.isRecommended ? "★ ${r.name}" : r.name,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                    color: isSel ? const Color(0xFF060A12) : AppTheme.textPrimary,
                                  ),
                                ),
                                selected: isSel,
                                selectedColor: AppTheme.accentPrimary,
                                backgroundColor: AppTheme.bgCardElevated,
                                side: BorderSide(
                                  color: isSel ? AppTheme.accentPrimary : AppTheme.borderMedium,
                                ),
                                onSelected: (_) => state.selectRoute(idx),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Route Metrics Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMetricColumn(
                            "ROUTE AQI",
                            selectedRoute.averageAqi.toStringAsFixed(0),
                            AqiColors.getColor(selectedRoute.averageAqi),
                          ),
                          _buildMetricColumn(
                            "AI PREDICTED",
                            selectedRoute.aiPredictedAqi.toStringAsFixed(0),
                            AqiColors.getColor(selectedRoute.aiPredictedAqi),
                          ),
                          _buildMetricColumn(
                            "PM2.5 DOSE",
                            selectedRoute.estimatedInhaledDose,
                            AppTheme.accentPrimary,
                          ),
                          StatusBadge(
                            label: selectedRoute.exposureLevel.toUpperCase(),
                            variant: selectedRoute.isRecommended
                                ? StatusBadgeVariant.success
                                : StatusBadgeVariant.warning,
                            fontSize: 8.5,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderMedium),
        boxShadow: AppTheme.depthLow,
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: AppTheme.textPrimary),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor,
            fontFamily: "monospace",
          ),
        ),
      ],
    );
  }
}
