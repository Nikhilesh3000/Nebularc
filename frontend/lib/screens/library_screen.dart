import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/auth_service.dart';
import '../services/song_service.dart';
import '../theme/app_colors.dart';
import '../widgets/now_playing_pulse.dart';
import '../widgets/song_tile.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final username = auth.user?.username ?? 'Listener';

     return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------- Title ----------
                      Text(
                        'Your Library',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$username\'s collection',
                        style: TextStyle(fontSize: 13, color: subtleColor),
                      ),
                      const SizedBox(height: 20),

                      // ---------- Quick filter chips ----------
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(label: 'All', isActive: true),
                            _FilterChip(label: '❤️ Liked'),
                            _FilterChip(label: '⬇️ Downloaded'),
                            _FilterChip(label: '🎧 Recently Played'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ---------- Tab Bar ----------
                                            Container(
                        height: 48, // ← fixed height ensures TabBar gets proper constraints
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          // ← indicatorPadding REMOVED
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: subtleColor,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          unselectedLabelStyle: const TextStyle(fontSize: 13),
                          tabs: const [
                            Tab(text: 'Songs'),
                            Tab(text: 'Albums'),
                            Tab(text: 'Artists'),
                            Tab(text: 'Playlists'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: const [
                _SongsTab(),
                _AlbumsTab(),
                _ArtistsTab(),
                _PlaylistsTab(),
              ],
            ),
          ),
        ),
      ); 
  }
}

// ============================================================================
// Filter chip
// ============================================================================
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  const _FilterChip({required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: isActive ? AppColors.buttonGradient : null,
        color: isActive ? null : surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? Colors.transparent
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.pink.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? Colors.white : textColor,
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 1 — Songs (with Now Playing Pulse)
// ============================================================================
class _SongsTab extends StatelessWidget {
  const _SongsTab();

  @override
  Widget build(BuildContext context) {
    final songs = SongService.allSongs;
    final player = context.watch<PlayerProvider>();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 120),
      itemCount: songs.length,
      itemBuilder: (context, i) {
        final song = songs[i];
        final isCurrent = player.currentSong?.id == song.id;
        return _SongRow(
          song: song,
          isPlaying: isCurrent && player.isPlaying,
          isCurrent: isCurrent,
          queue: songs,
        );
      },
    );
  }
}

// ============================================================================
// Custom song row with Now Playing Pulse
// ============================================================================
class _SongRow extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final bool isCurrent;
  final List<Song> queue;

  const _SongRow({
    required this.song,
    required this.isPlaying,
    required this.isCurrent,
    required this.queue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return ListTile(
      onTap: () {
        context.read<PlayerProvider>().playSong(song, queue: queue);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              song.coverUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 50,
                color: isDark ? Colors.black26 : Colors.black12,
                child: const Icon(Icons.music_note, size: 20),
              ),
            ),
          ),
          if (isCurrent)
            Positioned(
              left: 4,
              bottom: 4,
              child: NowPlayingPulse(isPlaying: isPlaying, size: 10),
            ),
        ],
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
          color: isCurrent ? AppColors.primary : textColor,
        ),
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: subtleColor),
      ),
      trailing: Icon(
        isPlaying ? Icons.equalizer : Icons.play_arrow,
        color: isCurrent ? AppColors.primary : subtleColor,
        size: 20,
      ),
    );
  }
}

// ============================================================================
// TAB 2 — Albums
// ============================================================================
class _AlbumsTab extends StatelessWidget {
  const _AlbumsTab();

  @override
  Widget build(BuildContext context) {
    // Group songs by "album"
    final songs = SongService.allSongs;
    final Map<String, List<Song>> albums = {};
    for (final s in songs) {
      albums.putIfAbsent(s.album, () => []).add(s);
    }

    if (albums.isEmpty) {
      return const _EmptyState(
        icon: Icons.album_outlined,
        message: 'No albums yet',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: albums.length,
      itemBuilder: (context, i) {
        final entry = albums.entries.elementAt(i);
        return _AlbumCard(
          name: entry.key,
          songs: entry.value,
        );
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final String name;
  final List<Song> songs;
  const _AlbumCard({required this.name, required this.songs});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return GestureDetector(
      onTap: () {
        if (songs.isNotEmpty) {
          context.read<PlayerProvider>().playSong(songs.first, queue: songs);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                songs.first.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: isDark ? Colors.black26 : Colors.black12,
                  child: const Icon(Icons.album, size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            '${songs.length} ${songs.length == 1 ? "song" : "songs"}',
            style: TextStyle(fontSize: 11, color: subtleColor),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 3 — Artists
// ============================================================================
class _ArtistsTab extends StatelessWidget {
  const _ArtistsTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    // Group songs by artist
    final songs = SongService.allSongs;
    final Map<String, List<Song>> artists = {};
    for (final s in songs) {
      artists.putIfAbsent(s.artist, () => []).add(s);
    }

    if (artists.isEmpty) {
      return const _EmptyState(
        icon: Icons.person_outline,
        message: 'No artists yet',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      itemCount: artists.length,
      itemBuilder: (context, i) {
        final entry = artists.entries.elementAt(i);
        return GestureDetector(
          onTap: () {
            context
                .read<PlayerProvider>()
                .playSong(entry.value.first, queue: entry.value);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  backgroundImage: NetworkImage(entry.value.first.coverUrl),
                  child: entry.value.first.coverUrl.isEmpty
                      ? Text(
                          entry.key.isNotEmpty
                              ? entry.key[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entry.value.length} ${entry.value.length == 1 ? "song" : "songs"}',
                        style: TextStyle(fontSize: 11, color: subtleColor),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.play_circle_outline,
                    color: AppColors.primary, size: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// TAB 4 — Playlists
// ============================================================================
class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    // Mock playlists
    final playlists = [
      {
        'name': 'Late Night Vibes',
        'count': 12,
        'colors': [Color(0xFF8A2BE2), Color(0xFF4A148C)],
      },
      {
        'name': 'Workout Boost',
        'count': 24,
        'colors': [Color(0xFFE84393), Color(0xFF6C5CE7)],
      },
      {
        'name': 'Indie Chill',
        'count': 8,
        'colors': [Color(0xFF00D2D3), Color(0xFF0984E3)],
      },
      {
        'name': 'Retro Drive',
        'count': 16,
        'colors': [Color(0xFFFF9E55), Color(0xFFFF5CA8)],
      },
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      children: [
        // --- Create new playlist button ---
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create playlist — coming soon')),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Playlist',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Build your own vibe',
                      style: TextStyle(fontSize: 11, color: subtleColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // --- Existing playlists ---
        ...playlists.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: p['colors'] as List<Color>,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.queue_music,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['name'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p['count']} songs',
                          style:
                              TextStyle(fontSize: 11, color: subtleColor),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: subtleColor),
                ],
              ),
            )),
      ],
    );
  }
}

// ============================================================================
// Empty state
// ============================================================================
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final subtleColor = Theme.of(context).textTheme.bodySmall?.color ??
        Colors.white.withOpacity(0.5);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: subtleColor),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: subtleColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}