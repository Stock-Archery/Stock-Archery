class AlertPost {
  final String id;
  final String category;
  final String text;
  final String? imageBase64;
  final DateTime createdAt;

  AlertPost({
    required this.id,
    required this.category,
    required this.text,
    this.imageBase64,
    required this.createdAt,
  });

  factory AlertPost.fromJson(Map<String, dynamic> json) {
    return AlertPost(
      id: json['_id']?.toString() ?? '',
      category: json['category'] ?? '',
      text: json['text'] ?? '',
      imageBase64: json['imageBase64'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
