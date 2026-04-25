import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stocks_service.dart';

final stocksServiceProvider = Provider((ref) => StocksService());

final recommendationsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(stocksServiceProvider);
  return await service.getRecommendations();
});
