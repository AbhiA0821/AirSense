import 'package:flutter/material.dart';

/// EPA-Compliant AQI Color and Category Utility
class AqiColors {
  static const Color good = Color(0xFF10B981);       // 0-50 Emerald Green
  static const Color moderate = Color(0xFFF59E0B);   // 51-100 Amber
  static const Color unhealthySensitive = Color(0xFFF97316); // 101-150 Orange
  static const Color unhealthy = Color(0xFFEF4444);   // 151-200 Red
  static const Color veryUnhealthy = Color(0xFFA855F7); // 201-300 Purple
  static const Color hazardous = Color(0xFF881337);   // 301+ Maroon
  static const Color unknown = Color(0xFF64748B);     // Slate Gray

  static Color getColor(double? aqi) {
    if (aqi == null) return unknown;
    if (aqi <= 50) return good;
    if (aqi <= 100) return moderate;
    if (aqi <= 150) return unhealthySensitive;
    if (aqi <= 200) return unhealthy;
    if (aqi <= 300) return veryUnhealthy;
    return hazardous;
  }

  static String getCategory(double? aqi) {
    if (aqi == null) return "Unknown";
    if (aqi <= 50) return "Good";
    if (aqi <= 100) return "Moderate";
    if (aqi <= 150) return "Unhealthy for Sensitive Groups";
    if (aqi <= 200) return "Unhealthy";
    if (aqi <= 300) return "Very Unhealthy";
    return "Hazardous";
  }
}
