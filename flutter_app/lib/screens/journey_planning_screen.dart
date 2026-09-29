import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/route_alternative_card.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/status_badge.dart';
import '../theme/app_theme.dart';

/// Screen 2 — Dedicated Delhi Smart Mobility & Route Planning Screen
class JourneyPlanningScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const JourneyPlanningScreen({super.key, this.onNavigateToTab});

  @override
  State<JourneyPlanningScreen> createState() => _JourneyPlanningScreenState();
}

class _JourneyPlanningScreenState extends State<JourneyPlanningScreen> {
  final TextEditingController _originController = TextEditingController(text: "IGI Airport");
  final TextEditingController _destController = TextEditingController(text: "Connaught Place");

  String? _delhiValidationError;

  // Supported Delhi Landmarks & Monitoring Corridors
  static const List<String> _delhiLocations = [
    "IGI Airport",
    "Connaught Place",
    "India Gate",
    "Red Fort",
    "New Delhi Railway Station",
    "Qutub Minar",
    "Lotus Temple",
    "Humayun's Tomb",
    "Rashtrapati Bhavan",
    "Akshardham Temple",
    "Chandni Chowk",
    "Dwarka",
    "Rohini",
    "Saket",
    "Hauz Khas",
    "Karol Bagh",
    "Lajpat Nagar",
    "Mayur Vihar",
  ];

  static const List<String> _quickLocations = [
    "Airport",
    "Connaught Place",
    "India Gate",
    "Red Fort",
  ];

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    super.dispose();
  }

  /// Normalize quick location text to full recognized Delhi landmark
  String _normalizeLocation(String loc) {
    final lower = loc.trim().toLowerCase();
    if (lower == "airport" || lower.contains("igi")) return "IGI Airport";
    if (lower == "cp" || lower.contains("connaught")) return "Connaught Place";
    if (lower.contains("india gate")) return "India Gate";
    if (lower.contains("red fort")) return "Red Fort";
    return loc.trim();
  }

  /// Validates whether the search input corresponds to supported Delhi geography
  bool _isDelhiLocation(String loc) {
    final clean = loc.trim().toLowerCase();
    if (clean.isEmpty) return false;

    // Known keywords for non-Delhi locations
    final nonDelhiKeywords = [
      "mumbai", "pune", "bangalore", "bengaluru", "chennai", "kolkata",
      "hyderabad", "ahmedabad", "jaipur", "lucknow", "chandigarh", "london",
      "new york", "paris", "california", "tokyo", "dubai"
    ];

    for (final kw in nonDelhiKeywords) {
      if (clean.contains(kw)) {
        return false;
      }
    }
    return true;
  }

  void _triggerAnalysis(AppStateProvider state) {
    setState(() {
      _delhiValidationError = null;
    });

    final origin = _normalizeLocation(_originController.text);
    final dest = _normalizeLocation(_destController.text);

    if (dest.isEmpty) {
      setState(() {
        _delhiValidationError = "Please select or search a destination landmark in Delhi.";
      });
      return;
    }

    if (!_isDelhiLocation(origin) || !_isDelhiLocation(dest)) {
      setState(() {
        _delhiValidationError = "Smart Mobility currently supports Delhi locations.";
      });
      return;
    }

    state.analyzeRoute(origin: origin, destination: dest);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, state, child) {
        final routeData = state.routeData;

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
                        "SMART ROUTE PLANNING",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Delhi environmental route intelligence & exposure minimization.",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(
                    label: "DELHI ONLY",
                    variant: StatusBadgeVariant.info,
                    icon: Icons.location_city,
                    fontSize: 8.5,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // -------------------------------------------------------------
              // 1. ORIGIN & DESTINATION CONFIGURATION CONSOLE
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.alt_route, size: 16, color: AppTheme.accentPrimary),
                            SizedBox(width: 8),
                            Text(
                              "DELHI JOURNEY PARAMETERS",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "OSRM ENGINE",
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Validation Alert (Outside Delhi or Missing Input)
                    if (_delhiValidationError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0x22EF4444),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x66EF4444)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.accentCritical),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _delhiValidationError!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentCritical,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ORIGIN FIELD (Dropdown + Search)
                    const Text(
                      "ORIGIN (DELHI)",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _originController,
                            style: const TextStyle(fontSize: 12.5, color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              hintText: "Enter Delhi origin or choose below...",
                              prefixIcon: Icon(Icons.my_location, color: AppTheme.accentPrimary, size: 16),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: Container(
                            height: 42,
                            width: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.bgCardElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderMedium),
                            ),
                            child: const Icon(Icons.arrow_drop_down, color: AppTheme.accentPrimary, size: 22),
                          ),
                          tooltip: "Select Delhi Origin",
                          color: AppTheme.bgCardElevated,
                          onSelected: (val) {
                            setState(() {
                              _originController.text = val;
                              _delhiValidationError = null;
                            });
                          },
                          itemBuilder: (context) => _delhiLocations.map((loc) {
                            return PopupMenuItem<String>(
                              value: loc,
                              child: Text(loc, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Quick Origin Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _quickLocations.map((q) {
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AppTheme.bgCardElevated,
                          side: const BorderSide(color: AppTheme.borderMedium),
                          label: Text(
                            q,
                            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
                            setState(() {
                              _originController.text = _normalizeLocation(q);
                              _delhiValidationError = null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // DESTINATION FIELD (Dropdown + Search)
                    const Text(
                      "DESTINATION (DELHI)",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _destController,
                            style: const TextStyle(fontSize: 12.5, color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              hintText: "Enter Delhi destination or choose below...",
                              prefixIcon: Icon(Icons.place_outlined, color: AppTheme.accentCritical, size: 16),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: Container(
                            height: 42,
                            width: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.bgCardElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderMedium),
                            ),
                            child: const Icon(Icons.arrow_drop_down, color: AppTheme.accentPrimary, size: 22),
                          ),
                          tooltip: "Select Delhi Destination",
                          color: AppTheme.bgCardElevated,
                          onSelected: (val) {
                            setState(() {
                              _destController.text = val;
                              _delhiValidationError = null;
                            });
                          },
                          itemBuilder: (context) => _delhiLocations.map((loc) {
                            return PopupMenuItem<String>(
                              value: loc,
                              child: Text(loc, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Quick Destination Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _quickLocations.map((q) {
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AppTheme.bgCardElevated,
                          side: const BorderSide(color: AppTheme.borderMedium),
                          label: Text(
                            q,
                            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
                            setState(() {
                              _destController.text = _normalizeLocation(q);
                              _delhiValidationError = null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ANALYZE ROUTES PRIMARY BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        icon: state.isAnalyzingRoute
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF060A12),
                                ),
                              )
                            : const Icon(Icons.analytics_outlined, size: 17),
                        label: Text(
                          state.isAnalyzingRoute ? "COMPUTING ENVIRONMENTAL DOSAGE..." : "ANALYZE ROUTES",
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                        ),
                        onPressed: state.isAnalyzingRoute ? null : () => _triggerAnalysis(state),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 2. ROUTE RESULTS DISPLAY (RECOMMENDED + ALTERNATIVES)
              // -------------------------------------------------------------
              if (state.isAnalyzingRoute) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: LoadingStateView(
                    message: "Querying OSRM driving geometry & calculating spatial IDW exposure...",
                  ),
                ),
              ] else if (state.routeError != null) ...[
                EmptyStateView(
                  icon: Icons.error_outline,
                  iconColor: AppTheme.accentCritical,
                  title: "Route Analysis Failed",
                  description: state.routeError!,
                  actionLabel: "RETRY",
                  onAction: () => _triggerAnalysis(state),
                ),
              ] else if (routeData != null && routeData.routes.isNotEmpty) ...[
                // Recommended Route Card
                if (routeData.recommendation != null) ...[
                  RecommendationCard(
                    recommendation: routeData.recommendation!,
                  ),
                  const SizedBox(height: 12),
                ],

                // Quick Navigation Actions on Results
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.map_outlined, size: 15, color: AppTheme.accentPrimary),
                        label: const Text(
                          "VIEW ON MAP",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accentPrimary),
                        ),
                        onPressed: () {
                          if (widget.onNavigateToTab != null) {
                            widget.onNavigateToTab!(2); // Go to Map Tab
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.analytics_outlined, size: 15, color: AppTheme.accentSecondary),
                        label: const Text(
                          "EXPOSURE DETAILS",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accentSecondary),
                        ),
                        onPressed: () {
                          if (widget.onNavigateToTab != null) {
                            widget.onNavigateToTab!(3); // Go to Exposure Tab
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Corridor Alternatives Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "EVALUATED ROUTE ALTERNATIVES",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      "${routeData.routes.length} Corridors",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Alternative Route Cards
                ...routeData.routes.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final r = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RouteAlternativeCard(
                      route: r,
                      isSelected: idx == state.selectedRouteIndex,
                      onTap: () => state.selectRoute(idx),
                      onViewOnMap: () {
                        state.selectRoute(idx);
                        if (widget.onNavigateToTab != null) {
                          widget.onNavigateToTab!(2);
                        }
                      },
                      onExposureDetails: () {
                        state.selectRoute(idx);
                        if (widget.onNavigateToTab != null) {
                          widget.onNavigateToTab!(3);
                        }
                      },
                    ),
                  );
                }),
              ] else ...[
                // Initial Empty State
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCardElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderMedium),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.explore_outlined, size: 36, color: AppTheme.accentPrimary),
                      const SizedBox(height: 12),
                      const Text(
                        "Delhi Environmental Mobility Ready",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Select Origin and Destination to analyze driving routes using spatial IDW air quality and PyTorch LSTM predictions.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary, height: 1.35),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text("ANALYZE AIRPORT → CONNAUGHT PLACE"),
                        onPressed: () {
                          _originController.text = "IGI Airport";
                          _destController.text = "Connaught Place";
                          _triggerAnalysis(state);
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
