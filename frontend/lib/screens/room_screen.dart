import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/room.dart';
import '../providers/player_provider.dart';
import '../services/socket_service.dart';
import '../services/song_service.dart';
import '../services/rooms_history_service.dart';
import '../theme/app_colors.dart';
import '../widgets/aurora_background.dart';
import '../widgets/floating_reaction.dart';
import '../widgets/nebularc_button.dart';
import 'wrapped_screen.dart';


class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final List<Widget> _floatingReactions = [];
  StreamSubscription? _reactionListener;
  StreamSubscription? _sessionListener;
  StreamSubscription? _sessionNoticeListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enableRoomMode();
      _listenForReactions();
      _listenForSessionEnd();
      _listenForSessionNotice();

      final room = context.read<SocketService>().currentRoom;
      if (room != null) {
        RoomsHistoryService.addRoom(room.code, room.name);
      }
    });
  }

  void _enableRoomMode() {
    final service = context.read<SocketService>();
    final player = context.read<PlayerProvider>();
    final room = service.currentRoom;
    if (room == null || service.userId == null) return;

    player.enableRoomMode(
      code: room.code,
      currentDjId: room.currentDjId ?? room.hostId,
      myUserId: service.userId!,
      socketService: service,
    );
  }

  void _listenForReactions() {
    final service = context.read<SocketService>();
    _reactionListener?.cancel();
    _reactionListener = service.reactionStream.listen((reaction) {
      if (!mounted) return;
      final key = UniqueKey();
      final widget = FloatingReaction(
        key: key,
        emoji: reaction.emoji,
        onComplete: () {
          if (!mounted) return;
          setState(() => _floatingReactions.removeWhere((w) => w.key == key));
        },
      );
      setState(() => _floatingReactions.add(widget));
    });
  }

  void _listenForSessionEnd() {
    final service = context.read<SocketService>();
    _sessionListener?.cancel();
        _sessionListener = service.sessionEndedStream.listen((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WrappedScreen()),
      );
    });
  }

    void _listenForSessionNotice() {
    final service = context.read<SocketService>();
    _sessionNoticeListener?.cancel();
    _sessionNoticeListener = service.sessionEndingNoticeStream.listen((data) {
      if (!mounted) return;

      final endedBy = data['endedByUsername'] ?? 'The DJ';

      // Show snackbar and pop back to MainScaffold
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎬 $endedBy ended the session'),
          duration: const Duration(seconds: 3),
        ),
      );

      // Clean up and return home
      context.read<PlayerProvider>().disableRoomMode();
      service.leaveRoom();
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  void dispose() {
    _reactionListener?.cancel();
    _sessionListener?.cancel();
    _sessionNoticeListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SocketService>();
    final player = context.watch<PlayerProvider>();
    final room = service.currentRoom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    if (room == null) {
      return Scaffold(
        body: AuroraBackground(
          child: Center(
            child: Text(
              'No room loaded',
              style: TextStyle(color: textColor),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // ---------- App Bar ----------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => _confirmLeave(context),
                          icon: Icon(Icons.arrow_back, color: textColor),
                        ),
                        Expanded(
                          child: Text(
                            room.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (player.isDj)
                          IconButton(
                            tooltip: 'End session & view Wrapped',
                            onPressed: () => _confirmEndSession(context),
                            icon: Icon(
                              Icons.stop_circle_outlined,
                              color: textColor,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ---------- Body ----------
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      child: Column(
                        children: [
                          _RoomCodeCard(code: room.code),
                          const SizedBox(height: 14),
                          _BatonCard(
                            room: room,
                            player: player,
                            myUserId: service.userId ?? '',
                          ),
                          const SizedBox(height: 14),
                          _NowPlayingCard(player: player),
                          const SizedBox(height: 14),
                          _VetoWidget(
                            player: player,
                            myUserId: service.userId ?? '',
                          ),
                          const SizedBox(height: 14),
                          if (player.isDj)
                            _DjControls(room: room, player: player),
                          const SizedBox(height: 20),
                          _MembersSection(
                            room: room,
                            myUserId: service.userId ?? '',
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Floating reactions overlay
              ..._floatingReactions,
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          title: const Text('Leave room?'),
          content: const Text('You can rejoin with the code later.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                final service = context.read<SocketService>();
                context.read<PlayerProvider>().disableRoomMode();
                service.leaveRoom();
                Navigator.pop(context);
              },
              child: const Text(
                'Leave',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmEndSession(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          title: const Text('End Session?'),
          content: const Text(
            'This will generate your Wrapped summary. Everyone will see it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<PlayerProvider>().endSession();
              },
              child: const Text(
                'End & Wrap',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// Room Code Card (gradient hero)
// ============================================================================
class _RoomCodeCard extends StatelessWidget {
  final String code;
  const _RoomCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Room Code',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            code,
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              letterSpacing: 10,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.share_outlined,
                  size: 12, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                'Share this code with friends',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Baton Card
// ============================================================================
class _BatonCard extends StatelessWidget {
  final Room room;
  final PlayerProvider player;
  final String myUserId;

  const _BatonCard({
    required this.room,
    required this.player,
    required this.myUserId,
  });

  @override
  Widget build(BuildContext context) {
    final djState = player.djState;
    final currentDjName = djState?.currentDjUsername ?? 'Waiting...';
    final isMe = djState?.currentDjId == myUserId;
    final played = djState?.songsPlayedInSet ?? 0;
    final max = djState?.maxSongsPerSet ?? 3;
    final remaining = max - played;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMe
            ? null
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        gradient: isMe ? AppColors.buttonGradient : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMe
              ? Colors.transparent
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: AppColors.pink.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('🎧', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? 'YOUR TURN' : 'CURRENT DJ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: isMe ? Colors.white70 : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMe ? 'You' : currentDjName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isMe
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkText
                                : AppColors.lightText),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '$remaining',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : AppColors.primary,
                      ),
                    ),
                    Text(
                      remaining == 1 ? 'song left' : 'songs left',
                      style: TextStyle(
                        fontSize: 9,
                        color: isMe
                            ? Colors.white70
                            : AppColors.primary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isMe) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(max, (i) {
                final isDone = i < played;
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.white
                        : Colors.white.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => context.read<PlayerProvider>().passBaton(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text(
                  'Pass Baton 🎺',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// Now Playing Card
// ============================================================================
class _NowPlayingCard extends StatelessWidget {
  final PlayerProvider player;
  const _NowPlayingCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    if (!player.hasSong) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.music_off, color: subtleColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No song playing. ${player.isDj ? "Pick one below!" : "Waiting for DJ..."}',
                style: TextStyle(color: subtleColor, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final song = player.currentSong!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              song.coverUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
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
                const Text(
                  'NOW PLAYING',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: subtleColor),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      player.isPlaying ? Icons.equalizer : Icons.pause,
                      size: 13,
                      color:
                          player.isPlaying ? AppColors.primary : subtleColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      player.isPlaying ? 'Synced' : 'Paused',
                      style: TextStyle(
                        fontSize: 11,
                        color: player.isPlaying
                            ? AppColors.primary
                            : subtleColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              player.isPlaying ? Icons.pause_circle : Icons.play_circle,
              size: 38,
              color: AppColors.primary,
            ),
            onPressed: player.togglePlayPause,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Veto Widget
// ============================================================================
class _VetoWidget extends StatefulWidget {
  final PlayerProvider player;
  final String myUserId;

  const _VetoWidget({required this.player, required this.myUserId});

  @override
  State<_VetoWidget> createState() => _VetoWidgetState();
}

class _VetoWidgetState extends State<_VetoWidget> {
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _VetoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startTimerIfNeeded();
  }

  void _startTimerIfNeeded() {
    final veto = widget.player.vetoState;
    if (veto == null) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_timer != null && _timer!.isActive) return;

    _timer?.cancel();
    _updateSeconds(veto);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final current = widget.player.vetoState;
      if (current == null) {
        t.cancel();
        return;
      }
      _updateSeconds(current);
      if (DateTime.now().millisecondsSinceEpoch > current.expiresAt) {
        t.cancel();
        if (current.proposedBy == widget.myUserId) {
          widget.player.clearVeto();
        }
      }
    });
  }

  void _updateSeconds(dynamic veto) {
    final remaining =
        ((veto.expiresAt - DateTime.now().millisecondsSinceEpoch) / 1000)
            .ceil();
    if (mounted) setState(() => _secondsLeft = remaining.clamp(0, 30));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final veto = player.vetoState;
    final hasVeto = player.hasActiveVeto;
    final hasVoted = player.hasIVoted;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    if (hasVeto && veto != null) {
      final percent = veto.threshold > 0
          ? (veto.currentVotes / veto.threshold).clamp(0.0, 1.0)
          : 0.0;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Text('🗳️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Veto: "${veto.songTitle}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_secondsLeft}s',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percent,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${veto.currentVotes} / ${veto.threshold} votes needed',
                  style: TextStyle(fontSize: 11, color: subtleColor),
                ),
                Text(
                  'by ${veto.proposedByUsername}',
                  style: TextStyle(fontSize: 11, color: subtleColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: hasVoted ? null : player.voteVeto,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      hasVoted ? Colors.grey.shade800 : AppColors.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(
                  hasVoted ? Icons.check : Icons.how_to_vote,
                  size: 18,
                ),
                label: Text(
                  hasVoted ? 'You voted to skip' : 'Vote to skip',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (player.hasSong && !player.isDj) {
      return SizedBox(
        width: double.infinity,
        height: 42,
        child: OutlinedButton.icon(
          onPressed: player.proposeVeto,
          style: OutlinedButton.styleFrom(
            foregroundColor: subtleColor,
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.how_to_vote, size: 16),
          label: const Text(
            'Propose Veto',
            style: TextStyle(fontSize: 13),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ============================================================================
// DJ Controls (fixes overflow — uses SizedBox with proper height)
// ============================================================================
class _DjControls extends StatelessWidget {
  final Room room;
  final PlayerProvider player;

  const _DjControls({required this.room, required this.player});

  @override
  Widget build(BuildContext context) {
    final songs = SongService.allSongs;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.headphones, size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                "YOU'RE THE DJ",
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Pick a song to play for everyone:',
          style: TextStyle(fontSize: 13, color: subtleColor),
        ),
        const SizedBox(height: 10),

        // FIX: give the horizontal list a slightly bigger height
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            itemBuilder: (context, i) {
              final s = songs[i];
              return GestureDetector(
                onTap: () =>
                    context.read<PlayerProvider>().playSong(s, queue: songs),
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                        child: Image.network(
                          s.coverUrl,
                          width: 130,
                          height: 115,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 130,
                            height: 115,
                            color: isDark ? Colors.black26 : Colors.black12,
                            child: const Icon(Icons.music_note),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                s.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: subtleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Members Section
// ============================================================================
class _MembersSection extends StatelessWidget {
  final Room room;
  final String myUserId;

  const _MembersSection({required this.room, required this.myUserId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Listeners',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${room.members.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...room.members.map((m) {
          final isMe = m.userId == myUserId;
          final isDj = m.userId == room.currentDjId ||
              (room.currentDjId == null && m.userId == room.hostId);
          return _MemberTile(
            member: m,
            isMe: isMe,
            isDj: isDj,
            isDark: isDark,
            textColor: textColor,
            subtleColor: subtleColor,
          );
        }),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final RoomMember member;
  final bool isMe;
  final bool isDj;
  final bool isDark;
  final Color textColor;
  final Color subtleColor;

  const _MemberTile({
    required this.member,
    required this.isMe,
    required this.isDj,
    required this.isDark,
    required this.textColor,
    required this.subtleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: isDj ? AppColors.buttonGradient : null,
              color: isDj ? null : AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              member.username.isNotEmpty
                  ? member.username[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDj ? Colors.white : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMe ? '${member.username} (You)' : member.username,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          if (isDj)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '🎧 DJ',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}