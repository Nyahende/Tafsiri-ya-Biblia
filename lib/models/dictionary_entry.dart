class DictionaryEntry {
  const DictionaryEntry({
    required this.word,
    required this.normalizedWord,
    required this.definition,
    this.shortDefinition,
    this.originalWord,
    this.transliteration,
    this.originalLanguage,
    this.exampleReference,
    this.exampleText,
  });

  /// The word as it should be displayed to the reader.
  ///
  /// Example:
  /// Hekima
  final String word;

  /// Lowercase form used when matching dictionary words
  /// against words appearing inside Bible verses.
  ///
  /// Example:
  /// hekima
  final String normalizedWord;

  /// Full explanation of the word.
  final String definition;

  /// Short explanation used inside the verse popup.
  ///
  /// When this is not provided, the app can use
  /// the full definition instead.
  final String? shortDefinition;

  /// Hebrew or Greek form of the word.
  final String? originalWord;

  /// Pronunciation of the original word.
  final String? transliteration;

  /// Original language, such as Kiebrania or Kigiriki.
  final String? originalLanguage;

  /// Example Bible reference.
  ///
  /// Example:
  /// Mithali 1:7
  final String? exampleReference;

  /// Example verse containing the word.
  final String? exampleText;

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    final String word = json['word']?.toString().trim() ?? '';

    final String definition = json['definition']?.toString().trim() ?? '';

    final String normalizedWord =
        json['normalizedWord']?.toString().trim().toLowerCase() ??
        word.toLowerCase();

    if (word.isEmpty) {
      throw const FormatException('Dictionary word cannot be empty.');
    }

    if (definition.isEmpty) {
      throw FormatException('Definition for "$word" cannot be empty.');
    }

    return DictionaryEntry(
      word: word,
      normalizedWord: normalizedWord,
      definition: definition,
      shortDefinition: _readOptionalString(json['shortDefinition']),
      originalWord: _readOptionalString(json['originalWord']),
      transliteration: _readOptionalString(json['transliteration']),
      originalLanguage: _readOptionalString(json['originalLanguage']),
      exampleReference: _readOptionalString(json['exampleReference']),
      exampleText: _readOptionalString(json['exampleText']),
    );
  }

  static String? _readOptionalString(dynamic value) {
    final String text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'normalizedWord': normalizedWord,
      'definition': definition,
      if (shortDefinition != null) 'shortDefinition': shortDefinition,
      if (originalWord != null) 'originalWord': originalWord,
      if (transliteration != null) 'transliteration': transliteration,
      if (originalLanguage != null) 'originalLanguage': originalLanguage,
      if (exampleReference != null) 'exampleReference': exampleReference,
      if (exampleText != null) 'exampleText': exampleText,
    };
  }

  /// Meaning displayed in the small popup inside
  /// the verse-reading screen.
  String get popupDefinition {
    return shortDefinition ?? definition;
  }

  @override
  String toString() {
    return 'DictionaryEntry('
        'word: $word, '
        'normalizedWord: $normalizedWord'
        ')';
  }
}
