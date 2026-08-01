import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Color backgroundColor = Color(0xFFFAF9F6);
  static const Color primaryBrown = Color(0xFF4E342E);
  static const Color secondaryBrown = Color(0xFF795548);
  static const Color gold = Color(0xFFD4A017);
  static const Color lightGold = Color(0xFFFFF5D9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: primaryBrown),
        ),
        title: const Text(
          'Sera ya Faragha',
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
              _buildIntroductionCard(),
              const SizedBox(height: 18),
              _buildSection(
                number: '1',
                title: 'Ukusanyaji wa Taarifa',
                children: const [
                  Text(
                    'Programu ya Jifunze Biblia haikusanyi, kuhifadhi wala '
                    'kutuma taarifa zozote binafsi za mtumiaji.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 12),
                  Text('Hutahitajika kutoa:', style: _bodyStyle),
                  SizedBox(height: 8),
                  _BulletList(
                    items: [
                      'Jina lako',
                      'Anwani ya barua pepe',
                      'Namba ya simu',
                      'Eneo ulipo (Location)',
                      'Orodha ya mawasiliano (Contacts)',
                      'Picha au faili zako',
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Programu inaweza kutumika bila kujiandikisha au kufungua '
                    'akaunti.',
                    style: _bodyStyle,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSection(
                number: '2',
                title: 'Taarifa Zinazohifadhiwa Kwenye Kifaa Chako',
                children: const [
                  Text(
                    'Ili kuboresha uzoefu wa matumizi, programu inaweza kuhifadhi '
                    'taarifa zifuatazo kwenye kifaa chako pekee:',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 8),
                  _BulletList(
                    items: [
                      'Sehemu uliyoishia kusoma Biblia',
                      'Mistari ya Biblia uliyohifadhi (Bookmarks)',
                      'Baadhi ya mipangilio ya programu',
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Taarifa hizi hazitumwi kwa msanidi wa programu wala kwa '
                    'mtu mwingine yeyote.',
                    style: _bodyStyle,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSection(
                number: '3',
                title: 'Matumizi ya Intaneti',
                children: const [
                  Text(
                    'Toleo la sasa la Jifunze Biblia halihitaji intaneti ili '
                    'kutumia huduma zake kuu.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Iwapo huduma zitakazohitaji intaneti zitaongezwa katika '
                    'matoleo yajayo, sera hii itasasishwa ili kueleza jinsi '
                    'taarifa zitakavyoshughulikiwa.',
                    style: _bodyStyle,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSection(
                number: '4',
                title: 'Kushirikisha Taarifa',
                children: const [
                  Text(
                    'Programu ya Jifunze Biblia haishirikishi taarifa za '
                    'watumiaji na mtu yeyote au taasisi yoyote.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 12),
                  Text('Vilevile:', style: _bodyStyle),
                  SizedBox(height: 8),
                  _BulletList(
                    items: [
                      'Haitumii huduma za kufuatilia matumizi ya watumiaji (Analytics).',
                      'Haitumii matangazo (Advertisements).',
                      'Haitumii huduma zinazokusanya taarifa za watumiaji kutoka kwa watu wengine.',
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSection(
                number: '5',
                title: 'Faragha ya Watoto',
                children: const [
                  Text(
                    'Programu hii inaweza kutumiwa na watu wa rika zote, ikiwemo '
                    'watoto.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Kwa kuwa programu haikusanyi taarifa binafsi, hakuna taarifa '
                    'za watoto zinazokusanywa au kuhifadhiwa.',
                    style: _bodyStyle,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSection(
                number: '6',
                title: 'Mabadiliko ya Sera Hii',
                children: const [
                  Text(
                    'Sera hii inaweza kufanyiwa marekebisho kadri programu '
                    'inavyoendelea kuboreshwa.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Mabadiliko yoyote yatatangazwa kupitia toleo jipya la sera hii.',
                    style: _bodyStyle,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSection(
                number: '7',
                title: 'Mawasiliano',
                children: const [
                  Text(
                    'Kwa maswali, maoni au mapendekezo kuhusu sera hii au programu '
                    'ya Jifunze Biblia, unaweza kuwasiliana na:',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Michael  Nyahende',
                    style: TextStyle(
                      color: primaryBrown,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  SelectableText(
                    'Barua pepe: michaelnyahende8@gmail.com',
                    style: TextStyle(
                      color: secondaryBrown,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Center(
                child: Column(
                  children: [
                    Text(
                      'Mwisho kusasishwa: Julai 2026',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryBrown,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '© 2026 Jifunze Biblia. Haki zote zimehifadhiwa.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: secondaryBrown, fontSize: 13),
                    ),
                  ],
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
            radius: 36,
            backgroundColor: Colors.white,
            child: Icon(Icons.privacy_tip_outlined, size: 38, color: gold),
          ),
          SizedBox(height: 16),
          Text(
            'Sera ya Faragha ya Jifunze Biblia',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryBrown,
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Tarehe ya Kuanza Kutumika: Julai 2026',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryBrown,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroductionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryBrown.withValues(alpha: 0.08)),
      ),
      child: const Text(
        'Karibu kwenye Jifunze Biblia.\n\n'
        'Tunathamini faragha yako na tumejitolea kuhakikisha kuwa '
        'taarifa zako zinalindwa. Sera hii inaeleza jinsi programu ya '
        'Jifunze Biblia inavyoshughulikia taarifa za watumiaji.',
        style: _bodyStyle,
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required List<Widget> children,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: lightGold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: gold,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: primaryBrown,
                    fontSize: 18,
                    height: 1.3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  static const TextStyle _bodyStyle = TextStyle(
    color: secondaryBrown,
    fontSize: 15,
    height: 1.6,
  );
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: PrivacyPolicyScreen.gold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: PrivacyPolicyScreen.secondaryBrown,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
