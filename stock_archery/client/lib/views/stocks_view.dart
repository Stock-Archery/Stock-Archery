import 'package:client/utils/design_system/design_system.dart';
import 'package:client/viewmodels/stocks_viewmodel.dart';
import 'package:client/viewmodels/navigation_viewmodel.dart';
import 'package:client/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class StocksView extends ConsumerWidget {
  const StocksView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final isPremium = ref.watch(authProvider).user?.isPremium ?? false;
    final String formattedDate = DateFormat(
      'MMMM dd, yyyy',
    ).format(DateTime.now()).toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.deepObsidian,
      body: recommendationsAsync.when(
        data: (stocks) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(recommendationsProvider.future),
            backgroundColor: AppColors.surfaceContainer,
            color: AppColors.goldBright,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.containerMarginMobile,
                vertical: AppSpacing.lg,
              ),
              children: [
                // 📅 Header Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top',
                          style: GoogleFonts.montserrat(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldBright,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Recommendations',
                          style: GoogleFonts.montserrat(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldBright,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: IconButton(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.goldBright,
                          size: 28,
                        ),
                        onPressed: () =>
                            ref.refresh(recommendationsProvider.future),
                        tooltip: 'Refresh Recommendations',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppColors.subtleGrey.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'POTENTIAL HIGH-MOVEMENT STOCKS FOR',
                          style:
                              AppTypography.labelSm(
                                color: AppColors.subtleGrey.withValues(
                                  alpha: 0.8,
                                ),
                              ).copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 22.0),
                      child: Text(
                        formattedDate,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldBright,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Empty State
                if (stocks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 64.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppColors.subtleGrey.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            "No recommendations yet",
                            style: AppTypography.titleMd(
                              color: AppColors.subtleGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Stock Cards List
                  ...stocks.asMap().entries.map((entry) {
                    return _StockCard(
                      symbol: entry.value,
                      index: entry.key + 1,
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Premium Upgrade Card
                if (!isPremium) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _PremiumUpgradeCard(
                    onUpgradePressed: () {
                      ref.read(navigationProvider.notifier).state = 4;
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldBright),
          ),
        ),
        error: (err, stack) => RefreshIndicator(
          onRefresh: () => ref.refresh(recommendationsProvider.future),
          backgroundColor: AppColors.surfaceContainer,
          color: AppColors.goldBright,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        "Oops! Something went wrong",
                        style: AppTypography.titleMd(
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        err.toString().replaceAll("Exception: ", ""),
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMd(
                          color: AppColors.subtleGrey,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.invalidate(recommendationsProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text("Retry"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldBright,
                          foregroundColor: AppColors.deepObsidian,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          textStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final String symbol;
  final int index;

  const _StockCard({required this.symbol, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: AppColors.goldBright.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.goldBright,
          ),
          child: Center(
            child: Text(
              "$index",
              style: GoogleFonts.montserrat(
                color: AppColors.deepObsidian,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
        title: Text(
          symbol,
          style: GoogleFonts.montserrat(
            color: AppColors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            "FEATURED RECOMMENDATION",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.subtleGrey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.subtleGrey,
        ),
        onTap: () {
          // Keep existing behavior or visual interactive response
        },
      ),
    );
  }
}

class _PremiumUpgradeCard extends StatelessWidget {
  final VoidCallback onUpgradePressed;

  const _PremiumUpgradeCard({required this.onUpgradePressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(
          color: AppColors.goldBright.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle circular star watermark in the bottom right corner
          Positioned(
            right: -24,
            bottom: -24,
            child: Opacity(
              opacity: 0.08,
              child: Icon(
                Icons.stars_rounded,
                size: 120,
                color: AppColors.goldBright,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Unlock Advanced Strategy",
                  style: GoogleFonts.montserrat(
                    color: AppColors.goldBright,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  "Get real-time entry and exit alerts for these stocks and more with Archery Premium.",
                  style: GoogleFonts.inter(
                    color: AppColors.onSurface.withValues(alpha: 0.75),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onUpgradePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldBright,
                      foregroundColor: AppColors.deepObsidian,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    child: Text(
                      "UPGRADE TO PREMIUM",
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.8,
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
