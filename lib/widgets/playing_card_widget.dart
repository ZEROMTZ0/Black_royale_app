import 'package:flutter/material.dart';
import '../models/card_model.dart';

class PlayingCardWidget extends StatelessWidget {
  final CardModel card;
  final bool faceDown;
  final double width;
  final double height;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.faceDown = false,
    this.width = 72,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: faceDown ? const Color(0xFF1565C0) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(2, 4)),
        ],
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: faceDown ? _buildBack() : _buildFront(),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.casino, color: Colors.white38, size: 32),
      ),
    );
  }

  Widget _buildFront() {
    // Muestra imagen de la API si está disponible, si no renderiza el card con texto
    if (card.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          card.imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorBuilder: (_, __, ___) => _buildTextCard(),
        ),
      );
    }
    return _buildTextCard();
  }

  Widget _buildTextCard() {
    final color = card.isRed ? const Color(0xFFD32F2F) : Colors.black87;
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.displayValue,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(card.suitSymbol,
              style: TextStyle(color: color, fontSize: 14)),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Transform.rotate(
              angle: 3.14159,
              child: Column(
                children: [
                  Text(card.displayValue,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(card.suitSymbol,
                      style: TextStyle(color: color, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Carta oculta (placeholder mientras se carga)
class CardPlaceholderWidget extends StatelessWidget {
  final double width;
  final double height;

  const CardPlaceholderWidget({super.key, this.width = 72, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
    );
  }
}
