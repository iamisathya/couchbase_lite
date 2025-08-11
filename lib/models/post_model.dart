class PostModel {
  final String id;
  final int userId;
  String title;
  String body;
  final DateTime createdAt;
  DateTime updatedAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Create from JSONPlaceholder API response
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'].toString(),
      userId: json['userId'] ?? 1,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
    );
  }

  // Create from CouchbaseLite document
  factory PostModel.fromDocument(Map<String, dynamic> doc) {
    return PostModel(
      id: doc['id']?.toString() ?? '',
      userId: doc['userId'] ?? 1,
      title: doc['title'] ?? '',
      body: doc['body'] ?? '',
      createdAt: doc['createdAt'] != null ? DateTime.parse(doc['createdAt']) : DateTime.now(),
      updatedAt: doc['updatedAt'] != null ? DateTime.parse(doc['updatedAt']) : DateTime.now(),
    );
  }

  // Convert to Map for CouchbaseLite storage
  Map<String, dynamic> toDocument() {
    return {
      'type': 'post',
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create copy with updated fields
  PostModel copyWith({
    String? id,
    int? userId,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  void updateContent({String? title, String? body}) {
    if (title != null) this.title = title;
    if (body != null) this.body = body;
    updatedAt = DateTime.now();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PostModel(id: $id, userId: $userId, title: $title, body: $body)';
  }
}