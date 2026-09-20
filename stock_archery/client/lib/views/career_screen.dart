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
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  const _Card({
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? AppColors.cardBorder,
          width: borderWidth,
        ),
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
              TextSpan(text: 'Join Bihar\'s Premier '),
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
        const _CandleChart(),
        const SizedBox(height: 28),
        _GoldButton(text: 'Reserve Your Seat', onTap: onFormTap),
        const SizedBox(height: 12),
        _OutlineButton(text: 'View Roadmap', onTap: onRoadmapTap),
      ],
    );
  }
}

class _CandleChart extends StatelessWidget {
  const _CandleChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      width: double.infinity,
      child: CustomPaint(painter: _CandlePainter()),
    );
  }
}

class _CandlePainter extends CustomPainter {
  final List<double> heights = const [
    0.28,
    0.42,
    0.22,
    0.48,
    0.32,
    0.58,
    0.26,
    0.46,
    0.54,
    0.38,
  ];
  final List<bool> isUp = const [
    true,
    false,
    true,
    false,
    true,
    false,
    true,
    false,
    true,
    false,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final n = heights.length;
    final gap = size.width / n;
    final baseline = size.height * 0.72;

    final linePaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      linePaint,
    );

    for (int i = 0; i < n; i++) {
      final x = gap * i + gap / 2;
      final h = heights[i] * size.height;
      final color = isUp[i] ? AppColors.green : AppColors.red;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      if (isUp[i]) {
        canvas.drawLine(Offset(x, baseline), Offset(x, baseline - h), paint);
      } else {
        canvas.drawLine(Offset(x, baseline), Offset(x, baseline + h), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------------------------
// Section 2 — Roadmap
// ----------------------------------------------------------------------

class _WeekData {
  final String title;
  final String description;
  const _WeekData(this.title, this.description);
}

class _RoadmapSection extends StatelessWidget {
  const _RoadmapSection({super.key});

  static const List<_WeekData> weeks = [
    _WeekData(
      'Week 1',
      'Foundation phase — an introduction to the trading floor environment '
          'and core fundamentals.',
    ),
    _WeekData(
      'Week 2',
      'Deepening core concepts through guided, hands-on practice.',
    ),
    _WeekData(
      'Week 3',
      'Live trading floor practice and strategy development.',
    ),
    _WeekData('Week 4', 'Final preparation and conduction of the assessment.'),
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
          'week-by-week curriculum will be announced shortly.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        for (int i = 0; i < weeks.length; i++)
          _TimelineItem(
            title: weeks[i].title,
            description: weeks[i].description,
            isLast: i == weeks.length - 1,
          ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String description;
  final bool isLast;
  const _TimelineItem({
    required this.title,
    required this.description,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.cardBorder),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                ],
              ),
            ),
          ),
        ],
      ),
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
              const _TimingRow(label: 'Morning Session', value: '9:30 – 2:30'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(color: AppColors.cardBorder, height: 1),
              ),
              const _TimingRow(label: 'Evening Session', value: '3:30 – 5:30'),
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
