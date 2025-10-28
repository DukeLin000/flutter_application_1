// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF030213),      // --primary
      onPrimary: Colors.white,         // --primary-foreground
      surface: Colors.white,           // --background / --card
      onSurface: Color(0xFF232323),    // --foreground (近似)
      secondary: Color(0xFFF2F2F6),    // --secondary
      onSecondary: Color(0xFF030213),  // --secondary-foreground
      error: Color(0xFFD4183D),        // --destructive
      onError: Colors.white,
      // 其餘依需求補齊
      tertiary: Color(0xFFE9EBEF),
      onTertiary: Color(0xFF030213),
      surfaceVariant: Color(0xFFF3F3F5),
      onSurfaceVariant: Color(0xFF717182),
      outline: Color(0x1A000000),      // --border (10% 黑)
      shadow: Colors.black12,
      inverseSurface: Color(0xFF232323),
      onInverseSurface: Colors.white,
    ),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFEDEDED),      // --primary (dark)
      onPrimary: Color(0xFF2E2E2E),    // --primary-foreground (dark)
      surface: Color(0xFF232323),      // --background (dark)
      onSurface: Color(0xFFF6F6F6),    // --foreground (dark)
      secondary: Color(0xFF444444),    // 取近似 --secondary (dark)
      onSecondary: Color(0xFFEDEDED),
      error: Color(0xFF8A1E1E),
      onError: Color(0xFFECCCCC),
      outline: Color(0xFF444444),
      shadow: Colors.black54,
      inverseSurface: Colors.white,
      onInverseSurface: Color(0xFF232323),
      tertiary: Color(0xFF3F3F3F),
      onTertiary: Color(0xFFEDEDED),
    ),
  );
}
