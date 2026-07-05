import 'package:purchases_flutter/models/customer_info_wrapper.dart';

class PremiumState {
  final bool isLoading;
  final bool isPremium;
  final CustomerInfo? customerInfo;
  final String? errorMessage;

  PremiumState({
    this.isLoading = true,
    this.isPremium = false,
    this.customerInfo,
    this.errorMessage,
  });

  PremiumState copyWith({
    bool? isLoading,
    bool? isPremium,
    CustomerInfo? customerInfo,
    String? errorMessage,
  }) {
    return PremiumState(
      isLoading: isLoading ?? this.isLoading,
      isPremium: isPremium ?? this.isPremium,
      customerInfo: customerInfo ?? this.customerInfo,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}