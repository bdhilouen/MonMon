class Achievement {
  final String id;
  final String title;
  final String description;
  final String conditionType;
  final double conditionValue;
  final String icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progressCurrent;
  final double progressTarget;
  final double progressPercentage;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.conditionType,
    required this.conditionValue,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progressCurrent = 0,
    this.progressTarget = 0,
    this.progressPercentage = 0,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      conditionType: json['condition_type'] ?? '',
      conditionValue: (json['condition_value'] as num?)?.toDouble() ?? 0.0,
      icon: json['icon'] ?? '*',
      isUnlocked: json['is_unlocked'] ?? false,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.tryParse(json['unlocked_at'].toString())
          : null,
      progressCurrent: (json['progress_current'] as num?)?.toDouble() ?? 0.0,
      progressTarget: (json['progress_target'] as num?)?.toDouble() ??
          (json['condition_value'] as num?)?.toDouble() ??
          0.0,
      progressPercentage:
          (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
