class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String audioUrl;
  final String coverUrl;
  final Duration duration;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.audioUrl,
    required this.coverUrl,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'audioUrl': audioUrl,
        'coverUrl': coverUrl,
        'duration': duration.inMilliseconds,
      };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        id: json['id'],
        title: json['title'],
        artist: json['artist'],
        album: json['album'],
        audioUrl: json['audioUrl'],
        coverUrl: json['coverUrl'],
        duration: Duration(milliseconds: json['duration']),
      );
}