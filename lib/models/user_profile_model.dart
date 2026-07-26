class UserProfileModel {
  final String name;
  final String avatarUrl;
  final int overallStreak;
  final String joinedDate;
  UserProfileModel({
    required this.name,
    required this.avatarUrl,
    required this.overallStreak,
    required this.joinedDate,
  });
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'avatarUrl': avatarUrl,
      'overallStreak': overallStreak,
      'joinedDate': joinedDate,
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      name: map['name'] as String? ?? 'Alex',
      avatarUrl: map['avatarUrl'] as String? ?? '',
      overallStreak: map['overallStreak'] as int? ?? 12,
      joinedDate: map['joinedDate'] as String? ?? 'October 2024',
    );
  }
}
