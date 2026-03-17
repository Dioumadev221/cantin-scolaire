import 'dart:ui';
import 'package:cantine_scolaire/features/auth/presentation/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/entities/user_entity.dart';
import 'plat_detail_screen.dart';
import 'profil_etudiant_screen.dart';
import 'notifications_etudiant_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final UserEntity user;
  const HomeScreen({super.key, required this.user});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedCat = 'Tous';
  int _bottomIndex = 0;

  final List<Map<String, String>> _categories = [
    {'label': 'Tous', 'emoji': '🍽️'},
    {'label': 'Express', 'emoji': '🍳'},
    {'label': 'Plat du jour', 'emoji': '🍛'},
    {'label': 'Entrées', 'emoji': '🥗'},
    {'label': 'Boissons', 'emoji': '🥤'},
  ];

  @override
  void initState() {
    super.initState();
    NotificationService().initialize(widget.user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: _bottomIndex == 0 ? _buildHomeTab() : _buildCommandesTab(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── BOTTOM NAV ─────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDEDED), width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _navItem(0, Icons.home_rounded, 'Accueil'),
              _navItem(1, Icons.receipt_long_outlined, 'Commandes'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _bottomIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _bottomIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active
                    ? const Color(0xFFFF6B35)
                    : const Color(0xFF8A8A8A),
                size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: active
                        ? const Color(0xFFFF6B35)
                        : const Color(0xFF8A8A8A))),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 6 : 0,
              height: active ? 6 : 0,
              decoration: const BoxDecoration(
                  color: Color(0xFFFF6B35), shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 0 — ACCUEIL
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        _buildSliverHero(),
        SliverToBoxAdapter(child: _buildSearchBar()),
        SliverToBoxAdapter(child: _buildCategoryRow()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Disponible maintenant',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A))),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('plats')
                      .where('disponible', isEqualTo: true)
                      .snapshots(),
                  builder: (c, s) => Text(
                    '${s.data?.docs.length ?? 0} plats',
                    style: const TextStyle(
                        color: Color(0xFFFF6B35),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildPlatsGrid(),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  // ── HERO GRADIENT ───────────────────────────────────────────────────────────

  Widget _buildSliverHero() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A2E),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0A2E),
                    Color(0xFF1E1B4B),
                    Color(0xFF312E81),
                  ],
                ),
              ),
            ),
            // Orange blob
            Positioned(
              right: -40,
              top: -20,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF6B35).withOpacity(0.5),
                      const Color(0xFFFF6B35).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Fast and',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 26,
                        fontWeight: FontWeight.w300),
                  ),
                  const Text(
                    'Délicieux Food',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Cloche notifications
        StreamBuilder<int>(
          stream: NotificationService.compteurNonLus(widget.user.uid),
          builder: (context, snap) {
            final unread = snap.data ?? 0;
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      NotificationsEtudiantScreen(user: widget.user),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 24),
                    if (unread > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6B35),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        // Avatar → Profil
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfilEtudiantScreen(user: widget.user),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white38),
            ),
            child: Center(
              child: Text(
                '${widget.user.prenom[0]}${widget.user.nom[0]}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── SEARCH BAR ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFFCCCCCC), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un plat ou une boisson...',
                  hintStyle:
                      TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ── CATÉGORIES ─────────────────────────────────────────────────────────────

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final active = cat['label'] == _selectedCat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCat = cat['label']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Text(cat['emoji']!,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    cat['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? Colors.white
                          : const Color(0xFF8A8A8A),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── GRID PLATS ─────────────────────────────────────────────────────────────

  Widget _buildPlatsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('plats')
          .where('disponible', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
              ),
            ),
          );
        }

        var docs = snapshot.data?.docs ?? [];

        if (_selectedCat != 'Tous') {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['categorie'] ?? '').toString().toLowerCase() ==
                _selectedCat.toLowerCase();
          }).toList();
        }

        if (_searchQuery.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['nom'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
                (data['description'] ?? '').toString().toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Aucun résultat pour "$_searchQuery"'
                          : 'Aucun plat disponible dans "$_selectedCat"',
                      style: const TextStyle(
                          color: Color(0xFF8A8A8A), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildPlatCard(doc.id, data);
              },
              childCount: docs.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlatCard(String id, Map<String, dynamic> data) {
    final isBoisson =
        (data['categorie'] ?? '').toString().toLowerCase() == 'boissons';
    final typeBoisson = data['typeBoisson'] ?? '';
    final emoji = isBoisson ? _emojiBoisson(typeBoisson) : _emojiCat(data['categorie'] ?? '');
    final gradient = isBoisson
        ? [const Color(0xFF1E3A5F), const Color(0xFF2563EB)]
        : [const Color(0xFF1A1A2E), const Color(0xFF3D1A00)];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlatDetailScreen(
            platId: id,
            data: data,
            user: widget.user,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Food emoji large
            Positioned(
              right: -8,
              top: 12,
              child: Text(emoji,
                  style: const TextStyle(fontSize: 80)),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Catégorie badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isBoisson
                          ? _labelBoisson(typeBoisson)
                          : (data['categorie'] ?? ''),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 9),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    data['nom'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (!isBoisson)
                    Text(
                      '${data['tempsPreparation'] ?? 0} min',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 10),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${data['prix'] ?? 0} F',
                          style: const TextStyle(
                            color: Color(0xFFFF9A6C),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 1 — MES COMMANDES
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildCommandesTab() {
    return Column(
      children: [
        Container(
          color: const Color(0xFF0A0A2E),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mes commandes',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    Text('Suivez vos commandes en temps réel',
                        style:
                            TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          NotificationsEtudiantScreen(user: widget.user)),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
        Expanded(child: _buildMesCommandesList()),
      ],
    );
  }

  Widget _buildMesCommandesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('commandes')
          .where('etudiantId', isEqualTo: widget.user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final allDocs = snapshot.data?.docs ?? [];
        final docs = List.from(allDocs);
        docs.sort((a, b) {
          final ta = ((a.data() as Map)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final tb = ((b.data() as Map)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          return tb.compareTo(ta);
        });

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📭', style: TextStyle(fontSize: 56)),
                SizedBox(height: 12),
                Text('Aucune commande pour l\'instant',
                    style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _buildCommandeCard(data);
          },
        );
      },
    );
  }

  Widget _buildCommandeCard(Map<String, dynamic> data) {
    final statut = data['statut'] ?? '';
    final statutInfo = _statutInfo(statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Commande #${data['numero'] ?? '—'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statutInfo['bg'] as Color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statutInfo['label'] as String,
                    style: TextStyle(
                        color: statutInfo['fg'] as Color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${data['montantTotal'] ?? 0} FCFA',
              style: const TextStyle(
                  color: Color(0xFFFF6B35),
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 4),
          // Progress steps
          _buildProgressSteps(statut),
        ],
      ),
    );
  }

  Widget _buildProgressSteps(String statut) {
    const steps = ['recue', 'en_cuisine', 'prete', 'recuperee'];
    const labels = ['Reçue', 'En cuisine', 'Prête', 'Livrée'];
    final currentIdx = steps.indexOf(statut);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: List.generate(steps.length, (i) {
          final done = i <= currentIdx;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: done
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEDEDED),
                    shape: BoxShape.circle,
                  ),
                  child: done
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 12)
                      : null,
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: done && i < currentIdx
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEDEDED),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── UTILS ───────────────────────────────────────────────────────────────────

  Map<String, dynamic> _statutInfo(String statut) {
    switch (statut) {
      case 'recue':
        return {
          'label': 'Reçue',
          'bg': const Color(0xFFFEF3C7),
          'fg': const Color(0xFFD97706)
        };
      case 'en_cuisine':
        return {
          'label': 'En cuisine',
          'bg': const Color(0xFFEFF6FF),
          'fg': const Color(0xFF2563EB)
        };
      case 'prete':
        return {
          'label': 'Prête !',
          'bg': const Color(0xFFF0FDF4),
          'fg': const Color(0xFF16A34A)
        };
      case 'recuperee':
        return {
          'label': 'Livrée',
          'bg': const Color(0xFFF5F5F5),
          'fg': const Color(0xFF6B7280)
        };
      case 'annulee':
        return {
          'label': 'Annulée',
          'bg': const Color(0xFFFEE2E2),
          'fg': const Color(0xFFDC2626)
        };
      default:
        return {
          'label': statut,
          'bg': const Color(0xFFF5F5F5),
          'fg': const Color(0xFF6B7280)
        };
    }
  }

  String _emojiCat(String cat) {
    switch (cat.toLowerCase()) {
      case 'express': return '🍳';
      case 'plat du jour': return '🍛';
      case 'entrées': return '🥗';
      case 'boissons': return '🥤';
      default: return '🍽️';
    }
  }

  String _emojiBoisson(String type) {
    switch (type) {
      case 'cafe': return '☕';
      case 'the': return '🍵';
      case 'jus': return '🍊';
      case 'eau': return '💧';
      case 'lait': return '🥛';
      default: return '🥤';
    }
  }

  String _labelBoisson(String type) {
    switch (type) {
      case 'cafe': return 'Café';
      case 'the': return 'Thé';
      case 'jus': return 'Jus';
      case 'eau': return 'Eau';
      case 'lait': return 'Lait';
      default: return 'Boisson';
    }
  }
}