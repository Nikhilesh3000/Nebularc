import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/rooms_history_service.dart';
import '../theme/app_colors.dart';
import '../widgets/section_header.dart';
import 'setting_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RecentRoom> _recentRooms = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    final rooms = await RoomsHistoryService.getRooms();
    if (mounted) setState(() => _recentRooms = rooms);
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
    final email = auth.user?.email ?? '';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

     return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    children: [
                      // ---------- Settings gear (top-right) ----------
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: 'Settings',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.settings_outlined,
                            color: textColor,
                            size: 24,
                          ),
                        ),
                      ),

                      // ---------- Avatar ----------
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.buttonGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.pink.withOpacity(0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(fontSize: 12, color: subtleColor),
                      ),
                      const SizedBox(height: 22),

                      // ---------- Tab Bar ----------
                      Container(
                        height: 48,
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
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: subtleColor,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          unselectedLabelStyle:
                              const TextStyle(fontSize: 13),
                          tabs: const [
                            Tab(text: 'Stats'),
                            Tab(text: 'Rooms'),
                            Tab(text: 'Tracks'),
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
              children: [
                _StatsTab(),
                _RoomsTab(rooms: _recentRooms),
                _TracksTab(),
              ],
            ),
        
          ),          
        ),        
       );   
  }
}

// ============================================================================
// TAB 1 — Stats (no settings section anymore)
// ============================================================================
class _StatsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        const SectionHeader(title: '📊 Your Stats'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: '🎵',
                value: '42',
                label: 'Songs Played',
                surface: surface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: '💫',
                value: '128',
                label: 'Reactions',
                surface: surface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: '🎧',
                value: '7',
                label: 'Rooms Joined',
                surface: surface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: '🎺',
                value: '12',
                label: 'Baton Passes',
                surface: surface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const SectionHeader(title: '🎬 Past Sessions'),
        const SizedBox(height: 8),
        _PastSessionCard(
          title: 'Cosmic Grooves',
          date: '2 days ago',
          songs: 12,
          members: 3,
          surface: surface,
        ),
        _PastSessionCard(
          title: 'Indie Chill',
          date: '5 days ago',
          songs: 8,
          members: 5,
          surface: surface,
        ),
      ],
    );
  }
}

// ============================================================================
// TAB 2 — Rooms
// ============================================================================
class _RoomsTab extends StatelessWidget {
  final List<RecentRoom> rooms;
  const _RoomsTab({required this.rooms});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room_outlined, size: 56, color: subtleColor),
            const SizedBox(height: 12),
            Text(
              'No rooms joined yet',
              style: TextStyle(color: subtleColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      itemCount: rooms.length,
      itemBuilder: (context, i) {
        final room = rooms[i];
        final date = DateTime.fromMillisecondsSinceEpoch(room.joinedAt);
        final ago = _timeAgo(date);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('🎧', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${room.code} • $ago',
                      style: TextStyle(fontSize: 11, color: subtleColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: subtleColor),
            ],
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

// ============================================================================
// TAB 3 — Tracks
// ============================================================================
class _TracksTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_music_outlined, size: 56, color: subtleColor),
          const SizedBox(height: 12),
          Text(
            'Liked tracks coming soon',
            style: TextStyle(color: subtleColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Stat Card
// ============================================================================
class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color surface;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: subtleColor)),
        ],
      ),
    );
  }
}

// ============================================================================
// Past Session Card
// ============================================================================
class _PastSessionCard extends StatelessWidget {
  final String title;
  final String date;
  final int songs;
  final int members;
  final Color surface;

  const _PastSessionCard({
    required this.title,
    required this.date,
    required this.songs,
    required this.members,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text('🎬', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('$songs songs',
                        style: TextStyle(fontSize: 11, color: subtleColor)),
                    const SizedBox(width: 10),
                    Icon(Icons.people, size: 11, color: subtleColor),
                    const SizedBox(width: 3),
                    Text('$members members',
                        style: TextStyle(fontSize: 11, color: subtleColor)),
                    const SizedBox(width: 10),
                    Text(date,
                        style: TextStyle(fontSize: 11, color: subtleColor)),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: subtleColor),
        ],
      ),
    );
  }
}