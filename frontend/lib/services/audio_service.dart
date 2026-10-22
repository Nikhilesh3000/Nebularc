import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/song.dart';

class AudioService {
  AudioService._internal();
  static final AudioService instance = AudioService._internal();

  final AudioPlayer player = AudioPlayer();
  List<Song> _queue = [];
  int _currentIndex = 0;

  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  Song? get currentSong =>
      _queue.isEmpty ? null : _queue[_currentIndex];

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> playSong(Song song, {List<Song>? queue}) async {
    if (queue != null) {
      _queue = queue;
      _currentIndex = queue.indexWhere((s) => s.id == song.id);
      if (_currentIndex < 0) _currentIndex = 0;
    } else {
      _queue = [song];
      _currentIndex = 0;
    }
    await player.setUrl(song.audioUrl);
    player.play();
  }

  Future<void> playNext() async {
    if (_queue.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _queue.length;
    await player.setUrl(_queue[_currentIndex].audioUrl);
    player.play();
  }

  Future<void> playPrevious() async {
    if (_queue.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    await player.setUrl(_queue[_currentIndex].audioUrl);
    player.play();
  }

  void togglePlayPause() {
    if (player.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  Future<void> seek(Duration position) => player.seek(position);
  Future<void> stop() async {
    await player.stop();
    _queue = [];
    _currentIndex = 0;
  }
   
  Future<void> playAtPosition({
    required Song song,
    required Duration position,
    List<Song>? queue,
  }) async {
    if (queue != null) {
      _queue = queue;
      _currentIndex = queue.indexWhere((s) => s.id == song.id);
      if (_currentIndex < 0) _currentIndex = 0;
    } else {
      _queue = [song];
      _currentIndex = 0;
    }

    await player.setUrl(song.audioUrl);
    if (position > Duration.zero) {
      await player.seek(position);
    }
    player.play();
  }

 
  int get currentPositionMs => player.position.inMilliseconds;


  bool get isPlaying => player.playing;
}
