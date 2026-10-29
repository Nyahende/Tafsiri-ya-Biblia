import 'package:flutter/material.dart';

import '../services/audio_bible_catalog.dart';
import '../services/audio_bible_download_service.dart';
import '../services/audio_bible_service.dart';
import 'audio_bible_chapters_screen.dart';

/// Download management for the selected book. No changes to playback history.
class AudioBibleDownloadsScreen extends StatefulWidget {
  const AudioBibleDownloadsScreen({required this.book, super.key});
  final AudioBibleBook book;

  @override
  State<AudioBibleDownloadsScreen> createState() =>
      _AudioBibleDownloadsScreenState();
}

class _AudioBibleDownloadsScreenState extends State<AudioBibleDownloadsScreen> {
  final _downloads = AudioBibleDownloadService.instance;
  int _bytes = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _downloads.addListener(_refresh);
    _reload();
  }

  @override
  void dispose() {
    _downloads.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) _reload();
  }

  Future<void> _reload() async {
    final bytes = await _downloads.bytesForBook(widget.book);
    if (mounted) setState(() => _bytes = bytes);
  }

  List<AudioBibleChapter> get _chapters => availableAudioChaptersForBook(
    widget.book,
  ).where(_downloads.isDownloaded).toList();

  bool _isLoaded(AudioBibleChapter chapter) =>
      audioBibleHandler.isChapterLoaded(chapter);

  Future<void> _delete(AudioBibleChapter chapter) async {
    if (_busy || _isLoaded(chapter)) {
      _message('Badilisha sura inayochezwa kabla ya kufuta hii.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa sauti iliyopakuliwa?'),
        content: Text(
          'Unataka kufuta ${chapter.title} kwenye simu? Historia ya kusikiliza haitafutwa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ghairi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Futa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (_isLoaded(chapter)) {
      _message('Sura hii imefunguliwa kwenye kichezaji.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _downloads.deleteChapter(chapter);
      await _reload();
    } catch (_) {
      _message('Imeshindikana kufuta sauti. Jaribu tena.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAll() async {
    if (_busy || _chapters.isEmpty) return;
    final count = _chapters.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa vipakuliwa vya kitabu hiki?'),
        content: Text(
          'Sura $count • ${_formatBytes(_bytes)}. Sura inayofunguliwa kwenye kichezaji itahifadhiwa. Historia ya kusikiliza haitafutwa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ghairi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Futa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    var skipped = 0;
    try {
      for (final chapter in List<AudioBibleChapter>.of(_chapters)) {
        if (_isLoaded(chapter) || _downloads.isDownloading(chapter)) {
          skipped++;
          continue;
        }
        await _downloads.deleteChapter(chapter);
      }
      await _reload();
      if (skipped > 0)
        _message('Sura $skipped zimehifadhiwa kwa sababu zinatumika.');
    } catch (_) {
      _message('Baadhi ya sauti hazikufutika. Jaribu tena.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1073741824)
      return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    const brown = AudioBibleChaptersScreen.primaryBrown;
    const gold = AudioBibleChaptersScreen.gold;
    return Scaffold(
      backgroundColor: AudioBibleChaptersScreen.backgroundColor,
      appBar: AppBar(
        backgroundColor: AudioBibleChaptersScreen.backgroundColor,
        foregroundColor: brown,
        title: const Text('Vipakuliwa Vyangu'),
      ),
      body: AnimatedBuilder(
        animation: _downloads,
        builder: (context, _) {
          final chapters = _chapters;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AudioBibleChaptersScreen.lightGold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.book.name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: brown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${chapters.length} sura zimepakuliwa',
                      style: const TextStyle(color: brown),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatBytes(_bytes),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: brown,
                      ),
                    ),
                    const Text(
                      'Nafasi iliyotumika kwenye simu',
                      style: TextStyle(color: brown),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (chapters.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _busy ? null : _deleteAll,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Futa vipakuliwa vya kitabu hiki'),
                  ),
                ),
              if (chapters.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 65),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_download_outlined,
                        size: 58,
                        color: gold,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Hakuna sura zilizopakuliwa',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: brown,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('Pakua sura ili uzisikilize bila intaneti.'),
                    ],
                  ),
                ),
              for (final chapter in chapters)
                Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(
                      Icons.offline_pin_rounded,
                      color: Color(0xFF388E3C),
                    ),
                    title: Text(chapter.title),
                    subtitle: Text(
                      _isLoaded(chapter)
                          ? 'Imefunguliwa kwenye kichezaji'
                          : 'Inapatikana bila intaneti',
                    ),
                    trailing: IconButton(
                      tooltip: _isLoaded(chapter)
                          ? 'Badilisha sura kabla ya kufuta'
                          : 'Futa sauti',
                      onPressed: _busy || _isLoaded(chapter)
                          ? null
                          : () => _delete(chapter),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                    onTap: () async {
                      try {
                        await audioBibleHandler.loadChapter(chapter);
                      } catch (_) {
                        _message('Imeshindikana kucheza sauti.');
                      }
                      if (mounted) setState(() {});
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
