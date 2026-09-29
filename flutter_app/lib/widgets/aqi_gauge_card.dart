import 'package:flutter/material.dart';
import '../models/environment_model.dart';
import '../utils/aqi_colors.dart';
import '../theme/app_theme.dart';

/// Professional 3D-Inspired Live Air Quality Console & Location Panel
class AqiGaugeCard extends StatefulWidget {
  final EnvironmentResponse environment;
  final Function(String) onSearch;
  final VoidCallback onUseGps;

  const AqiGaugeCard({
    super.key,
    required this.environment,
    required this.onSearch,
    required this.onUseGps,
  });

  @override
  State<AqiGaugeCard> createState() => _AqiGaugeCardState();
}

class _AqiGaugeCardState extends State<AqiGaugeCard> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final env = widget.environment;
    final aqiVal = env.currentAqi;
    final aqiColor = AqiColors.getColor(aqiVal);
    final category = env.aqiCategory;
    final isFallback = env.isFallback;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderMedium, width: 1.0),
        boxShadow: AppTheme.depthMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -------------------------------------------------------------
          // 1. LOCATION FALLBACK OR LIVE GPS STATUS BANNER
          // -------------------------------------------------------------
          if (isFallback)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: const BoxDecoration(
                color: Color(0x22F59E0B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
                border: Border(
                  bottom: BorderSide(color: Color(0x44F59E0B), width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppTheme.accentWarning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "LOCATION FALLBACK",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: AppTheme.accentWarning,
                          ),
                        ),
                        Text(
                          env.fallbackReason.isNotEmpty
                              ? env.fallbackReason
                              : "Using fallback location because current GPS is unavailable.",
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.my_location, size: 13, color: AppTheme.accentPrimary),
                    label: const Text(
                      "RETRY GPS",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentPrimary,
                      ),
                    ),
                    onPressed: widget.onUseGps,
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: const BoxDecoration(
                color: Color(0x1A10B981),
                borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
                border: Border(
                  bottom: BorderSide(color: Color(0x3310B981), width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed, size: 14, color: AppTheme.accentSuccess),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "LIVE GPS LOCATION: ${env.cityName} (${env.latitude.toStringAsFixed(4)}° N, ${env.longitude.toStringAsFixed(4)}° E)",
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppTheme.accentSuccess,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: aqiColor,
                            boxShadow: [
                              BoxShadow(color: aqiColor.withValues(alpha: 0.6), blurRadius: 6),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "LIVE AIR QUALITY",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _showSearch ? Icons.close : Icons.search,
                            size: 17,
                            color: AppTheme.accentPrimary,
                          ),
                          tooltip: _showSearch ? "Close Search" : "Search Location",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () {
                            setState(() {
                              _showSearch = !_showSearch;
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.my_location, size: 17, color: AppTheme.accentPrimary),
                          tooltip: "Acquire Live GPS",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: widget.onUseGps,
                        ),
                      ],
                    ),
                  ],
                ),

                // Collapsible Search Bar
                if (_showSearch) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              hintText: "Search city or landmark (e.g. Pune, Delhi)...",
                              prefixIcon: Icon(Icons.search, size: 15, color: AppTheme.textMuted),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                widget.onSearch(val.trim());
                                setState(() {
                                  _showSearch = false;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          onPressed: () {
                            if (_searchController.text.trim().isNotEmpty) {
                              widget.onSearch(_searchController.text.trim());
                              setState(() {
                                _showSearch = false;
                              });
                            }
                          },
                          child: const Text("GO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // -------------------------------------------------------------
                // 3D ELEVATED METRIC HERO BOX
                // -------------------------------------------------------------
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCardElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: aqiColor.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: aqiColor.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Large AQI Display Container with Inner Glow
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppTheme.bgDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: aqiColor.withValues(alpha: 0.5), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: aqiColor.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              aqiVal != null ? aqiVal.toStringAsFixed(0) : "--",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: aqiColor,
                                fontFamily: "monospace",
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "AIR QUALITY INDEX",
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Metadata and Severity Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Severity Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: aqiColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: aqiColor.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: aqiColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // City & State/Country Name
                            Text(
                              env.locationName.isNotEmpty ? env.locationName : env.cityName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),

                            // Technical Details
                            Row(
                              children: [
                                const Icon(Icons.grain, size: 12, color: AppTheme.accentPrimary),
                                const SizedBox(width: 4),
                                Text(
                                  "Dominant: ${env.dominantPollutant}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accentPrimary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text("•", style: TextStyle(color: AppTheme.textMuted)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "${env.latitude.toStringAsFixed(3)}°, ${env.longitude.toStringAsFixed(3)}°",
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppTheme.textSecondary,
                                      fontFamily: "monospace",
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
