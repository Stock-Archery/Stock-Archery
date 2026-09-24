class AlertPost {
  final String id;
  final String category;
  final String text;

  /// The alert's image, hosted on ImageKit.
  final String? imageUrl;

  /// LEGACY: alerts posted before ImageKit carry their image inline as base64.
  /// Only present on those older posts; new posts use [imageUrl].
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

  /// A feed-sized version of the image. ImageKit resizes and recompresses on
  /// the fly via URL parameters, so the feed downloads far less than the
  /// original. The full-screen viewer uses [imageUrl] as is.
  String? get feedImageUrl {
    if (!hasImageUrl) return null;
    final separator = imageUrl!.contains('?') ? '&' : '?';
    return '$imageUrl${separator}tr=w-1080,q-85';
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
