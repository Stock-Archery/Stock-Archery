import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class BrokersView extends StatefulWidget {
  const BrokersView({super.key});

  @override
  State<BrokersView> createState() => _BrokersViewState();
}

class _BrokersViewState extends State<BrokersView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _howToEarnKey = GlobalKey();

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

  void _scrollToHowToEarn() {
    final context = _howToEarnKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _showComingSoon(BuildContext context, String broker) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "$broker integration is coming soon! Stay tuned.",
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6366F1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showVerifyPlaceholder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Verification", style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Text(
          "A Google Form will open here shortly to verify your account registration. This feature is currently being finalized.",
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Got it", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Broker Partners",
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Compare and earn rewards",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCashbackCard(context, isDark),
                ],
              ),

              const SizedBox(height: 24),

              // How to Earn Shortcut (Replaces Available Offers Bar)
              InkWell(
                onTap: _scrollToHowToEarn,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Not sure how it works?",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            Text(
                              "Click here to see 'How to Earn'",
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6366F1)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Broker Cards
              _buildBrokerCard(
                context,
                name: "Fyers",
                logoAsset: "assets/logos/fyers.jpeg",
                reward: "₹ 0",
                description: "Fast execution, advanced charts & trading tools.",
                color: const Color(0xFF2563EB),
                isPopular: true,
                isDark: isDark,
                onTap: () => _launchUrl("https://signup.fyers.in/?utm-source=AP-Leads&utm-medium=AP3324"),
              ),
              _buildBrokerCard(
                context,
                name: "CoinDCX",
                logoAsset: "assets/logos/coindcx.png",
                isWide: true,
                reward: "₹ 0",
                description: "India's safest crypto exchange with 500+ assets.",
                color: const Color(0xFFF97316),
                isDark: isDark,
                onTap: () => _launchUrl("https://invite.coindcx.com/46915912"),
              ),
              _buildBrokerCard(
                context,
                name: "Angel One",
                logoAsset: "assets/logos/angelone.png",
                isWide: true,
                reward: "₹ 0",
                description: "Zero brokerage on delivery & simple interface.",
                color: const Color(0xFF3B82F6),
                isDark: isDark,
                onTap: () => _showComingSoon(context, "Angel One"),
              ),
              _buildBrokerCard(
                context,
                name: "Dhan",
                logoAsset: "assets/logos/dhan.jpeg",
                reward: "₹ 0",
                description: "Lightning fast trading experience for pros.",
                color: const Color(0xFF22C55E),
                isDark: isDark,
                onTap: () => _showComingSoon(context, "Dhan"),
              ),
              _buildBrokerCard(
                context,
                name: "Upstox",
                logoAsset: "assets/logos/upstox.jpeg",
                reward: "₹ 0",
                description: "Reliable platform with advanced analytics.",
                color: const Color(0xFF9333EA),
                isDark: isDark,
                onTap: () => _showComingSoon(context, "Upstox"),
              ),

              const SizedBox(height: 32),

              // How to Earn Section
              _buildHowToEarnSection(isDark, _howToEarnKey),

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

  Widget _buildCashbackCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, 
              color: Color(0xFF22C55E), size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "CASHBACK",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                "₹ 0",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFF0F172A),
              foregroundColor: isDark ? Colors.white : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              "Redeem",
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrokerCard(
    BuildContext context, {
    required String name,
    required String logoAsset,
    required String reward,
    required String description,
    required Color color,
    bool isPopular = false,
    bool isWide = false,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: isWide ? 85 : 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isWide ? Colors.transparent : color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          logoAsset,
                          fit: isWide ? BoxFit.contain : BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              name[0],
                              style: GoogleFonts.inter(
                                color: isWide ? color : Colors.white,
                                fontSize: 24,
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
                          Row(
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              if (isPopular) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0E7FF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "POPULAR",
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF4338CA),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[500],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "REWARD",
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          reward,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          "Open Account",
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () => _showVerifyPlaceholder(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
                          foregroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          "Registered? Verify",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHowToEarnSection(bool isDark, GlobalKey key) {
    final List<Map<String, String>> steps = [
      {
        "title": "Open Account",
        "desc": "Click on your preferred broker and open a new demat/trading account."
      },
      {
        "title": "Add Funds",
        "desc": "Add a minimum of ₹100 and execute your first trade within 7 days."
      },
      {
        "title": "Take Screenshot",
        "desc": "Capture your client ID and first trade confirmation from the broker app."
      },
      {
        "title": "Submit Details",
        "desc": "Upload screenshots through our verification form to claim your reward."
      },
    ];

    return Container(
      key: key,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_filled_rounded, color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 12),
              Text(
                "How to Earn",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(steps.length, (index) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0)),
                        ),
                        child: Center(
                          child: Text(
                            "${index + 1}",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                      if (index != steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[index]["title"]!,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          steps[index]["desc"]!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[500],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showVerifyPlaceholder(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already registered? Submit Details",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Need Assistance?",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Our support team is available 24/7 to help with account opening and verification.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4F46E5),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                "Contact Support",
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

