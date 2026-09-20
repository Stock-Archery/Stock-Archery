// Offline Trading Class — vertical scroll version
//
// Single self-contained Flutter file.

import 'package:flutter/material.dart';

void main() => runApp(const TradingClassApp());

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
        border: Border.all(color: AppColors.cardBorder),
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
  const _HeroSection({
    required this.onRoadmapTap,
    required this.onFormTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PillBadge('Offline Class · Bhagalpur, Bihar'),
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
              TextSpan(text: 'Bihar ki sabse badi '),
              TextSpan(
                text: 'Trading Floor',
                style: TextStyle(
                  color: AppColors.gold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              TextSpan(text: ' join karo'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '25-din ka offline bootcamp — seekho, practice karo aur asli '
          'trading floor ke mahaul mein khud ko test karo.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        const _CandleChart(),
        const SizedBox(height: 28),
        _GoldButton(text: 'Seat book karo', onTap: onFormTap),
        const SizedBox(height: 12),
        _OutlineButton(text: 'Roadmap dekho', onTap: onRoadmapTap),
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
      'Foundation phase — trading floor ka mahaul, basics ki shuruaat.',
    ),
    _WeekData('Week 2', 'Concepts ko practice ke saath deepen karna.'),
    _WeekData('Week 3', 'Live floor practice aur strategy building.'),
    _WeekData('Week 4', 'Final assessment ki taiyari aur test conduction.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Roadmap'),
        const SizedBox(height: 8),
        const _Heading('25 Days Offline Bootcamp'),
        const SizedBox(height: 10),
        const Text(
          'Poora program 4 weeks mein baata gaya hai. Har week ka '
          'structure jald hi reveal hoga.',
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
                      'Details jald aa rahe hain',
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
        const _Heading('Class timing aur investment'),
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
                value: '9:30 – 2:30',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(color: AppColors.cardBorder, height: 1),
              ),
              const _TimingRow(
                label: 'Evening Session',
                value: '4:00 – 7:30',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Course Fee',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                '₹27,000',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 4),
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
        const _Heading('Kahan hoti hai class'),
        const SizedBox(height: 20),
        _Card(
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
                  ],
                ),
              ),
            ],
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
// Section 4 — Rewards
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
        const _Heading('Winners ke liye rewards'),
        const SizedBox(height: 10),
        const Text(
          'Bootcamp ke end mein test hoga aur top performers ko ye milega:',
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
          subtitle: '1 year paid internship (remote)',
          highlighted: true,
        ),
        const SizedBox(height: 14),
        const _RewardRow(
          rank: '2',
          title: '2nd Winner',
          subtitle: '\$10K funded account',
        ),
        const SizedBox(height: 14),
        const _RewardRow(
          rank: '3',
          title: '3rd Winner',
          subtitle: '\$5K funded account',
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
            children: [
              Text('🥇', style: TextStyle(fontSize: 22)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Har participant ko Certificate of Participation milta hai.',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _OutlineButton(text: 'Form pe jao', onTap: onGetInTouchTap),
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
// Section 5 — Form
// ----------------------------------------------------------------------

class _FormSection extends StatefulWidget {
  const _FormSection({super.key});

  @override
  State<_FormSection> createState() => _FormSectionState();
}

class _FormSectionState extends State<_FormSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String? _experience;

  static const experiences = [
    'Beginner',
    'Kuch mahine',
    '1+ saal',
    'Professional',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _placeCtrl.dispose();
    _ageCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (valid && _experience != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submit ho gaya! Team jald contact karegi.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Get In Touch'),
          const SizedBox(height: 8),
          const _Heading('Apna seat reserve karo'),
          const SizedBox(height: 10),
          const Text(
            'Neeche apni details bharo, hamari team aapse contact karegi.',
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
                const _FieldLabel('Name'),
                _InputField(controller: _nameCtrl, hint: 'Aapka poora naam'),
                const SizedBox(height: 20),
                const _FieldLabel('Place'),
                _InputField(
                  controller: _placeCtrl,
                  hint: 'Aapka sheher / gaon',
                ),
                const SizedBox(height: 20),
                const _FieldLabel('Age'),
                _InputField(
                  controller: _ageCtrl,
                  hint: 'Aapki age',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                const _FieldLabel('Trading Experience'),
                _ExperienceDropdown(
                  value: _experience,
                  items: experiences,
                  onChanged: (v) => setState(() => _experience = v),
                ),
                const SizedBox(height: 20),
                const _FieldLabel('Contact No.'),
                _InputField(
                  controller: _contactCtrl,
                  hint: '10-digit mobile number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                _GoldButton(text: 'Submit karo', onTap: _submit),
                const SizedBox(height: 14),
                const Text(
                  'Submit karne ke baad hamari team 24 ghante ke andar call karegi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
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
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.7)),
        filled: true,
        fillColor: AppColors.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }
}

class _ExperienceDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _ExperienceDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: value,
          hint: const Text(
            'Chuniye',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          dropdownColor: AppColors.card,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textMuted,
          ),
          decoration: const InputDecoration(border: InputBorder.none),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Please select' : null,
        ),
      ),
    );
  }
}
