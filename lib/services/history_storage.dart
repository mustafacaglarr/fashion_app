import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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

  /// ---- Public API ----
  /// URL (http/https) **veya** data URI (data:image/...) kabul eder.
  static Future<HistoryItem> saveFromUrl(String input,
      {required String userKey}) async {
    if (input.startsWith('data:')) {
      return _saveFromDataUri(input, userKey: userKey);
    }
    return _saveFromHttp(input, userKey: userKey);
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
    try {
      final dir = await _userDir(userKey);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// ---- İç işler ----

  static Future<HistoryItem> _saveBytes({
    required List<int> bytes,
    required String userKey,
    required String extension, // non-null
  }) async {
    final dir = await _userDir(userKey);
    final fileName =
        'tryon_${DateTime.now().microsecondsSinceEpoch}.${extension.toLowerCase()}';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    final item = HistoryItem(path: file.path, savedAt: DateTime.now());
    final list = await loadAll(userKey);
    list.insert(0, item);
    await _persist(list, userKey);
    return item;
  }

  static Future<HistoryItem> _saveFromDataUri(String dataUri,
      {required String userKey}) async {
    try {
      final uri = Uri.parse(dataUri);
      final Uint8List bytes = uri.data?.contentAsBytes() ??
          base64Decode(dataUri.split(',').last);
      if (bytes.isEmpty) {
        throw Exception('Boş data URI.');
      }

      final mime = uri.data?.mimeType ?? _mimeFromDataUri(dataUri);
      // MIME yoksa baytlardan yakalamayı dene
      final ext = _extFromMime(mime) ?? _detectExtFromBytes(bytes) ?? 'png';

      return _saveBytes(bytes: bytes, userKey: userKey, extension: ext);
    } catch (e) {
      throw Exception('Data URI kaydedilemedi: $e');
    }
  }

  static Future<HistoryItem> _saveFromHttp(String url,
      {required String userKey}) async {
    http.Response res;
    try {
      res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    } catch (e) {
      throw Exception('Görsel indirilemedi (ağ/timeout): $e');
    }
    if (res.statusCode != 200) {
      throw Exception('Görsel indirilemedi (HTTP ${res.statusCode}).');
    }

    final headerMime = res.headers['content-type'];
    final extFromMime = _extFromMime(headerMime);
    final extFromUrl = _extFromUrl(url);
    final extFromBytes = _detectExtFromBytes(res.bodyBytes);
    final ext = extFromMime ?? extFromUrl ?? extFromBytes ?? 'jpg';

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
        return null;
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
      if (ext.contains('%')) ext = Uri.decodeComponent(ext);
      if (ext == 'jpeg') ext = 'jpg';
      if (ext.length > 5) return null;
      return ext;
    } catch (_) {
      return null;
    }
  }

  /// Baytlardan format tespiti (magic numbers)
  static String? _detectExtFromBytes(List<int> bytes) {
    if (bytes.length < 12) return null;
    // JPG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return 'jpg';
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) return 'png';
    // GIF: "GIF87a" / "GIF89a"
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) return 'gif';
    // WEBP: "RIFF....WEBP"
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) return 'webp';
    // BMP: 'B' 'M'
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return 'bmp';
    // HEIC/HEIF: ftypheic / ftypheif / ftypmif1 vs.
    final header = utf8.decode(bytes.sublist(4, 12), allowMalformed: true);
    if (header.contains('ftypheic') ||
        header.contains('ftypheif') ||
        header.contains('ftypmif1')) return 'heic';
    return null;
  }

  static Future<void> _persist(List<HistoryItem> items, String userKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKeyFor(userKey),
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
