import 'package:flutter/foundation.dart';
import '../../data/history_item.dart';
import '../../services/history_storage.dart';

enum HistoryState { idle, loading, error }

class HistoryViewModel extends ChangeNotifier {
  List<HistoryItem> items = [];
  HistoryState state = HistoryState.idle;
  String? error;

  Future<void> load() async {
    state = HistoryState.loading; notifyListeners();
    try {
      items = await HistoryStorage.loadAll();
      state = HistoryState.idle;
    } catch (e) {
      error = e.toString();
      state = HistoryState.error;
    }
    notifyListeners();
  }

  Future<void> saveFromUrl(String url) async {
    try {
      await HistoryStorage.saveFromUrl(url);
      await load();
    } catch (e) {
      error = e.toString();
      state = HistoryState.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> remove(int index) async {
    await HistoryStorage.removeAt(index);
    await load();
  }

  Future<void> clearAll() async {
    await HistoryStorage.clearAll();
    await load();
  }
}
