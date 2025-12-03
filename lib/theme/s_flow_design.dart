import 'dart:ui';
import 'package:flutter/material.dart';

// ==========================================
// 1. 顏色系統 (Color System)
// ==========================================

class SFlowColors {
  final Color primary;
  final Color secondary;
  final Color glow;
  final Color text;
  final Color textDim;
  final Color glassBorder;
  final Color glassBg;
  final List<Color> bgGradient;
  final List<Color> accentGradient;

  const SFlowColors({
    required this.primary,
    required this.secondary,
    required this.glow,
    required this.text,
    required this.textDim,
    required this.glassBorder,
    required this.glassBg,
    required this.bgGradient,
    required this.accentGradient,
  });
}

class SFlowThemes {
  static final SFlowColors gold = SFlowColors(
    primary: const Color(0xFFFBBF24), // amber-400
    secondary: const Color(0xFFFDE68A), // yellow-200
    glow: const Color.fromRGBO(251, 191, 36, 0.4),
    text: const Color(0xFFFEF3C7), // amber-100
    textDim: const Color(0xFFFEF3C7).withOpacity(0.6),
    glassBorder: const Color(0xFFFBBF24).withOpacity(0.3),
    glassBg: const Color(0xFF000000).withOpacity(0.4), // 深色玻璃底
    bgGradient: [
      const Color(0xFF0F172A), // slate-900
      const Color(0xFF1C1917), // stone-900
      Colors.black,
    ],
    accentGradient: [const Color(0xFFF59E0B), const Color(0xFFFDE047)],
  );

  static final SFlowColors purple = SFlowColors(
    primary: const Color(0xFFA78BFA), // violet-400
    secondary: const Color(0xFFF0ABFC), // fuchsia-300
    glow: const Color.fromRGBO(167, 139, 250, 0.4),
    text: const Color(0xFFEDE9FE), // violet-100
    textDim: const Color(0xFFEDE9FE).withOpacity(0.6),
    glassBorder: const Color(0xFFA78BFA).withOpacity(0.3),
    glassBg: const Color(0xFF000000).withOpacity(0.4),
    bgGradient: [
      const Color(0xFF0F172A), // slate-900
      const Color(0xFF020617), // slate-950
      Colors.black,
    ],
    accentGradient: [const Color(0xFF7C3AED), const Color(0xFF818CF8)],
  );
}

// ==========================================
// 2. 玻璃擬態容器 (Glass Container)
// ==========================================

class GlassContainer extends StatelessWidget {
  final Widget child;
  final SFlowColors? colors; // 若為 null 則使用預設白/灰玻璃
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.colors,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // 如果沒有傳入 colors，使用通用的深色玻璃風格
    final borderColor = colors?.glassBorder ?? Colors.white.withOpacity(0.15);
    final bgColor = colors?.glassBg ?? Colors.white.withOpacity(0.08);
    final glowColor = colors?.glow.withOpacity(0.1) ?? Colors.transparent;

    Widget container = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: -5,
              ),
              if (colors != null)
                BoxShadow(
                  color: glowColor,
                  blurRadius: 15,
                  spreadRadius: 0,
                ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }
}

// ==========================================
// 3. 全域動態背景 (Global Background)
// ==========================================

class SFlowBackground extends StatelessWidget {
  final SFlowColors colors;
  final Widget child;

  const SFlowBackground({
    super.key,
    required this.colors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.bgGradient,
        ),
      ),
      child: Stack(
        fit: StackFit.expand, // 確保填滿
        children: [
          // 光暈 1 (右上)
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.secondary.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          // 光暈 2 (左下)
          Positioned(
            bottom: -50,
            left: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          // 內容
          child,
        ],
      ),
    );
  }
}