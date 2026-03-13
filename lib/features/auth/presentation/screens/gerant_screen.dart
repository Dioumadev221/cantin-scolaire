import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import 'gerant/commandes_screen..dart';
import 'gerant/plats_screen.dart';
import 'gerant/menus_screen.dart';
import 'gerant/profil_gerant_screen.dart';

class GerantScreen extends ConsumerStatefulWidget {
  final UserEntity user;
  const GerantScreen({super.key, required this.user});

  @override
  ConsumerState<GerantScreen> createState() => _GerantScreenState();
}

class _GerantScreenState extends ConsumerState<GerantScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      PlatsScreen(user: widget.user),
      CommandesScreen(user: widget.user),
      MenusScreen(user: widget.user),
      ProfilGerantScreen(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEDEDED), width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _buildNavItem(0, '🍽️', 'Plats'),
                _buildNavItem(1, '📦', 'Commandes'),
                _buildNavItem(2, '📅', 'Menus'),
                _buildNavItem(3, '👤', 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String icon, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? const Color(0xFFFF6B35)
                    : const Color(0xFF8A8A8A),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 6 : 0,
              height: isActive ? 6 : 0,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B35),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
