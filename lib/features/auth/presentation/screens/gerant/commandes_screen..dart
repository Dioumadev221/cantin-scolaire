import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../auth/domain/entities/user_entity.dart';

class CommandesScreen extends StatefulWidget {
  final UserEntity user;
  const CommandesScreen({super.key, required this.user});

  @override
  State<CommandesScreen> createState() => _CommandesScreenState();
}

class _CommandesScreenState extends State<CommandesScreen> {
  String _filter = 'Toutes';
  final _firestore = FirebaseFirestore.instance;

  final List<String> _filters = [
    'Toutes',
    'Reçues',
    'En cuisine',
    'Prêtes',
    'Récupérées',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildFilters(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFFFF6B35),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'En direct',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Commandes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('commandes')
                    .where('statut', whereIn: ['recue', 'en_cuisine'])
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('commandes').snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              final today = DateTime.now();
              final todayDocs = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final ts = data['createdAt'] as Timestamp?;
                if (ts == null) return false;
                final date = ts.toDate();
                return date.day == today.day &&
                    date.month == today.month &&
                    date.year == today.year;
              }).toList();
              final recettes = todayDocs.fold<double>(0, (sum, d) {
                final data = d.data() as Map<String, dynamic>;
                return sum + (data['montantTotal'] ?? 0).toDouble();
              });
              return Row(
                children: [
                  _buildKpi(
                    '${todayDocs.length}',
                    "Aujourd'hui",
                    '▲ +3 vs hier',
                  ),
                  const SizedBox(width: 8),
                  _buildKpi(
                    '${recettes.toStringAsFixed(0)} F',
                    'Recettes',
                    '▲ +12%',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpi(String val, String label, String trend) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              val,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            Text(
              trend,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: _filters.map((f) {
            final isActive = f == _filter;
            return GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFEDEDED),
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.white : const Color(0xFF8A8A8A),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getCommandesStream(),
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
                const Text('📦', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  _filter == 'Toutes'
                      ? 'Aucune commande'
                      : 'Aucune commande $_filter',
                  style: const TextStyle(
                    color: Color(0xFF8A8A8A),
                    fontSize: 14,
                  ),
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
            return _buildCommandeCard(docs[i].id, data);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getCommandesStream() {
    final ref = _firestore.collection('commandes');
    switch (_filter) {
      case 'Reçues':
        return ref.where('statut', isEqualTo: 'recue').snapshots();
      case 'En cuisine':
        return ref.where('statut', isEqualTo: 'en_cuisine').snapshots();
      case 'Prêtes':
        return ref.where('statut', isEqualTo: 'prete').snapshots();
      case 'Récupérées':
        return ref.where('statut', isEqualTo: 'recuperee').snapshots();
      default:
        return ref.orderBy('createdAt', descending: true).snapshots();
    }
  }

  Widget _buildCommandeCard(String id, Map<String, dynamic> data) {
    final statut = data['statut'] ?? 'recue';
    final ts = data['createdAt'] as Timestamp?;
    final timeAgo = ts != null ? _timeAgo(ts.toDate()) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED), width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['numero'] ?? 'CMD-000',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$timeAgo',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                  ],
                ),
                _buildStatusPill(statut),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🍛', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['etudiantNom'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Commande · ${data['modePaiement'] ?? 'wallet'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${data['montantTotal'] ?? 0} FCFA',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),
          ),
          if (statut != 'recuperee')
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFEDEDED), width: 0.5),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (statut != 'prete') ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _updateStatut(id, statut),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getNextAction(statut),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (statut == 'prete')
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _updateStatut(id, statut),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '✓ Récupérée',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (statut != 'prete')
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _updateStatut(id, 'annulee'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F0EB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Annuler',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF8A8A8A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String statut) {
    Color bg, text;
    String label;
    switch (statut) {
      case 'recue':
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF1E40AF);
        label = 'Reçue';
        break;
      case 'en_cuisine':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFF92400E);
        label = 'En cuisine';
        break;
      case 'prete':
        bg = const Color(0xFFD1FAE5);
        text = const Color(0xFF065F46);
        label = 'Prête ✓';
        break;
      case 'recuperee':
        bg = const Color(0xFFF3F4F6);
        text = const Color(0xFF6B7280);
        label = 'Récupérée';
        break;
      default:
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFF991B1B);
        label = 'Annulée';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  String _getNextAction(String statut) {
    switch (statut) {
      case 'recue':
        return '→ Passer en cuisine';
      case 'en_cuisine':
        return '✓ Marquer prête';
      default:
        return '→ Suivant';
    }
  }

  void _updateStatut(String id, String current) {
    String next;
    switch (current) {
      case 'recue':
        next = 'en_cuisine';
        break;
      case 'en_cuisine':
        next = 'prete';
        break;
      case 'prete':
        next = 'recuperee';
        break;
      default:
        next = 'annulee';
    }
    _firestore.collection('commandes').doc(id).update({
      'statut': next,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }
}
