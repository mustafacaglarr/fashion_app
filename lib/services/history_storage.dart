import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/history_item.dart';

class HistoryStorage {
  static const _prefsKey = 'history_items_v1';

  /// URL'den indirip uygulama belgeler klasörüne kaydeder, HistoryItem döner.
  static Future<HistoryItem> saveFromUrl(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Görsel indirilemedi (HTTP ${res.statusCode}).');
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'tryon_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(res.bodyBytes);

    final item = HistoryItem(path: file.path, savedAt: DateTime.now());
    final list = await loadAll();
    list.insert(0, item);
    await _persist(list);
    return item;
  }

  static Future<List<HistoryItem>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? <String>[];
    return raw
        .map((s) => HistoryItem.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> removeAt(int index) async {
    final list = await loadAll();
    if (index < 0 || index >= list.length) return;
    final item = list.removeAt(index);
    // dosyayı da sil
    try { final f = File(item.path); if (await f.exists()) { await f.delete(); } } catch (_) {}
    await _persist(list);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadAll();
    for (final it in list) {
      try { final f = File(it.path); if (await f.exists()) { await f.delete(); } } catch (_) {}
    }
    await prefs.remove(_prefsKey);
  }

  static Future<void> _persist(List<HistoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
