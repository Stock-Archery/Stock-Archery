class StockRecommendation {
  final String id;
  final List<String> stocks;
  final DateTime updatedAt;

  StockRecommendation({
    required this.id,
    required this.stocks,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': 'current_recommendations',
      'stocks': stocks,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StockRecommendation.fromJson(Map<String, dynamic> json) {
    return StockRecommendation(
      id: json['_id']?.toString() ?? '',
      stocks: List<String>.from(json['stocks'] ?? []),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
