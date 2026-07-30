import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'privacy_policy_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const Color backgroundColor = Color(0xFFFAF9F6);
  static const Color primaryBrown = Color(0xFF4E342E);
  static const Color secondaryBrown = Color(0xFF795548);
  static const Color gold = Color(0xFFD4A017);
  static const Color lightGold = Color(0xFFFFF5D9);

  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    if (!mounted) {
      return;
    }

    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded, color: primaryBrown),
        ),
        title: const Text(
          'Kuhusu',
          style: TextStyle(
            color: primaryBrown,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildDescriptionCard(),
              const SizedBox(height: 18),
              _buildAppInformationCard(),
              const SizedBox(height: 18),
              _buildContactCard(),
              const SizedBox(height: 18),
              _buildPrivacyPolicyCard(context),
              const SizedBox(height: 18),
              _buildVerseCard(),
              const SizedBox(height: 22),
              const Center(
                child: Text(
                  '© 2026 Tafsiri ya Biblia',
                  style: TextStyle(
                    color: secondaryBrown,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: lightGold,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gold.withValues(alpha: 0.22)),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white,
            child: Icon(Icons.menu_book_rounded, size: 42, color: gold),
          ),
          SizedBox(height: 16),
          Text(
            'Tafsiri ya Biblia',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryBrown,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Soma → Tafakari → Ishi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryBrown,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return _buildInformationCard(
      icon: Icons.info_outline_rounded,
      title: 'Kuhusu Programu',
      child: const Text(
        'Tafsiri ya Biblia ni programu ya Kiswahili iliyoundwa '
        'kumsaidia msomaji kusoma, kuelewa na kutafakari Neno la Mungu '
        'kwa urahisi. Programu ina tafsiri ya Biblia, kamusi ya maneno '
        'ya kibiblia, utafutaji wa maandiko, alamisho na uwezo wa '
        'kushiriki aya na wengine.',
        style: TextStyle(color: secondaryBrown, fontSize: 16, height: 1.65),
      ),
    );
  }

  Widget _buildAppInformationCard() {
    return _buildInformationCard(
      icon: Icons.apps_rounded,
      title: 'Taarifa za Programu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(label: 'Jina', value: 'Tafsiri ya Biblia'),
          _buildDetailRow(label: 'Toleo', value: '$_version ($_buildNumber)'),
          _buildDetailRow(label: 'Lugha', value: 'Kiswahili'),
          _buildDetailRow(label: 'Aina', value: 'Vitabu na Marejeo'),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return _buildInformationCard(
      icon: Icons.mail_outline_rounded,
      title: 'Mawasiliano',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kwa maoni, mapendekezo, marekebisho au msaada kuhusu '
            'programu, unaweza kuwasiliana na msanidi kupitia:',
            style: TextStyle(color: secondaryBrown, fontSize: 15, height: 1.55),
          ),
          SizedBox(height: 14),
          SelectableText(
            'michaelnyahende8@gmail.com\n'
            '+255784392668',
            style: TextStyle(
              color: primaryBrown,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicyCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: primaryBrown.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: primaryBrown.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: lightGold,
                child: Icon(Icons.privacy_tip_outlined, color: gold, size: 25),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sera ya Faragha',
                      style: TextStyle(
                        color: primaryBrown,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Soma jinsi programu inavyolinda taarifa zako.',
                      style: TextStyle(
                        color: secondaryBrown,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: gold, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: primaryBrown,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(Icons.format_quote_rounded, color: gold, size: 30),
          SizedBox(height: 12),
          Text(
            'Neno lako ni taa ya miguu yangu, '
            'na mwanga wa njia yangu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1.6,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Zaburi 119:105',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: gold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryBrown.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: primaryBrown.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: lightGold,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: gold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: primaryBrown,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: secondaryBrown,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: primaryBrown,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
