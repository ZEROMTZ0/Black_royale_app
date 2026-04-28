import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';
import '../models/game_history.dart';
import '../services/deck_service.dart';
import '../services/history_service.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/chip_widget.dart';

enum GamePhase { betting, loading, playerTurn, dealerTurn, result }

// Pantalla 3: Juego principal — StatefulWidget + setState (requisito 3)
// Incluye Stack de cartas (req 5), GridView de fichas (req 5), API (req 6)
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final _deckService = DeckService();
  final _historyService = HistoryService();

  List<CardModel> _playerHand = [];
  List<CardModel> _dealerHand = [];

  int _bet = 0;
  int _chips = 1000;
  GamePhase _phase = GamePhase.betting;
  String? _resultText;
  String? _resultOutcome; // 'win','lose','push','blackjack'
  bool _showDealerHole = false;
  bool _isApiLoading = false;
  String? _apiError;

  // Constantes del juego
  static const List<int> _chipValues = [10, 25, 100, 500];
  static const _betMin = 10;

  @override
  void initState() {
    super.initState();
    _loadChips();
    _initDeck();
  }

  // ──────────────────────────────
  // Persistencia (SharedPreferences)
  // ──────────────────────────────
  Future<void> _loadChips() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _chips = prefs.getInt('player_chips') ?? 1000);
  }

  Future<void> _saveStats({required bool isWin}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('player_chips', _chips);
    if (_chips > (prefs.getInt('high_score') ?? 0)) {
      await prefs.setInt('high_score', _chips);
    }
    await prefs.setInt('games_played', (prefs.getInt('games_played') ?? 0) + 1);
    if (isWin) {
      await prefs.setInt('games_won', (prefs.getInt('games_won') ?? 0) + 1);
    }
  }

  // ──────────────────────────────
  // API: inicializar baraja
  // ──────────────────────────────
  Future<void> _initDeck() async {
    try {
      await _deckService.initializeDeck();
    } catch (_) {
      // Fallback a modo local si la API falla
    }
  }

  // ──────────────────────────────
  // Lógica de apuestas
  // ──────────────────────────────
  void _addToBet(int amount) {
    if (_bet + amount > _chips) {
      _showSnack('No tienes suficientes fichas');
      return;
    }
    setState(() => _bet += amount);
  }

  void _clearBet() => setState(() => _bet = 0);

  // ──────────────────────────────
  // Valor de la mano (Blackjack)
  // ──────────────────────────────
  int _handValue(List<CardModel> hand) {
    int total = 0;
    int aces = 0;
    for (final card in hand) {
      if (card.value == 'ACE') {
        aces++;
        total += 11;
      } else {
        total += card.numericValue;
      }
    }
    // Convertir Ases de 11 a 1 si se pasa de 21
    while (total > 21 && aces > 0) {
      total -= 10;
      aces--;
    }
    return total;
  }

  bool _isBlackjack(List<CardModel> hand) =>
      hand.length == 2 && _handValue(hand) == 21;

  // ──────────────────────────────
  // Robar cartas (API o fallback)
  // ──────────────────────────────
  Future<List<CardModel>> _draw(int count) async {
    if (_deckService.isInitialized) {
      return await _deckService.drawCards(count);
    }
    return _deckService.generateLocalCards(count);
  }

  // ──────────────────────────────
  // Acciones del juego
  // ──────────────────────────────
  Future<void> _deal() async {
    if (_bet < _betMin) {
      _showSnack('Apuesta mínima: \$$_betMin');
      return;
    }

    setState(() {
      _phase = GamePhase.loading;
      _isApiLoading = true;
      _apiError = null;
    });

    try {
      // Robar 4 cartas: jugador[0], crupier[0], jugador[1], crupier[1]
      final cards = await _draw(4);
      final playerCards = [cards[0], cards[2]];
      final dealerCards  = [cards[1], cards[3]];

      setState(() {
        _playerHand = playerCards;
        _dealerHand = dealerCards;
        _showDealerHole = false;
        _isApiLoading = false;
      });

      // Verificar Blackjack inmediato
      final playerBJ = _isBlackjack(playerCards);
      final dealerBJ  = _isBlackjack(dealerCards);

      if (playerBJ && dealerBJ) {
        setState(() => _showDealerHole = true);
        _endGame('push');
      } else if (playerBJ) {
        setState(() => _showDealerHole = true);
        _endGame('blackjack');
      } else {
        setState(() => _phase = GamePhase.playerTurn);
      }
    } catch (e) {
      setState(() {
        _isApiLoading = false;
        _phase = GamePhase.betting;
        _apiError = 'Error de conexión. Reintenta.';
      });
    }
  }

  Future<void> _hit() async {
    setState(() => _isApiLoading = true);
    try {
      final cards = await _draw(1);
      setState(() {
        _playerHand = [..._playerHand, cards[0]];
        _isApiLoading = false;
      });

      final value = _handValue(_playerHand);
      if (value > 21) {
        _endGame('bust');
      } else if (value == 21) {
        await _stand();
      }
    } catch (e) {
      setState(() => _isApiLoading = false);
      _showSnack('Error al robar carta, reintenta');
    }
  }

  Future<void> _stand() async {
    setState(() {
      _showDealerHole = true;
      _phase = GamePhase.dealerTurn;
      _isApiLoading = true;
    });

    // El crupier roba hasta tener 17 o más
    while (_handValue(_dealerHand) < 17) {
      try {
        final cards = await _draw(1);
        setState(() => _dealerHand = [..._dealerHand, cards[0]]);
        // Pequeña pausa para efecto visual
        await Future.delayed(const Duration(milliseconds: 650));
      } catch (_) {
        break;
      }
    }

    setState(() => _isApiLoading = false);

    final playerVal = _handValue(_playerHand);
    final dealerVal = _handValue(_dealerHand);

    if (dealerVal > 21) {
      _endGame('dealer_bust');
    } else if (playerVal > dealerVal) {
      _endGame('win');
    } else if (dealerVal > playerVal) {
      _endGame('lose');
    } else {
      _endGame('push');
    }
  }

  Future<void> _doubleDown() async {
    if (_chips < _bet * 2) {
      _showSnack('No tienes fichas para doblar');
      return;
    }
    setState(() {
      _bet *= 2;
      _isApiLoading = true;
    });

    try {
      final cards = await _draw(1);
      setState(() {
        _playerHand = [..._playerHand, cards[0]];
        _isApiLoading = false;
      });

      if (_handValue(_playerHand) > 21) {
        _endGame('bust');
      } else {
        await _stand();
      }
    } catch (e) {
      setState(() => _isApiLoading = false);
    }
  }

  // ──────────────────────────────
  // Fin de partida + guardar historial
  // ──────────────────────────────
  void _endGame(String outcome) {
    int chipChange = 0;
    String text = '';
    bool isWin = false;

    switch (outcome) {
      case 'blackjack':
        chipChange = (_bet * 1.5).round();
        text = '🎉 BLACKJACK!';
        isWin = true;
        break;
      case 'win':
        chipChange = _bet;
        text = '✅ ¡Ganaste!';
        isWin = true;
        break;
      case 'dealer_bust':
        chipChange = _bet;
        text = '💥 Crupier se pasó — ¡Ganaste!';
        isWin = true;
        break;
      case 'bust':
        chipChange = -_bet;
        text = '💣 Te pasaste — Perdiste';
        break;
      case 'lose':
        chipChange = -_bet;
        text = '❌ Perdiste';
        break;
      case 'push':
        chipChange = 0;
        text = '🤝 Empate';
        break;
    }

    final finalResult = isWin ? (outcome == 'blackjack' ? 'blackjack' : 'win') :
                        (outcome == 'push' ? 'push' : 'lose');

    setState(() {
      _chips = (_chips + chipChange).clamp(0, 999999);
      _resultText = text;
      _resultOutcome = finalResult;
      _phase = GamePhase.result;
      _showDealerHole = true;
    });

    _saveStats(isWin: isWin);
    _saveHistory(finalResult, chipChange);
  }

  Future<void> _saveHistory(String result, int chipChange) async {
    final entry = GameHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      result: result,
      bet: _bet,
      chipChange: chipChange,
      chipsAfter: _chips,
      playedAt: DateTime.now(),
      playerCards: _playerHand.map((c) => c.code).join(','),
      dealerCards: _dealerHand.map((c) => c.code).join(','),
    );
    await _historyService.add(entry);
  }

  void _newHand() {
    setState(() {
      _playerHand = [];
      _dealerHand = [];
      _bet = 0;
      _phase = GamePhase.betting;
      _resultText = null;
      _resultOutcome = null;
      _showDealerHole = false;
      _apiError = null;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
    );
  }

  // ──────────────────────────────
  // UI
  // ──────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1F0D), Color(0xFF1B4332), Color(0xFF0D2B0D)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: _phase == GamePhase.betting || _phase == GamePhase.loading
                    ? _buildBettingArea()
                    : _buildGameTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          const Text('BLACKJACK ROYAL',
              style: TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700)),
            ),
            child: Text('\$$_chips',
                style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  // ── Área de apuesta ────────────────────────────────────────────────────────
  Widget _buildBettingArea() {
    final isLoading = _phase == GamePhase.loading;
    return Column(
      children: [
        const Spacer(),
        if (_apiError != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_apiError!, style: const TextStyle(color: Color(0xFFEF5350))),
          ),
        const Text('ELIGE TU APUESTA',
            style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 2)),
        const SizedBox(height: 16),
        // Apuesta actual
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
          ),
          child: Text(
            'Apuesta: \$$_bet',
            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),
        // GridView de fichas (requisito 5)
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: _chipValues.map((v) => ChipWidget(
            value: v,
            enabled: !isLoading && v <= _chips,
            onTap: () => _addToBet(v),
          )).toList(),
        ),
        const SizedBox(height: 20),
        // Botones de acción
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _clearBet,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Limpiar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isLoading || _bet < _betMin ? null : _deal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 6,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                      : const Text('REPARTIR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }

  // ── Mesa de juego ──────────────────────────────────────────────────────────
  Widget _buildGameTable() {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Mano del crupier
        _HandSection(
          label: 'CRUPIER',
          hand: _dealerHand,
          showHole: _showDealerHole,
          value: _showDealerHole
              ? _handValue(_dealerHand)
              : (_dealerHand.isNotEmpty ? _dealerHand[0].numericValue : 0),
          showValueHidden: !_showDealerHole,
        ),
        const SizedBox(height: 12),

        // Banner de resultado con AnimatedContainer (requisito 8)
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          height: _phase == GamePhase.result ? 72 : 0,
          child: _phase == GamePhase.result ? _buildResultBanner() : const SizedBox.shrink(),
        ),

        const Spacer(),

        // Mano del jugador
        _HandSection(
          label: 'JUGADOR',
          hand: _playerHand,
          showHole: true,
          value: _handValue(_playerHand),
          showValueHidden: false,
          highlight: true,
        ),
        const SizedBox(height: 16),

        // Indicador de carga durante turno del crupier
        if (_isApiLoading && _phase == GamePhase.dealerTurn)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Crupier robando...', style: TextStyle(color: Colors.white54, fontSize: 13)),
          ),

        // Botones de acción del jugador / nueva mano
        if (_phase == GamePhase.playerTurn) _buildPlayerActions(),
        if (_phase == GamePhase.result)     _buildResultActions(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildResultBanner() {
    final isWin = _resultOutcome == 'win' || _resultOutcome == 'blackjack';
    final isPush = _resultOutcome == 'push';
    final color = isWin ? const Color(0xFF2E7D32) : (isPush ? const Color(0xFF1565C0) : const Color(0xFFB71C1C));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 12)],
      ),
      child: Center(
        child: Text(
          _resultText ?? '',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPlayerActions() {
    final canDouble = _chips >= _bet * 2 && _playerHand.length == 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'HIT',
              icon: Icons.add,
              color: const Color(0xFF1565C0),
              onTap: _isApiLoading ? null : _hit,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              label: 'STAND',
              icon: Icons.pan_tool,
              color: const Color(0xFF4A148C),
              onTap: _isApiLoading ? null : _stand,
            ),
          ),
          if (canDouble) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: '2x',
                icon: Icons.double_arrow,
                color: const Color(0xFF6D4C41),
                onTap: _isApiLoading ? null : _doubleDown,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.home, size: 18),
              label: const Text('Menú'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _chips > 0 ? _newHand : null,
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('Nueva mano', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets reutilizables ────────────────────────────────────────────────────

class _HandSection extends StatelessWidget {
  final String label;
  final List<CardModel> hand;
  final bool showHole;
  final int value;
  final bool showValueHidden;
  final bool highlight;

  const _HandSection({
    required this.label,
    required this.hand,
    required this.showHole,
    required this.value,
    required this.showValueHidden,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 2)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: highlight ? const Color(0xFFFFD700) : Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                showValueHidden ? '??' : '$value',
                style: TextStyle(
                  color: highlight ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Stack de cartas con superposición (requisito 5 - Stack widget)
        SizedBox(
          height: 110,
          child: hand.isEmpty
              ? const SizedBox.shrink()
              : Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(width: 72.0 + (hand.length - 1) * 46.0),
                    ...List.generate(hand.length, (i) {
                      final faceDown = i == 1 && !showHole;
                      return Positioned(
                        left: i * 46.0,
                        child: PlayingCardWidget(
                          card: hand[i],
                          faceDown: faceDown,
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({required this.label, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
