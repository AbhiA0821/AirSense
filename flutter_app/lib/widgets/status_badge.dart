import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StatusBadgeVariant { info, success, warning, critical, neutral, purple }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeVariant variant;
  final IconData? icon;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = StatusBadgeVariant.neutral,
    this.icon,
    this.fontSize = 10,
  });

  Color get _color {
    switch (variant) {
      case StatusBadgeVariant.info:
        return AppTheme.accentPrimary;
      case StatusBadgeVariant.success:
        return AppTheme.accentSuccess;
      case StatusBadgeVariant.warning:
        return AppTheme.accentWarning;
      case StatusBadgeVariant.critical:
        return AppTheme.accentCritical;
      case StatusBadgeVariant.purple:
        return AppTheme.accentSecondary;
      case StatusBadgeVariant.neutral:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: c,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
