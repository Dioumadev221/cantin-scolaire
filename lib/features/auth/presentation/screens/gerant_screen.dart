import 'package:cantine_scolaire/features/auth/presentation/screens/gerant/commandes_screen..dart';
import 'package:cantine_scolaire/features/auth/presentation/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../presentation/providers/auth_provider.dart';
import '../screens/login_screen.dart';
import 'gerant/profil_gerant_screen.dart';

/// GerantScreen — Gestion des commandes uniquement.
/// Plats & Menus sont gérés par l'Admin.
class GerantScreen extends ConsumerStatefulWidget {
  final UserEntity user;
  const GerantScreen({super.key, required this.user});
  @override
  ConsumerState<GerantScreen> createState() => _GerantScreenState();
}

class _GerantScreenState extends ConsumerState<GerantScreen> {
  @override
  void initState() {
    super.initState();
    NotificationService().initialize(widget.user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(child: CommandesScreen(user: widget.user)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: const Color(0xFFFF6B35),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      child: Row(children: [
        // Titre
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Gérant — Commandes', style: TextStyle(color: Colors.white70, fontSize: 11)),
            Text('${widget.user.prenom} ${widget.user.nom}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
        ),

        // Cloche notifications avec badge
        StreamBuilder<int>(
          stream: NotificationService.compteurNonLusGerant(),
          builder: (context, snap) {
            final unread = snap.data ?? 0;
            return GestureDetector(
              onTap: _showNotifications,
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                  ),
                  if (unread > 0)
                    Positioned(top: -4, right: -4,
                      child: Container(
                        width: 18, height: 18,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Center(child: Text(unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(color: Color(0xFFFF6B35),
                                fontSize: 9, fontWeight: FontWeight.w800))),
                      ),
                    ),
                ]),
              ),
            );
          },
        ),

        // Avatar + PopupMenu (Profil | Déconnexion)
        PopupMenuButton<String>(
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white, elevation: 8,
          onSelected: (v) async {
            if (v == 'profil') {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ProfilGerantScreen(user: widget.user)));
            } else if (v == 'logout') {
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
              }
            }
          },
          itemBuilder: (_) => [
            _menuItem(Icons.person_outline, 'Mon profil', 'profil',
                const Color(0xFFFF6B35), const Color(0xFFFFF3EE)),
            const PopupMenuDivider(height: 1),
            _menuItem(Icons.logout, 'Se déconnecter', 'logout',
                const Color(0xFFEF4444), const Color(0xFFFEE2E2)),
          ],
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white38)),
            child: Center(child: Text('${widget.user.prenom[0]}${widget.user.nom[0]}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
          ),
        ),
      ]),
    );
  }

  PopupMenuItem<String> _menuItem(IconData icon, String label, String value,
      Color color, Color bg) {
    return PopupMenuItem(value: value, height: 48,
      child: Row(children: [
        Container(width: 32, height: 32,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: color)),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.4, expand: false,
        builder: (_, scrollCtrl) => Column(children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFEDEDED),
                  borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
            child: Row(children: [
              const Expanded(child: Text('Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              TextButton(
                onPressed: () => NotificationService.marquerToutesLuesGerant(),
                child: const Text('Tout lire', style: TextStyle(
                    color: Color(0xFFFF6B35), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: NotificationService.streamToutesGerant(),
              builder: (_, snap) {
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🔔', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 10),
                    Text('Aucune notification pour l\'instant',
                        style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 13)),
                  ],
                ));
                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final isRead = data['lu'] == true;
                    final ts = data['createdAt'] as Timestamp?;
                    final type = data['type'] ?? 'info';
                    return GestureDetector(
                      onTap: () => NotificationService.marquerLue(docs[i].id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : const Color(0xFFFFF8F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isRead ? const Color(0xFFEDEDED) : const Color(0xFFFFB89A),
                              width: isRead ? 0.5 : 1.5),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: type == 'nouvelle_commande'
                                  ? const Color(0xFFF0FDF4) : const Color(0xFFFFF3EE),
                              borderRadius: BorderRadius.circular(14)),
                            child: Center(child: Text(
                                NotificationService.iconForType(type),
                                style: const TextStyle(fontSize: 20))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(data['titre'] ?? '',
                                  style: TextStyle(fontSize: 13,
                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                      color: const Color(0xFF1A1A1A)))),
                              Text(NotificationService.timeAgo(ts),
                                  style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 10)),
                            ]),
                            const SizedBox(height: 3),
                            Text(data['corps'] ?? '',
                                style: const TextStyle(
                                    color: Color(0xFF6B7280), fontSize: 12, height: 1.4)),
                          ])),
                          if (!isRead) ...[
                            const SizedBox(width: 8),
                            Container(width: 8, height: 8,
                                decoration: const BoxDecoration(
                                    color: Color(0xFFFF6B35), shape: BoxShape.circle)),
                          ],
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}