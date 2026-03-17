import 'package:cantine_scolaire/features/auth/domain/entities/user_entity.dart';
import 'package:cantine_scolaire/features/auth/presentation/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatelessWidget {
  final UserEntity user;
  const NotificationsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFFFF6B35),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: NotificationService.streamNonLues(user.uid),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;
              if (count == 0) return const SizedBox();
              return GestureDetector(
                onTap: () => NotificationService.marquerToutesLues(user.uid),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tout lire',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<QuerySnapshot>(
      stream: NotificationService.streamToutes(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text('🔔', style: TextStyle(fontSize: 38)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucune notification',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Vous serez notifié ici de vos commandes',
                  style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 13),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final lu = data['lu'] ?? false;
            final ts = data['createdAt'] as Timestamp?;
            final time = ts != null ? _timeAgo(ts.toDate()) : '';

            return Dismissible(
              key: Key(docs[i].id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) =>
                  NotificationService.supprimer(docs[i].id),
              background: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete_outline,
                    color: Colors.white, size: 22),
              ),
              child: GestureDetector(
                onTap: () {
                  if (!lu) NotificationService.marquerLue(docs[i].id);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: lu ? Colors.white : const Color(0xFFFFF3EE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: lu
                          ? const Color(0xFFEDEDED)
                          : const Color(0xFFFFB89A),
                      width: lu ? 0.5 : 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: lu
                              ? const Color(0xFFF5F5F5)
                              : const Color(0xFFFF6B35).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _getIcon(data['type'] ?? 'commande',
                                data['titre'] ?? ''),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    data['titre'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: lu
                                          ? FontWeight.w600
                                          : FontWeight.w800,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ),
                                if (!lu)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF6B35),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['corps'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8A8A8A),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFCCCCCC),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getIcon(String type, String titre) {
    if (titre.startsWith('🔔')) return '🔔';
    if (titre.startsWith('👨‍🍳')) return '👨‍🍳';
    if (titre.startsWith('✅')) return '✅';
    if (titre.startsWith('❌')) return '❌';
    if (titre.startsWith('💰')) return '💰';
    switch (type) {
      case 'wallet':
        return '💰';
      case 'systeme':
        return '⚙️';
      default:
        return '📦';
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Widget cloche avec badge pour les AppBars
class NotificationBell extends StatelessWidget {
  final UserEntity user;
  final Color color;

  const NotificationBell({
    super.key,
    required this.user,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: NotificationService.streamNonLues(user.uid),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotificationsScreen(user: user),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white38),
                ),
                child: Icon(Icons.notifications_outlined,
                    color: color, size: 20),
              ),
              if (count > 0)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}