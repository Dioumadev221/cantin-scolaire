import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  final UserEntity user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5E6),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B35),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bonjour 👋',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    '${user.prenom} ${user.nom}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('🍽️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Bienvenue sur Cantine Scolaire !',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1a1a1a),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Commandez depuis votre salle de cours',
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            // Bouton déconnexion
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const _LoginRedirect()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B35),
                    side: const BorderSide(color: Color(0xFFFF6B35)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Se déconnecter',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget temporaire pour rediriger vers login
class _LoginRedirect extends ConsumerWidget {
  const _LoginRedirect();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold();
  }
}
