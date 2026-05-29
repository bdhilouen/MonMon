class Category {
  final String id;
  final String? userId;
  final String name;
  final String icon;
  final String color;
  final String type; // 'income' or 'expense'

  Category({
    required this.id,
    this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  bool get isCustom => userId != null;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      name: json['name'] ?? '',
      icon: json['icon'] ?? '📦',
      color: json['color'] ?? '#999999',
      type: json['type'] ?? 'expense',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
    };
  }
}
