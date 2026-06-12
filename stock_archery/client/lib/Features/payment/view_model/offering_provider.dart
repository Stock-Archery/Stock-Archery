import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// Yeh provider automatic dashboard se active packages utha ke laayega
final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  try {
    Offerings offerings = await Purchases.getOfferings();
    return offerings;
  } catch (e) {
    return null;
  }
});