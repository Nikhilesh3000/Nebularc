import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final List<Song>? queue;
  final VoidCallback? onTap;

  const SongTile({
    super.key,
    required this.song,
    this.queue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final isCurrent = player.currentSong?.id == song.id;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          song.coverUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 56,
            height: 56,
            color: const Color(0xFF1A1A2E),
            child: const Icon(Icons.music_note, color: Colors.white54),
          ),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isCurrent ? const Color(0xFF6C5CE7) : Colors.white,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
      ),
      trailing: isCurrent && player.isPlaying
          ? const Icon(Icons.equalizer, color: Color(0xFF6C5CE7))
          : const Icon(Icons.play_arrow, color: Colors.white38),
      onTap: onTap ??
          () {
            context
                .read<PlayerProvider>()
                .playSong(song, queue: queue);
          },
    );
  }
}
