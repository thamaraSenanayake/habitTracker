// export const HABIT_MODEL_DART = `import 'dart:convert';
import 'dart:convert';

class HabitModel {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String category;
  final int targetCount;
  final String unit;
  final int currentCount;
  final String colorBg;
  final String colorText;
  final int streakDays;
  final List<String> completedDates;
  final Map<String, int> logs;
  final String createdAt;
  final String? reminderTime;
  HabitModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.category,
    required this.targetCount,
    required this.unit,
    required this.currentCount,
    required this.colorBg,
    required this.colorText,
    required this.streakDays,
    required this.completedDates,
    required this.logs,
    required this.createdAt,
    this.reminderTime,
  });
  bool isCompletedOn(String dateStr) {
    return completedDates.contains(dateStr);
  }

  HabitModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? icon,
    String? category,
    int? targetCount,
    String? unit,
    int? currentCount,
    String? colorBg,
    String? colorText,
    int? streakDays,
    List<String>? completedDates,
    Map<String, int>? logs,
    String? createdAt,
    String? reminderTime,
  }) {
    return HabitModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      targetCount: targetCount ?? this.targetCount,
      unit: unit ?? this.unit,
      currentCount: currentCount ?? this.currentCount,
      colorBg: colorBg ?? this.colorBg,
      colorText: colorText ?? this.colorText,
      streakDays: streakDays ?? this.streakDays,
      completedDates: completedDates ?? this.completedDates,
      logs: logs ?? this.logs,
      createdAt: createdAt ?? this.createdAt,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  // Convert to Map for sqflite database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'category': category,
      'targetCount': targetCount,
      'unit': unit,
      'currentCount': currentCount,
      'colorBg': colorBg,
      'colorText': colorText,
      'streakDays': streakDays,
      'completedDates': jsonEncode(completedDates),
      'logs': jsonEncode(logs),
      'createdAt': createdAt,
      'reminderTime': reminderTime,
    };
  }

  // Construct from sqflite record
  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
      icon: map['icon'] as String,
      category: map['category'] as String,
      targetCount: map['targetCount'] as int,
      unit: map['unit'] as String,
      currentCount: map['currentCount'] as int,
      colorBg: map['colorBg'] as String,
      colorText: map['colorText'] as String,
      streakDays: map['streakDays'] as int,
      completedDates: List<String>.from(
        jsonDecode(map['completedDates'] as String? ?? '[]'),
      ),
      logs: Map<String, int>.from(jsonDecode(map['logs'] as String? ?? '{}')),
      createdAt: map['createdAt'] as String,
      reminderTime: map['reminderTime'] as String?,
    );
  }
}
