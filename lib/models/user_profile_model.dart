import 'dart:typed_data';

class UserProfileModel {
  final String userId;
  final String name;
  final String avatarUrl;
  final Uint8List? avatarData;
  final int overallStreak;
  final String joinedDate;

  UserProfileModel({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    this.avatarData,
    required this.overallStreak,
    required this.joinedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'avatarUrl': avatarUrl,
      'avatarData': avatarData,
      'overallStreak': overallStreak,
      'joinedDate': joinedDate,
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      userId: map['userId'] as String? ?? '1',
      name: map['name'] as String? ?? 'Alex',
      avatarUrl: map['avatarUrl'] as String? ?? '',
      avatarData: map['avatarData'] as Uint8List?,
      overallStreak: map['overallStreak'] as int? ?? 12,
      joinedDate: map['joinedDate'] as String? ?? 'October 2024',
    );
  }

  UserProfileModel copyWith({
    String? userId,
    String? name,
    String? avatarUrl,
    Uint8List? avatarData,
    int? overallStreak,
    String? joinedDate,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarData: avatarData ?? this.avatarData,
      overallStreak: overallStreak ?? this.overallStreak,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }
}
