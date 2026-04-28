import 'package:flutter/material.dart';

class ChipWidget extends StatelessWidget {
  final int value;
  final VoidCallback onTap;
  final bool enabled;

  const ChipWidget({
    super.key,
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  Color get _chipColor {
    if (value <= 10) return const Color(0xFFE53935);   // rojo  $10
    if (value <= 25) return const Color(0xFF1565C0);   // azul  $25
    if (value <= 100) return const Color(0xFF2E7D32);  // verde $100
    if (value <= 500) return const Color(0xFF4A148C);  // morado $500
    return const Color(0xFF37474F);                    // negro $1000
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _chipColor,
            border: Border.all(color: Colors.white38, width: 3),
            boxShadow: [
              BoxShadow(
                color: _chipColor.withOpacity(0.6),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Borde interior decorativo
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
              ),
              Text(
                '\$$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
