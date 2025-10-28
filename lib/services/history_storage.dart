// lib/ui/storage/history_storage.dart
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

  /// Dışa kapalı: Baytları diske yazıp HistoryItem oluşturur ve persist eder.
  static Future<HistoryItem> _saveBytes({
    required List<int> bytes,
    required String userKey,
    required String extension, // non-null
  }) async {
    final dir = await _userDir(userKey);
    final fileName =
        'tryon_${DateTime.now().millisecondsSinceEpoch}.${extension.toLowerCase()}';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    final item = HistoryItem(path: file.path, savedAt: DateTime.now());
    final list = await loadAll(userKey);
    list.insert(0, item);
    await _persist(list, userKey);
    return item;
  }

  /// URL'den indirip (veya data URI'den decode edip) kullanıcının klasörüne kaydeder.
  /// Hem http(s) hem de data: şemasını destekler.
  static Future<HistoryItem> saveFromUrl(String url, {required String userKey}) async {
    if (url.startsWith('data:')) {
      // DATA URI (örn: data:image/png;base64,....)
      return _saveFromDataUri(url, userKey: userKey);
    }
    // HTTP(S)
    return _saveFromHttp(url, userKey: userKey);
  }

  /// DATA URI (base64) kaydetme
  static Future<HistoryItem> _saveFromDataUri(String dataUri, {required String userKey}) async {
    try {
      final uri = Uri.parse(dataUri);

      // contentAsBytes() hem base64 hem de percent-encode için çalışır
      final bytes = uri.data?.contentAsBytes() ??
          base64Decode(dataUri.split(',').last);

      if (bytes.isEmpty) {
        throw Exception('Data URI çözülemedi (boş veri).');
      }

      final mime = uri.data?.mimeType ?? _mimeFromDataUri(dataUri) ?? 'image/png';
      final ext = _extFromMime(mime) ?? 'png'; // <-- NULL OLMAYACAK

      return _saveBytes(bytes: bytes, userKey: userKey, extension: ext);
    } catch (e) {
      throw Exception('Data URI kaydedilemedi: $e');
    }
  }

  /// HTTP(S) kaydetme
  static Future<HistoryItem> _saveFromHttp(String url, {required String userKey}) async {
    http.Response res;
    try {
      res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    } catch (e) {
      throw Exception('Görsel indirilemedi (ağ/timeout): $e');
    }

    if (res.statusCode != 200) {
      throw Exception('Görsel indirilemedi (HTTP ${res.statusCode}).');
    }

    // İçerik tipinden ya da URL uzantısından uygun dosya uzantısı
    final headerMime = res.headers['content-type'];
    final extFromMime = _extFromMime(headerMime);
    final extFromUrl = _extFromUrl(url);
    final ext = extFromMime ?? extFromUrl ?? 'jpg'; // <-- NULL OLMAYACAK

    return _saveBytes(bytes: res.bodyBytes, userKey: userKey, extension: ext);
  }

  /// content-type -> dosya uzantısı
  static String? _extFromMime(String? mime) {
    if (mime == null) return null;
    final m = mime.split(';').first.toLowerCase().trim();
    switch (m) {
      case 'image/jpeg':
      case 'image/jpg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/heic':
        return 'heic';
      case 'image/heif':
        return 'heif';
      case 'image/gif':
        return 'gif';
      case 'image/bmp':
        return 'bmp';
      case 'image/tiff':
        return 'tiff';
      default:
        return null; // bilinmeyen mime -> null
    }
  }

  /// data:image/png;base64,... içinden MIME çıkar
  static String? _mimeFromDataUri(String dataUri) {
    final match = RegExp(r'^data:([^;]+);').firstMatch(dataUri);
    return match?.group(1);
  }

  /// URL path uzantısını çıkar (query parçalarını atar)
  static String? _extFromUrl(String url) {
    try {
      final u = Uri.parse(url);
      final path = u.path; // /foo/bar/image.png
      if (path.isEmpty) return null;
      final last = path.split('/').last; // image.png
      final dot = last.lastIndexOf('.');
      if (dot <= 0 || dot == last.length - 1) return null;

      var ext = last.substring(dot + 1).toLowerCase();
      if (ext.contains('%')) {
        // bazen encoded olabiliyor
        ext = Uri.decodeComponent(ext);
      }
      if (ext == 'jpeg') ext = 'jpg';
      if (ext.length > 5) return null; // çok uzun/garip uzantıları filtrele
      return ext;
    } catch (_) {
      return null;
    }
  }

  /// Kayıtlı tüm öğeleri oku
  static Future<List<HistoryItem>> loadAll(String userKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKeyFor(userKey)) ?? <String>[];
    return raw
        .map((s) => HistoryItem.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  /// Belirli index’i sil (dosyayla birlikte) ve persist et
  static Future<void> removeAt(int index, {required String userKey}) async {
    final list = await loadAll(userKey);
    if (index < 0 || index >= list.length) return;
    final item = list.removeAt(index);
    try {
      final f = File(item.path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
    await _persist(list, userKey);
  }

  /// Tüm geçmişi temizle (dosyalar + kayıt)
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
