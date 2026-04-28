import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/card_model.dart';

// Consumo de API: https://deckofcardsapi.com/
// Endpoints usados:
//   POST /api/deck/new/shuffle/         → crear baraja mezclada
//   GET  /api/deck/{id}/draw/?count=N   → robar N cartas
//   GET  /api/deck/{id}/shuffle/        → remezclar

class DeckService {
  static const _base = 'https://deckofcardsapi.com/api/deck';

  String? _deckId;
  int _remaining = 0;

  bool get isInitialized => _deckId != null;

  Future<void> initializeDeck() async {
    final uri = Uri.parse('$_base/new/shuffle/?deck_count=1');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _deckId = data['deck_id'] as String;
      _remaining = data['remaining'] as int;
    } else {
      throw Exception('No se pudo crear la baraja (${response.statusCode})');
    }
  }

  Future<List<CardModel>> drawCards(int count) async {
    // Remezclar si quedan pocas cartas
    if (_remaining < count + 10) {
      await _reshuffle();
    }

    final uri = Uri.parse('$_base/$_deckId/draw/?count=$count');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _remaining = data['remaining'] as int;
      final cardsList = data['cards'] as List<dynamic>;
      return cardsList
          .map((c) => CardModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al robar cartas (${response.statusCode})');
    }
  }

  Future<void> _reshuffle() async {
    if (_deckId == null) {
      await initializeDeck();
      return;
    }
    final uri = Uri.parse('$_base/$_deckId/shuffle/');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _remaining = data['remaining'] as int;
    }
  }

  // Fallback local si la API no está disponible
  List<CardModel> generateLocalCards(int count) {
    const values = [
      'ACE', '2', '3', '4', '5', '6', '7',
      '8', '9', '10', 'JACK', 'QUEEN', 'KING'
    ];
    const suits = ['HEARTS', 'DIAMONDS', 'CLUBS', 'SPADES'];
    final rng = Random();

    return List.generate(count, (_) {
      final v = values[rng.nextInt(values.length)];
      final s = suits[rng.nextInt(suits.length)];
      final code = '${v == '10' ? '0' : v[0]}${s[0]}';
      return CardModel(value: v, suit: s, imageUrl: '', code: code);
    });
  }
}
