import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';
import '../models/room.dart';
import 'dart:async';

class PlaybackSync {
  final String songId;
  final String songTitle;
  final String songArtist;
  final String songUrl;
  final String songCover;
  final bool isPlaying;
  final int positionMs;
  final int startedAtMs;
  final String triggeredBy;

  PlaybackSync({
    required this.songId,
    required this.songTitle,
    required this.songArtist,
    required this.songUrl,
    required this.songCover,
    required this.isPlaying,
    required this.positionMs,
    required this.startedAtMs,
    required this.triggeredBy,
  });

  factory PlaybackSync.fromJson(Map<String, dynamic> json) {
    return PlaybackSync(
      songId: json['songId'] ?? '',
      songTitle: json['songTitle'] ?? '',
      songArtist: json['songArtist'] ?? '',
      songUrl: json['songUrl'] ?? '',
      songCover: json['songCover'] ?? '',
      isPlaying: json['isPlaying'] ?? false,
      positionMs: json['positionMs'] ?? 0,
      startedAtMs: json['startedAtMs'] ?? 0,
      triggeredBy: json['triggeredBy'] ?? '',
    );
  }
}
class DjState {
  final String currentDjId;
  final String currentDjUsername;
  final int songsPlayedInSet;
  final int maxSongsPerSet;

  DjState({
    required this.currentDjId,
    required this.currentDjUsername,
    required this.songsPlayedInSet,
    required this.maxSongsPerSet,
  });

  factory DjState.fromJson(Map<String, dynamic> json) {
    return DjState(
      currentDjId: json['currentDjId'] ?? '',
      currentDjUsername: json['currentDjUsername'] ?? '',
      songsPlayedInSet: json['songsPlayedInSet'] ?? 0,
      maxSongsPerSet: json['maxSongsPerSet'] ?? 3,
    );
  }
}

class VetoState {
  final String songId;
  final String songTitle;
  final String proposedBy;
  final String proposedByUsername;
  final int startedAt;
  final int expiresAt;
  final int threshold;
  final int currentVotes;
  final List<String> voters;
  final bool isActive;

  VetoState({
    required this.songId,
    required this.songTitle,
    required this.proposedBy,
    required this.proposedByUsername,
    required this.startedAt,
    required this.expiresAt,
    required this.threshold,
    required this.currentVotes,
    required this.voters,
    required this.isActive,
  });

  factory VetoState.fromJson(Map<String, dynamic> json) {
    return VetoState(
      songId: json['songId'] ?? '',
      songTitle: json['songTitle'] ?? '',
      proposedBy: json['proposedBy'] ?? '',
      proposedByUsername: json['proposedByUsername'] ?? '',
      startedAt: json['startedAt'] ?? 0,
      expiresAt: json['expiresAt'] ?? 0,
      threshold: json['threshold'] ?? 2,
      currentVotes: json['currentVotes'] ?? 0,
      voters: (json['voters'] as List<dynamic>?)
              ?.map((v) => v.toString())
              .toList() ??
          [],
      isActive: json['isActive'] ?? false,
    );
  }
}

class VetoResult {
  final bool passed;
  final String songId;
  final int voteCount;
  final int threshold;
  final String reason;

  VetoResult({
    required this.passed,
    required this.songId,
    required this.voteCount,
    required this.threshold,
    required this.reason,
  });

  factory VetoResult.fromJson(Map<String, dynamic> json) {
    return VetoResult(
      passed: json['passed'] ?? false,
      songId: json['songId'] ?? '',
      voteCount: json['voteCount'] ?? 0,
      threshold: json['threshold'] ?? 0,
      reason: json['reason'] ?? '',
    );
  }
}

class Reaction {
  final String id;
  final String type;
  final String userId;
  final String username;
  final String songId;
  final int timestamp;

  Reaction({
    required this.id,
    required this.type,
    required this.userId,
    required this.username,
    required this.songId,
    required this.timestamp,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      id: json['id'] ?? '',
      type: json['type'] ?? 'love',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      songId: json['songId'] ?? '',
      timestamp: json['timestamp'] ?? 0,
    );
  }

  String get emoji {
    switch (type) {
      case 'love':
        return '❤️';
      case 'fire':
        return '🔥';
      case 'laugh':
        return '😂';
      case 'party':
        return '🎉';
      case 'wow':
        return '😮';
      default:
        return '❤️';
    }
  }
}

class VibeState {
  final int energy;
  final int totalReactions;
  final Map<String, int> reactionCounts;

  VibeState({
    required this.energy,
    required this.totalReactions,
    required this.reactionCounts,
  });

  factory VibeState.fromJson(Map<String, dynamic> json) {
    final counts = json['reactionCounts'] as Map<String, dynamic>? ?? {};
    return VibeState(
      energy: json['energy'] ?? 0,
      totalReactions: json['totalReactions'] ?? 0,
      reactionCounts: counts.map((k, v) => MapEntry(k, (v ?? 0) as int)),
    );
  }
}

class BatonPassedEvent {
  final String previousDjId;
  final String previousDjUsername;
  final String newDjId;
  final String newDjUsername;
  final String reason;
  final int passedAt;

  BatonPassedEvent({
    required this.previousDjId,
    required this.previousDjUsername,
    required this.newDjId,
    required this.newDjUsername,
    required this.reason,
    required this.passedAt,
  });

  factory BatonPassedEvent.fromJson(Map<String, dynamic> json) {
    return BatonPassedEvent(
      previousDjId: json['previousDjId'] ?? '',
      previousDjUsername: json['previousDjUsername'] ?? '',
      newDjId: json['newDjId'] ?? '',
      newDjUsername: json['newDjUsername'] ?? '',
      reason: json['reason'] ?? 'manual',
      passedAt: json['passedAt'] ?? 0,
    );
  }
}

class SongPlayRecord {
  final String songId;
  final String songTitle;
  final String songArtist;
  final String songCover;
  final String playedByUserId;
  final String playedByUsername;
  final int playedAt;

  SongPlayRecord({
    required this.songId,
    required this.songTitle,
    required this.songArtist,
    required this.songCover,
    required this.playedByUserId,
    required this.playedByUsername,
    required this.playedAt,
  });

  factory SongPlayRecord.fromJson(Map<String, dynamic> json) {
    return SongPlayRecord(
      songId: json['songId'] ?? '',
      songTitle: json['songTitle'] ?? '',
      songArtist: json['songArtist'] ?? '',
      songCover: json['songCover'] ?? '',
      playedByUserId: json['playedByUserId'] ?? '',
      playedByUsername: json['playedByUsername'] ?? '',
      playedAt: json['playedAt'] ?? 0,
    );
  }
}

class Award {
  final String type;
  final String emoji;
  final String title;
  final String description;
  final String? winnerUserId;
  final String? winnerUsername;
  final int? value;

  Award({
    required this.type,
    required this.emoji,
    required this.title,
    required this.description,
    this.winnerUserId,
    this.winnerUsername,
    this.value,
  });

  factory Award.fromJson(Map<String, dynamic> json) {
    return Award(
      type: json['type'] ?? '',
      emoji: json['emoji'] ?? '🏆',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      winnerUserId: json['winnerUserId'],
      winnerUsername: json['winnerUsername'],
      value: json['value'],
    );
  }
}

class MemberStats {
  final String userId;
  final String username;
  final int songsPlayed;
  final int reactionsSent;
  final int vetoesProposed;
  final int vetoesVoted;

  MemberStats({
    required this.userId,
    required this.username,
    required this.songsPlayed,
    required this.reactionsSent,
    required this.vetoesProposed,
    required this.vetoesVoted,
  });

  factory MemberStats.fromJson(Map<String, dynamic> json) {
    return MemberStats(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      songsPlayed: json['songsPlayed'] ?? 0,
      reactionsSent: json['reactionsSent'] ?? 0,
      vetoesProposed: json['vetoesProposed'] ?? 0,
      vetoesVoted: json['vetoesVoted'] ?? 0,
    );
  }
}

class WrappedSummary {
  final String roomCode;
  final String roomName;
  final int startedAt;
  final int endedAt;
  final int durationMs;
  final int totalSongs;
  final int totalReactions;
  final int totalVetoes;
  final int totalBatonPasses;
  final int memberCount;
  final List<SongPlayRecord> songsPlayed;
  final SongPlayRecord? topSong;
  final int topSongReactions;
  final List<MemberStats> memberStats;
  final List<Award> awards;

  WrappedSummary({
    required this.roomCode,
    required this.roomName,
    required this.startedAt,
    required this.endedAt,
    required this.durationMs,
    required this.totalSongs,
    required this.totalReactions,
    required this.totalVetoes,
    required this.totalBatonPasses,
    required this.memberCount,
    required this.songsPlayed,
    this.topSong,
    required this.topSongReactions,
    required this.memberStats,
    required this.awards,
  });

  factory WrappedSummary.fromJson(Map<String, dynamic> json) {
    return WrappedSummary(
      roomCode: json['roomCode'] ?? '',
      roomName: json['roomName'] ?? '',
      startedAt: json['startedAt'] ?? 0,
      endedAt: json['endedAt'] ?? 0,
      durationMs: json['durationMs'] ?? 0,
      totalSongs: json['totalSongs'] ?? 0,
      totalReactions: json['totalReactions'] ?? 0,
      totalVetoes: json['totalVetoes'] ?? 0,
      totalBatonPasses: json['totalBatonPasses'] ?? 0,
      memberCount: json['memberCount'] ?? 0,
      songsPlayed: (json['songsPlayed'] as List<dynamic>?)
              ?.map((s) => SongPlayRecord.fromJson(Map<String, dynamic>.from(s)))
              .toList() ??
          [],
      topSong: json['topSong'] != null
          ? SongPlayRecord.fromJson(Map<String, dynamic>.from(json['topSong']))
          : null,
      topSongReactions: json['topSongReactions'] ?? 0,
      memberStats: (json['memberStats'] as List<dynamic>?)
              ?.map((s) => MemberStats.fromJson(Map<String, dynamic>.from(s)))
              .toList() ??
          [],
      awards: (json['awards'] as List<dynamic>?)
              ?.map((a) => Award.fromJson(Map<String, dynamic>.from(a)))
              .toList() ??
          [],
    );
  }
}

class LiveSearchRoom {
  final String code;
  final String name;
  final String currentSongTitle;
  final String currentDjUsername;
  final int listenerCount;
  final bool isPlaying;

  LiveSearchRoom({
    required this.code,
    required this.name,
    required this.currentSongTitle,
    required this.currentDjUsername,
    required this.listenerCount,
    required this.isPlaying,
  });

  factory LiveSearchRoom.fromJson(Map<String, dynamic> json) {
    return LiveSearchRoom(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      currentSongTitle: json['currentSongTitle'] ?? '',
      currentDjUsername: json['currentDjUsername'] ?? '',
      listenerCount: json['listenerCount'] ?? 0,
      isPlaying: json['isPlaying'] ?? false,
    );
  }
}

class LiveSearchUser {
  final String userId;
  final String username;
  final String roomCode;
  final String roomName;

  LiveSearchUser({
    required this.userId,
    required this.username,
    required this.roomCode,
    required this.roomName,
  });

  factory LiveSearchUser.fromJson(Map<String, dynamic> json) {
    return LiveSearchUser(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      roomCode: json['roomCode'] ?? '',
      roomName: json['roomName'] ?? '',
    );
  }
}

class LiveSearchResult {
  final List<LiveSearchRoom> rooms;
  final List<LiveSearchUser> users;

  LiveSearchResult({required this.rooms, required this.users});

  factory LiveSearchResult.fromJson(Map<String, dynamic> json) {
    return LiveSearchResult(
      rooms: (json['rooms'] as List<dynamic>?)
              ?.map((r) => LiveSearchRoom.fromJson(Map<String, dynamic>.from(r)))
              .toList() ??
          [],
      users: (json['users'] as List<dynamic>?)
              ?.map((u) => LiveSearchUser.fromJson(Map<String, dynamic>.from(u)))
              .toList() ??
          [],
    );
  }
}

class ExploreRoom {
  final String code;
  final String name;
  final String currentSongTitle;
  final String currentSongCover;
  final String currentDjUsername;
  final int listenerCount;
  final bool isPlaying;

  ExploreRoom({
    required this.code,
    required this.name,
    required this.currentSongTitle,
    required this.currentSongCover,
    required this.currentDjUsername,
    required this.listenerCount,
    required this.isPlaying,
  });

  factory ExploreRoom.fromJson(Map<String, dynamic> json) {
    return ExploreRoom(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      currentSongTitle: json['currentSongTitle'] ?? '',
      currentSongCover: json['currentSongCover'] ?? '',
      currentDjUsername: json['currentDjUsername'] ?? '',
      listenerCount: json['listenerCount'] ?? 0,
      isPlaying: json['isPlaying'] ?? false,
    );
  }
}

class ExploreData {
  final List<ExploreRoom> liveRooms;
  final int totalActiveListeners;

  ExploreData({
    required this.liveRooms,
    required this.totalActiveListeners,
  });

  factory ExploreData.fromJson(Map<String, dynamic> json) {
    return ExploreData(
      liveRooms: (json['liveRooms'] as List<dynamic>?)
              ?.map((r) => ExploreRoom.fromJson(Map<String, dynamic>.from(r)))
              .toList() ??
          [],
      totalActiveListeners: json['totalActiveListeners'] ?? 0,
    );
  }
}

class SocketService extends ChangeNotifier {
  io.Socket? _socket;
  Room? _currentRoom;
  String? _userId;
  String? _username;
  bool _isConnected = false;

  Room? get currentRoom => _currentRoom;
  String? get userId => _userId;
  String? get username => _username;
  bool get isConnected => _isConnected;
  PlaybackSync? _playbackSync;
  final _syncController = StreamController<PlaybackSync?>.broadcast();

   
  PlaybackSync? get playbackSync => _playbackSync;
  Stream<PlaybackSync?> get syncStream => _syncController.stream;
  
  DjState? _djState;
  final _djStateController = StreamController<DjState?>.broadcast();
  final _batonPassedController = StreamController<BatonPassedEvent>.broadcast();

  DjState? get djState => _djState;
  Stream<DjState?> get djStateStream => _djStateController.stream;
  Stream<BatonPassedEvent> get batonPassedStream => _batonPassedController.stream;

  VetoState? _vetoState;
  final _vetoController = StreamController<VetoState?>.broadcast();
  final _vetoResultController = StreamController<VetoResult>.broadcast();

  VetoState? get vetoState => _vetoState;
  Stream<VetoState?> get vetoStream => _vetoController.stream;
  Stream<VetoResult> get vetoResultStream => _vetoResultController.stream;

  final _reactionController = StreamController<Reaction>.broadcast();
  final _vibeController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Reaction> get reactionStream => _reactionController.stream;
  Stream<Map<String, dynamic>> get vibeStream => _vibeController.stream;

      final _sessionEndedController =
      StreamController<WrappedSummary>.broadcast();
  Stream<WrappedSummary> get sessionEndedStream =>
      _sessionEndedController.stream;

  final _sessionEndingNoticeController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get sessionEndingNoticeStream =>
      _sessionEndingNoticeController.stream;

    final _searchResultsController = StreamController<LiveSearchResult>.broadcast();
  Stream<LiveSearchResult> get searchResultsStream => _searchResultsController.stream;

  ExploreData? _exploreData;
  final _exploreController = StreamController<ExploreData>.broadcast();

  ExploreData? get exploreData => _exploreData;
  Stream<ExploreData> get exploreStream => _exploreController.stream;

  // ---------------------------------------------------------------------------
  // Connect to backend
  // ---------------------------------------------------------------------------
  void connect({required String userId, required String username}) {
    if (_socket != null && _socket!.connected) return;

    _userId = userId;
    _username = username;

    _socket = io.io(
      AppConfig.backendUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('✅ Connected to Nebularc backend');
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('❌ Disconnected from backend');
      notifyListeners();
    });

    // -------- Room events --------
    _socket!.on('room_created', (data) {
      debugPrint('🏠 Room created: ${data['room']}');
      _currentRoom = Room.fromJson(data['room']);
      notifyListeners();
    });

    _socket!.on('room_joined', (data) {
      debugPrint('👤 Joined room: ${data['room']}');
      _currentRoom = Room.fromJson(data['room']);
      notifyListeners();
    });

    _socket!.on('member_joined', (data) {
      if (_currentRoom == null) return;
      final members = (data['members'] as List)
          .map((m) => RoomMember.fromJson(m as Map<String, dynamic>))
          .toList();
      _currentRoom = Room(
        code: _currentRoom!.code,
        name: _currentRoom!.name,
        hostId: _currentRoom!.hostId,
        currentDjId: _currentRoom!.currentDjId,
        members: members,
      );
      notifyListeners();
    });

    _socket!.on('member_left', (data) {
      if (_currentRoom == null) return;
      final members = (data['members'] as List)
          .map((m) => RoomMember.fromJson(m as Map<String, dynamic>))
          .toList();
      _currentRoom = Room(
        code: _currentRoom!.code,
        name: _currentRoom!.name,
        hostId: _currentRoom!.hostId,
        currentDjId: _currentRoom!.currentDjId,
        members: members,
      );
      notifyListeners();
    });

    _socket!.on('room_error', (data) {
      debugPrint('⚠️ Room error: ${data['message']}');
    });

        // -------- Playback sync events --------
    _socket!.on('sync_play', (data) {
      debugPrint('🎵 sync_play received');
      _playbackSync = PlaybackSync.fromJson(Map<String, dynamic>.from(data));
      _syncController.add(_playbackSync);
      notifyListeners();
    });

    _socket!.on('sync_pause', (data) {
      debugPrint('⏸️ sync_pause received');
      _playbackSync = PlaybackSync.fromJson(Map<String, dynamic>.from(data));
      _syncController.add(_playbackSync);
      notifyListeners();
    });

    _socket!.on('sync_resume', (data) {
      debugPrint('▶️ sync_resume received');
      _playbackSync = PlaybackSync.fromJson(Map<String, dynamic>.from(data));
      _syncController.add(_playbackSync);
      notifyListeners();
    });

    _socket!.on('sync_seek', (data) {
      debugPrint('⏩ sync_seek received');
      _playbackSync = PlaybackSync.fromJson(Map<String, dynamic>.from(data));
      _syncController.add(_playbackSync);
      notifyListeners();
    });

    _socket!.on('sync_state', (data) {
      debugPrint('🔄 sync_state received');
      if (data == null) {
        _playbackSync = null;
      } else {
        _playbackSync = PlaybackSync.fromJson(Map<String, dynamic>.from(data));
      }
      _syncController.add(_playbackSync);
      notifyListeners();
    });

        // -------- DJ Baton events --------
    _socket!.on('dj_state_updated', (data) {
      debugPrint('🎧 DJ state updated');
      if (data == null) {
        _djState = null;
      } else {
        _djState = DjState.fromJson(Map<String, dynamic>.from(data));
      }
      _djStateController.add(_djState);
      notifyListeners();
    });

    _socket!.on('baton_passed', (data) {
      debugPrint('🎺 Baton passed');
      final event = BatonPassedEvent.fromJson(Map<String, dynamic>.from(data));
      _batonPassedController.add(event);
      notifyListeners();
    });

        // -------- Veto events --------
    _socket!.on('veto_started', (data) {
      debugPrint('🗳️ veto_started');
      _vetoState = VetoState.fromJson(Map<String, dynamic>.from(data));
      _vetoController.add(_vetoState);
      notifyListeners();
    });

    _socket!.on('veto_updated', (data) {
      debugPrint('🗳️ veto_updated');
      _vetoState = VetoState.fromJson(Map<String, dynamic>.from(data));
      _vetoController.add(_vetoState);
      notifyListeners();
    });

    _socket!.on('veto_result', (data) {
      debugPrint('🗳️ veto_result');
      final result = VetoResult.fromJson(Map<String, dynamic>.from(data));
      _vetoState = null;
      _vetoController.add(null);
      _vetoResultController.add(result);
      notifyListeners();
    });

        // -------- Reaction events --------
    _socket!.on('reaction_received', (data) {
      final reaction = Reaction.fromJson(Map<String, dynamic>.from(data));
      _reactionController.add(reaction);
      notifyListeners();
    });

    _socket!.on('vibe_updated', (data) {
      _vibeController.add(Map<String, dynamic>.from(data));
      notifyListeners();
    });

    _socket!.on('vibe_state', (data) {
      _vibeController.add(Map<String, dynamic>.from(data));
      notifyListeners();
    });

         _socket!.on('session_ended', (data) {
      debugPrint('🎬 session_ended received');
      final wrapped =
          WrappedSummary.fromJson(Map<String, dynamic>.from(data));
      _sessionEndedController.add(wrapped);
      notifyListeners();
    });

    _socket!.on('session_ending_notice', (data) {
      debugPrint('🎬 session_ending_notice received');
      _sessionEndingNoticeController.add(
        Map<String, dynamic>.from(data ?? {}),
      );
    });


    _socket!.on('search_results', (data) {
      final result = LiveSearchResult.fromJson(Map<String, dynamic>.from(data));
      _searchResultsController.add(result);
    });

    _socket!.on('explore_data', (data) {
      _exploreData = ExploreData.fromJson(Map<String, dynamic>.from(data));
      _exploreController.add(_exploreData!);
      notifyListeners();
    });
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  void createRoom(String name, {bool isPublic = false}) {
    _socket?.emit('create_room', {
      'name': name,
      'userId': _userId,
      'username': _username,
      'isPublic': isPublic,
    });
  }

  void joinRoom(String code) {
    _socket?.emit('join_room', {
      'code': code,
      'userId': _userId,
      'username': _username,
    });
  }

  void leaveRoom() {
    if (_currentRoom == null) return;
    _socket?.emit('leave_room', {'code': _currentRoom!.code});
    _currentRoom = null;
    notifyListeners();
  }
    // ---------------------------------------------------------------------------
  // Playback sync actions
  // ---------------------------------------------------------------------------
  void emitSyncPlay({
    required String code,
    required String songId,
    required String songTitle,
    required String songArtist,
    required String songUrl,
    required String songCover,
  }) {
    _socket?.emit('sync_play', {
      'code': code,
      'songId': songId,
      'songTitle': songTitle,
      'songArtist': songArtist,
      'songUrl': songUrl,
      'songCover': songCover,
      'userId': _userId,
    });
  }

  void emitSyncPause(String code, int positionMs) {
    _socket?.emit('sync_pause', {'code': code, 'positionMs': positionMs});
  }

  void emitSyncResume(String code, int positionMs) {
    _socket?.emit('sync_resume', {'code': code, 'positionMs': positionMs});
  }

  void emitSyncSeek(String code, int positionMs) {
    _socket?.emit('sync_seek', {'code': code, 'positionMs': positionMs});
  }

  void emitSyncRequest(String code) {
    _socket?.emit('sync_request', {'code': code});
  }
   void emitPassBaton(String code) {
    _socket?.emit('pass_baton', {'code': code, 'userId': _userId});
  }

  void requestDjState(String code) {
    _socket?.emit('dj_state_request', {'code': code});
  }

    void emitProposeVeto(String code) {
    _socket?.emit('propose_veto', {
      'code': code,
      'userId': _userId,
      'username': _username,
    });
  }

  void emitVoteVeto(String code) {
    _socket?.emit('vote_veto', {'code': code, 'userId': _userId});
  }

  void emitClearVeto(String code) {
    _socket?.emit('clear_veto', {'code': code});
  }

    void emitReaction({
    required String code,
    required String songId,
    required String type,
  }) {
    _socket?.emit('send_reaction', {
      'code': code,
      'userId': _userId,
      'username': _username,
      'songId': songId,
      'type': type,
    });
  }

  void requestVibeState(String code, String songId) {
    _socket?.emit('vibe_request', {'code': code, 'songId': songId});
  }

   void emitEndSession(String code) {
    _socket?.emit('end_session', {
      'code': code,
      'userId': _userId,
    });
  }

  void emitSearchLive(String query) {
    _socket?.emit('search_live', {'query': query});
  }

  void requestExploreData() {
    _socket?.emit('explore_request');
  }


   @override
  void dispose() {
    _syncController.close();
    _djStateController.close();
    _batonPassedController.close();
    _vetoController.close();
    _vetoResultController.close();
    _reactionController.close();
    _vibeController.close();
    _sessionEndedController.close();
    _sessionEndingNoticeController.close();
    _searchResultsController.close();
    _exploreController.close();
    _socket?.dispose();
    super.dispose();
  } 
}