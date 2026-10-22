import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../services/socket_service.dart';
import '../services/song_service.dart';
import '../theme/app_colors.dart';
import '../widgets/song_tile.dart';
import 'room_screen.dart';
import 'package:shimmer/shimmer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;

  List<LiveSearchRoom> _liveRooms = [];
  List<LiveSearchUser> _liveUsers = [];
  StreamSubscription? _searchSub;
  StreamSubscription? _exploreSub;
  ExploreData? _exploreData;

  final List<Map<String, dynamic>> _moods = [
    {'name': 'Chillout', 'emoji': '🌙', 'color': Color(0xFF6EC8F0)},
    {'name': 'Dance', 'emoji': '💃', 'color': Color(0xFFE84393)},
    {'name': 'Indie', 'emoji': '🎸', 'color': Color(0xFF9B63F0)},
    {'name': 'Work', 'emoji': '💼', 'color': Color(0xFF00D2D3)},
    {'name': 'Morn', 'emoji': '☀️', 'color': Color(0xFFFF9E55)},
    {'name': 'Party', 'emoji': '🎉', 'color': Color(0xFFFF5CA8)},
    {'name': 'Yoga', 'emoji': '🧘', 'color': Color(0xFF7ED6A5)},
    {'name': 'Retro', 'emoji': '📻', 'color': Color(0xFFFFC048)},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listen();
      context.read<SocketService>().requestExploreData();
    });
  }

  void _listen() {
    final service = context.read<SocketService>();
    _searchSub?.cancel();
    _searchSub = service.searchResultsStream.listen((r) {
      if (!mounted) return;
      setState(() {
        _liveRooms = r.rooms;
        _liveUsers = r.users;
      });
    });
    _exploreSub?.cancel();
    _exploreSub = service.exploreStream.listen((d) {
      if (!mounted) return;
      setState(() => _exploreData = d);
    });
  }

  void _onChanged(String v) {
    setState(() => _query = v);
    _debounce?.cancel();
    if (v.length >= 2) {
      _debounce = Timer(const Duration(milliseconds: 350), () {
        context.read<SocketService>().emitSearchLive(v);
      });
    } else {
      setState(() {
        _liveRooms = [];
        _liveUsers = [];
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchSub?.cancel();
    _exploreSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = SongService.search(_query);
    final isSearching = _query.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
              // ---------- Header ----------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSearching ? 'Search' : 'Explore',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness ==
                                  Brightness.dark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SearchBar(
                        controller: _controller,
                        onChanged: _onChanged,
                        showClear: _query.isNotEmpty,
                        onClear: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // =====================================================
              // SEARCH MODE
              // =====================================================
              if (isSearching) ...[
                if (_liveRooms.isNotEmpty) ...[
                  _SectionTitle(
                    '🔴 Live Right Now',
                    trailing: '${_liveRooms.length}',
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (c, i) => _LiveRoomRow(room: _liveRooms[i]),
                      childCount: _liveRooms.length,
                    ),
                  ),
                ],
                if (_liveUsers.isNotEmpty) ...[
                  const _SectionTitle('🎧 Listeners'),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (c, i) => _LiveUserRow(user: _liveUsers[i]),
                      childCount: _liveUsers.length,
                    ),
                  ),
                ],
                if (results.isNotEmpty) ...[
                  const _SectionTitle('🎵 Songs'),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (c, i) => SongTile(song: results[i], queue: results),
                      childCount: results.length,
                    ),
                  ),
                ],
                if (results.isEmpty &&
                    _liveRooms.isEmpty &&
                    _liveUsers.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 56,
                              color: Theme.of(context)
                                  .iconTheme
                                  .color
                                  ?.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text(
                            'No results for "$_query"',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],

              // =====================================================
              // EXPLORE MODE
              // =====================================================
              if (!isSearching) ...[
                if (_exploreData == null) 
                const SliverToBoxAdapter(child: _ExploreShimmerLoader())
              else ...[
                // ---------- Top Charts ----------
                const _SectionTitle('🎵 Top Charts'),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (c, i) => _ChartRow(
                      index: i,
                      song: SongService.allSongs[i],
                    ),
                    childCount: 3,
                  ),
                ),

                // ---------- Fresh Drops ----------
                const _SectionTitle('🆕 Fresh Drops'),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 190,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: SongService.getRecentlyAdded().length,
                      itemBuilder: (c, i) => _FreshDropCard(
                        song: SongService.getRecentlyAdded()[i],
                      ),
                    ),
                  ),
                ),

                // ---------- Browse by Mood ----------
                const _SectionTitle('🎯 Browse by Mood'),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.2,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (c, i) => _MoodCard(mood: _moods[i]),
                      childCount: _moods.length,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ],
          ),          
        ),
      );
  }
}

// ============================================================================
// Section title widget
// ============================================================================
class _SectionTitle extends StatelessWidget {
  final String text;
  final String? trailing;
  const _SectionTitle(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subtle =
        Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const Spacer(),
            if (trailing != null)
              Text(trailing!,
                  style: TextStyle(fontSize: 12, color: subtle)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Search bar
// ============================================================================
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool showClear;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.showClear,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.10),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Songs, artists, rooms, people...',
          hintStyle: TextStyle(color: subtleColor, fontSize: 13),
          prefixIcon:
              Icon(Icons.search, color: subtleColor, size: 20),
          suffixIcon: showClear
              ? IconButton(
                  icon: Icon(Icons.close, color: subtleColor, size: 18),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ============================================================================
// Top chart row
// ============================================================================
class _ChartRow extends StatelessWidget {
  final int index;
  final dynamic song;
  const _ChartRow({required this.index, required this.song});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return GestureDetector(
      onTap: () => context
          .read<PlayerProvider>()
          .playSong(song, queue: SongService.allSongs),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: index < 3 ? AppColors.primary : subtleColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                song.coverUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  color: isDark ? Colors.black26 : Colors.black12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: subtleColor),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Fresh drop card
// ============================================================================
class _FreshDropCard extends StatelessWidget {
  final dynamic song;
  const _FreshDropCard({required this.song});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return GestureDetector(
      onTap: () => context
          .read<PlayerProvider>()
          .playSong(song, queue: SongService.getRecentlyAdded()),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                song.coverUrl,
                width: 130,
                height: 130,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 130,
                  height: 130,
                  color: isDark ? Colors.black26 : Colors.black12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: textColor,
              ),
            ),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: subtleColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Mood card
// ============================================================================
class _MoodCard extends StatelessWidget {
  final Map<String, dynamic> mood;
  const _MoodCard({required this.mood});

  @override
  Widget build(BuildContext context) {
    final color = mood['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.85), color.withOpacity(0.45)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -4,
            bottom: -4,
            child: Text(
              mood['emoji'] as String,
              style: TextStyle(
                fontSize: 48,
                color: Colors.white.withOpacity(0.25),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              mood['name'] as String,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Live room row (search result)
// ============================================================================
class _LiveRoomRow extends StatelessWidget {
  final LiveSearchRoom room;
  const _LiveRoomRow({required this.room});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text('🎧', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor)),
                Text('Playing: ${room.currentSongTitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: subtleColor)),
                Text('${room.listenerCount} listeners • DJ ${room.currentDjUsername}',
                    style: TextStyle(fontSize: 10, color: subtleColor)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<SocketService>().joinRoom(room.code);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RoomScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Join',
                style:
                    TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Live user row (search result)
// ============================================================================
class _LiveUserRow extends StatelessWidget {
  final LiveSearchUser user;
  const _LiveUserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor)),
                Text('In room: ${user.roomName}',
                    style: TextStyle(fontSize: 11, color: subtleColor)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              context.read<SocketService>().joinRoom(user.roomCode);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RoomScreen()));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Tune In',
                style:
                    TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
class _ExploreShimmerLoader extends StatelessWidget {
  const _ExploreShimmerLoader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white10 : Colors.black12;
    final highlightColor = isDark ? Colors.white24 : Colors.black26;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton Section Title
            Container(width: 150, height: 20, color: Colors.white, margin: const EdgeInsets.only(bottom: 20)),
            // Skeleton List Rows
            ...List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: double.infinity, height: 14, color: Colors.white),
                        const SizedBox(height: 6),
                        Container(width: 100, height: 12, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 20),
            Container(width: 150, height: 20, color: Colors.white, margin: const EdgeInsets.only(bottom: 20)),
            // Skeleton Horizontal Cards (Fresh Drops)
            Row(
              children: List.generate(3, (i) => Container(
                width: 130, height: 130,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              )),
            ),
          ],
        ),
      ),
    );
  }
}