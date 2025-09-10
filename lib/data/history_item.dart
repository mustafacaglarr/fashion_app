class HistoryItem {
  final String path;      // cihaz içi dosya yolu
  final DateTime savedAt; // kayıt zamanı

  HistoryItem({required this.path, required this.savedAt});

  Map<String, dynamic> toJson() => {
        'path': path,
        'savedAt': savedAt.toIso8601String(),
      };

  factory HistoryItem.fromJson(Map<String, dynamic> j) =>
      HistoryItem(path: j['path'] as String, savedAt: DateTime.parse(j['savedAt'] as String));
}
