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
              _buildAppDetailsCard(),
              const SizedBox(height: 18),
              _buildSection(
                number: '1',
                title: 'Ukusanyaji wa Taarifa',
                children: const [
                  Text(
                    'Jifunze biblia imeundwa kwa ajili ya kusoma na kujifunza '
                    'Biblia pamoja na huduma nyingine zinazohusiana na maudhui '
                    'ya Biblia.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Programu haihitaji mtumiaji kufungua akaunti au kutoa '
                    'taarifa binafsi ili kutumia huduma zake kuu.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Mtumiaji hahitajiki kutoa taarifa kama:',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 8),
                  _BulletList(
                    items: [
                      'Jina',
                      'Anwani ya barua pepe',
                      'Namba ya simu',
                      'Eneo alipo (Location)',
                      'Orodha ya mawasiliano (Contacts)',
                      'Picha au faili binafsi',
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Taarifa binafsi ambazo hazikusanywi na programu '
                    'hazihifadhiwi kwenye seva za msanidi.',
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
                    'Ili kuboresha matumizi ya programu, Jifunze biblia inaweza '
                    'kuhifadhi baadhi ya taarifa moja kwa moja kwenye kifaa cha '
                    'mtumiaji, kama vile:',
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
                    'Taarifa hizi hutumika kusaidia utendaji wa programu na '
                    'hazikusanywi moja kwa moja na Michael Nyahende kwa '
                    'madhumuni ya biashara, matangazo au uuzaji wa taarifa.',
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
                    'Huduma kuu za kusoma Biblia ndani ya Jifunze biblia '
                    'zimeundwa kufanya kazi bila kuhitaji mtumiaji kutoa '
                    'taarifa binafsi kupitia intaneti.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Ikiwa huduma mpya zinazohitaji intaneti au usindikaji wa '
                    'taarifa zitaongezwa katika matoleo yajayo, Sera hii ya '
                    'Faragha itasasishwa inapohitajika ili kueleza jinsi '
                    'taarifa hizo zitakavyoshughulikiwa.',
                    style: _bodyStyle,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSection(
                number: '4',
                title: 'Matumizi na Ushirikishaji wa Taarifa',
                children: const [
                  Text(
                    'Michael Nyahende hauzi taarifa binafsi za watumiaji wa '
                    'Jifunze biblia wala kuzitumia kwa madhumuni ya matangazo '
                    'au masoko.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Taarifa zozote zinazohifadhiwa ndani ya kifaa kwa ajili '
                    'ya utendaji wa programu hutumika kutoa au kuboresha '
                    'huduma za programu.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Ikiwa programu itatumia huduma za mfumo wa Android au '
                    'huduma nyingine za wahusika wengine katika matoleo '
                    'yajayo, sera hii itasasishwa inapohitajika ili kueleza '
                    'matumizi hayo.',
                    style: _bodyStyle,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSection(
                number: '5',
                title: 'Arifa (Notifications)',
                children: const [
                  Text(
                    'Jifunze biblia inaweza kutuma arifa zinazohusiana na '
                    'maudhui ya Biblia, ikiwemo huduma kama Neno la Leo.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Ruhusa ya kupokea arifa inadhibitiwa kupitia mfumo wa '
                    'Android na mipangilio ya kifaa cha mtumiaji. Mtumiaji '
                    'anaweza kuzima arifa kupitia mipangilio ya kifaa chake.',
                    style: _bodyStyle,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSection(
                number: '6',
                title: 'Usalama wa Taarifa',
                children: const [
                  Text(
                    'Jifunze biblia imeundwa kwa kuzingatia faragha ya '
                    'mtumiaji na kupunguza ukusanyaji usio wa lazima wa '
                    'taarifa binafsi.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Hatua zinazofaa huchukuliwa kulinda taarifa '
                    'zinazoshughulikiwa na programu. Hata hivyo, hakuna mfumo '
                    'wa kielektroniki unaoweza kuhakikishiwa kuwa salama kwa '
                    'asilimia 100.',
                    style: _bodyStyle,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSection(
                number: '7',
                title: 'Uhifadhi na Ufutaji wa Taarifa',
                children: const [
                  Text(
                    'Jifunze biblia haihitaji akaunti ya mtumiaji kwa ajili '
                    'ya huduma zake kuu. Kwa hiyo, taarifa binafsi ambazo '
                    'hazikusanywi na msanidi hazihifadhiwi kwenye seva za '
                    'msanidi.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Taarifa zinazohifadhiwa ndani ya kifaa na programu '
                    'zinaweza kuondolewa kwa kufuta data ya programu kupitia '
                    'mipangilio ya kifaa au kwa kuiondoa (uninstall) programu.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Kwa swali au ombi lolote kuhusu faragha au taarifa '
                    'zinazohusiana na Jifunze biblia, mtumiaji anaweza '
                    'kuwasiliana na msanidi kupitia anuani ya barua pepe '
                    'iliyotolewa katika sera hii.',
                    style: _bodyStyle,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSection(
                number: '8',
                title: 'Faragha ya Watoto',
                children: const [
                  Text(
                    'Jifunze biblia inaweza kutumiwa na watu wa rika '
                    'mbalimbali, ikiwemo watoto.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Programu haikusudii kukusanya taarifa binafsi za watoto. '
                    'Ikiwa msanidi atatambua kuwa taarifa binafsi za mtoto '
                    'zimekusanywa kinyume na sera hii au masharti yanayotumika, '
                    'hatua zinazofaa zitachukuliwa kushughulikia au kuondoa '
                    'taarifa hizo.',
                    style: _bodyStyle,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSection(
                number: '9',
                title: 'Mabadiliko ya Sera Hii',
                children: const [
                  Text(
                    'Sera hii inaweza kusasishwa mara kwa mara kutokana na '
                    'maboresho ya Jifunze biblia, mabadiliko ya huduma zake, '
                    'au mahitaji yanayotumika ya faragha.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Toleo lililosasishwa la sera litawekwa kwenye ukurasa '
                    'huu na tarehe ya mwisho ya kusasishwa itaonyeshwa.',
                    style: _bodyStyle,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSection(
                number: '10',
                title: 'Mawasiliano',
                children: const [
                  Text(
                    'Kwa maswali, maoni, au maombi yanayohusiana na faragha, '
                    'matumizi ya taarifa, au programu ya Jifunze biblia, '
                    'wasiliana na:',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Michael Nyahende',
                    style: TextStyle(
                      color: primaryBrown,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('Msanidi wa Jifunze biblia', style: _bodyStyle),
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
                      'Mwisho kusasishwa: 2 Oktoba 2026',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryBrown,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '© 2026 Jifunze biblia. Haki zote zimehifadhiwa.',
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
            'Sera ya Faragha ya Jifunze biblia',
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
            'Tarehe ya Kuanza Kutumika: 2 Oktoba 2026',
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
        'Karibu kwenye Jifunze biblia.\n\n'
        'Sera hii ya Faragha inatumika kwa programu ya Android inayoitwa '
        'Jifunze biblia, iliyotengenezwa na kuchapishwa na Michael Nyahende.\n\n'
        'Tunathamini faragha yako na tumejitolea kuhakikisha kuwa taarifa za '
        'watumiaji zinalindwa. Sera hii inaeleza jinsi programu ya Jifunze '
        'biblia inavyoshughulikia taarifa na data za watumiaji.',
        style: _bodyStyle,
      ),
    );
  }

  Widget _buildAppDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightGold,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: gold.withValues(alpha: 0.22)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Taarifa za Programu na Msanidi',
            style: TextStyle(
              color: primaryBrown,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Jina la programu: Jifunze biblia\n'
            'Msanidi: Michael Nyahende\n'
            'Package name: com.nyahende.tafsiriyabiblia\n'
            'Barua pepe: michaelnyahende8@gmail.com',
            style: _bodyStyle,
          ),
        ],
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
