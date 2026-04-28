import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../models/game_history.dart';

// Pantalla 4: Historial — ListView (requisito 5)
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _historyService = HistoryService();

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B4332),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Borrar historial', style: TextStyle(color: Colors.white)),
        content: const Text('¿Eliminar todas las partidas?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar', style: TextStyle(color: Color(0xFFEF5350))),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _historyService.clearAll();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _historyService.getAll();

    return Scaffold(
      backgroundColor: const Color(0xFF0D2B0D),
      appBar: AppBar(
        title: const Text('Historial de Partidas'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF5350)),
              onPressed: _confirmClear,
              tooltip: 'Borrar historial',
            ),
        ],
      ),
      body: history.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('♠', style: TextStyle(fontSize: 64, color: Colors.white12)),
                  SizedBox(height: 12),
                  Text('Sin partidas aún', style: TextStyle(color: Colors.white38, fontSize: 18)),
                ],
              ),
            )
          : Column(
              children: [
                // Resumen en la parte superior
                _SummaryBar(
                  total: _historyService.totalGames,
                  wins: _historyService.wins,
                  losses: _historyService.losses,
                ),
                // ListView del historial (requisito 5)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                    itemCount: history.length,
                    itemBuilder: (_, i) => _HistoryCard(entry: history[i]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final int total;
  final int wins;
  final int losses;

  const _SummaryBar({required this.total, required this.wins, required this.losses});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF1B4332),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(label: 'Total', value: '$total', color: Colors.white70),
          _SummaryItem(label: 'Victorias', value: '$wins', color: Colors.greenAccent),
          _SummaryItem(label: 'Derrotas', value: '$losses', color: const Color(0xFFEF5350)),
          _SummaryItem(
            label: 'Win Rate',
            value: total == 0 ? '—' : '${(wins / total * 100).toStringAsFixed(0)}%',
            color: const Color(0xFFFFD700),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final GameHistory entry;

  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isWin = entry.result == 'win' || entry.result == 'blackjack';
    final isPush = entry.result == 'push';
    final resultColor = isWin ? Colors.greenAccent : (isPush ? Colors.blueAccent : const Color(0xFFEF5350));
    final resultLabel = switch (entry.result) {
      'blackjack' => 'BLACKJACK',
      'win'       => 'VICTORIA',
      'lose'      => 'DERROTA',
      'push'      => 'EMPATE',
      _           => entry.result.toUpperCase(),
    };
    final chipLabel = entry.chipChange == 0
        ? '±\$0'
        : (entry.chipChange > 0 ? '+\$${entry.chipChange}' : '-\$${entry.chipChange.abs()}');
    final chipColor = isWin ? Colors.greenAccent : (isPush ? Colors.white54 : const Color(0xFFEF5350));

    final dt = entry.playedAt;
    final dateStr = '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: resultColor, width: 4)),
      ),
      child: Row(
        children: [
          // Resultado
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(resultLabel, textAlign: TextAlign.center,
                style: TextStyle(color: resultColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          // Cartas
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu mano: ${entry.playerCards}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 2),
                Text('Crupier: ${entry.dealerCards}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 4),
                Text(dateStr, style: const TextStyle(color: Colors.white24, fontSize: 10)),
              ],
            ),
          ),
          // Apuesta y resultado
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Apuesta: \$${entry.bet}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 4),
              Text(chipLabel,
                  style: TextStyle(color: chipColor, fontSize: 16, fontWeight: FontWeight.bold)),
              Text('\$${entry.chipsAfter}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
