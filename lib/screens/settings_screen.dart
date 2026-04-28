import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pantalla 6: Configuración — SharedPreferences + formulario con validación (req 5 y 7)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _soundEnabled = true;
  bool _animationsEnabled = true;
  bool _isLoading = true;
  int _currentChips = 0;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text  = prefs.getString('player_name') ?? '';
      _soundEnabled         = prefs.getBool('sound_enabled') ?? true;
      _animationsEnabled    = prefs.getBool('animations_enabled') ?? true;
      _currentChips         = prefs.getInt('player_chips') ?? 1000;
      _highScore            = prefs.getInt('high_score') ?? 1000;
      _isLoading = false;
    });
  }

  Future<void> _savePrefs() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player_name', _nameController.text.trim());
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('animations_enabled', _animationsEnabled);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cambios guardados'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _resetChips() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B4332),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reiniciar fichas', style: TextStyle(color: Colors.white)),
        content: const Text('¿Restablecer tu balance a \$1,000?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reiniciar', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
    if (ok == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('player_chips', 1000);
      setState(() => _currentChips = 1000);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichas restablecidas a \$1,000'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2B0D),
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _savePrefs,
            child: const Text('Guardar', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Sección: perfil
                  _SectionTitle(label: 'PERFIL'),
                  const SizedBox(height: 10),
                  // Avatar decorativo con Stack (requisito 5)
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1B5E20),
                            border: Border.all(color: const Color(0xFFFFD700), width: 3),
                          ),
                          child: const Center(
                            child: Text('♠', style: TextStyle(fontSize: 44, color: Color(0xFFFFD700))),
                          ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFD700),
                              border: Border.all(color: const Color(0xFF0D2B0D), width: 2),
                            ),
                            child: const Icon(Icons.edit, size: 14, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // TextField con validación (requisito 5 — formularios)
                  TextFormField(
                    controller: _nameController,
                    maxLength: 20,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nombre del jugador',
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFFFD700)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.07),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFFD700)),
                      ),
                      counterStyle: const TextStyle(color: Colors.white38),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Ingresa tu nombre';
                      if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Sección: balance
                  _SectionTitle(label: 'BALANCE'),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Fichas actuales',
                    value: '\$$_currentChips',
                  ),
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.emoji_events_outlined,
                    label: 'Mejor balance',
                    value: '\$$_highScore',
                    valueColor: const Color(0xFFFFD700),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _resetChips,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reiniciar fichas a \$1,000'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sección: preferencias
                  _SectionTitle(label: 'PREFERENCIAS'),
                  const SizedBox(height: 10),
                  _ToggleTile(
                    icon: Icons.volume_up_outlined,
                    label: 'Sonido',
                    subtitle: 'Efectos de sonido del juego',
                    value: _soundEnabled,
                    onChanged: (v) => setState(() => _soundEnabled = v),
                  ),
                  const SizedBox(height: 8),
                  _ToggleTile(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Animaciones',
                    subtitle: 'Efectos visuales y transiciones',
                    value: _animationsEnabled,
                    onChanged: (v) => setState(() => _animationsEnabled = v),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _savePrefs,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      child: const Text('Guardar cambios',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2));
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 20),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(value,
              style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFFD700),
          ),
        ],
      ),
    );
  }
}
