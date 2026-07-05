import 'package:client/Features/payment/view_model/offering_provider.dart';
import 'package:client/Features/payment/view_model/premium_provider.dart';
import 'package:client/utils/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionView extends ConsumerWidget {
  const SubscriptionView({super.key});

  void _showSubscriptionSheet(
    BuildContext context,
    WidgetRef ref,
    Package annualPackage,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.deepObsidian,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final premiumState = ref.watch(premiumProvider);

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.containerMarginMobile,
                right: AppSpacing.containerMarginMobile,
                top: AppSpacing.lg,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.subtleGrey.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.goldBright.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: AppColors.goldBright.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.goldBright,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Confirm Premium',
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Secure Google Play checkout',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.subtleGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PaymentDetailRow(
                    icon: Icons.credit_card_rounded,
                    title: 'Subscription Type',
                    subtitle: 'Google Play subscription',
                  ),
                  _PaymentDetailRow(
                    icon: Icons.calendar_today_outlined,
                    title: 'Billing Cycle',
                    subtitle:
                        'Yearly access (${annualPackage.storeProduct.priceString}/year)',
                  ),
                  const _PaymentDetailRow(
                    icon: Icons.security_rounded,
                    title: 'Payment Security',
                    subtitle: 'Encrypted and secured by Google Play',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: premiumState.isLoading
                          ? null
                          : () async {
                              final success = await ref
                                  .read(premiumProvider.notifier)
                                  .purchasePackage(annualPackage);

                              if (!context.mounted) return;
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Subscription successful. Welcome to Premium.'
                                        : 'Payment failed or was cancelled.',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: success
                                          ? AppColors.deepObsidian
                                          : AppColors.onSurface,
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: success
                                      ? AppColors.goldBright
                                      : AppColors.errorContainer,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.md,
                                    ),
                                  ),
                                  margin: const EdgeInsets.all(AppSpacing.md),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldBright,
                        foregroundColor: AppColors.deepObsidian,
                        disabledBackgroundColor: AppColors.goldBright
                            .withValues(alpha: 0.45),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                      ),
                      child: premiumState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.deepObsidian,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'PAY ${annualPackage.storeProduct.priceString}',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.deepObsidian,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringsAsync = ref.watch(offeringsProvider);
    final premiumState = ref.watch(premiumProvider);

    return Scaffold(
      backgroundColor: AppColors.deepObsidian,
      body: offeringsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldBright),
          ),
        ),
        error: (err, stack) => _StateMessage(
          icon: Icons.error_outline_rounded,
          title: 'Unable to load Premium',
          message: err.toString(),
          color: AppColors.error,
        ),
        data: (offerings) {
          debugPrint('REVENUECAT DUMP: ${offerings?.all}');
          debugPrint('CURRENT OFFERING DUMP: ${offerings?.current}');

          final currentOffering = offerings?.current;

          if (currentOffering == null ||
              currentOffering.availablePackages.isEmpty) {
            return const _StateMessage(
              icon: Icons.inventory_2_outlined,
              title: 'No subscription found',
              message: 'No subscription bundles found on Play Console.',
              color: AppColors.subtleGrey,
            );
          }

          final activePackage = currentOffering.availablePackages.firstWhere(
            (pkg) => pkg.packageType == PackageType.annual,
            orElse: () => currentOffering.availablePackages.first,
          );

          final localizedPrice = activePackage.storeProduct.priceString;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerMarginMobile,
              AppSpacing.lg,
              AppSpacing.containerMarginMobile,
              AppSpacing.xxl,
            ),
            children: [
              Text(
                'Premium',
                style: GoogleFonts.montserrat(
                  color: AppColors.goldBright,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Upgrade your Stock Archery tools with AI insights, premium lessons, and advanced market tracking.',
                style: GoogleFonts.inter(
                  color: AppColors.subtleGrey,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _PlanCard(
                price: localizedPrice,
                isPremium: premiumState.isPremium,
                onPressed: premiumState.isPremium
                    ? null
                    : () => _showSubscriptionSheet(context, ref, activePackage),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'What You Unlock',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const _PremiumFeatureCard(
                icon: Icons.smart_toy_outlined,
                title: 'Live AI Trading Bot',
                description:
                    'Get instant AI-powered answers to your stock market questions.',
              ),
              const _PremiumFeatureCard(
                icon: Icons.play_circle_outline_rounded,
                title: 'Premium Video Lectures',
                description:
                    'Master trading and investing with expert-curated premium lessons.',
              ),
              const _PremiumFeatureCard(
                icon: Icons.people_alt_outlined,
                title: 'Top Influencer Stocks',
                description:
                    'Track trending investments and portfolios from top creators.',
              ),
              const _PremiumFeatureCard(
                icon: Icons.show_chart_rounded,
                title: 'AI Buy/Sell Signals',
                description:
                    'Receive smart stock alerts and AI-generated trading opportunities.',
              ),
              const _PremiumFeatureCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Broker Referral Rewards',
                description:
                    'Earn cashback and rewards with the premium broker referral program.',
              ),
              const SizedBox(height: AppSpacing.md),
              _TrustFooter(),
            ],
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String price;
  final bool isPremium;
  final VoidCallback? onPressed;

  const _PlanCard({
    required this.price,
    required this.isPremium,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(
          color: AppColors.goldBright.withValues(alpha: 0.22),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -28,
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 150,
              color: AppColors.goldBright.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldBright.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: AppColors.goldBright.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: AppColors.goldBright,
                        size: 15,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        isPremium ? 'ACTIVE PLAN' : 'MOST POPULAR',
                        style: GoogleFonts.inter(
                          color: AppColors.goldBright,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Archery Premium',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Built for sharper market decisions with premium research, AI tools, and broker benefits.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onSurface.withValues(alpha: 0.76),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        price,
                        style: GoogleFonts.montserrat(
                          color: AppColors.goldBright,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '/ year',
                        style: GoogleFonts.inter(
                          color: AppColors.subtleGrey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onPressed,
                    icon: Icon(
                      isPremium
                          ? Icons.check_circle_rounded
                          : Icons.workspace_premium_rounded,
                      size: 20,
                    ),
                    label: Text(isPremium ? 'PREMIUM ACTIVE' : 'UPGRADE NOW'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldBright,
                      foregroundColor: AppColors.deepObsidian,
                      disabledBackgroundColor: AppColors.goldBright.withValues(
                        alpha: 0.45,
                      ),
                      disabledForegroundColor: AppColors.deepObsidian
                          .withValues(alpha: 0.75),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      textStyle: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PremiumFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: AppColors.subtleGrey.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.goldBright.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: AppColors.goldBright.withValues(alpha: 0.24),
              ),
            ),
            child: Icon(icon, color: AppColors.goldBright, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.subtleGrey,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentDetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PaymentDetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.subtleGrey.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.goldBright, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.subtleGrey,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pureBlack.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.subtleGrey.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 16,
            color: AppColors.goldBright,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              'Secure payments - Cancel anytime - Instant access',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.subtleGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 58),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: AppColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.subtleGrey,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
