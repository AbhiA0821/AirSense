import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/status_badge.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

/// Screen 5 — System & Model Status, Technical Architecture & Engine Health
class SystemInfoScreen extends StatelessWidget {
  const SystemInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, state, child) {
        final isOnline = state.isBackendOnline;
        final env = state.environment;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Screen Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SYSTEM & MODEL STATUS",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Microservice architecture, neural model pipeline & subsystem health.",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(
                    label: isOnline ? "CLUSTER OPERATIONAL" : "OFFLINE",
                    variant: isOnline ? StatusBadgeVariant.success : StatusBadgeVariant.critical,
                    fontSize: 8.5,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // -------------------------------------------------------------
              // 1. SUBSYSTEM STATUS 3D CONSOLE (PART 24)
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
                            Icon(Icons.hub_outlined, size: 16, color: AppTheme.accentPrimary),
                            SizedBox(width: 8),
                            Text(
                              "CORE ENGINE HEALTH",
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
                          "MILESTONE 1 + 2 + 3",
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

                    // FastAPI
                    _buildSubsystemRow(
                      icon: Icons.api,
                      title: "FastAPI REST Gateway",
                      subtitle: "High-performance async endpoints (:8000)",
                      statusText: isOnline ? "ONLINE" : "DISCONNECTED",
                      statusColor: isOnline ? AppTheme.accentSuccess : AppTheme.accentCritical,
                      isOperational: isOnline,
                    ),
                    const Divider(height: 18, color: AppTheme.borderMedium),

                    // PyTorch LSTM
                    _buildSubsystemRow(
                      icon: Icons.memory,
                      title: "PyTorch LSTM Neural Network",
                      subtitle: "Dual-layer LSTM +24h AQI predictive model",
                      statusText: isOnline ? "LOADED" : "OFFLINE",
                      statusColor: isOnline ? AppTheme.accentSuccess : AppTheme.accentWarning,
                      isOperational: isOnline,
                    ),
                    const Divider(height: 18, color: AppTheme.borderMedium),

                    // IDW Spatial AQI
                    _buildSubsystemRow(
                      icon: Icons.scatter_plot,
                      title: "IDW Spatial AQI Interpolation",
                      subtitle: "Mathematical surface modeling across Delhi stations",
                      statusText: isOnline ? "ACTIVE" : "STANDBY",
                      statusColor: isOnline ? AppTheme.accentSuccess : AppTheme.textMuted,
                      isOperational: isOnline,
                    ),
                    const Divider(height: 18, color: AppTheme.borderMedium),

                    // OSRM
                    _buildSubsystemRow(
                      icon: Icons.alt_route,
                      title: "OSRM Routing Engine",
                      subtitle: "Real-world driving route geometry & duration",
                      statusText: isOnline ? "ONLINE" : "STANDBY",
                      statusColor: isOnline ? AppTheme.accentSuccess : AppTheme.textMuted,
                      isOperational: isOnline,
                    ),
                    const Divider(height: 18, color: AppTheme.borderMedium),

                    // Geocoding
                    _buildSubsystemRow(
                      icon: Icons.travel_explore,
                      title: "Geocoding & Reverse Geocoding",
                      subtitle: "Nominatim OSM + Delhi verified landmark lookup",
                      statusText: "READY",
                      statusColor: AppTheme.accentSuccess,
                      isOperational: true,
                    ),
                    const Divider(height: 18, color: AppTheme.borderMedium),

                    // Location
                    _buildSubsystemRow(
                      icon: Icons.place_outlined,
                      title: "Location Services",
                      subtitle: env != null
                          ? (env.isFallback ? "Delhi NCR Fallback Active" : "Device GPS Active")
                          : "Ready",
                      statusText: "READY",
                      statusColor: AppTheme.accentSuccess,
                      isOperational: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 2. TECHNICAL ARCHITECTURE FLOW (PART 24)
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
                        Icon(Icons.account_tree_outlined, size: 16, color: AppTheme.accentPrimary),
                        SizedBox(width: 8),
                        Text(
                          "END-TO-END TECHNICAL ARCHITECTURE",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Architecture Nodes
                    _buildArchitectureStep(
                      stepNum: "1",
                      title: "Flutter Presentation Layer",
                      desc: "Professional 3D-inspired AI console with responsive top navigation and full Delhi smart mobility UI.",
                      color: AppTheme.accentPrimary,
                    ),
                    _buildArchArrow(),
                    _buildArchitectureStep(
                      stepNum: "2",
                      title: "FastAPI REST Gateway",
                      desc: "Unified asynchronous backend orchestrating feeds, caching, and serving endpoints at 127.0.0.1:8000.",
                      color: AppTheme.accentBlue,
                    ),
                    _buildArchArrow(),
                    _buildArchitectureStep(
                      stepNum: "3",
                      title: "Environmental Intelligence",
                      desc: "Real-time ingestion of CPCB station feeds, WAQI air quality, and Open-Meteo meteorological telemetry.",
                      color: AppTheme.accentEmerald,
                    ),
                    _buildArchArrow(),
                    _buildArchitectureStep(
                      stepNum: "4",
                      title: "PyTorch LSTM Forecast Engine",
                      desc: "Dual-layer LSTM neural network producing dynamic 24-hour continuous AQI predictions.",
                      color: AppTheme.accentSecondary,
                    ),
                    _buildArchArrow(),
                    _buildArchitectureStep(
                      stepNum: "5",
                      title: "IDW Spatial AQI Interpolation",
                      desc: "Inverse Distance Weighting (p=2.0) calculating continuous surface pollution levels along driving corridors.",
                      color: AppTheme.accentPrimary,
                    ),
                    _buildArchArrow(),
                    _buildArchitectureStep(
                      stepNum: "6",
                      title: "OSRM Driving Engine",
                      desc: "Real-world turn-by-turn driving polylines, durations, and multi-alternative corridor geometry.",
                      color: AppTheme.accentBlue,
                    ),
                    _buildArchArrow(),
                    _buildArchitectureStep(
                      stepNum: "7",
                      title: "Route Exposure & Recommendation",
                      desc: "Physiological inhaled PM2.5 dosage computation and smart health-risk minimization recommendation.",
                      color: AppTheme.accentSuccess,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 3. PYTORCH LSTM MODEL METADATA CARD (PART 9)
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology_outlined, size: 16, color: AppTheme.accentSecondary),
                            SizedBox(width: 8),
                            Text(
                              "PRODUCTION NEURAL MODEL SPECIFICATION",
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
                          label: "PYTORCH",
                          variant: StatusBadgeVariant.purple,
                          fontSize: 8.5,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildConfigItem("Model File", "backend/models/aqi_lstm_model.pth"),
                    _buildConfigItem("Scaler File", "backend/models/scaler.pkl"),
                    _buildConfigItem("Metadata File", "backend/models/model_metadata.json"),
                    _buildConfigItem("Architecture", "Dual-Layer LSTM (Hidden: 64, Dropout: 0.2, Linear Output)"),
                    _buildConfigItem("Sequence Length", "24 Hours Historical Context"),
                    _buildConfigItem("Input Features", "13 (AQI, PM2.5, PM10, NO2, CO, SO2, O3, Temp, Hum, Wind, Press, Hour, DoW)"),
                    _buildConfigItem("Evaluation Metrics", "MAE: ~12.4 | RMSE: ~16.8 (Valid test set)"),
                    _buildConfigItem("Gateway Base URL", ApiConfig.baseUrl),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubsystemRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String statusText,
    required Color statusColor,
    required bool isOperational,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 16, color: statusColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
                boxShadow: [
                  BoxShadow(color: statusColor.withValues(alpha: 0.6), blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: statusColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildArchitectureStep({
    required String stepNum,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCardElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              stepNum,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF060A12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchArrow() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Icon(Icons.arrow_downward, size: 14, color: AppTheme.borderMedium),
      ),
    );
  }

  Widget _buildConfigItem(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: "monospace",
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
