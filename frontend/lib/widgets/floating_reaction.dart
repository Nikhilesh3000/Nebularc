import 'package:flutter/material.dart';
import 'dart:math';

class FloatingReaction extends StatefulWidget {
  final String emoji;
  final VoidCallback? onComplete;

  const FloatingReaction({
    super.key,
    required this.emoji,
    this.onComplete,
  });

  @override
  State<FloatingReaction> createState() => _FloatingReactionState();
}

class _FloatingReactionState extends State<FloatingReaction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late double _startX;
  late double _driftX;

  @override
  void initState() {
    super.initState();
    final rand = Random();
    _startX = 0.5 + (rand.nextDouble() - 0.5) * 0.6;
    _driftX = (rand.nextDouble() - 0.5) * 0.4;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        final yOffset = -(_controller.value * screenHeight * 0.6);
        final xOffset = _driftX * _controller.value * screenWidth;

        return Positioned(
          left: screenWidth * _startX + xOffset,
          bottom: 100 + (-yOffset),
          child: Opacity(
            opacity: _fadeAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 42),
              ),
            ),
          ),
        );
      },
    );
  }
}
