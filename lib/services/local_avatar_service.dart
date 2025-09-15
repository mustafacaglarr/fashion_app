// lib/services/local_avatar_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAvatarService {
  static const _prefsKeyPrefix = 'avatar_';

  static Future<String?> getSavedPath({String userId = 'local'}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefsKeyPrefix$userId');
  }

  static Future<void> clear({String userId = 'local'}) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('$_prefsKeyPrefix$userId');
    if (path != null) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
    await prefs.remove('$_prefsKeyPrefix$userId');
  }

  /// Her seçimde ZAMAN DAMGALI dosya adı üretir. (ör: avatar_local_1715788712345.jpg)
  static Future<String?> pickAndSave({String userId = 'local'}) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory(p.join(appDir.path, 'avatars'));
    if (!await avatarsDir.exists()) {
      await avatarsDir.create(recursive: true);
    }

    // önceki dosyayı sil (varsa)
    final oldPath = await getSavedPath(userId: userId);
    if (oldPath != null) {
      final oldFile = File(oldPath);
      if (await oldFile.exists()) {
        try { await oldFile.delete(); } catch (_) {}
      }
    }

    final ext = p.extension(x.path).isEmpty ? '.jpg' : p.extension(x.path);
    final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final target = File(p.join(avatarsDir.path, fileName));

    final src = File(x.path);
    final saved = await src.copy(target.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsKeyPrefix$userId', saved.path);

    return saved.path;
  }
}
