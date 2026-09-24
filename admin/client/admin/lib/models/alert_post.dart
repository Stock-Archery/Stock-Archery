class AlertPost {
  final String id;
  final String category;
  final String text;

  /// The alert's image, hosted on ImageKit.
  final String? imageUrl;

  /// LEGACY: posts made before ImageKit carry their image inline as base64.
  /// New posts never have this; they use [imageUrl].
  final String? imageBase64;

  final DateTime createdAt;

  AlertPost({
    required this.id,
    required this.category,
    required this.text,
    this.imageUrl,
    this.imageBase64,
    required this.createdAt,
  });

  bool get hasImageUrl => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasLegacyImage => imageBase64 != null && imageBase64!.isNotEmpty;
  bool get hasImage => hasImageUrl || hasLegacyImage;

  /// A resized version for list thumbnails. ImageKit resizes on the fly via
  /// URL parameters, so the list doesn't download full-size originals.
  String? thumbnailUrl({int width = 600}) {
    if (!hasImageUrl) return null;
    final separator = imageUrl!.contains('?') ? '&' : '?';
    return '$imageUrl${separator}tr=w-$width,q-80';
  }

  factory AlertPost.fromJson(Map<String, dynamic> json) {
    return AlertPost(
      id: json['_id']?.toString() ?? '',
      category: json['category'] ?? '',
      text: json['text'] ?? '',
      imageUrl: json['imageUrl'],
      imageBase64: json['imageBase64'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
