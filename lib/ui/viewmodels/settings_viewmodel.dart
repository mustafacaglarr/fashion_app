import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  static const _kFaceLocalKey = 'face_local_store';
  static const _kPushKey = 'push_notifications';
  static const _kNewsletterKey = 'newsletter';

  bool _faceLocalStore = true;
  bool _pushNotifications = true;
  bool _newsletter = false;

  bool get faceLocalStore => _faceLocalStore;
  bool get pushNotifications => _pushNotifications;
  bool get newsletter => _newsletter;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _faceLocalStore = sp.getBool(_kFaceLocalKey) ?? true;
    _pushNotifications = sp.getBool(_kPushKey) ?? true;
    _newsletter = sp.getBool(_kNewsletterKey) ?? false;
    notifyListeners();
  }

  Future<void> setFaceLocalStore(bool v) async {
    _faceLocalStore = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kFaceLocalKey, v);
    notifyListeners();
  }

  Future<void> setPushNotifications(bool v) async {
    _pushNotifications = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kPushKey, v);
    notifyListeners();
  }

}
