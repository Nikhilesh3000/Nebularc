import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../services/socket_service.dart';
import '../theme/app_colors.dart';
import '../widgets/aurora_background.dart';
import 'package:confetti/confetti.dart';

class WrappedScreen extends StatefulWidget {
  const WrappedScreen({super.key});

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    // Fire confetti when the screen loads
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  } 

  String _fmtDuration(int ms) {
    final m = ms ~/ 60000;
    final s = (ms % 60000) ~/ 1000;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final wrapped = player.wrappedSummary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    if (wrapped == null) {
      return Scaffold(
        body: AuroraBackground(
          child: Center(
            child: Text('No session data',
                style: TextStyle(color: textColor)),
          ),
        ),
      );
    }

    return Scaffold(
      body: AuroraBackground(
        child: Stack(
          children: [
            // ---- CONFETTI OVERLAY ----
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.2,
                colors: const [AppColors.primary, AppColors.pink, AppColors.cyan, Colors.white],
              ),
            ),
            SafeArea(
          child: Column(
            children: [
             Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        context.read<PlayerProvider>().clearWrapped();
                        context.read<PlayerProvider>().disableRoomMode();
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      icon: Icon(Icons.close, color: textColor, size: 22),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Your Wrapped',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================================================
                      // HERO CARD — compact, gradient
                      // ================================================
                      _HeroCard(
                        roomName: wrapped.roomName,
                        roomCode: wrapped.roomCode,
                        durationText: _fmtDuration(wrapped.durationMs),
                        memberCount: wrapped.memberCount,
                      ),
                      const SizedBox(height: 24),

                      // ================================================
                      // SESSION STATS — compact 2x2 grid
                      // ================================================
                      _SectionTitle('Session Stats', textColor),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              emoji: '🎵',
                              value: '${wrapped.totalSongs}',
                              label: 'Songs Played',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              emoji: '💫',
                              value: '${wrapped.totalReactions}',
                              label: 'Reactions',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              emoji: '🗳️',
                              value: '${wrapped.totalVetoes}',
                              label: 'Veto Votes',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              emoji: '🎺',
                              value: '${wrapped.totalBatonPasses}',
                              label: 'Baton Passes',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),

                      // ================================================
                      // TOP SONG
                      // ================================================
                      if (wrapped.topSong != null) ...[
                        const SizedBox(height: 24),
                        _SectionTitle('Top Song', textColor),
                        const SizedBox(height: 10),
                        _TopSongCard(
                          cover: wrapped.topSong!.songCover,
                          title: wrapped.topSong!.songTitle,
                          artist: wrapped.topSong!.songArtist,
                          reactions: wrapped.topSongReactions,
                          isDark: isDark,
                        ),
                      ],

                      // ================================================
                      // AWARDS
                      // ================================================
                      if (wrapped.awards.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionTitle('🏆 Awards', textColor),
                        const SizedBox(height: 10),
                        ...wrapped.awards.map(
                          (a) => _AwardCard(award: a, isDark: isDark),
                        ),
                      ],

                      // ================================================
                      // LEADERBOARD
                      // ================================================
                      if (wrapped.memberStats.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionTitle('👥 Leaderboard', textColor),
                        const SizedBox(height: 10),
                        ...wrapped.memberStats.map(
                          (m) => _MemberRow(stats: m, isDark: isDark),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // ================================================
                      // Footer
                      // ================================================
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Made with Nebularc',
                              style: TextStyle(
                                fontSize: 11,
                                color: subtleColor,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'One beat. Every device.',
                              style: TextStyle(
                                fontSize: 10,
                                color: subtleColor.withOpacity(0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ],
      ),
      )
    );
  }
}

class _CountingStatCard extends StatelessWidget {
  final String emoji;
  final int target;
  final String label;
  final bool isDark;

  const _CountingStatCard({required this.emoji, required this.target, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor = isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const Spacer(),
              // ANIMATED COUNTER
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: target),
                duration: const Duration(seconds: 2),
                curve: Curves.easeOutExpo,
                builder: (context, value, child) {
                  return Text(
                    '$value',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: subtleColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ============================================================================
// Section title
// ============================================================================
class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionTitle(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ============================================================================
// Hero Card — compact with gradient
// ============================================================================
class _HeroCard extends StatelessWidget {
  final String roomName;
  final String roomCode;
  final String durationText;
  final int memberCount;

  const _HeroCard({
    required this.roomName,
    required this.roomCode,
    required this.durationText,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🌌', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            roomName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Room $roomCode • $memberCount ${memberCount == 1 ? "member" : "members"}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  durationText,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'of shared listening',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Stat Card — compact and readable
// ============================================================================
class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final bool isDark;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: subtleColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Top Song Card
// ============================================================================
class _TopSongCard extends StatelessWidget {
  final String cover;
  final String title;
  final String artist;
  final int reactions;
  final bool isDark;

  const _TopSongCard({
    required this.cover,
    required this.title,
    required this.artist,
    required this.reactions,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              cover,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 68,
                height: 68,
                color: isDark ? Colors.black26 : Colors.black12,
                child: const Icon(Icons.music_note),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: subtleColor),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$reactions 💫',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Award Card
// ============================================================================
class _AwardCard extends StatelessWidget {
  final dynamic award;
  final bool isDark;

  const _AwardCard({required this.award, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              award.emoji ?? '🏆',
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  award.title ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  award.winnerUsername ?? 'Everyone',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  award.description ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: subtleColor),
                ),
              ],
            ),
          ),
          if (award.value != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${award.value}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// Member Stat Row
// ============================================================================
class _MemberRow extends StatelessWidget {
  final dynamic stats;
  final bool isDark;

  const _MemberRow({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              (stats.username as String).isNotEmpty
                  ? stats.username[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stats.username ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          _MiniStat('🎵', stats.songsPlayed ?? 0, subtleColor),
          const SizedBox(width: 8),
          _MiniStat('💫', stats.reactionsSent ?? 0, subtleColor),
          const SizedBox(width: 8),
          _MiniStat('🗳️', stats.vetoesProposed ?? 0, subtleColor),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String emoji;
  final int value;
  final Color color;
  const _MiniStat(this.emoji, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 2),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}