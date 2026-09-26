import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const TradingClassApp());

// ----------------------------------------------------------------------
// External links — replace with your real URLs
// ----------------------------------------------------------------------

class AppLinks {
  static const String googleMapsUrl =
      'https://www.google.com/maps?client=ms-android-motorola-rvo3&hs=JXfq&sca_esv=de9039c1853f1b8f&hl=en-IN&cs=1&sxsrf=APpeQnvN8Pj2-yS-zFp7aL8Y9uCw6ZQSiw:1789928664884&kgmid=/g/11pf1vn1wy&shem=epsd1,ltae,rimspwouoe&shndl=30&kgs=29f668bc24c05ac9&um=1&ie=UTF-8&fb=1&gl=in&sa=X&geocode=KY18R0OuN_A5MdpkFrqYZIuj&daddr=Manik+sarkar+chowk,+near+Babulal+sweets,+bgp,+Adampur,+Bhagalpur,+Shanker+Pur,+Bihar+812001';

  static const String registrationFormUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLSeHZjDCy0DveuYNpJ1sSIYDs8eB-NLN6GLDI8OL5sR2-dygTw/viewform';
}

class TradingClassApp extends StatelessWidget {
  const TradingClassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offline Trading Class',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          brightness: Brightness.dark,
        ),
      ),
      home: const TradingClassScreen(),
    );
  }
}

// ----------------------------------------------------------------------
// Palette
// ----------------------------------------------------------------------

class AppColors {
  static const bg = Color(0xFF0A0E17);
  static const card = Color(0xFF131826);
  static const cardBorder = Color(0xFF242B3D);
  static const gold = Color(0xFFE3A857);
  static const goldLight = Color(0xFFEFC58A);
  static const textMuted = Color(0xFF9AA3B8);
  static const green = Color(0xFF3FCF8E);
  static const red = Color(0xFFEF5A5A);
}

// ----------------------------------------------------------------------
// Helper: open an external URL safely
// ----------------------------------------------------------------------

Future<void> _openUrl(BuildContext context, String urlString) async {
  final uri = Uri.parse(urlString);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open the link.')));
  }
}

// ----------------------------------------------------------------------
// Root screen: smooth continuous vertical scroll
// ----------------------------------------------------------------------

class TradingClassScreen extends StatefulWidget {
  const TradingClassScreen({super.key});

  @override
  State<TradingClassScreen> createState() => _TradingClassScreenState();
}

class _TradingClassScreenState extends State<TradingClassScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _roadmapKey = GlobalKey();
  final GlobalKey _formKeySection = GlobalKey();

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroSection(
                onRoadmapTap: () => _scrollToKey(_roadmapKey),
                onFormTap: () => _scrollToKey(_formKeySection),
              ),
              const SizedBox(height: 40),
              _RoadmapSection(key: _roadmapKey),
              const SizedBox(height: 40),
              const _ScheduleFeeVenueSection(),
              const SizedBox(height: 40),
              _RewardsSection(
                onGetInTouchTap: () => _scrollToKey(_formKeySection),
              ),
              const SizedBox(height: 40),
              _FormSection(key: _formKeySection),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Shared small pieces
// ----------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.gold,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        fontFamily: 'serif',
        height: 1.2,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: child,
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String text;
  const _PillBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: AppColors.gold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _GoldButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _OutlineButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Section 1 — Hero
// ----------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  final VoidCallback onRoadmapTap;
  final VoidCallback onFormTap;
  const _HeroSection({required this.onRoadmapTap, required this.onFormTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PillBadge('Offline Programme · Bhagalpur, Bihar'),
        const SizedBox(height: 24),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 32,
              height: 1.18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'serif',
            ),
            children: [
              TextSpan(text: 'Join Bihar\'s Premium '),
              TextSpan(
                text: 'Trading Floor',
                style: TextStyle(
                  color: AppColors.gold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              TextSpan(text: ' Experience'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'A 25-day offline bootcamp designed to build practical trading '
          'skills through structured learning, hands-on practice, and a '
          'real trading floor environment.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        const _TradingFloorProof(),
        const SizedBox(height: 28),
        _GoldButton(text: 'Reserve Your Seat', onTap: onFormTap),
        const SizedBox(height: 12),
        _OutlineButton(text: 'View Roadmap', onTap: onRoadmapTap),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// Social-proof photo — Trading Floor Collage
// ----------------------------------------------------------------------

class _TradingFloorProof extends StatelessWidget {
  const _TradingFloorProof();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.30),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.12),
            blurRadius: 28,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Actual photo ──────────────────────────────────────────────
          AspectRatio(
            aspectRatio: 1024 / 860, // matches the collage proportions
            child: Image.asset(
              'assets/images/trading_floor_collage.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ── Gradient veil — bottom-to-top, keeps text readable ───────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.45, 0.72, 1.0],
                  colors: [
                    Colors.transparent,
                    AppColors.bg.withValues(alpha: 0.55),
                    AppColors.bg.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),

          // ── Top-left: LIVE badge ──────────────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Real Classroom · Bhagalpur',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom caption row ────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caption headline
                  const Text(
                    'Learn on a Real Trading Floor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Live screens · Expert mentors · Peer learning environment',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Trust stat chips
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.people_alt_outlined,
                        label: '200+ Students',
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.star_rounded,
                        label: '4.9 Rating',
                        isGold: true,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.verified_rounded,
                        label: 'Since 2021',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isGold;

  const _StatChip({
    required this.icon,
    required this.label,
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGold ? AppColors.gold : Colors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGold
              ? AppColors.gold.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Section 2 — Roadmap
// ----------------------------------------------------------------------

class _ScheduleTopic {
  final String title;
  final List<String> bulletPoints;

  const _ScheduleTopic({required this.title, this.bulletPoints = const []});
}

class _WeekData {
  final String title;
  final String description;
  final String? scheduleHeader;
  final List<_ScheduleTopic>? scheduleTopics;
  final String? footerNote;
  final String? watermarkNumber;

  const _WeekData({
    required this.title,
    required this.description,
    this.scheduleHeader,
    this.scheduleTopics,
    this.footerNote,
    this.watermarkNumber,
  });
}

class _RoadmapSection extends StatelessWidget {
  const _RoadmapSection({super.key});

  static const List<_WeekData> weeks = [
    _WeekData(
      title: 'Week 1',
      description:
          'Foundation phase — an introduction to the trading floor environment '
          'and core fundamentals.',
      scheduleHeader: "What we'll Learn in the 1ˢᵗ week",
      watermarkNumber: '01',
      scheduleTopics: [
        _ScheduleTopic(
          title: 'Introduction',
          bulletPoints: ['Price Action', 'Risk Management'],
        ),
        _ScheduleTopic(title: '30-TF Intraday Strategy', bulletPoints: []),
        _ScheduleTopic(
          title: 'FNO Pathshala',
          bulletPoints: [
            'Introduction to FNO',
            'Option Buying vs Option Selling',
            'Option Greeks',
            'OI – Data Reading',
          ],
        ),
        _ScheduleTopic(
          title: 'Crypto Class',
          bulletPoints: [
            'Introduction Class',
            'Move over to CoinMarketCap',
            'Leverage Understanding',
            'Token Selection',
          ],
        ),
      ],
    ),
    _WeekData(
      title: 'Week 2',
      description: 'Deepening core concepts through guided, hands-on practice.',
      scheduleHeader: "What we'll Learn in the 2ⁿᵈ week",
      watermarkNumber: '02',
      scheduleTopics: [
        _ScheduleTopic(title: 'SOB Strategy', bulletPoints: []),
        _ScheduleTopic(title: 'Live Trade Deployment', bulletPoints: []),
        _ScheduleTopic(
          title:
              'Introduction to Nifty / Sensex Option Selling & Hedging Strategy',
          bulletPoints: [
            'Short Iron Condor',
            'Expiry Special DTE-1 Strategy',
            'Directional Spreads',
          ],
        ),
        _ScheduleTopic(
          title: 'Forex Special',
          bulletPoints: ['XAUT & XAG 15-min Strategy', 'Practice Session'],
        ),
      ],
    ),
    _WeekData(
      title: 'Week 3',
      description: 'Live trading floor practice and strategy development.',
      scheduleHeader: "What we'll Learn in the 3ʳᵈ week",
      watermarkNumber: '03',
      scheduleTopics: [
        _ScheduleTopic(
          title: 'Live Trading + Doubts Clearing Session',
          bulletPoints: [],
        ),
        _ScheduleTopic(title: 'Algo Integration', bulletPoints: []),
        _ScheduleTopic(title: 'Advance Arbitrage Trading', bulletPoints: []),
      ],
    ),
    _WeekData(
      title: 'Week 4',
      description:
          'Final preparation, long-term portfolio building, and assessment.',
      scheduleHeader: "What we'll Learn in the 4ᵗʰ week",
      watermarkNumber: '04',
      footerNote: '[ Work With Us – Special Seminar (Only for Students) ]',
      scheduleTopics: [
        _ScheduleTopic(
          title: 'Trading & Investment in US Stock',
          bulletPoints: [],
        ),
        _ScheduleTopic(title: 'Long-term Portfolio Building', bulletPoints: []),
        _ScheduleTopic(
          title: '1-on-1 Counselling & Individual Roadmap Allotment',
          bulletPoints: [],
        ),
        _ScheduleTopic(
          title: '(Government Bonds, Life term & Health insurance Suggestions)',
          bulletPoints: [],
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Roadmap'),
        const SizedBox(height: 8),
        const _Heading('25-Day Offline Bootcamp'),
        const SizedBox(height: 10),
        const Text(
          'The programme is structured across four weeks. Detailed '
          'week-by-week curriculum is listed below.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        for (int i = 0; i < weeks.length; i++)
          _TimelineItem(week: weeks[i], isLast: i == weeks.length - 1),
        const SizedBox(height: 12),
        const _AdditionalBenefitsCard(),
      ],
    );
  }
}

class _TimelineItem extends StatefulWidget {
  final _WeekData week;
  final bool isLast;

  const _TimelineItem({required this.week, required this.isLast});

  @override
  State<_TimelineItem> createState() => _TimelineItemState();
}

class _TimelineItemState extends State<_TimelineItem> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasSchedule =
        widget.week.scheduleTopics != null &&
        widget.week.scheduleTopics!.isNotEmpty;

    // Stack is sized by its one non-positioned child (the Row).
    // The connector line is Positioned so it fills exactly that height — no
    // IntrinsicHeight, no fake large heights, no extra clipping needed.
    return Stack(
      children: [
        // ── Connector line (behind everything) ──────────────────────────
        if (!widget.isLast)
          Positioned(
            left: 10, // horizontally centred in the 22-px dot column
            top: 22, // starts right below the dot
            bottom: 0,
            child: Container(width: 2, color: AppColors.cardBorder),
          ),

        // ── Main content row ─────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (hasSchedule && _isExpanded)
                    ? AppColors.gold
                    : Colors.transparent,
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: (hasSchedule && _isExpanded)
                  ? const Icon(Icons.check, size: 13, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 16),

            // Content — Expanded so it takes all remaining width
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + arrow
                    InkWell(
                      onTap: hasSchedule ? _toggleExpanded : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.week.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (hasSchedule)
                              AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _isExpanded
                                        ? AppColors.gold.withValues(alpha: 0.18)
                                        : AppColors.cardBorder.withValues(
                                            alpha: 0.5,
                                          ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: _isExpanded
                                        ? AppColors.gold
                                        : AppColors.textMuted,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.week.description,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pill button
                    if (hasSchedule)
                      InkWell(
                        onTap: _toggleExpanded,
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _isExpanded
                                ? AppColors.gold.withValues(alpha: 0.15)
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isExpanded
                                  ? AppColors.gold
                                  : AppColors.gold.withValues(alpha: 0.45),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isExpanded
                                    ? 'Hide ${widget.week.title} Schedule'
                                    : 'View ${widget.week.title} Schedule',
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.gold,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Text(
                          'Detailed schedule coming soon',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    // Schedule card — AnimatedSize smoothly expands/collapses.
                    // No IntrinsicHeight anywhere → no layout thrash, no overflow.
                    if (hasSchedule)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.topCenter,
                        child: _isExpanded
                            ? Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: _WeekScheduleCard(
                                  header:
                                      widget.week.scheduleHeader ??
                                      "What we'll Learn in this week",
                                  topics: widget.week.scheduleTopics!,
                                  footerNote: widget.week.footerNote,
                                  watermarkNumber: widget.week.watermarkNumber,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeekScheduleCard extends StatelessWidget {
  final String header;
  final List<_ScheduleTopic> topics;
  final String? footerNote;
  final String? watermarkNumber;

  const _WeekScheduleCard({
    required this.header,
    required this.topics,
    this.footerNote,
    this.watermarkNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1420),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background watermark number (like '01' / '02' / '03' / '04' in image)
          if (watermarkNumber != null)
            Positioned(
              right: 10,
              bottom: 4,
              child: IgnorePointer(
                child: Text(
                  watermarkNumber!,
                  style: TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'sans-serif',
                    color: Colors.white.withValues(alpha: 0.04),
                    letterSpacing: -4,
                    height: 0.9,
                  ),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top yellow accent line
              Container(
                height: 3.5,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFD54F),
                      Color(0xFFE3A857),
                      Color(0xFFFFD54F),
                    ],
                  ),
                ),
              ),
              // Header text
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        header,
                        style: const TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF1E2638), height: 1, thickness: 1),
              // Topics list
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < topics.length; i++) ...[
                      if (i > 0) const SizedBox(height: 20),
                      _TopicItem(topic: topics[i]),
                    ],
                    if (footerNote != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          footerNote!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.goldLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdditionalBenefitsCard extends StatelessWidget {
  const _AdditionalBenefitsCard();

  static const List<Map<String, dynamic>> benefits = [
    {
      'title': '1 Year Support',
      'icon': Icons.verified_user_outlined,
      'desc': 'Dedicated guidance, doubts clearing & regular mentorship.',
    },
    {
      'title': 'Free Access to AI Trade Bot',
      'icon': Icons.smart_toy_outlined,
      'desc': 'Automated algorithmic trading setups & market indicators.',
    },
    {
      'title': 'Access to Stock Archery App',
      'icon': Icons.phone_android_rounded,
      'desc': 'Community access, live market alerts & exclusive resources.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1420),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.05),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top yellow accent line
          Container(
            height: 3.5,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFD54F),
                  Color(0xFFE3A857),
                  Color(0xFFFFD54F),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Additional Benefits',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 44,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7C948),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                for (int i = 0; i < benefits.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: Color(0xFF1E2638), height: 1),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          benefits[i]['icon'] as IconData,
                          color: AppColors.gold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              benefits[i]['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              benefits[i]['desc'] as String,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicItem extends StatelessWidget {
  final _ScheduleTopic topic;

  const _TopicItem({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          topic.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        // Yellow underline accent bar
        Container(
          width: 36,
          height: 3.5,
          decoration: BoxDecoration(
            color: const Color(0xFFF7C948),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (topic.bulletPoints.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final bullet in topic.bulletPoints)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7, right: 10),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      bullet,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// ----------------------------------------------------------------------
// Section 3 — Schedule & Fee + Venue
// ----------------------------------------------------------------------

class _ScheduleFeeVenueSection extends StatelessWidget {
  const _ScheduleFeeVenueSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Schedule & Fee'),
        const SizedBox(height: 8),
        const _Heading('Class Timings and Investment'),
        const SizedBox(height: 24),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Class Timing',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 18),
              const _TimingRow(
                label: 'Morning Session',
                value: '9:30 am – 2:30 pm',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(color: AppColors.cardBorder, height: 1),
              ),
              const _TimingRow(
                label: 'Evening Session',
                value: '3:30 pm – 5:30 pm',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Course Fee — highlighted prominently; "One-time payment" kept
        // as a low-emphasis, muted note underneath.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gold.withValues(alpha: 0.16),
                AppColors.gold.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'COURSE FEE',
                style: TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '₹27,000',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'One-time payment',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const _SectionLabel('Venue'),
        const SizedBox(height: 8),
        const _Heading('Where the Class Is Held'),
        const SizedBox(height: 20),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openUrl(context, AppLinks.googleMapsUrl),
          child: _Card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.gold,
                  size: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Near Stock Archery',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Manik Sarkar Chowk, Beside Dabulal Kachori Wala, '
                        'Bhagalpur, Bihar – 812001',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Tap to open in Google Maps',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.open_in_new,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimingRow extends StatelessWidget {
  final String label;
  final String value;
  const _TimingRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// Section 4 — Rewards / Test Conduction
// ----------------------------------------------------------------------

class _RewardsSection extends StatelessWidget {
  final VoidCallback onGetInTouchTap;
  const _RewardsSection({required this.onGetInTouchTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Test Conduction'),
        const SizedBox(height: 8),
        const _Heading('Assessment and Rewards'),
        const SizedBox(height: 10),
        const Text(
          'At the conclusion of the bootcamp, participants will take an '
          'assessment based entirely on the syllabus covered during the '
          'programme. Top performers will receive the following rewards:',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        const _RewardRow(
          rank: '1',
          title: '1st Winner',
          subtitle: 'One-year paid internship ',
          highlighted: true,
        ),
        const SizedBox(height: 14),
        const _RewardRow(
          rank: '2',
          title: '2nd Winner',
          subtitle: '\$10,000 funded trading account',
        ),
        const SizedBox(height: 14),
        const _RewardRow(
          rank: '3',
          title: '3rd Winner',
          subtitle: '\$5,000 funded trading account',
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold, width: 1.2),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🥇', style: TextStyle(fontSize: 22)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Will every participant receive a certificate?',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Yes — every participant receives a Certificate of '
                      'Participation upon completion of the bootcamp.',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _OutlineButton(text: 'Proceed to Registration', onTap: onGetInTouchTap),
      ],
    );
  }
}

class _RewardRow extends StatelessWidget {
  final String rank;
  final String title;
  final String subtitle;
  final bool highlighted;
  const _RewardRow({
    required this.rank,
    required this.title,
    required this.subtitle,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlighted
                  ? AppColors.gold.withValues(alpha: 0.15)
                  : Colors.transparent,
              border: Border.all(
                color: highlighted ? AppColors.gold : AppColors.cardBorder,
                width: 1.5,
              ),
            ),
            child: Text(
              rank,
              style: TextStyle(
                color: highlighted ? AppColors.gold : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
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

// ----------------------------------------------------------------------
// Section 5 — Registration (Fill Form button linking to a Google Form)
// ----------------------------------------------------------------------

class _FormSection extends StatelessWidget {
  const _FormSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Get In Touch'),
        const SizedBox(height: 8),
        const _Heading('Reserve Your Seat'),
        const SizedBox(height: 10),
        const Text(
          'Complete the registration form below and our team will get in '
          'touch with you within 24 hours.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.description_outlined,
                color: AppColors.gold,
                size: 32,
              ),
              const SizedBox(height: 16),
              const Text(
                'Registration Form',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please provide your name, location, age, trading '
                'experience, and contact number to secure your seat.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              _GoldButton(
                text: 'Fill Registration Form',
                onTap: () => _openUrl(context, AppLinks.registrationFormUrl),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'Offline Trading Bootcamp · Bhagalpur, Bihar',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}
