import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class ReactionBar extends StatelessWidget {
  const ReactionBar({super.key});

  static const reactions = [
    {'type': 'love', 'emoji': '❤️'},
    {'type': 'fire', 'emoji': '🔥'},
    {'type': 'laugh', 'emoji': '😂'},
    {'type': 'party', 'emoji': '🎉'},
    {'type': 'wow', 'emoji': '😮'},
  ];

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    if (!player.hasSong) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: reactions.map((r) {
          final type = r['type']!;
          final emoji = r['emoji']!;
          return _ReactionButton(
            emoji: emoji,
            onTap: () => player.sendReaction(type),
          );
        }).toList(),
      ),
    );
  }
}

class _ReactionButton extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;

  const _ReactionButton({required this.emoji, required this.onTap});

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Text(
            widget.emoji,
            style: const TextStyle(fontSize: 26),
          ),
        ),
      ),
    );
  }
}
