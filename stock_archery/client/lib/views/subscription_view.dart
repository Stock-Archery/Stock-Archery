import 'package:client/Features/payment/view_model/offering_provider.dart';
import 'package:client/widgets/build_Feature.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 Add Riverpod
import 'package:purchases_flutter/purchases_flutter.dart'; // 👈 Add RevenueCat models

// Apne providers ka exact path yahan sahi se daal dena:
import 'package:client/features/payment/view_model/premium_provider.dart'; 
//import 'package:client/features/payment/view_model/offerings_provider.dart';

class SubscriptionView extends ConsumerWidget { // 👈 Changed to ConsumerWidget
  const SubscriptionView({super.key});

  void _showSubscriptionSheet(BuildContext context, WidgetRef ref, Package annualPackage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // Hamare premiumProvider ki live state ko listen karne ke liye inside builder
        return Consumer(
          builder: (context, ref, child) {
            final premiumState = ref.watch(premiumProvider);

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 56,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Confirm Premium',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure checkout with payment details below. Tap Pay to activate premium access.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const PaymentDetailRow(
                    icon: Icons.credit_card,
                    title: 'Card Type',
                    subtitle: 'Google Play Subscription', // 👈 Cleaned up text
                  ),
                  PaymentDetailRow(
                    icon: Icons.calendar_today_outlined,
                    title: 'Billing Cycle',
                    subtitle: 'Yearly access (${annualPackage.storeProduct.priceString}/year)', // 👈 Dynamic price string
                  ),
                  const PaymentDetailRow(
                    icon: Icons.security,
                    title: 'Payment Security',
                    subtitle: 'Encrypted and Google Play secured',
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // Agar loading chal rahi hai toh button disable ho jayega
                      onPressed: premiumState.isLoading
                          ? null
                          : () async {
                              // Actual backend logic trigger ho rahi hai yahan
                              final success = await ref
                                  .read(premiumProvider.notifier)
                                  .purchasePackage(annualPackage);

                              if (context.mounted) {
                                Navigator.pop(context); // Close sheet
                                
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Subscription successful! 🎉 Welcome to Pro.',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                      ),
                                      backgroundColor: const Color(0xFF10B981), // Success Green
                                    ),
                                  );
                                } else if (premiumState.errorMessage != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Payment Failed or Cancelled ❌',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: premiumState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Pay ${annualPackage.storeProduct.priceString}', // 👈 Localized Store Price (e.g., ₹499)
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) { // 👈 Added WidgetRef
    // Google Play se products fetch karo
    final offeringsAsync = ref.watch(offeringsProvider);
    final premiumState = ref.watch(premiumProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Premium',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ),
      body: offeringsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error fetching subscription: $err")),
        data: (offerings) {

          debugPrint("🚨 REVENUECAT DUMP: ${offerings?.all}");
          debugPrint("🚨 CURRENT OFFERING DUMP: ${offerings?.current}");
          
          final currentOffering = offerings?.current;
          
          if (currentOffering == null || currentOffering.availablePackages.isEmpty) {
            return const Center(child: Text("No subscription bundles found on Play Console."));
          }

          // Aapka Annual package automatically select hoga yahan dashboard se
          final activePackage = currentOffering.availablePackages.firstWhere(
            (pkg) => pkg.packageType == PackageType.annual,
            orElse: () => currentOffering.availablePackages.first,
          );

          final localizedPrice = activePackage.storeProduct.priceString;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HERO SECTION
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.25),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'MOST POPULAR',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Unlock Smarter Investing 🚀',
                        style: GoogleFonts.inter(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Premium AI insights, influencer stock tracking, advanced trading lectures, and powerful investment tools.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Text(
                            localizedPrice, // 👈 Dashboard dynamic price string
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '/year', // 👈 Naming sync with your Play Console annual plan
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Premium Features',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                FeatureCard(
                  title: 'Live AI Trading Bot',
                  description: 'Get instant AI-powered answers to your stock market queries anytime.',
                  color: const Color(0xFF4F46E5),
                ),
                const SizedBox(height: 16),
                FeatureCard(
                  title: 'Premium Video Lectures',
                  description: 'Master trading and investing with expert-curated premium lessons.',
                  color: const Color(0xFFEC4899),
                ),
                const SizedBox(height: 16),
                FeatureCard(
                  title: 'Top Influencer Stocks',
                  description: 'Track trending investments and portfolios from top creators.',
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(height: 16),
                FeatureCard(
                  title: 'AI Buy/Sell Signals',
                  description: 'Receive smart stock alerts and AI-generated trading opportunities.',
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 16),
                FeatureCard(
                  title: 'Broker Referral Rewards',
                  description: 'Earn cashback and rewards with our premium broker referral program.',
                  color: const Color(0xFF8B5CF6),
                ),
                const SizedBox(height: 32),

                /// SUBSCRIBE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // Package details ko sheet ke andar pass kiya
                    onPressed: () => _showSubscriptionSheet(context, ref, activePackage),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: premiumState.isPremium ? const Color(0xFF10B981) : const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          premiumState.isPremium ? Icons.check_circle : Icons.workspace_premium_rounded,
                          color: Colors.amber,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          premiumState.isPremium ? 'You are a Pro User 👑' : 'Subscribe Now',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'Secure Payments • Cancel Anytime • Instant Access',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  ),
);
}
}