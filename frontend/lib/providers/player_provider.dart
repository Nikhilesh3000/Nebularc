import 'dart:async';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/audio_service.dart';
import '../services/socket_service.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioService _audio = AudioService.instance;
  SocketService? _socket;

  bool _roomMode = false;
  String? _roomCode;
  bool _isDj = false;
  StreamSubscription? _syncSub;

  PlayerProvider() {
    _audio.init();
    _audio.player.playerStateStream.listen((_) => notifyListeners());
    _audio.player.positionStream.listen((_) => notifyListeners());
    _audio.player.durationStream.listen((_) => notifyListeners());
  }

  // ---------------------------------------------------------------------------
  // Basic getters
  // ---------------------------------------------------------------------------
  Song? get currentSong => _audio.currentSong;
  bool get isPlaying => _audio.player.playing;
  Duration get position => _audio.player.position;
  Duration get duration => _audio.player.duration ?? Duration.zero;
  bool get hasSong => currentSong != null;
  int get currentPositionMs => _audio.currentPositionMs;

  bool get roomMode => _roomMode;
  String? get roomCode => _roomCode;
  bool get isDj => _isDj;
   DjState? _djState;
  StreamSubscription? _djSub;
  StreamSubscription? _batonSub;

  DjState? get djState => _djState;
  int get songsRemainingInSet {
    if (_djState == null) return 0;
    return _djState!.maxSongsPerSet - _djState!.songsPlayedInSet;
  }

  VetoState? _vetoState;
  StreamSubscription? _vetoSub;
  StreamSubscription? _vetoResultSub;

  VetoState? get vetoState => _vetoState;
  bool get hasActiveVeto => _vetoState != null && _vetoState!.isActive;
  bool get hasIVoted => _vetoState?.voters.contains(_myUserId ?? '') ?? false;
  String? _myUserId;

    final List<Reaction> _recentReactions = [];
  VibeState? _vibeState;
  StreamSubscription? _reactionSub;
  StreamSubscription? _vibeSub;

  List<Reaction> get recentReactions => List.unmodifiable(_recentReactions);
  VibeState? get vibeState => _vibeState;
  int get vibeEnergy => _vibeState?.energy ?? 0;
  int get reactionCount => _vibeState?.totalReactions ?? 0;

  StreamSubscription? _sessionSub;
  WrappedSummary? _wrappedSummary;
  WrappedSummary? get wrappedSummary => _wrappedSummary;  

  // ---------------------------------------------------------------------------
  // Solo playback (existing behavior)
  // ---------------------------------------------------------------------------
  Future<void> playSong(Song song, {List<Song>? queue}) async {
    if (_roomMode) {
      // In room mode, route through sync
      _socket?.emitSyncPlay(
        code: _roomCode!,
        songId: song.id,
        songTitle: song.title,
        songArtist: song.artist,
        songUrl: song.audioUrl,
        songCover: song.coverUrl,
      );
      return;
    }
    await _audio.playSong(song, queue: queue);
    notifyListeners();
  }

  void togglePlayPause() {
    if (_roomMode) {
      if (_audio.player.playing) {
        _socket?.emitSyncPause(_roomCode!, _audio.currentPositionMs);
      } else {
        _socket?.emitSyncResume(_roomCode!, _audio.currentPositionMs);
      }
      return;
    }
    _audio.togglePlayPause();
    notifyListeners();
  }

  Future<void> next() async {
    if (_roomMode && !_isDj) return; // only DJ can skip
    await _audio.playNext();
    notifyListeners();
  }

  Future<void> previous() async {
    if (_roomMode && !_isDj) return;
    await _audio.playPrevious();
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    if (_roomMode) {
      _socket?.emitSyncSeek(_roomCode!, position.inMilliseconds);
      return;
    }
    await _audio.seek(position);
    notifyListeners();
  }

  Future<void> stop() async {
    await _audio.stop();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Room mode management
  // ---------------------------------------------------------------------------
  void enableRoomMode({
    required String code,
    required String currentDjId,
    required String myUserId,
    required SocketService socketService,
  }) {
    _roomMode = true;
    _roomCode = code;
    _isDj = currentDjId == myUserId;
    _socket = socketService;

    // Subscribe to sync events
    _syncSub?.cancel();
    _syncSub = _socket!.syncStream.listen(_handleSyncEvent);
        _djSub?.cancel();
    _djSub = _socket!.djStateStream.listen((djState) {
      _djState = djState;
      if (djState != null) {
        _isDj = djState.currentDjId == myUserId;
      }
      notifyListeners();
    });
      _myUserId = myUserId;

    _vetoSub?.cancel();
    _vetoSub = _socket!.vetoStream.listen((veto) {
      _vetoState = veto;
      notifyListeners();
    });

    _vetoResultSub?.cancel();
    _vetoResultSub = _socket!.vetoResultStream.listen((result) {
      debugPrint('🗳️ Veto result: passed=${result.passed}');
      _vetoState = null;
      notifyListeners();
    });


    _batonSub?.cancel();
    _batonSub = _socket!.batonPassedStream.listen((event) {
      debugPrint('🎺 Baton passed: ${event.newDjUsername}');
      notifyListeners();
    });

        _reactionSub?.cancel();
    _reactionSub = _socket!.reactionStream.listen((reaction) {
      _recentReactions.insert(0, reaction);
      if (_recentReactions.length > 20) {
        _recentReactions.removeLast();
      }
      notifyListeners();
    });

    _vibeSub?.cancel();
    _vibeSub = _socket!.vibeStream.listen((data) {
      final vibeData = data['vibe'];
      if (vibeData != null) {
        _vibeState = VibeState.fromJson(Map<String, dynamic>.from(vibeData));
        notifyListeners();
      }
    });

    // Request initial DJ state
    _socket!.requestDjState(code);

    // Ask backend for current state
    _socket!.emitSyncRequest(code);
    notifyListeners();

    _sessionSub?.cancel();
    _sessionSub = _socket!.sessionEndedStream.listen((wrapped) {
      debugPrint('🎬 Session ended, Wrapped generated');
      _wrappedSummary = wrapped;
      notifyListeners();
    });
  }

  void updateDjStatus(String currentDjId, String myUserId) {
    _isDj = currentDjId == myUserId;
    notifyListeners();
  } 

  void disableRoomMode() {
    _roomMode = false;
    _roomCode = null;
    _isDj = false;
    _djState = null;
    _syncSub?.cancel();
    _djSub?.cancel();
    _batonSub?.cancel();
    _syncSub = null;
    _djSub = null;
    _batonSub = null;
    _audio.stop();
    _vetoSub?.cancel();
    _vetoResultSub?.cancel();
    _vetoSub = null;
    _vetoResultSub = null;
    _vetoState = null;
    _reactionSub?.cancel();
    _vibeSub?.cancel();
    _reactionSub = null;
    _vibeSub = null;
    _recentReactions.clear();
    _vibeState = null;
     _sessionSub?.cancel();
    _sessionSub = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Handle sync events from backend
  // ---------------------------------------------------------------------------
  void _handleSyncEvent(PlaybackSync? sync) async {
    if (sync == null) {
      await _audio.stop();
      notifyListeners();
      return;
    }

    // Calculate true position: if playing, add elapsed time since startedAtMs
    int targetPosition = sync.positionMs;
    if (sync.isPlaying) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - sync.startedAtMs;
      targetPosition = sync.positionMs + elapsed;
    }

    final song = Song(
      id: sync.songId,
      title: sync.songTitle,
      artist: sync.songArtist,
      album: '',
      audioUrl: sync.songUrl,
      coverUrl: sync.songCover,
      duration: Duration.zero,
    );

    // If it's a new song, load it
    if (_audio.currentSong?.id != song.id) {
      await _audio.playAtPosition(
        
        song: song,
        position: Duration(milliseconds: targetPosition),
      );
    } else {
      // Same song — just correct the position if drift is > 500ms
      final drift = (targetPosition - _audio.currentPositionMs).abs();
      if (drift > 500) {
        await _audio.seek(Duration(milliseconds: targetPosition));
      }
      // Match play/pause state
      if (sync.isPlaying && !_audio.isPlaying) {
        _audio.player.play();
      } else if (!sync.isPlaying && _audio.isPlaying) {
        _audio.player.pause();
      }
    }
    if (_audio.currentSong?.id != song.id) {
      _recentReactions.clear();
      _vibeState = null;
      if (_roomCode != null) {
        _socket?.requestVibeState(_roomCode!, song.id);
      }
    }

    notifyListeners();
  }
  void passBaton() {
    if (!_roomMode || !_isDj || _roomCode == null) return;
    _socket?.emitPassBaton(_roomCode!);
  }

  void proposeVeto() {
    if (!_roomMode || _roomCode == null) return;
    _socket?.emitProposeVeto(_roomCode!);
  }

  void voteVeto() {
    if (!_roomMode || _roomCode == null) return;
    _socket?.emitVoteVeto(_roomCode!);
  }

  void clearVeto() {
    if (!_roomMode || _roomCode == null) return;
    _socket?.emitClearVeto(_roomCode!);
  }

    void sendReaction(String type) {
    if (!_roomMode || _roomCode == null || currentSong == null) return;
    _socket?.emitReaction(
      code: _roomCode!,
      songId: currentSong!.id,
      type: type,
    );
  }

  void endSession() {
    if (!_roomMode || _roomCode == null) return;
    _socket?.emitEndSession(_roomCode!);
  }

  void clearWrapped() {
    _wrappedSummary = null;
    notifyListeners();
  } 


  @override
  void dispose() {
    _syncSub?.cancel();
    _djSub?.cancel();
    _batonSub?.cancel();
    _vetoSub?.cancel();
    _vetoResultSub?.cancel();
    _reactionSub?.cancel();
    _vibeSub?.cancel();
    _sessionSub?.cancel();
    super.dispose();
  }
}