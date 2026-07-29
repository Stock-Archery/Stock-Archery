import 'package:purchases_flutter/models/customer_info_wrapper.dart';

class PremiumState {
  final bool isLoading;
  final bool superPremium;
  final CustomerInfo? customerInfo;
  final String? errorMessage;

  PremiumState({
    this.isLoading = true,
    this.superPremium = false,
    this.customerInfo,
    this.errorMessage,
  });

  PremiumState copyWith({
    bool? isLoading,
    bool? superPremium,
    CustomerInfo? customerInfo,
    String? errorMessage,
  }) {
    return PremiumState(
      isLoading: isLoading ?? this.isLoading,
      superPremium: superPremium ?? this.superPremium,
      customerInfo: customerInfo ?? this.customerInfo,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}