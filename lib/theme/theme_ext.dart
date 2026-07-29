import 'package:flutter/material.dart';

extension ThemeExt on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Background and primary scaffold layout color
  Color get bgColor => isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

  // Cards, panels, and input fields color
  Color get cardColor => isDark ? const Color(0xFF1E293B) : Colors.white;

  // Grouped setting cards containers color
  Color get containerColor => isDark ? const Color(0xFF1F1F27) : const Color(0xFFF1F5F9);

  // Text colors
  Color get textColor => isDark ? const Color(0xFFE4E1ED) : const Color(0xFF1E293B);
  Color get secondaryTextColor => isDark ? const Color(0xFFC7C4D7) : const Color(0xFF64748B);
}
