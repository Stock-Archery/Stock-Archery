import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert_post.dart';
import '../services/alerts_service.dart';
import '../services/app_config.dart';

final alertsServiceProvider = Provider<AlertsService>((ref) {
  return AlertsService(baseUrl: AppConfig.baseUrl);
});

final selectedCategoryProvider = StateProvider<String>((ref) => 'SOB');

final alertsProvider = FutureProvider.family<List<AlertPost>, String>((ref, category) async {
  final service = ref.watch(alertsServiceProvider);
  return service.getAlerts(category);
});
