class Room {
  final String code;
  final String name;
  final String hostId;
  final String? currentDjId;
  final List<RoomMember> members;

  Room({
    required this.code,
    required this.name,
    required this.hostId,
    this.currentDjId,
    this.members = const [],
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      hostId: json['hostId'] ?? '',
      currentDjId: json['currentDjId'],
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => RoomMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RoomMember {
  final String socketId;
  final String userId;
  final String username;
  final int joinedAt;

  RoomMember({
    required this.socketId,
    required this.userId,
    required this.username,
    required this.joinedAt,
  });

  factory RoomMember.fromJson(Map<String, dynamic> json) {
    return RoomMember(
      socketId: json['socketId'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? 'Anonymous',
      joinedAt: json['joinedAt'] ?? 0,
    );
  }
}