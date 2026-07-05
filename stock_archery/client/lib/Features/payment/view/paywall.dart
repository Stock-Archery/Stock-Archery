import 'package:client/Features/payment/view_model/offering_provider.dart';
import 'package:client/Features/payment/view_model/premium_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/models/offering_wrapper.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';


class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch live products from Google Play via RevenueCat
    final offeringsAsync = ref.watch(offeringsProvider);
    final premiumState = ref.watch(premiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("👑 Stock Archery Pro")),
      body: offeringsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error loading plans: $err")),
        data: (offerings) {
          // Dashboard par set kiya hua 'default_paywall' offering uthao
          final currentOffering = offerings?.current;
          
          if (currentOffering == null || currentOffering.availablePackages.isEmpty) {
            return const Center(child: Text("No active subscription plans found."));
          }

          // Aapka Annual package yahan list mein milega
          final annualPackage = currentOffering.availablePackages.firstWhere(
            (pkg) => pkg.packageType == PackageType.annual,
            orElse: () => currentOffering.availablePackages.first,
          );

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
                const SizedBox(height: 16),
                const Text(
                  "Unlock Full Archery Analytics",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                
                // Package Box UI
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.amber.withOpacity(0.05),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            annualPackage.storeProduct.title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text("Full yearly billing cycle access"),
                        ],
                      ),
                      // Automatically localizes price based on region (e.g., ₹999/yr)
                      Text(
                        annualPackage.storeProduct.priceString,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Action Purchase Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: premiumState.isLoading 
                      ? null 
                      : () async {
                          // Trigger execution inside notifier
                          final success = await ref
                              .read(premiumProvider.notifier)
                              .purchasePackage(annualPackage);

                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("🎉 Purchase Successful! Welcome to Pro.")),
                            );
                            Navigator.pop(context); // Screen close karo checkout ke baad
                          }
                        },
                  child: premiumState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SUBSCRIBE NOW", style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                ),
                
                const SizedBox(height: 16),
                
                // Restore Button (App Review standard practice rule)
                TextButton(
                  onPressed: () async {
                    await ref.read(premiumProvider.notifier).restorePurchases();
                  },
                  child: const Text("Restore Existing Purchase", style: TextStyle(color: Colors.grey)),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}