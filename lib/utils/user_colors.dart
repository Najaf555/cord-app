import 'package:flutter/material.dart';

const List<Color> userBorderColors = [
  Color(0xFFEB5757), // Red
  Color(0xFF27AE60), // Green
  Color(0xFF2F80ED), // Blue
  Color(0xFFFF833E), // Orange
  Color(0xFF9B51E0), // Purple
  Color(0xFF00B8A9), // Teal
  Color(0xFFFFC542), // Yellow
  Color(0xFF6A89CC), // Indigo
  Color(0xFFB33771), // Pink
  Color(0xFF218c5c), // Dark Green
  Color(0xFFE74C3C), // Bright Red
  Color(0xFF2ECC71), // Emerald
  Color(0xFF3498DB), // Sky Blue
  Color(0xFFF39C12), // Orange
  Color(0xFF8E44AD), // Purple
  Color(0xFF1ABC9C), // Turquoise
  Color(0xFFF1C40F), // Yellow
  Color(0xFF34495E), // Dark Blue
  Color(0xFFE91E63), // Pink
  Color(0xFF795548), // Brown
  Color(0xFF607D8B), // Blue Grey
  Color(0xFF9C27B0), // Deep Purple
  Color(0xFF3F51B5), // Indigo
  Color(0xFF2196F3), // Blue
  Color(0xFF00BCD4), // Cyan
  Color(0xFF009688), // Teal
  Color(0xFF4CAF50), // Green
  Color(0xFF8BC34A), // Light Green
  Color(0xFFCDDC39), // Lime
  Color(0xFFFFEB3B), // Yellow
  Color(0xFFFFC107), // Amber
  Color(0xFFFF9800), // Orange
  Color(0xFFFF5722), // Deep Orange
  Color(0xFF795548), // Brown
  Color(0xFF9E9E9E), // Grey
  Color(0xFF607D8B), // Blue Grey
];

Color getUserColor(String? id, String? name) {
  if (id != null && id.isNotEmpty) {
    return userBorderColors[id.hashCode % userBorderColors.length];
  } else if (name != null && name.isNotEmpty) {
    return userBorderColors[name.hashCode % userBorderColors.length];
  }
  return userBorderColors[0];
} 