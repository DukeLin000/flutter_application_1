import 'package:flutter/material.dart';

class AppTheme {
  // S-FLOW 風格是深色系的，我們將 Light 和 Dark 都統一為深色邏輯
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent, // ★ 關鍵：讓 Scaffold 透明
    
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFA78BFA),      // Violet-400 (預設紫)
      onPrimary: Colors.black,
      surface: Colors.transparent,     // ★ 卡片預設透明
      onSurface: Color(0xFFEDE9FE),    // Violet-100
      secondary: Color(0xFFF0ABFC),    // Fuchsia-300
      onSecondary: Colors.black,
      error: Color(0xFFEF4444),
      onError: Colors.white,
    ),
    
    // AppBar 透明化
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20, 
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    ),

    // Card 透明化
    // 修正：確保 const 結構正確
    // 0x0DFFFFFF = White 5%
    // 0x1AFFFFFF = White 10%
    cardTheme: CardThemeData(
      color: const Color(0x0DFFFFFF), 
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // 修正：這裡移除了 const，因為 BorderRadius.circular 不是 const
        // 但 Color 仍然可以是 const
        side: const BorderSide(color: Color(0x1AFFFFFF)),
      ),
    ),

    // Bottom Navigation Bar (玻璃感)
    // 0xCC0F172A = Slate-900 80%
    // 0x33A78BFA = Primary 20%
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xCC0F172A), 
      indicatorColor: const Color(0x33A78BFA),
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      iconTheme: MaterialStateProperty.all(
        const IconThemeData(color: Colors.white),
      ),
    ),

    // 輸入框樣式
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x0DFFFFFF), // White 5%
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1AFFFFFF)), // White 10%
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFA78BFA)),
      ),
      hintStyle: const TextStyle(color: Colors.white38),
      labelStyle: const TextStyle(color: Colors.white70),
    ),
  );

  // 為了方便，Light 也可以指向 Dark，確保風格不跑掉
  static final light = dark; 
}