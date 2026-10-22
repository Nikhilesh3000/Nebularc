import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentRoom {
  final String code;
  final String name;
  final int joinedAt;

  RecentRoom({
    required this.code,
    required this.name,
    required this.joinedAt,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'joinedAt': joinedAt,
      };

  factory RecentRoom.fromJson(Map<String, dynamic> json) => RecentRoom(
        code: json['code'] ?? '',
        name: json['name'] ?? '',
        joinedAt: json['joinedAt'] ?? 0,
      );
}

class RoomsHistoryService {
  static const _key = 'recent_rooms';
  static const _maxRooms = 10;

  /// Save a room to history. Deduplicates by code and moves to front.
  static Future<void> addRoom(String code, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getRooms();

    // Remove if already exists
    list.removeWhere((r) => r.code == code);

    // Add to front
    list.insert(
      0,
      RecentRoom(code: code, name: name, joinedAt: DateTime.now().millisecondsSinceEpoch),
    );

    // Trim to max
    if (list.length > _maxRooms) {
      list.removeRange(_maxRooms, list.length);
    }

    await prefs.setString(
      _key,
      jsonEncode(list.map((r) => r.toJson()).toList()),
    );
  }

  /// Get all recently joined rooms (most recent first).
  static Future<List<RecentRoom>> getRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((j) => RecentRoom.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Remove a specific room from history.
  static Future<void> removeRoom(String code) async {
    final list = await getRooms();
    list.removeWhere((r) => r.code == code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(list.map((r) => r.toJson()).toList()),
    );
  }

  /// Clear all history.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
