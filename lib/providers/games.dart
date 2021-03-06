import 'package:flutter/cupertino.dart';

import '../helpers/db_helper.dart';

class Games with ChangeNotifier {
  List<Map<String, Object>> _games;
  List<Map<String, Object>> get games => _games == null ? null : [..._games];
  bool get isReady => _games != null;
  int padding = 0;

  Future<void> fetch() async {
    _games = await DatabaseHelper.fetchAll();
    if (_games.isNotEmpty)
      padding =
          (games.map((e) => e["id"]).toList()..sort()).last.toString().length;
    notifyListeners();
  }

  Future<Map<String, Object>> fetchLastGame() async {
    var result = await DatabaseHelper.fetchLastGame();
    if (result != null && result["finished"] == 0)
      return result;
    else
      return null;
  }

  Future<void> delete(List<int> ids) async {
    await DatabaseHelper.deleteMultiple(ids);
    _games = games.where((element) => !ids.contains(element['id'])).toList();
    notifyListeners();
  }

  void clearGames() {
    _games = null;
    notifyListeners();
  }
}
