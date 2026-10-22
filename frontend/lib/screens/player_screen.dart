import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_colors.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    // 15 seconds for a full rotation
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;

    if (song == null) {
      return const Scaffold(body: Center(child: Text('No song playing')));
    }

    // Start or stop the spin based on play state
    if (player.isPlaying) {
      _spinController.repeat();
    } else {
      _spinController.stop();
    }

    return Scaffold(
      backgroundColor: AppColors.darkBg, // Always dark for the immersive player
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing', style: TextStyle(fontSize: 14)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // ---- THE VINYL SPIN ----
            Expanded(
              flex: 5,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: RotationTransition(
                    turns: _spinController,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipOval(
                          child: Image.network(
                            song.coverUrl,
                            width: 300,
                            height: 300,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 300,
                              height: 300,
                              color: AppColors.darkSurface,
                              child: const Icon(Icons.music_note, size: 100),
                            ),
                          ),
                        ),
                        // Center hole of the vinyl
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.darkBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Title & Artist
            Text(
              song.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              song.artist,
              style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            // Progress Bar
            Slider(
              value: player.duration.inMilliseconds > 0
                  ? player.position.inMilliseconds.toDouble().clamp(0, player.duration.inMilliseconds.toDouble())
                  : 0,
              max: player.duration.inMilliseconds.toDouble() > 0 ? player.duration.inMilliseconds.toDouble() : 1,
              onChanged: (v) => player.seek(Duration(milliseconds: v.toInt())),
              activeColor: AppColors.primary,
              inactiveColor: Colors.white12,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(player.position), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(_fmt(player.duration), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                  onPressed: player.previous,
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.buttonGradient,
                  ),
                  child: IconButton(
                    iconSize: 36,
                    icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                    onPressed: player.togglePlayPause,
                  ),
                ),
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  onPressed: player.next,
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}