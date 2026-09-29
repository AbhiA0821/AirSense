import 'package:flutter/material.dart';
import '../models/route_model.dart';
import '../utils/aqi_colors.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

/// Professional Technical Card displaying a single Route Alternative with IDW AQI and Inhaled Dose
class RouteAlternativeCard extends StatelessWidget {
  final RouteAlternative route;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onViewOnMap;
  final VoidCallback? onExposureDetails;

  const RouteAlternativeCard({
    super.key,
    required this.route,
    required this.isSelected,
    required this.onTap,
    this.onViewOnMap,
    this.onExposureDetails,
  });

  @override
  Widget build(BuildContext context) {
    final aqiColor = AqiColors.getColor(route.averageAqi);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.bgCardHover : AppTheme.bgCardSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentPrimary
                : (route.isRecommended ? AppTheme.accentSuccess.withValues(alpha: 0.5) : AppTheme.borderSubtle),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Index, Route Name & Recommended Badge
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppTheme.accentPrimary : AppTheme.bgDark,
                    border: Border.all(
                      color: isSelected ? AppTheme.accentPrimary : AppTheme.borderMedium,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "${route.routeIndex}",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (route.isRecommended)
                  const StatusBadge(
                    label: "RECOMMENDED",
                    variant: StatusBadgeVariant.success,
                    icon: Icons.star,
                    fontSize: 9,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Distance & Travel Time Row
            Row(
              children: [
                const Icon(Icons.directions_car_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  "${route.distanceKm.toStringAsFixed(1)} km",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontFamily: "monospace",
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.schedule, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  "${route.durationMinutes} mins",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontFamily: "monospace",
                  ),
                ),
                const Spacer(),
                Text(
                  route.exposureLevel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: aqiColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // AQI & PM2.5 Inhaled Dose Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: aqiColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Route AQI: ${route.averageAqi.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: aqiColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "(Pred: ${route.aiPredictedAqi.toStringAsFixed(0)})",
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "Dose: ${route.estimatedInhaledDose}",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentPrimary,
                      fontFamily: "monospace",
                    ),
                  ),
                ],
              ),
            ),

            // Contextual Actions if selected
            if (isSelected && (onViewOnMap != null || onExposureDetails != null)) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (onViewOnMap != null)
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.map_outlined, size: 14, color: AppTheme.accentPrimary),
                          label: const Text(
                            "View on Map",
                            style: TextStyle(fontSize: 11, color: AppTheme.accentPrimary),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: const BorderSide(color: AppTheme.borderHighlight),
                          ),
                          onPressed: onViewOnMap,
                        ),
                      ),
                    ),
                  if (onViewOnMap != null && onExposureDetails != null)
                    const SizedBox(width: 8),
                  if (onExposureDetails != null)
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.analytics_outlined, size: 14, color: AppTheme.textSecondary),
                          label: const Text(
                            "Exposure Details",
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: const BorderSide(color: AppTheme.borderMedium),
                          ),
                          onPressed: onExposureDetails,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
