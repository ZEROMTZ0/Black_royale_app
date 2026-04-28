import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../models/game_history.dart';

// Pantalla 5: Ranking — GridView (requisito 5 — diseño de interfaces complejas)
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = HistoryService();
    final topEntries = service.getTopByChips();

    return Scaffold(
      backgroundColor: const Color(0xFF0D2B0D),
      appBar: AppBar(
        title: const Text('Ranking - Mejores Partidas'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: topEntries.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🏆', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 12),
                  Text('Juega para aparecer en el ranking',
                      style: TextStyle(color: Colors.white38, fontSize: 16)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Podio: top 3
                  if (topEntries.length >= 1) _buildPodium(topEntries),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: Text('TOP 10 — MAYORES BALANCES',
                        style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
                  ),
                  // GridView de posiciones (requisito 5)
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.0,
                      ),
                      itemCount: topEntries.length,
                      itemBuilder: (_, i) => _LeaderCard(entry: topEntries[i], position: i + 1),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPodium(List<GameHistory> entries) {
    final medals = ['🥇', '🥈', '🥉'];
    final colors = [const Color(0xFFFFD700), Colors.grey.shade400, const Color(0xFFCD7F32)];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(entries.length > 3 ? 3 : entries.length, (i) {
        final e = entries[i];
        final heights = [100.0, 80.0, 65.0];
        return Column(
          children: [
            Text(medals[i], style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text('\$${e.chipsAfter}',
                style: TextStyle(color: colors[i], fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Container(
              width: 80,
              height: heights[i],
              decoration: BoxDecoration(
                color: colors[i].withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                border: Border.all(color: colors[i].withOpacity(0.5)),
              ),
              child: Center(
                child: Text('${i + 1}', style: TextStyle(color: colors[i], fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _LeaderCard extends StatelessWidget {
  final GameHistory entry;
  final int position;

  const _LeaderCard({required this.entry, required this.position});

  @override
  Widget build(BuildContext context) {
    final resultColor = (entry.result == 'win' || entry.result == 'blackjack')
        ? Colors.greenAccent
        : (entry.result == 'push' ? Colors.blueAccent : const Color(0xFFEF5350));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Text('#$position',
              style: const TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\$${entry.chipsAfter}',
                    style: const TextStyle(color: Color(0xFFFFD700), fontSize: 17, fontWeight: FontWeight.bold)),
                Text('Apuesta: \$${entry.bet}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: resultColor),
          ),
        ],
      ),
    );
  }
}
