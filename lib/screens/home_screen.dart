import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/history_service.dart';

// Pantalla 2: Home — menú principal con estadísticas del jugador
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _historyService = HistoryService();

  String _playerName = 'Jugador';
  int _chips = 1000;
  int _highScore = 1000;
  int _gamesPlayed = 0;
  int _gamesWon = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _playerName  = prefs.getString('player_name') ?? 'Jugador';
      _chips       = prefs.getInt('player_chips') ?? 1000;
      _highScore   = prefs.getInt('high_score') ?? 1000;
      _gamesPlayed = prefs.getInt('games_played') ?? 0;
      _gamesWon    = prefs.getInt('games_won') ?? 0;
    });
  }

  double get _winRate => _gamesPlayed == 0 ? 0 : (_gamesWon / _gamesPlayed) * 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D2B0D), Color(0xFF1B4332), Color(0xFF0D2B0D)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bienvenido,', style: TextStyle(color: Colors.white60, fontSize: 14)),
                        Text(
                          _playerName,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Color(0xFFFFD700)),
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/settings');
                        _loadData();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Fichas
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('TUS FICHAS', style: TextStyle(color: Colors.white60, fontSize: 13, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text(
                        '\$$_chips',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Récord: \$$_highScore',
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Estadísticas
                Row(
                  children: [
                    Expanded(child: _StatBox(label: 'Partidas', value: '$_gamesPlayed', icon: Icons.casino)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatBox(label: 'Victorias', value: '$_gamesWon', icon: Icons.emoji_events)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatBox(label: 'Win Rate', value: '${_winRate.toStringAsFixed(0)}%', icon: Icons.trending_up)),
                  ],
                ),
                const SizedBox(height: 28),

                // Botón principal: JUGAR
                _chips <= 0
                    ? _NoChipsWarning(onReset: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('player_chips', 1000);
                        _loadData();
                      })
                    : _MenuButton(
                        label: 'JUGAR BLACKJACK',
                        icon: '♠',
                        color: const Color(0xFFFFD700),
                        textColor: Colors.black,
                        onTap: () async {
                          await Navigator.pushNamed(context, '/game');
                          _loadData();
                        },
                        large: true,
                      ),
                const SizedBox(height: 16),

                // Botones secundarios
                Row(
                  children: [
                    Expanded(
                      child: _MenuButton(
                        label: 'Historial',
                        icon: '📋',
                        color: const Color(0xFF1565C0),
                        textColor: Colors.white,
                        onTap: () => Navigator.pushNamed(context, '/history'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MenuButton(
                        label: 'Ranking',
                        icon: '🏆',
                        color: const Color(0xFF4A148C),
                        textColor: Colors.white,
                        onTap: () => Navigator.pushNamed(context, '/leaderboard'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Suits decorativos
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('♥  ♦  ♣  ♠', style: TextStyle(color: Colors.white24, fontSize: 20, letterSpacing: 8)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatBox({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 22),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final String icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final bool large;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: large ? 68 : 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: large ? 22 : 18)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: large ? 18 : 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoChipsWarning extends StatelessWidget {
  final VoidCallback onReset;
  const _NoChipsWarning({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF5350)),
      ),
      child: Column(
        children: [
          const Text('¡Sin fichas!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Te has quedado sin fichas.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onReset,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black),
            child: const Text('Reiniciar con \$1,000'),
          ),
        ],
      ),
    );
  }
}
