import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/game_history.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(GameHistoryAdapter());
  await Hive.openBox<GameHistory>('history');
  runApp(const BlackjackApp());
}
