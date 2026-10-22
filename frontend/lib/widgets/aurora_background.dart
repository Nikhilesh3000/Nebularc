import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AuroraBackground extends StatefulWidget {
  final Widget child;

  const AuroraBackground({super.key, required this.child});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Palettes (Slightly more vibrant for both themes)
  // ---------------------------------------------------------------------------
  List<Color> _pinkPalette(bool isDark) => isDark
      ? const [Color(0xFFFF9DD1), Color(0xFFFF6BB8)] // Brighter pink
      : const [Color(0xFFFF5CA8), Color(0xFFFF3B91)]; // Deeper pink for light mode

  List<Color> _bluePalette(bool isDark) => isDark
      ? const [Color(0xFF8EDFFF), Color(0xFF5DCCFA)] // Brighter blue
      : const [Color(0xFF4AB8E8), Color(0xFF2B9BCE)];

  List<Color> _purplePalette(bool isDark) => isDark
      ? const [Color(0xFFB98CFF), Color(0xFF9455F5)] // Brighter purple
      : const [Color(0xFF9B63F0), Color(0xFF7D3ED6)];

  List<Color> _peachPalette(bool isDark) => isDark
      ? const [Color(0xFFFFC79C), Color(0xFFFF9D5C)] // Brighter peach
      : const [Color(0xFFFF9E55), Color(0xFFED802B)];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Increased base opacity to make the lights pop
    final opacityBoost = isDark ? 1.2 : 1.4;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            child: widget.child,
            builder: (context, child) {
              final t = _controller.value * 2 * pi;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // --- Pink Beam (Top-Left) ---
                  Positioned(
                    top: -120 + sin(t) * 80,
                    left: -screenWidth * 0.10 + cos(t) * 120,
                    child: _Blob(
                      colors: _pinkPalette(isDark),
                      width: 450,
                      height: 200,
                      rotation: t * 0.8,
                      // INCREASED OPACITY
                      opacity: (isDark ? 0.65 : 0.90) * opacityBoost,
                    ),
                  ),

                  // --- Blue Beam (Top-Right) ---
                  Positioned(
                    top: -100 + cos(t + 1.5) * 100,
                    right: -screenWidth * 0.05 + sin(t + 1.5) * 120,
                    child: _Blob(
                      colors: _bluePalette(isDark),
                      width: 420,
                      height: 220,
                      rotation: -t * 1.2,
                      // INCREASED OPACITY
                      opacity: (isDark ? 0.60 : 0.95) * opacityBoost,
                    ),
                  ),

                  // --- Purple Beam (Center-Left) ---
                  Positioned(
                    top: screenHeight * 0.20 + sin(t + 3.0) * 120,
                    left: screenWidth * 0.05 + cos(t + 3.0) * 150,
                    child: _Blob(
                      colors: _purplePalette(isDark),
                      width: 400,
                      height: 250,
                      rotation: t * 1.0,
                      // INCREASED OPACITY
                      opacity: (isDark ? 0.55 : 0.90) * opacityBoost,
                    ),
                  ),

                  // --- Peach Beam (Center-Right) ---
                  Positioned(
                    top: screenHeight * 0.35 + cos(t + 4.5) * 130,
                    left: screenWidth * 0.45 + sin(t + 4.5) * 140,
                    child: _Blob(
                      colors: _peachPalette(isDark),
                      width: 380,
                      height: 200,
                      rotation: -t * 0.9,
                      // INCREASED OPACITY
                      opacity: (isDark ? 0.50 : 0.95) * opacityBoost,
                    ),
                  ),

                  // --- Lower Pink Beam (Bottom) ---
                  Positioned(
                    bottom: -80 + sin(t + 1.0) * 100,
                    left: screenWidth * 0.25 + cos(t + 1.0) * 160,
                    child: _Blob(
                      colors: _pinkPalette(isDark),
                      width: 450,
                      height: 220,
                      rotation: t * 1.5,
                      // INCREASED OPACITY
                      opacity: (isDark ? 0.45 : 0.90) * opacityBoost,
                    ),
                  ),

                  child!,
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Blob Widget (Tighter Gradient for brightness)
// ============================================================================
class _Blob extends StatelessWidget {
  final List<Color> colors;
  final double width;
  final double height;
  final double rotation;
  final double opacity;

  const _Blob({
    required this.colors,
    required this.width,
    required this.height,
    required this.rotation,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final safeOpacity = opacity.clamp(0.0, 1.0);

    return IgnorePointer(
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              // Holding the color longer before fading to 0
              colors: [
                colors[0].withOpacity(safeOpacity),
                colors[0].withOpacity(safeOpacity * 0.85), // Was 0.6
                colors[1].withOpacity(safeOpacity * 0.40), // Was 0.2
                colors[1].withOpacity(0.0),
              ],
              // Tighter stops to make the core much brighter
              stops: const [0.0, 0.35, 0.65, 1.0], 
            ),
          ),
        ),
      ),
    );
  }
}