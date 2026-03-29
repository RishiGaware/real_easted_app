// ignore_for_file: file_names
class RolesModel {
  final String id;
  final String name;
  final String description;
  final String createdByUserId;
  final String updatedByUserId;
  final bool published;
  final int userCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  RolesModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdByUserId,
    required this.updatedByUserId,
    required this.published,
    this.userCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });


  /// Deserialize from JSON
  factory RolesModel.fromJson(Map<String, dynamic> json) {
    return RolesModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdByUserId: json['createdByUserId'] ?? '',
      updatedByUserId: json['updatedByUserId'] ?? '',
      published: json['published'] ?? false,
      userCount: json['userCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdByUserId': createdByUserId,
      'updatedByUserId': updatedByUserId,
      'published': published,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
