class Tenzi {
  final int number;
  final String title;
  final String lyrics;

  const Tenzi({
    required this.number,
    required this.title,
    required this.lyrics,
  });

  factory Tenzi.fromJson(Map<String, dynamic> json) {
    return Tenzi(
      number: _parseInt(json['number']),
      title: json['title']?.toString().trim() ?? '',
      lyrics: json['lyrics']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'number': number, 'title': title, 'lyrics': lyrics};
  }

  String get displayNumber => number.toString().padLeft(3, '0');

  String get reference => 'Tenzi Na. $number';

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
