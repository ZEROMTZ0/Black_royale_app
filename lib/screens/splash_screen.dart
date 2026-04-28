import 'package:flutter/material.dart';

// Pantalla 1: Splash — AnimationController con fade + scale + slide
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );
    _scale = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.75, curve: Curves.elasticOut)),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic)),
    );

    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF1B5E20), Color(0xFF0A1A0A)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(color: const Color(0xFFFFD700), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '♠',
                        style: TextStyle(fontSize: 80, color: Color(0xFFFFD700)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      const Text(
                        'BlackJack',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                          letterSpacing: 4,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
                          ],
                        ),
                      ),
                      const Text(
                        'ROYAL',
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.white70,
                          letterSpacing: 10,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('♥', style: TextStyle(fontSize: 24, color: Color(0xFFE53935))),
                          SizedBox(width: 8),
                          Text('♦', style: TextStyle(fontSize: 24, color: Color(0xFFE53935))),
                          SizedBox(width: 8),
                          Text('♣', style: TextStyle(fontSize: 24, color: Colors.white70)),
                          SizedBox(width: 8),
                          Text('♠', style: TextStyle(fontSize: 24, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
