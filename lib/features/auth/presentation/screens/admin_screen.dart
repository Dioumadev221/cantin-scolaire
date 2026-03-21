import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AdminScreen
// ─────────────────────────────────────────────────────────────────────────────
class AdminScreen extends ConsumerStatefulWidget {
  final UserEntity user;
  const AdminScreen({super.key, required this.user});
  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int _tab = 0;
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _DashboardTab(user: widget.user, db: _db),
      _PlatsTab(user: widget.user, db: _db),
      _MenusTab(user: widget.user, db: _db),
      _GerantsTab(user: widget.user, db: _db, auth: _auth),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: tabs[_tab],
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    const items = [
      {'icon': '📊', 'label': 'Dashboard'},
      {'icon': '🍽️', 'label': 'Plats'},
      {'icon': '📅', 'label': 'Menus'},
      {'icon': '👥', 'label': 'Gérants'},
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a1a),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = _tab == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        items[i]['icon']!,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i]['label']!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 6 : 0,
                        height: active ? 6 : 0,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B35),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _AdminHeader extends ConsumerWidget {
  final UserEntity user;
  final String title;
  final String subtitle;
  final FirebaseFirestore db;

  const _AdminHeader({
    required this.user,
    required this.title,
    required this.subtitle,
    required this.db,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a1a),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            offset: const Offset(0, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            elevation: 8,
            onSelected: (v) async {
              if (v == 'profil')
                _showProfil(context);
              else if (v == 'mdp')
                _showChangePwd(context);
              else if (v == 'logout') {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false,
                  );
              }
            },
            itemBuilder: (_) => [
              _mi(
                Icons.person_outline,
                'Mon profil',
                'profil',
                const Color(0xFF1a1a1a),
              ),
              _mi(
                Icons.lock_outline,
                'Changer le mot de passe',
                'mdp',
                const Color(0xFF1a1a1a),
              ),
              const PopupMenuDivider(height: 1),
              _mi(
                Icons.logout,
                'Se déconnecter',
                'logout',
                const Color(0xFFEF4444),
                bg: const Color(0xFFFEE2E2),
              ),
            ],
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Center(
                child: Text(
                  '${user.prenom[0]}${user.nom[0]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _mi(
    IconData icon,
    String label,
    String value,
    Color color, {
    Color bg = const Color(0xFFF5F5F5),
  }) {
    return PopupMenuItem(
      value: value,
      height: 48,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfil(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StreamBuilder<DocumentSnapshot>(
        stream: db.collection('users').doc(user.uid).snapshots(),
        builder: (_, snap) {
          final d = snap.data?.data() as Map<String, dynamic>? ?? {};
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _handle(),
                const SizedBox(height: 14),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a1a),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '${(d['prenom'] ?? user.prenom)[0]}${(d['nom'] ?? user.nom)[0]}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${d['prenom'] ?? user.prenom} ${d['nom'] ?? user.nom}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  d['email'] ?? user.email,
                  style: const TextStyle(
                    color: Color(0xFF8A8A8A),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                _row(
                  ctx,
                  'Nom',
                  '${d['prenom'] ?? user.prenom} ${d['nom'] ?? user.nom}',
                  () => _edit(ctx, 'Nom', 'nom', d['nom'] ?? user.nom),
                ),
                _row(
                  ctx,
                  'Téléphone',
                  d['telephone'] ?? 'Ajouter',
                  () => _edit(
                    ctx,
                    'Téléphone',
                    'telephone',
                    d['telephone'] ?? '',
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(
    BuildContext ctx,
    String label,
    String value,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF8A8A8A), size: 16),
        ],
      ),
    ),
  );

  void _edit(BuildContext ctx, String label, String field, String current) {
    final ctrl = TextEditingController(text: current);
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(c).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modifier $label',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a1a1a),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  db.collection('users').doc(user.uid).update({
                    field: ctrl.text.trim(),
                  });
                  Navigator.pop(c);
                },
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePwd(BuildContext context) {
    final c1 = TextEditingController(),
        c2 = TextEditingController(),
        c3 = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setS) {
          bool loading = false;
          String? err;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(c).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _handle(),
                const SizedBox(height: 14),
                const Text(
                  '🔐 Changer le mot de passe',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _pwdF('Mot de passe actuel', c1),
                const SizedBox(height: 10),
                _pwdF('Nouveau mot de passe', c2),
                const SizedBox(height: 10),
                _pwdF('Confirmer', c3),
                if (err != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      err!,
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1a1a1a),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: loading
                        ? null
                        : () async {
                            if (c2.text != c3.text) {
                              setS(() => err = 'Mots de passe différents');
                              return;
                            }
                            if (c2.text.length < 6) {
                              setS(() => err = 'Minimum 6 caractères');
                              return;
                            }
                            setS(() {
                              loading = true;
                              err = null;
                            });
                            try {
                              final u = FirebaseAuth.instance.currentUser!;
                              await u.reauthenticateWithCredential(
                                EmailAuthProvider.credential(
                                  email: u.email!,
                                  password: c1.text,
                                ),
                              );
                              await u.updatePassword(c2.text);
                              if (c.mounted) Navigator.pop(c);
                            } on FirebaseAuthException catch (e) {
                              setS(() {
                                loading = false;
                                err =
                                    (e.code == 'wrong-password' ||
                                        e.code == 'invalid-credential')
                                    ? 'Mot de passe actuel incorrect'
                                    : e.message;
                              });
                            }
                          },
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Mettre à jour'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _pwdF(String label, TextEditingController ctrl) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        obscureText: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ],
  );

  Widget _handle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 0 — DASHBOARD avec graphique recettes
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardTab extends ConsumerWidget {
  final UserEntity user;
  final FirebaseFirestore db;
  const _DashboardTab({required this.user, required this.db});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _AdminHeader(
            user: user,
            title: 'Tableau de bord',
            subtitle: 'Vue d\'ensemble en temps réel',
            db: db,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection('commandes').snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                final today = DateTime.now();

                final todayDocs = docs.where((d) {
                  final ts = (d.data() as Map)['createdAt'] as Timestamp?;
                  if (ts == null) return false;
                  final dt = ts.toDate();
                  return dt.day == today.day &&
                      dt.month == today.month &&
                      dt.year == today.year;
                }).toList();

                final total = todayDocs.length;
                final annulees = todayDocs
                    .where((d) => (d.data() as Map)['statut'] == 'annulee')
                    .length;
                final livrees = todayDocs
                    .where((d) => (d.data() as Map)['statut'] == 'recuperee')
                    .length;
                final enCours = todayDocs
                    .where(
                      (d) => [
                        'recue',
                        'en_cuisine',
                        'prete',
                      ].contains((d.data() as Map)['statut']),
                    )
                    .length;
                final recettes = todayDocs.fold<double>(
                  0,
                  (s, d) =>
                      s + ((d.data() as Map)['montantTotal'] ?? 0).toDouble(),
                );

                // Données pour le graphique : recettes cumulées par heure
                final Map<int, double> recettesParHeure = {};
                for (final doc in todayDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final ts = data['createdAt'] as Timestamp?;
                  if (ts == null) continue;
                  final h = ts.toDate().hour;
                  final montant = (data['montantTotal'] ?? 0).toDouble();
                  recettesParHeure[h] = (recettesParHeure[h] ?? 0) + montant;
                }

                // Top plats
                final platCounts = <String, int>{};
                for (final doc in todayDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nom = data['nomPlat'] ?? 'Inconnu';
                  final qty = (data['quantite'] ?? 1) as int;
                  platCounts[nom] = (platCounts[nom] ?? 0) + qty;
                }
                final topPlats = platCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── KPIs ──────────────────────────────────────────────────
                    Row(
                      children: [
                        _kpi(
                          '$total',
                          'Commandes\naujourd\'hui',
                          '📦',
                          const Color(0xFF1a1a1a),
                        ),
                        const SizedBox(width: 10),
                        _kpi(
                          '${recettes.toStringAsFixed(0)} F',
                          'Recettes\ndu jour',
                          '💰',
                          const Color(0xFFFF6B35),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _kpi(
                          '$enCours',
                          'En cours',
                          '🔥',
                          const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 10),
                        _kpi(
                          '$livrees',
                          'Livrées',
                          '✅',
                          const Color(0xFF22C55E),
                        ),
                        const SizedBox(width: 10),
                        _kpi(
                          '$annulees',
                          'Annulées',
                          '❌',
                          const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── GRAPHIQUE RECETTES ────────────────────────────────────
                    _RevenueChart(
                      recettesParHeure: recettesParHeure,
                      total: recettes,
                    ),
                    const SizedBox(height: 20),

                    // ── TOP PLATS ─────────────────────────────────────────────
                    const Text(
                      'Plats les plus commandés',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (topPlats.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Aucune commande aujourd\'hui',
                            style: TextStyle(
                              color: Color(0xFF8A8A8A),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ...topPlats
                          .take(5)
                          .map(
                            (e) =>
                                _topRow(e.key, e.value, topPlats.first.value),
                          ),

                    const SizedBox(height: 20),
                    StreamBuilder<QuerySnapshot>(
                      stream: db
                          .collection('users')
                          .where('role', isEqualTo: 'etudiant')
                          .snapshots(),
                      builder: (_, snap) {
                        final count = snap.data?.docs.length ?? 0;
                        return _kpiWide(
                          '$count',
                          'Étudiants inscrits',
                          '🎓',
                          const Color(0xFF3B82F6),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String val, String label, String emoji, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  val,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8A8A8A),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _kpiWide(String val, String label, String emoji, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEDED), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  val,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8A8A8A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _topRow(String nom, int count, int maxCount) {
    final pct = maxCount > 0 ? count / maxCount : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEDED), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: const Color(0xFFEDEDED),
                    color: const Color(0xFFFF6B35),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '×$count',
              style: const TextStyle(
                color: Color(0xFFFF6B35),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRAPHIQUE RECETTES DE LA JOURNÉE
// ─────────────────────────────────────────────────────────────────────────────
class _RevenueChart extends StatelessWidget {
  final Map<int, double> recettesParHeure;
  final double total;

  const _RevenueChart({required this.recettesParHeure, required this.total});

  @override
  Widget build(BuildContext context) {
    // Heures d'activité : 7h → 21h
    const startH = 7;
    const endH = 21;
    const nbH = endH - startH + 1;

    // Points : recettes cumulées heure par heure
    double cumul = 0;
    final points = <double>[];
    for (int h = startH; h <= endH; h++) {
      cumul += recettesParHeure[h] ?? 0;
      points.add(cumul);
    }

    final maxVal = points.isEmpty
        ? 1.0
        : points.reduce(max).clamp(1.0, double.infinity);
    final currentHour = DateTime.now().hour;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEDED), width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('📈', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Évolution des recettes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      'Aujourd\'hui · ${total.toStringAsFixed(0)} FCFA au total',
                      style: const TextStyle(
                        color: Color(0xFF8A8A8A),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge heure courante
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B35),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${currentHour}h',
                      style: const TextStyle(
                        color: Color(0xFFFF6B35),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Graphique
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _LineChartPainter(
                points: points,
                maxVal: maxVal,
                currentHour: currentHour,
                startH: startH,
                endH: endH,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),

          // Labels heures
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [7, 9, 11, 13, 15, 17, 19, 21]
                .map(
                  (h) => Text(
                    '${h}h',
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                .toList(),
          ),

          // Légende mini-stats par slot
          if (recettesParHeure.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFEDEDED)),
            const SizedBox(height: 12),
            _buildSlotStats(),
          ],
        ],
      ),
    );
  }

  Widget _buildSlotStats() {
    // Calculer recettes par slot (matin / midi / soir)
    double matin = 0, midi = 0, soir = 0;
    recettesParHeure.forEach((h, v) {
      if (h < 11)
        matin += v;
      else if (h < 15)
        midi += v;
      else
        soir += v;
    });
    return Row(
      children: [
        _slot('🌅', 'Matin', matin),
        _slotDivider(),
        _slot('☀️', 'Midi', midi),
        _slotDivider(),
        _slot('🌙', 'Soir', soir),
      ],
    );
  }

  Widget _slot(String emoji, String label, double val) => Expanded(
    child: Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          '${val.toStringAsFixed(0)} F',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Color(0xFF8A8A8A)),
        ),
      ],
    ),
  );

  Widget _slotDivider() =>
      Container(width: 0.5, height: 40, color: const Color(0xFFEDEDED));
}

// ─── CustomPainter pour le line chart ────────────────────────────────────────
class _LineChartPainter extends CustomPainter {
  final List<double> points;
  final double maxVal;
  final int currentHour;
  final int startH;
  final int endH;

  _LineChartPainter({
    required this.points,
    required this.maxVal,
    required this.currentHour,
    required this.startH,
    required this.endH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final nbPts = points.length;

    // Grille horizontale
    final gridPaint = Paint()
      ..color = const Color(0xFFF5F0EB)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = h - (i / 4) * h;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Labels Y
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 1; i <= 4; i++) {
      final val = (maxVal * i / 4).toStringAsFixed(0);
      final y = h - (i / 4) * h;
      textPainter.text = TextSpan(
        text: '${val}F',
        style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 8),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 8));
    }

    // Construire les offsets
    final offsets = <Offset>[];
    for (int i = 0; i < nbPts; i++) {
      final x = (i / (nbPts - 1)) * w;
      final y = h - (points[i] / maxVal) * (h - 10) - 5;
      offsets.add(Offset(x, y));
    }

    // Aire de remplissage (gradient)
    final fillPath = Path()..moveTo(offsets.first.dx, h);
    for (int i = 0; i < offsets.length - 1; i++) {
      final cp1 = Offset(
        (offsets[i].dx + offsets[i + 1].dx) / 2,
        offsets[i].dy,
      );
      final cp2 = Offset(
        (offsets[i].dx + offsets[i + 1].dx) / 2,
        offsets[i + 1].dy,
      );
      fillPath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        offsets[i + 1].dx,
        offsets[i + 1].dy,
      );
    }
    fillPath.lineTo(offsets.last.dx, h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF6B35).withOpacity(0.3),
          const Color(0xFFFF6B35).withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Courbe principale
    final linePaint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 0; i < offsets.length - 1; i++) {
      final cp1 = Offset(
        (offsets[i].dx + offsets[i + 1].dx) / 2,
        offsets[i].dy,
      );
      final cp2 = Offset(
        (offsets[i].dx + offsets[i + 1].dx) / 2,
        offsets[i + 1].dy,
      );
      linePath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        offsets[i + 1].dx,
        offsets[i + 1].dy,
      );
    }
    canvas.drawPath(linePath, linePaint);

    // Point actuel (heure courante)
    final curIdx = (currentHour - startH).clamp(0, nbPts - 1);
    final curOffset = offsets[curIdx];
    canvas.drawCircle(curOffset, 6, Paint()..color = const Color(0xFFFF6B35));
    canvas.drawCircle(curOffset, 4, Paint()..color = Colors.white);
    canvas.drawCircle(curOffset, 2.5, Paint()..color = const Color(0xFFFF6B35));

    // Tooltip valeur courante
    final curVal = points[curIdx].toStringAsFixed(0);
    final tooltipPaint = Paint()..color = const Color(0xFF1a1a1a);
    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(curOffset.dx - 28, curOffset.dy - 30, 56, 20),
      const Radius.circular(6),
    );
    canvas.drawRRect(tooltipRect, tooltipPaint);
    textPainter.text = TextSpan(
      text: '${curVal}F',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(curOffset.dx - 14, curOffset.dy - 26));
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.points != points || old.currentHour != currentHour;
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — PLATS
// ─────────────────────────────────────────────────────────────────────────────
class _PlatsTab extends ConsumerStatefulWidget {
  final UserEntity user;
  final FirebaseFirestore db;
  const _PlatsTab({required this.user, required this.db});
  @override
  ConsumerState<_PlatsTab> createState() => _PlatsTabState();
}

class _PlatsTabState extends ConsumerState<_PlatsTab> {
  String _cat = 'Tous';
  String _search = '';
  final _cats = ['Tous', 'Petit déjeuner', 'Déjeuner', 'Dîner', 'Boissons'];
  static const _typeBoissons = [
    {'value': 'cafe', 'label': 'Café', 'emoji': '☕'},
    {'value': 'the', 'label': 'Thé', 'emoji': '🍵'},
    {'value': 'jus', 'label': 'Jus', 'emoji': '🍊'},
    {'value': 'eau', 'label': 'Eau', 'emoji': '💧'},
    {'value': 'lait', 'label': 'Lait', 'emoji': '🥛'},
    {'value': 'autre', 'label': 'Autre', 'emoji': '🥤'},
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _AdminHeader(
        user: widget.user,
        title: 'Gestion des plats',
        subtitle: 'Ajoutez et gérez le menu',
        db: widget.db,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEDEDED), width: 0.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xFFCCCCCC), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 12,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          itemCount: _cats.length,
          itemBuilder: (_, i) {
            final active = _cats[i] == _cat;
            return GestureDetector(
              onTap: () => setState(() => _cat = _cats[i]),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF1a1a1a) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? const Color(0xFF1a1a1a)
                        : const Color(0xFFEDEDED),
                  ),
                ),
                child: Text(
                  _cats[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: active ? Colors.white : const Color(0xFF8A8A8A),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: widget.db.collection('plats').snapshots(),
          builder: (context, snap) {
            var docs = snap.data?.docs ?? [];

            // Mapping label affiché → valeur stockée dans Firestore
            const catMap = {
              'Petit déjeuner': 'petit_dejeuner',
              'Déjeuner': 'dejeuner',
              'Dîner': 'diner',
              'Boissons': 'boissons',
            };

            if (_cat != 'Tous') {
              final stored = catMap[_cat] ?? _cat.toLowerCase();
              docs = docs
                  .where(
                    (d) =>
                        ((d.data() as Map)['categorie'] ?? '')
                            .toString()
                            .toLowerCase() ==
                        stored,
                  )
                  .toList();
            }
            if (_search.isNotEmpty) {
              docs = docs
                  .where(
                    (d) => ((d.data() as Map)['nom'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(_search),
                  )
                  .toList();
            }
            if (docs.isEmpty)
              return const Center(
                child: Text(
                  'Aucun plat',
                  style: TextStyle(color: Color(0xFF8A8A8A)),
                ),
              );

            // Tri par catégorie quand "Tous" est sélectionné
            if (_cat == 'Tous') {
              const order = ['petit_dejeuner', 'dejeuner', 'diner', 'boissons'];
              const labels = {
                'petit_dejeuner': '🌅 Petit déjeuner',
                'dejeuner': '☀️ Déjeuner',
                'diner': '🌙 Dîner',
                'boissons': '🥤 Boissons',
              };
              final grouped = <String, List<QueryDocumentSnapshot>>{};
              for (final doc in docs) {
                final cat = ((doc.data() as Map)['categorie'] ?? '')
                    .toString()
                    .toLowerCase();
                grouped.putIfAbsent(cat, () => []).add(doc);
              }
              final items = <Widget>[];
              for (final cat in order) {
                final catDocs = grouped[cat];
                if (catDocs == null || catDocs.isEmpty) continue;
                items.add(
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          labels[cat] ?? cat,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${catDocs.length}',
                            style: const TextStyle(
                              color: Color(0xFFFF6B35),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                for (final doc in catDocs) {
                  items.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _platCard(
                        doc.id,
                        doc.data() as Map<String, dynamic>,
                      ),
                    ),
                  );
                }
              }
              // Catégories inconnues
              for (final entry in grouped.entries) {
                if (order.contains(entry.key)) continue;
                for (final doc in entry.value) {
                  items.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _platCard(
                        doc.id,
                        doc.data() as Map<String, dynamic>,
                      ),
                    ),
                  );
                }
              }
              return ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: items,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: docs.length,
              itemBuilder: (_, i) =>
                  _platCard(docs[i].id, docs[i].data() as Map<String, dynamic>),
            );
          },
        ),
      ),
      _addBtn(),
    ],
  );

  Widget _platCard(String id, Map<String, dynamic> data) {
    final dispo = data['disponible'] == true;
    final isB =
        (data['categorie'] ?? '').toString().toLowerCase() == 'boissons';
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
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (data['imageUrl'] as String?)?.isNotEmpty == true
                            ? Image.network(
                                data['imageUrl'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    isB
                                        ? _emojiB(data['typeBoisson'] ?? '')
                                        : _emojiC(data['categorie'] ?? ''),
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  isB
                                      ? _emojiB(data['typeBoisson'] ?? '')
                                      : _emojiC(data['categorie'] ?? ''),
                                  style: const TextStyle(fontSize: 26),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: dispo
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['nom'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        isB
                            ? 'Boisson · ${_labelB(data['typeBoisson'] ?? '')}'
                            : '${data['categorie'] ?? ''} · ${data['tempsPreparation'] ?? 0}min',
                        style: const TextStyle(
                          color: Color(0xFF8A8A8A),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${data['prix'] ?? 0} FCFA',
                        style: const TextStyle(
                          color: Color(0xFFFF6B35),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFEDEDED), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                _act(
                  '✏️ Modifier',
                  const Color(0xFF1a1a1a),
                  () => _form(id: id, data: data, isB: isB),
                ),
                Container(
                  width: 0.5,
                  height: 36,
                  color: const Color(0xFFEDEDED),
                ),
                _act(
                  dispo ? '● Dispo' : '✕ Indispo',
                  dispo ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  () => widget.db.collection('plats').doc(id).update({
                    'disponible': !dispo,
                  }),
                ),
                Container(
                  width: 0.5,
                  height: 36,
                  color: const Color(0xFFEDEDED),
                ),
                _act('🗑️', const Color(0xFFEF4444), () => _del(id)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _act(String label, Color color, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    ),
  );

  Widget _addBtn() => GestureDetector(
    onTap: _typeSelect,
    child: Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'Ajouter un plat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

  void _typeSelect() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Que souhaitez-vous ajouter ?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _form(isB: false);
                    },
                    child: _typeCard(
                      '🍽️',
                      'Plat',
                      'Petit déj, déjeuner, dîner...',
                      const Color(0xFFFFF3EE),
                      const Color(0xFFFFB89A),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _form(isB: true);
                    },
                    child: _typeCard(
                      '🥤',
                      'Boisson',
                      'Café, thé, jus, eau, lait',
                      const Color(0xFFEFF6FF),
                      const Color(0xFF93C5FD),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeCard(
    String emoji,
    String label,
    String sub,
    Color bg,
    Color border,
  ) => Container(
    padding: const EdgeInsets.symmetric(vertical: 22),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: border, width: 1.5),
    ),
    child: Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: Color(0xFF8A8A8A)),
        ),
      ],
    ),
  );

  void _form({String? id, Map<String, dynamic>? data, required bool isB}) {
    final nom = TextEditingController(text: data?['nom'] ?? '');
    final desc = TextEditingController(text: data?['description'] ?? '');
    final prix = TextEditingController(text: data?['prix']?.toString() ?? '');
    final temps = TextEditingController(
      text: data?['tempsPreparation']?.toString() ?? '',
    );
    String tb = data?['typeBoisson'] ?? 'cafe';
    String cat = data?['categorie'] ?? 'petit_dejeuner';
    String? imageUrl = data?['imageUrl'];
    File? imageFile;
    bool uploading = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setS) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(c).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                id == null
                    ? (isB ? 'Nouvelle boisson' : 'Nouveau plat')
                    : 'Modifier',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              if (isB) ...[
                const Text(
                  'Type',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _typeBoissons.map((t) {
                    final sel = tb == t['value'];
                    return GestureDetector(
                      onTap: () => setS(() => tb = t['value']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFFEFF6FF) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFEDEDED),
                            width: sel ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t['emoji']!,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              t['label']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: sel
                                    ? const Color(0xFF1D4ED8)
                                    : const Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              // ── Sélecteur image ──────────────────────────
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                  );
                  if (picked != null) {
                    setS(() => imageFile = File(picked.path));
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0EB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFB89A),
                      width: 1.5,
                    ),
                  ),
                  child: imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(imageFile!, fit: BoxFit.cover),
                        )
                      : imageUrl != null && imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(imageUrl!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: Color(0xFFFF6B35),
                              size: 30,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Ajouter une photo',
                              style: TextStyle(
                                color: Color(0xFFFF6B35),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              _f('Nom', nom), const SizedBox(height: 10),
              _f('Description', desc),
              const SizedBox(height: 10),
              _f('Prix (FCFA)', prix, num: true),
              if (!isB) ...[
                const SizedBox(height: 10),
                _f('Temps (min)', temps, num: true),
                const SizedBox(height: 10),
                const Text(
                  'Catégorie',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: cat,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F0EB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'petit_dejeuner',
                      child: Text('🌅 Petit déjeuner'),
                    ),
                    DropdownMenuItem(
                      value: 'dejeuner',
                      child: Text('☀️ Déjeuner'),
                    ),
                    DropdownMenuItem(value: 'diner', child: Text('🌙 Dîner')),
                  ],
                  onChanged: (v) => setS(() => cat = v!),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a1a1a),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: uploading
                      ? null
                      : () async {
                          setS(() => uploading = true);
                          try {
                            String platId =
                                id ?? widget.db.collection('plats').doc().id;
                            String? finalImageUrl = imageUrl;

                            if (imageFile != null) {
                              final ref = FirebaseStorage.instance.ref().child(
                                'plats/$platId.jpg',
                              );
                              await ref.putFile(imageFile!);
                              finalImageUrl = await ref.getDownloadURL();
                            }

                            final d = isB
                                ? <String, dynamic>{
                                    'nom': nom.text.trim(),
                                    'description': desc.text.trim(),
                                    'prix': double.tryParse(prix.text) ?? 0,
                                    'categorie': 'boissons',
                                    'typeBoisson': tb,
                                    'tempsPreparation': 0,
                                    'disponible': true,
                                    if (finalImageUrl != null)
                                      'imageUrl': finalImageUrl,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  }
                                : <String, dynamic>{
                                    'nom': nom.text.trim(),
                                    'description': desc.text.trim(),
                                    'prix': double.tryParse(prix.text) ?? 0,
                                    'categorie': cat,
                                    'repas':
                                        cat, // petit_dejeuner, dejeuner ou diner
                                    'tempsPreparation':
                                        int.tryParse(temps.text) ?? 0,
                                    'disponible': true,
                                    if (finalImageUrl != null)
                                      'imageUrl': finalImageUrl,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  };

                            if (id == null) {
                              d['createdAt'] = FieldValue.serverTimestamp();
                              await widget.db
                                  .collection('plats')
                                  .doc(platId)
                                  .set(d);
                            } else {
                              await widget.db
                                  .collection('plats')
                                  .doc(id)
                                  .update(d);
                            }
                            if (c.mounted) Navigator.pop(c);
                          } catch (e) {
                            setS(() => uploading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur : $e'),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        },
                  child: uploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          id == null ? 'Ajouter' : 'Enregistrer',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _del(String id) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Supprimer ce plat ?'),
      content: const Text('Action irréversible.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            widget.db.collection('plats').doc(id).delete();
            Navigator.pop(context);
          },
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );

  Widget _f(String label, TextEditingController ctrl, {bool num = false}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: ctrl,
            keyboardType: num ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F0EB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ],
      );

  String _emojiC(String c) {
    switch (c.toLowerCase()) {
      case 'petit_dejeuner':
        return '🌅';
      case 'dejeuner':
        return '☀️';
      case 'diner':
        return '🌙';
      case 'boissons':
        return '🥤';
      default:
        return '🍽️';
    }
  }

  String _emojiB(String t) {
    switch (t) {
      case 'cafe':
        return '☕';
      case 'the':
        return '🍵';
      case 'jus':
        return '🍊';
      case 'eau':
        return '💧';
      case 'lait':
        return '🥛';
      default:
        return '🥤';
    }
  }

  String _labelB(String t) {
    switch (t) {
      case 'cafe':
        return 'Café';
      case 'the':
        return 'Thé';
      case 'jus':
        return 'Jus';
      case 'eau':
        return 'Eau';
      case 'lait':
        return 'Lait';
      default:
        return 'Boisson';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — MENUS (gestion complète des menus de la semaine)
// ─────────────────────────────────────────────────────────────────────────────
class _MenusTab extends ConsumerStatefulWidget {
  final UserEntity user;
  final FirebaseFirestore db;
  const _MenusTab({required this.user, required this.db});
  @override
  ConsumerState<_MenusTab> createState() => _MenusTabState();
}

class _MenusTabState extends ConsumerState<_MenusTab> {
  int _selectedDay = DateTime.now().weekday - 1;
  int _weekOffset = 0;
  final _days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven'];

  DateTime get _monday {
    final now = DateTime.now();
    return now
        .subtract(Duration(days: now.weekday - 1))
        .add(Duration(days: _weekOffset * 7));
  }

  DateTime get _selectedDate => _monday.add(Duration(days: _selectedDay));

  String get _dateStr {
    final d = _selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  bool get _isPast {
    final today = DateTime.now();
    final sel = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return sel.isBefore(DateTime(today.year, today.month, today.day));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminHeader(
          user: widget.user,
          title: 'Gestion des menus',
          subtitle: 'Planifiez les menus de la semaine',
          db: widget.db,
        ),
        _buildWeekNav(),
        _buildDaysRow(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: widget.db
                .collection('menus')
                .where('date', isEqualTo: _dateStr)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                );
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return _buildEmpty();
              final doc = docs.first;
              return _buildContent(
                doc.id,
                doc.data() as Map<String, dynamic>,
                _isPast,
              );
            },
          ),
        ),
      ],
    );
  }

  // ── NAVIGATION SEMAINE ────────────────────────────────────────────────────

  Widget _buildWeekNav() {
    const months = [
      '',
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    final fri = _monday.add(const Duration(days: 4));
    final label =
        '${_monday.day} ${months[_monday.month]} – ${fri.day} ${months[fri.month]} ${fri.year}';
    String sub = _weekOffset == 0
        ? 'Cette semaine'
        : _weekOffset == -1
        ? 'Semaine passée'
        : _weekOffset == 1
        ? 'Semaine prochaine'
        : _weekOffset < 0
        ? 'Il y a ${_weekOffset.abs()} sem.'
        : 'Dans $_weekOffset sem.';

    return Container(
      color: const Color(0xFFFF6B35),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _weekBtn(
            '‹',
            () => setState(() {
              _weekOffset--;
              _selectedDay = 0;
            }),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _weekOffset = 0;
              _selectedDay = DateTime.now().weekday - 1;
            }),
            child: Column(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      sub,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    if (_weekOffset != 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '↩ Aujourd\'hui',
                          style: TextStyle(color: Colors.white, fontSize: 9),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _weekBtn(
            '›',
            () => setState(() {
              _weekOffset++;
              _selectedDay = 0;
            }),
          ),
        ],
      ),
    );
  }

  Widget _weekBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );

  // ── JOURS ─────────────────────────────────────────────────────────────────

  Widget _buildDaysRow() {
    final now = DateTime.now();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(5, (i) {
          final day = _monday.add(Duration(days: i));
          final active = i == _selectedDay;
          final isToday =
              day.day == now.day &&
              day.month == now.month &&
              day.year == now.year;
          final isPast = day.isBefore(DateTime(now.year, now.month, now.day));
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDay = i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFFF6B35) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? const Color(0xFFFF6B35)
                        : isToday
                        ? const Color(0xFFFF6B35)
                        : const Color(0xFFEDEDED),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _days[i],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? Colors.white70
                            : isPast
                            ? const Color(0xFFCCCCCC)
                            : const Color(0xFF8A8A8A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? Colors.white
                            : isPast
                            ? const Color(0xFFCCCCCC)
                            : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── EMPTY ─────────────────────────────────────────────────────────────────

  Widget _buildEmpty() => Column(
    children: [
      const Spacer(),
      Text(_isPast ? '🔒' : '📅', style: const TextStyle(fontSize: 56)),
      const SizedBox(height: 12),
      Text(
        _isPast ? 'Jour passé' : 'Aucun menu pour ce jour',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        _isPast
            ? 'Impossible de créer un menu passé'
            : 'Créez le menu de cette journée',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 13),
      ),
      const Spacer(),
      if (!_isPast)
        GestureDetector(
          onTap: _createMenu,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Créer le menu du jour',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      if (_isPast) const SizedBox(height: 16),
    ],
  );

  // ── CONTENU MENU ──────────────────────────────────────────────────────────

  Widget _buildContent(String menuId, Map<String, dynamic> data, bool isPast) {
    final actif = data['actif'] ?? true;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Toggle actif — désactivé si jour passé
          GestureDetector(
            onTap: isPast
                ? null
                : () => widget.db.collection('menus').doc(menuId).update({
                    'actif': !actif,
                  }),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: actif
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: actif
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEDEDED),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: actif
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF8A8A8A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    actif
                        ? 'Menu actif — visible par les étudiants'
                        : 'Menu inactif — invisible',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: actif
                          ? const Color(0xFF065F46)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    actif ? Icons.visibility : Icons.visibility_off,
                    size: 14,
                    color: actif
                        ? const Color(0xFF065F46)
                        : const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
          ),
          if (isPast) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Text(
                    'Jour passé — modification impossible',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildSlot(
            menuId,
            '🌅',
            'Petit déjeuner',
            'petitDej',
            (data['petitDej'] as List?)?.cast<String>() ?? [],
            isPast,
            'petit_dejeuner',
          ),
          const SizedBox(height: 12),
          _buildSlot(
            menuId,
            '☀️',
            'Déjeuner',
            'dejeuner',
            (data['dejeuner'] as List?)?.cast<String>() ?? [],
            isPast,
            'dejeuner',
          ),
          const SizedBox(height: 12),
          _buildSlot(
            menuId,
            '🌙',
            'Dîner',
            'diner',
            (data['diner'] as List?)?.cast<String>() ?? [],
            isPast,
            'diner',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFFECACA)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: isPast ? null : () => _deleteMenu(menuId),
              child: const Text(
                'Supprimer le menu du jour',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSlot(
    String menuId,
    String emoji,
    String titre,
    String field,
    List<String> platsIds,
    bool isPast,
    String categorie,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED), width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${platsIds.length} plat(s)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
          ),
          ...platsIds.map((pid) => _platInSlot(menuId, field, pid, isPast)),
          if (!isPast)
            GestureDetector(
              onTap: () => _showAddPlat(menuId, field, platsIds, categorie),
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFFB89A),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    '+ Ajouter un plat',
                    style: TextStyle(
                      color: Color(0xFFFF6B35),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _platInSlot(String menuId, String field, String platId, bool isPast) {
    return FutureBuilder<DocumentSnapshot>(
      future: widget.db.collection('plats').doc(platId).get(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();
        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final disponible = data['disponible'] == true;
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: disponible
                ? const Color(0xFFF5F0EB)
                : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              (data['imageUrl'] as String?)?.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data['imageUrl'],
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          _emojiCat(data['categorie'] ?? ''),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    )
                  : Text(
                      _emojiCat(data['categorie'] ?? ''),
                      style: const TextStyle(fontSize: 20),
                    ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['nom'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!disponible)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Indispo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${data['prix'] ?? 0} FCFA',
                      style: TextStyle(
                        fontSize: 11,
                        color: disponible
                            ? const Color(0xFFFF6B35)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPast)
                GestureDetector(
                  onTap: () =>
                      widget.db.collection('menus').doc(menuId).update({
                        field: FieldValue.arrayRemove([platId]),
                      }),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddPlat(
    String menuId,
    String field,
    List<String> existing,
    String categorie,
  ) {
    const labels = {
      'petit_dejeuner': '🌅 Petit déjeuner',
      'dejeuner': '☀️ Déjeuner',
      'diner': '🌙 Dîner',
      'boissons': '🥤 Boissons',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => StreamBuilder<QuerySnapshot>(
          // Filtre Firestore : uniquement les plats de la catégorie du slot
          stream: widget.db
              .collection('plats')
              .where('disponible', isEqualTo: true)
              .where('categorie', isEqualTo: categorie)
              .snapshots(),
          builder: (_, snap) {
            final allDocs =
                snap.data?.docs
                    .where((d) => !existing.contains(d.id))
                    .toList() ??
                [];

            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ajouter au menu',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              labels[categorie] ?? categorie,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB0B0B0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${allDocs.length} plat(s)',
                          style: const TextStyle(
                            color: Color(0xFFFF6B35),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                if (allDocs.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🍽️', style: TextStyle(fontSize: 40)),
                            SizedBox(height: 12),
                            Text(
                              'Aucun plat disponible\ndans cette catégorie',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF8A8A8A),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      itemCount: allDocs.length,
                      itemBuilder: (_, i) {
                        final doc = allDocs[i];
                        final data = doc.data() as Map<String, dynamic>;
                        return GestureDetector(
                          onTap: () async {
                            await widget.db
                                .collection('menus')
                                .doc(menuId)
                                .update({
                                  field: FieldValue.arrayUnion([doc.id]),
                                });
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F7F4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFEEEEEE),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                (data['imageUrl'] as String?)?.isNotEmpty ==
                                        true
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          data['imageUrl'],
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Text(
                                            _emojiCat(data['categorie'] ?? ''),
                                            style: const TextStyle(
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        _emojiCat(data['categorie'] ?? ''),
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['nom'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${data['prix']} FCFA',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFFF6B35),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.add_circle_outline,
                                  color: Color(0xFFFF6B35),
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _createMenu() {
    widget.db.collection('menus').add({
      'date': _dateStr,
      'actif': true,
      'petitDej': [],
      'dejeuner': [],
      'diner': [],
      'creePar': widget.user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _deleteMenu(String id) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Supprimer le menu ?'),
      content: const Text('Le menu de ce jour sera supprimé.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            widget.db.collection('menus').doc(id).delete();
            Navigator.pop(context);
          },
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );

  String _emojiCat(String c) {
    switch (c.toLowerCase()) {
      case 'petit_dejeuner':
        return '🌅';
      case 'dejeuner':
        return '☀️';
      case 'diner':
        return '🌙';
      case 'boissons':
        return '🥤';
      default:
        return '🍽️';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — GÉRANTS
// ─────────────────────────────────────────────────────────────────────────────
class _GerantsTab extends ConsumerWidget {
  final UserEntity user;
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  const _GerantsTab({required this.user, required this.db, required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _AdminHeader(
          user: user,
          title: 'Gérants',
          subtitle: 'Gérez les comptes gérants',
          db: db,
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: db
                .collection('users')
                .where('role', isEqualTo: 'gerant_cantine')
                .snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty)
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('👤', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text(
                        'Aucun gérant enregistré',
                        style: TextStyle(
                          color: Color(0xFF8A8A8A),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: docs.length,
                itemBuilder: (_, i) => _card(
                  context,
                  docs[i].id,
                  docs[i].data() as Map<String, dynamic>,
                ),
              );
            },
          ),
        ),
        _addBtn(context, ref),
      ],
    );
  }

  Widget _card(BuildContext context, String uid, Map<String, dynamic> d) {
    final nom = d['nom'] ?? '';
    final prenom = d['prenom'] ?? '';
    final email = d['email'] ?? '';
    final cantine = d['nomCantine'] ?? '—';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$prenom $nom',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.store_outlined,
                      size: 10,
                      color: Color(0xFFFF6B35),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        cantine,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _del(context, uid, '$prenom $nom'),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline,
                size: 16,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _del(BuildContext ctx, String uid, String nom) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      title: const Text('Supprimer ce gérant ?'),
      content: Text('$nom sera supprimé.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            db.collection('users').doc(uid).delete();
            Navigator.pop(ctx);
          },
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );

  Widget _addBtn(BuildContext context, WidgetRef ref) => GestureDetector(
    onTap: () => _create(context, ref),
    child: Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'Créer un gérant',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

  void _create(BuildContext context, WidgetRef ref) {
    final nom = TextEditingController(),
        prenom = TextEditingController(),
        email = TextEditingController(),
        pwd = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Créer un gérant',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tf(nom, 'Nom'),
              const SizedBox(height: 10),
              _tf(prenom, 'Prénom'),
              const SizedBox(height: 10),
              _tf(email, 'Email', type: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _tf(pwd, 'Mot de passe', obscure: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a1a1a),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref
                  .read(authProvider.notifier)
                  .inscription(
                    nom.text.trim(),
                    prenom.text.trim(),
                    email.text.trim(),
                    pwd.text.trim(),
                    'gerant_cantine',
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  Widget _tf(
    TextEditingController ctrl,
    String label, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
  }) => TextField(
    controller: ctrl,
    keyboardType: type,
    obscureText: obscure,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF5F0EB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
