import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class VibeMeter extends StatelessWidget {
  const VibeMeter({super.key});

  Color _energyColor(int energy) {
    if (energy < 30) return const Color(0xFF00D2D3); // chill blue
    if (energy < 60) return const Color(0xFF9B59B6); // purple
    if (energy < 85) return const Color(0xFFE84393); // pink
    return const Color(0xFFFF3838); // hot red
  }

  String _energyLabel(int energy) {
    if (energy == 0) return 'Waiting...';
    if (energy < 30) return 'Chill';
    if (energy < 60) return 'Groovy';
    if (energy < 85) return 'Hyped';
    return 'ON FIRE';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final energy = player.vibeEnergy;
    final label = _energyLabel(energy);
    final color = _energyColor(energy);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: color),
              const SizedBox(width: 6),
              const Text(
                'ROOM VIBE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (energy / 100).clamp(0.0, 1.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.4), color],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$energy%',
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${player.reactionCount} reactions',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
