import 'package:flutter/material.dart';

/// Animated equalizer bars that pulse when a song is playing.
/// Overlays on top of the album art of the currently playing song.
class NowPlayingPulse extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double size;

  const NowPlayingPulse({
    super.key,
    this.isPlaying = true,
    this.color = Colors.white,
    this.size = 16,
  });

  @override
  State<NowPlayingPulse> createState() => _NowPlayingPulseState();
}

class _NowPlayingPulseState extends State<NowPlayingPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant NowPlayingPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
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
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(6),
          ),
          child: SizedBox(
            height: widget.size,
            width: widget.size * 1.4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(4, (i) {
                // Each bar has a phase offset
                final phase = (_controller.value + i * 0.25) % 1.0;
                // Triangle wave: 0 -> 1 -> 0
                final amplitude = 1.0 - (phase - 0.5).abs() * 2;
                final barHeight = (widget.size * (0.3 + 0.7 * amplitude));
                return Container(
                  width: 2.5,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}