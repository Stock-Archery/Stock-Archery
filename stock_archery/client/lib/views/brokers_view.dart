import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:client/utils/design_system/design_system.dart';

class BrokersView extends StatefulWidget {
  const BrokersView({super.key});

  @override
  State<BrokersView> createState() => _BrokersViewState();
}

class _BrokersViewState extends State<BrokersView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void _showComingSoon(BuildContext context, String broker) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "$broker integration is coming soon! Stay tuned.",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepObsidian,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.containerMarginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title / Description
              Text(
                "Broker Partners",
                style: AppTypography.headlineLgMobile(
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Compare top-tier brokers and get exclusive benefits.",
                style: AppTypography.bodyMd(color: AppColors.subtleGrey),
              ),
              const SizedBox(height: 24),

              // How to Earn Section Header
              Text(
                "How to Claim Benefits",
                style: AppTypography.titleMd(color: AppColors.goldBright),
              ),
              const SizedBox(height: 16),

              // How to Earn Steps Grid (2x2 with descriptions)
              _buildHowToEarnGrid(),
              const SizedBox(height: 32),

              // Fill Form to Claim Benefits Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      _launchUrl("https://forms.gle/dKjcY2FPy534AC2o7"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldBright,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 4,
                    shadowColor: AppColors.goldBright.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Fill Form to Claim Benefits",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Broker Cards
              _buildBrokerCard(
                name: "Fyers",
                logoAsset: "assets/logos/fyers.jpeg",
                description:
                    "Focus on long-term investing with zero brokerage.",
                color: const Color(0xFF2563EB),
                isPopular: true,
                isWide: false,
                onTap: () => _launchUrl(
                  "https://signup.fyers.in/?utm-source=AP-Leads&utm-medium=AP3324",
                ),
                onVerifyTap: () =>
                    _launchUrl("https://forms.gle/M9pksV9eWH2sjqPB6"),
              ),
              _buildBrokerCard(
                name: "CoinDCX",
                logoAsset: "assets/logos/coindcx.png",
                description: "India's safest crypto exchange with 500+ assets.",
                color: const Color(0xFFF97316),
                isPopular: false,
                isWide: true,
                onTap: () => _launchUrl("https://invite.coindcx.com/46915912"),
                onVerifyTap: () =>
                    _launchUrl("https://forms.gle/idJxF6auWfS7Yiy69"),
              ),
              _buildBrokerCard(
                name: "Angel One",
                logoAsset: "assets/logos/angelone.png",
                description: "Intelligent trading with ARQ Prime advisory.",
                color: const Color(0xFF3B82F6),
                isPopular: false,
                isWide: true,
                onTap: () => _showComingSoon(context, "Angel One"),
              ),
              _buildBrokerCard(
                name: "Dhan",
                logoAsset: "assets/logos/dhan.jpeg",
                description: "Lighting fast trading experience for pros.",
                color: const Color(0xFF22C55E),
                isPopular: false,
                isWide: false,
                onTap: () => _showComingSoon(context, "Dhan"),
              ),
              _buildBrokerCard(
                name: "Upstox",
                logoAsset: "assets/logos/upstox.jpeg",
                description: "Reliable platform with advanced analytics.",
                color: const Color(0xFF9333EA),
                isPopular: false,
                isWide: false,
                onTap: () => _showComingSoon(context, "Upstox"),
              ),

              const SizedBox(height: 24),

              // Assistance Card
              _buildAssistanceCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowToEarnGrid() {
    final List<Map<String, dynamic>> steps = [
      {
        "icon": Icons.person_add_alt_1_outlined,
        "title": "Open Account",
        "desc": "Open a new trading account via the broker link.",
      },
      {
        "icon": Icons.account_balance_wallet_outlined,
        "title": "Add Funds",
        "desc": "Add min ₹100 and execute first trade within 7 days.",
      },
      {
        "icon": Icons.crop_free_outlined,
        "title": "Take Screenshot",
        "desc": "Capture client ID and trade confirmation screen.",
      },
      {
        "icon": Icons.check_circle_outline_outlined,
        "title": "Submit Details",
        "desc": "Upload screenshots through form to claim benefit.",
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.pureBlack.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.subtleGrey.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  step["icon"] as IconData,
                  color: AppColors.metallicGold,
                  size: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step["title"] as String,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step["desc"] as String,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.subtleGrey,
                  height: 1.25,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrokerCard({
    required String name,
    required String logoAsset,
    required String description,
    required Color color,
    bool isPopular = false,
    bool isWide = false,
    required VoidCallback onTap,
    VoidCallback? onVerifyTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.subtleGrey.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isWide ? Colors.white : color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      logoAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          name[0],
                          style: GoogleFonts.inter(
                            color: isWide ? color : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.subtleGrey,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        onVerifyTap ?? () => _showComingSoon(context, name),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.metallicGold,
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      foregroundColor: AppColors.metallicGold,
                    ),
                    child: Text(
                      "Registered? Verify",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Open Account",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.pureBlack.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.subtleGrey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Need Assistance?",
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Our elite support team is ready to help you with your account verification.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.subtleGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.metallicGold, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              foregroundColor: AppColors.metallicGold,
            ),
            child: Text(
              "Contact Support",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
