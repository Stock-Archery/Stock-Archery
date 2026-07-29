import 'package:client/Features/payment/model/premium_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart'; // Apni state file import karein

class PremiumNotifier extends StateNotifier<PremiumState> {
  PremiumNotifier() : super(PremiumState()) {
    _init();
  }

  // App start hote hi user ki details load karega
  Future<void> _init() async {
    try {
      // RevenueCat se user ki current profile details nikaalo
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _updateStatus(customerInfo);

      // Jab bhi user purchase karega ya status badlega, yeh listener automatically trigger hoga
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updateStatus(customerInfo);
      });
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void _updateStatus(CustomerInfo customerInfo) {
    // 'premium' wahi entitlement ID hai jo aapne RevenueCat dashboard par banayi thi
    bool superPremium = customerInfo.entitlements.all['premium']?.isActive ?? false;
    
    state = state.copyWith(
      isLoading: false,
      superPremium: superPremium,
      customerInfo: customerInfo,
      errorMessage: null,
    );
  }

  // Purchase process trigger karne ka method
  Future<bool> purchasePackage(Package package) async {
    try {
      state = state.copyWith(isLoading: true);
      final result = await Purchases.purchasePackage(package);
      final customerInfo = result.customerInfo;
      //CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      _updateStatus(customerInfo);
      return state.superPremium;
    } catch (e) {
      //state = state.copyWith(isLoading: false, errorMessage: e.toString());

      if (e is PlatformException && e.code == PurchasesErrorCode.purchaseCancelledError.toString()) {
    // User ne khud cancel kiya hai, toh koi error mat dikhao, bas loading false kar do
    state = state.copyWith(isLoading: false);
    debugPrint("User cancelled the purchase flow.");
    } else {
      // Asli error (jaise internet na hona)
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }

      return false;
    }
  }

  // Purani purchases restore karne ke liye (Aapke app ke settings page ke liye)
  // Purani purchases restore karne ke liye
  Future<void> restorePurchases() async {
    try {
      state = state.copyWith(isLoading: true);
      
      // CHANGE HERE: explicit CustomerInfo type hatakar simple 'final' likho
      final customerInfo = await Purchases.restorePurchases();
      
      _updateStatus(customerInfo);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

// Global Provider jise hum pure UI me use karenge
final premiumProvider = StateNotifierProvider<PremiumNotifier, PremiumState>((ref) {
  return PremiumNotifier();
});