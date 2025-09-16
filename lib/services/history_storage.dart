import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/history_item.dart';

class HistoryStorage {
  static const _prefsBaseKey = 'history_items_v1';

  static String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');

  static String _prefsKeyFor(String userKey) =>
      '${_prefsBaseKey}_${_sanitize(userKey)}';

  /// Her kullanıcı için ayrı bir klasör (…/documents/users/<userKey>)
  static Future<Directory> _userDir(String userKey) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/users/${_sanitize(userKey)}');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// URL'den indirip kullanıcının klasörüne kaydeder, HistoryItem döner.
  static Future<HistoryItem> saveFromUrl(String url, {required String userKey}) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Görsel indirilemedi (HTTP ${res.statusCode}).');
    }

    final dir = await _userDir(userKey);
    final fileName = 'tryon_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(res.bodyBytes);

    final item = HistoryItem(path: file.path, savedAt: DateTime.now());
    final list = await loadAll(userKey);
    list.insert(0, item);
    await _persist(list, userKey);
    return item;
  }

  static Future<List<HistoryItem>> loadAll(String userKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKeyFor(userKey)) ?? <String>[];
    return raw
        .map((s) => HistoryItem.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> removeAt(int index, {required String userKey}) async {
    final list = await loadAll(userKey);
    if (index < 0 || index >= list.length) return;
    final item = list.removeAt(index);
    // dosyayı da sil
    try {
      final f = File(item.path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
    await _persist(list, userKey);
  }

  static Future<void> clearAll(String userKey) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadAll(userKey);
    for (final it in list) {
      try {
        final f = File(it.path);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }
    await prefs.remove(_prefsKeyFor(userKey));

    // İsteğe bağlı: o kullanıcıya ait klasörü de temizle
    try {
      final dir = await _userDir(userKey);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  static Future<void> _persist(List<HistoryItem> items, String userKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKeyFor(userKey),
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
