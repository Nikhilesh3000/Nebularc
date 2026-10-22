import '../models/song.dart';

class SongService {
  // Royalty-free test audio from SoundHelix
  static final List<Song> allSongs = [
    Song(
      id: 's1',
      title: 'Midnight Drive',
      artist: 'Nebula Sounds',
      album: 'Cosmic Nights',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      coverUrl: 'https://picsum.photos/seed/1/400',
      duration: const Duration(minutes: 5, seconds: 2),
    ),
    Song(
      id: 's2',
      title: 'Electric Dreams',
      artist: 'Aurora Beats',
      album: 'Neon Horizon',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      coverUrl: 'https://picsum.photos/seed/2/400',
      duration: const Duration(minutes: 4, seconds: 45),
    ),
    Song(
      id: 's3',
      title: 'Cosmic Waves',
      artist: 'Stellar Tune',
      album: 'Beyond Orbit',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      coverUrl: 'https://picsum.photos/seed/3/400',
      duration: const Duration(minutes: 6, seconds: 12),
    ),
    Song(
      id: 's4',
      title: 'Neon Pulse',
      artist: 'Retro Nights',
      album: 'Analog Heart',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      coverUrl: 'https://picsum.photos/seed/4/400',
      duration: const Duration(minutes: 5, seconds: 30),
    ),
    Song(
      id: 's5',
      title: 'Deep Space',
      artist: 'Cosmic Collective',
      album: 'Starlight',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
      coverUrl: 'https://picsum.photos/seed/5/400',
      duration: const Duration(minutes: 4, seconds: 15),
    ),
    Song(
      id: 's6',
      title: 'Aurora',
      artist: 'Skyline Echo',
      album: 'Northern Lights',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
      coverUrl: 'https://picsum.photos/seed/6/400',
      duration: const Duration(minutes: 5, seconds: 48),
    ),
  ];

  static List<Song> getTrending() => allSongs.take(4).toList();
  static List<Song> getRecentlyAdded() => allSongs.reversed.take(4).toList();
  static List<Song> search(String query) {
    if (query.isEmpty) return allSongs;
    final q = query.toLowerCase();
    return allSongs
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q))
        .toList();
  }
}
