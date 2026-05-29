class User {
  final String id;
  final String name;
  final String email;
  final double balance;
  final int points;
  final int level;
  final int streak;
  final DateTime? lastActiveDate;
  final DateTime? emailVerifiedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.balance = 0,
    this.points = 0,
    this.level = 1,
    this.streak = 0,
    this.lastActiveDate,
    this.emailVerifiedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      balance: (json['balance'] is int)
          ? (json['balance'] as int).toDouble()
          : (json['balance'] as num?)?.toDouble() ?? 0.0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      lastActiveDate: json['last_active_date'] != null
          ? DateTime.tryParse(json['last_active_date'].toString())
          : null,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'].toString())
          : null,
    );
  }
}
