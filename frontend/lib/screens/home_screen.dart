import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/song_service.dart';
import '../services/rooms_history_service.dart';
import '../theme/app_colors.dart';
import '../widgets/live_orbit_card.dart';
import '../widgets/now_playing_pulse.dart';
import '../widgets/section_header.dart';
import '../providers/nav_provider.dart';
import 'room_screen.dart';
import 'rooms_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<RecentRoom> _recentRooms = [];

  @override
  void initState() {
    super.initState();
    _loadRecentRooms();
  }

  Future<void> _loadRecentRooms() async {
    final rooms = await RoomsHistoryService.getRooms();
    if (mounted) {
      setState(() => _recentRooms = rooms.take(5).toList());
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SocketService>();
    final auth = context.watch<AuthService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor = isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    final username = auth.user?.username ?? 'Listener';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final activeListeners = service.exploreData?.totalActiveListeners ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecentRooms,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_greeting()}, $username 🧑',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: subtleColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Listen together\nanywhere',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.read<NavProvider>().setIndex(3),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.buttonGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.pink.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Live Pill
              if (activeListeners > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RoomsScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(isDark ? 0.15 : 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PulseDot(color: Colors.green),
                            const SizedBox(width: 6),
                            Text(
                              '$activeListeners ${activeListeners == 1 ? "listener" : "listeners"} active now',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Hero Buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      _PillButton(
                        label: 'Join Room',
                        gradient: AppColors.buttonGradient,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RoomsScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _PillButton(
                        label: 'Solo Listen',
                        gradient: AppColors.buttonGradient,
                        onTap: () {
                          final all = SongService.allSongs;
                          if (all.isNotEmpty) {
                            context.read<PlayerProvider>().playSong(all.first, queue: all);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Your Rooms
              if (_recentRooms.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SectionHeader(title: '🎧 Your Rooms')),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _recentRooms.length,
                      itemBuilder: (context, i) => _RecentRoomCard(room: _recentRooms[i]),
                    ),
                  ),
                ),
              ],

              // Trending Now
              const SliverToBoxAdapter(child: SectionHeader(title: 'Trending Now')),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: SongService.getTrending().length,
                    itemBuilder: (context, i) => _TrendingCard(
                      song: SongService.getTrending()[i],
                      queue: SongService.getTrending(),
                    ),
                  ),
                ),
              ),

              // Live Orbit
              const SliverToBoxAdapter(child: SectionHeader(title: 'Live Orbit')),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 195,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _OrbitItem(
                      user: _mockOrbit[i]['user']!,
                      title: _mockOrbit[i]['title']!,
                      artist: _mockOrbit[i]['artist']!,
                      cover: _mockOrbit[i]['cover']!,
                    ),
                    childCount: _mockOrbit.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    ); // <--- 3 closing brackets for Scaffold, SafeArea, RefreshIndicator
  }
}

// ============================================================================
// Recently Played Room Card
// ============================================================================
class _RecentRoomCard extends StatelessWidget {
  final RecentRoom room;
  const _RecentRoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor = isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return GestureDetector(
      onTap: () {
        final service = context.read<SocketService>();
        void listener() {
          if (service.currentRoom != null) {
            service.removeListener(listener);
            if (context.mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomScreen()));
            }
          }
        }
        service.addListener(listener);
        service.joinRoom(room.code);
        Future.delayed(const Duration(seconds: 5), () => service.removeListener(listener));
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(gradient: AppColors.buttonGradient, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: const Text('🎧', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 10),
            Text(room.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 2),
            Text('#${room.code}', style: TextStyle(fontSize: 11, color: subtleColor)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Pulse Dot
// ============================================================================
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.4 + 0.6 * _controller.value),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: widget.color.withOpacity(0.5 * _controller.value), blurRadius: 8, spreadRadius: 1)],
          ),
        );
      },
    );
  }
}

// ============================================================================
// Pill button
// ============================================================================
class _PillButton extends StatelessWidget {
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _PillButton({required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppColors.pink.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ============================================================================
// Trending card
// ============================================================================
class _TrendingCard extends StatelessWidget {
  final Song song;
  final List<Song> queue;
  const _TrendingCard({required this.song, required this.queue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor = isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    final player = context.watch<PlayerProvider>();
    final isCurrent = player.currentSong?.id == song.id;
    final isPlaying = isCurrent && player.isPlaying;

    return GestureDetector(
      onTap: () => context.read<PlayerProvider>().playSong(song, queue: queue),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: isCurrent ? Border.all(color: AppColors.primary, width: 1.5) : null,
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    song.coverUrl,
                    width: 114,
                    height: 114,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 114, height: 114, color: isDark ? Colors.black26 : Colors.black12, child: const Icon(Icons.music_note),
                    ),
                  ),
                ),
                if (isCurrent) Positioned(left: 6, bottom: 6, child: NowPlayingPulse(isPlaying: isPlaying)),
              ],
            ),
            const SizedBox(height: 8),
            Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isCurrent ? AppColors.primary : textColor)),
            Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: subtleColor)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Orbit item
// ============================================================================
class _OrbitItem extends StatelessWidget {
  final String user;
  final String title;
  final String artist;
  final String cover;

  const _OrbitItem({required this.user, required this.title, required this.artist, required this.cover});

  @override
  Widget build(BuildContext context) {
    return LiveOrbitCard(
      username: user,
      songTitle: title,
      songArtist: artist,
      songCoverUrl: cover,
      onListenTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Joining $user's room...")));
      },
    );
  }
}

final _mockOrbit = [
  {'user': 'Aisha', 'title': 'Pink + White', 'artist': 'Frank Ocean', 'cover': 'https://picsum.photos/seed/pink/200'},
  {'user': 'Rohan', 'title': 'Tame Impala', 'artist': 'Tame Impala', 'cover': 'https://picsum.photos/seed/tame/200'},
  {'user': 'Aisha', 'title': 'Proeteia', 'artist': 'Proeteia', 'cover': 'https://picsum.photos/seed/pro/200'},
  {'user': 'Rohan', 'title': 'Indie Chill', 'artist': 'Frank Ocean', 'cover': 'https://picsum.photos/seed/indie/200'},
];