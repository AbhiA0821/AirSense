import 'package:flutter/material.dart';
import '../models/route_model.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

/// Professional AI Smart Mobility Recommendation Card with Selection Rationale
class RecommendationCard extends StatelessWidget {
  final SmartRecommendation recommendation;

  const RecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final rec = recommendation;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentSuccess.withValues(alpha: 0.4), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_outlined, color: AppTheme.accentSuccess, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "AI SMART MOBILITY RECOMMENDATION",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppTheme.accentSuccess,
                    ),
                  ),
                ],
              ),
              StatusBadge(
                label: "LOWEST DOSE",
                variant: StatusBadgeVariant.success,
                fontSize: 9,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route Name & Core Metrics
          Text(
            rec.recommendedRoute,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                "${rec.distanceKm.toStringAsFixed(1)} km",
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.accentPrimary,
                  fontWeight: FontWeight.w600,
                  fontFamily: "monospace",
                ),
              ),
              const Text(" • ", style: TextStyle(color: AppTheme.textMuted)),
              Text(
                "${rec.durationMinutes} mins",
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.accentPrimary,
                  fontWeight: FontWeight.w600,
                  fontFamily: "monospace",
                ),
              ),
              const Text(" • ", style: TextStyle(color: AppTheme.textMuted)),
              Text(
                "PM2.5: ${rec.pm25Exposure}",
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.accentSuccess,
                  fontWeight: FontWeight.w700,
                  fontFamily: "monospace",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Rationale Text Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgCardSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Text(
              rec.selectionRationale,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Disclaimer on Traffic Limitation
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rec.trafficLimitation,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
