import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

/// Top-level Navigation Destination Definition
class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

/// Reusable Professional Application Shell
/// Features a prominent TOP-RIGHT navigation bar inspired by AI Engineering consoles
class AppShell extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final Widget child;

  static const List<NavItem> navItems = [
    NavItem(label: "OVERVIEW", icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard),
    NavItem(label: "ROUTES", icon: Icons.alt_route_outlined, activeIcon: Icons.alt_route),
    NavItem(label: "MAP", icon: Icons.map_outlined, activeIcon: Icons.map),
    NavItem(label: "EXPOSURE", icon: Icons.analytics_outlined, activeIcon: Icons.analytics),
    NavItem(label: "SYSTEM", icon: Icons.memory_outlined, activeIcon: Icons.memory),
  ];

  const AppShell({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, state, _) {
        final isOnline = state.isBackendOnline;
        final env = state.environment;
        final isFallback = env?.isFallback ?? false;

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: Column(
            children: [
              // -------------------------------------------------------------
              // TOP PROFESSIONAL NAVIGATION HEADER (NO BOTTOM NAVIGATION)
              // -------------------------------------------------------------
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  border: const Border(
                    bottom: BorderSide(color: AppTheme.borderMedium, width: 1.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isSingleLine = constraints.maxWidth >= 1050;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // LEFT: Application Brand & Subtitle
                                Expanded(
                                  child: _buildBrand(context),
                                ),

                                const SizedBox(width: 12),

                                // RIGHT: Navigation items on wide screen, or status cluster on all
                                if (isSingleLine) ...[
                                  _buildNavLinks(context, isCompact: false),
                                  const SizedBox(width: 18),
                                  Container(
                                    height: 22,
                                    width: 1,
                                    color: AppTheme.borderMedium,
                                  ),
                                  const SizedBox(width: 14),
                                ],
                                _buildStatusCluster(context, isOnline, isFallback, state, minimal: constraints.maxWidth < 850),
                              ],
                            ),
                          ),

                          // DEDICATED TOP HORIZONTAL NAVIGATION STRIP (When width < 1050)
                          if (!isSingleLine)
                            Container(
                              height: 42,
                              decoration: const BoxDecoration(
                                color: AppTheme.bgDark,
                                border: Border(
                                  top: BorderSide(color: Color(0x3326364D), width: 1.0),
                                ),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  children: List.generate(navItems.length, (index) {
                                    return _buildNavItemButton(
                                      navItems[index],
                                      index,
                                      isCompact: true,
                                    );
                                  }),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // -------------------------------------------------------------
              // MAIN VIEWPORT
              // -------------------------------------------------------------
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }

  /// Brand Identification with 3D Tech Emblem
  Widget _buildBrand(BuildContext context) {
    return InkWell(
      onTap: () => onTabSelected(0),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accentPrimary, AppTheme.accentSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.radar,
                color: Color(0xFF060A12),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "ENVIRONMENTAL INTELLIGENCE",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1),
                  Text(
                    "AI Air Quality & Smart Mobility",
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                      color: AppTheme.accentPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top Right Navigation Buttons Cluster
  Widget _buildNavLinks(BuildContext context, {required bool isCompact}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(navItems.length, (index) {
        return _buildNavItemButton(navItems[index], index, isCompact: isCompact);
      }),
    );
  }

  Widget _buildNavItemButton(NavItem item, int index, {required bool isCompact}) {
    final isSelected = index == currentIndex;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 3 : 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTabSelected(index),
          borderRadius: BorderRadius.circular(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 13,
              vertical: isCompact ? 6 : 7,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentPrimary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? AppTheme.accentPrimary : Colors.transparent,
                width: 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.accentPrimary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: isCompact ? 15 : 16,
                  color: isSelected ? AppTheme.accentPrimary : AppTheme.textSecondary,
                ),
                const SizedBox(width: 7),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: isCompact ? 11 : 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: 0.6,
                    color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Right Status Cluster (API Online + GPS status + Action icon)
  Widget _buildStatusCluster(
    BuildContext context,
    bool isOnline,
    bool isFallback,
    AppStateProvider state, {
    bool minimal = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!minimal) ...[
          // API Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isOnline ? AppTheme.accentSuccess : AppTheme.accentCritical).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (isOnline ? AppTheme.accentSuccess : AppTheme.accentCritical).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? AppTheme.accentSuccess : AppTheme.accentCritical,
                    boxShadow: [
                      BoxShadow(
                        color: (isOnline ? AppTheme.accentSuccess : AppTheme.accentCritical).withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOnline ? "API ONLINE" : "API OFFLINE",
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isOnline ? AppTheme.accentSuccess : AppTheme.accentCritical,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Location Mode Badge
          StatusBadge(
            label: isFallback ? "NCR FALLBACK" : "LIVE GPS",
            variant: isFallback ? StatusBadgeVariant.warning : StatusBadgeVariant.info,
            icon: isFallback ? Icons.location_city : Icons.gps_fixed,
            fontSize: 9.5,
          ),
          const SizedBox(width: 8),
        ],

        // Refresh Data Action
        IconButton(
          icon: Icon(
            Icons.refresh,
            size: 19,
            color: state.isLoadingEnvironment ? AppTheme.accentPrimary : AppTheme.textSecondary,
          ),
          tooltip: "Refresh Environmental Telemetry",
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: state.isLoadingEnvironment
              ? null
              : () => state.loadEnvironment(useGps: true),
        ),

        // System Settings / Architecture quick link
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 19, color: AppTheme.textSecondary),
          tooltip: "System Status & Model Architecture",
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () => onTabSelected(4), // Navigate to System Tab
        ),
      ],
    );
  }
}
