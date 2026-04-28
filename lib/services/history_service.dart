import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_history.dart';

class HistoryService {
  Box<GameHistory> get _box => Hive.box<GameHistory>('history');

  Future<void> add(GameHistory entry) async {
    await _box.put(entry.id, entry);
  }

  List<GameHistory> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    return list;
  }

  // Top 10 por fichas acumuladas (para el leaderboard)
  List<GameHistory> getTopByChips() {
    final list = _box.values.toList();
    list.sort((a, b) => b.chipsAfter.compareTo(a.chipsAfter));
    return list.take(10).toList();
  }

  Future<void> clearAll() async => await _box.clear();

  int get totalGames => _box.length;
  int get wins => _box.values.where((h) => h.result == 'win' || h.result == 'blackjack').length;
  int get losses => _box.values.where((h) => h.result == 'lose').length;
}
