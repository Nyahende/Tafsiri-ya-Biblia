import 'dart:convert';

import 'package:flutter/services.dart';

class CrossReference {
  const CrossReference({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.type,
    required this.strength,
  });

  final String bookId;
  final int chapter;
  final int verse;
  final String type;
  final String strength;

  factory CrossReference.fromJson(Map<String, dynamic> json) {
    return CrossReference(
      bookId: json['bookId'] as String,
      chapter: json['chapter'] as int,
      verse: json['verse'] as int,
      type: json['type'] as String? ?? 'theme',
      strength: json['strength'] as String? ?? 'strong',
    );
  }
}

class CrossReferenceService {
  CrossReferenceService._();

  static Map<String, dynamic>? _data;
  static List<String> _bookIds = const <String>[];
  static List<String> _typeCodes = const <String>[];
  static List<String> _strengthCodes = const <String>[];

  static Future<void> _ensureLoaded() async {
    if (_data != null) {
      return;
    }

    final String jsonString = await rootBundle.loadString(
      'assets/data/cross_references.json',
    );

    final dynamic decoded = jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Muundo wa cross_references.json si sahihi.');
    }

    _data = decoded;

    _bookIds = _readStringList(decoded['bookIds']);
    _typeCodes = _readStringList(decoded['typeCodes']);
    _strengthCodes = _readStringList(decoded['strengthCodes']);
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    return value.whereType<String>().toList(growable: false);
  }

  static CrossReference? _fromCompactReference(dynamic rawReference) {
    if (rawReference is! List || rawReference.length < 3) {
      return null;
    }

    final dynamic rawBookIndex = rawReference[0];
    final dynamic rawChapter = rawReference[1];
    final dynamic rawVerse = rawReference[2];

    if (rawBookIndex is! int ||
        rawChapter is! int ||
        rawVerse is! int ||
        rawBookIndex < 0 ||
        rawBookIndex >= _bookIds.length) {
      return null;
    }

    String type = 'theme';
    String strength = 'strong';

    if (rawReference.length > 3) {
      final dynamic rawTypeIndex = rawReference[3];

      if (rawTypeIndex is int &&
          rawTypeIndex >= 0 &&
          rawTypeIndex < _typeCodes.length) {
        type = _typeCodes[rawTypeIndex];
      }
    }

    if (rawReference.length > 4) {
      final dynamic rawStrengthIndex = rawReference[4];

      if (rawStrengthIndex is int &&
          rawStrengthIndex >= 0 &&
          rawStrengthIndex < _strengthCodes.length) {
        strength = _strengthCodes[rawStrengthIndex];
      }
    }

    return CrossReference(
      bookId: _bookIds[rawBookIndex],
      chapter: rawChapter,
      verse: rawVerse,
      type: type,
      strength: strength,
    );
  }

  static CrossReference? _parseReference(dynamic rawReference) {
    // New mobile-optimized format:
    // [bookIndex, chapter, verse, typeIndex, strengthIndex, votes]
    if (rawReference is List) {
      return _fromCompactReference(rawReference);
    }

    // Backward compatibility with the previous verbose JSON format.
    if (rawReference is Map<String, dynamic>) {
      try {
        return CrossReference.fromJson(rawReference);
      } on Object {
        return null;
      }
    }

    return null;
  }

  static Future<List<CrossReference>> getReferences({
    required String bookId,
    required int chapter,
    required int verse,
  }) async {
    await _ensureLoaded();

    final dynamic referencesData = _data!['references'];

    if (referencesData is! Map<String, dynamic>) {
      return const <CrossReference>[];
    }

    final String key = '$bookId.$chapter.$verse';
    final dynamic rawReferences = referencesData[key];

    if (rawReferences is! List) {
      return const <CrossReference>[];
    }

    final List<CrossReference> references = <CrossReference>[];

    for (final dynamic rawReference in rawReferences) {
      final CrossReference? reference = _parseReference(rawReference);

      if (reference != null) {
        references.add(reference);
      }
    }

    return references;
  }

  static Future<bool> hasReferences({
    required String bookId,
    required int chapter,
    required int verse,
  }) async {
    await _ensureLoaded();

    final dynamic referencesData = _data!['references'];

    if (referencesData is! Map<String, dynamic>) {
      return false;
    }

    final String key = '$bookId.$chapter.$verse';
    final dynamic rawReferences = referencesData[key];

    return rawReferences is List && rawReferences.isNotEmpty;
  }
}
