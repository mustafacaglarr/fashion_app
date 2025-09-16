// lib/ui/viewmodels/history_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../../data/history_item.dart';
import '../../services/history_storage.dart';

enum HistoryState { idle, loading, error }

class HistoryViewModel extends ChangeNotifier {
  // DAİMA geçerli bir değer olsun:
  String _userKey = 'anon';
  String get userKey => _userKey;

  HistoryViewModel({String? userKey}) {
    _userKey = (userKey != null && userKey.isNotEmpty) ? userKey : 'anon';
  }

  List<HistoryItem> items = [];
  HistoryState state = HistoryState.idle;
  String? error;

  /// Hesap değişiminde çağırın (null gelirse 'anon' olur)
  Future<void> setUser(String? newUserKey) async {
    final next = (newUserKey != null && newUserKey.isNotEmpty) ? newUserKey : 'anon';
    if (_userKey == next) return;

    _userKey = next;

    // Ekranı hızlıca temizle
    items = [];
    error = null;
    state = HistoryState.idle;
    notifyListeners();

    await load();
  }

  Future<void> load() async {
    state = HistoryState.loading; notifyListeners();
    try {
      items = await HistoryStorage.loadAll(userKey);
      state = HistoryState.idle;
    } catch (e) {
      error = e.toString();
      state = HistoryState.error;
    }
    notifyListeners();
  }

  Future<void> saveFromUrl(String url) async {
    try {
      await HistoryStorage.saveFromUrl(url, userKey: userKey);
      await load();
    } catch (e) {
      error = e.toString();
      state = HistoryState.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> remove(int index) async {
    await HistoryStorage.removeAt(index, userKey: userKey);
    await load();
  }

  Future<void> clearAll() async {
    await HistoryStorage.clearAll(userKey);
    await load();
  }
}
