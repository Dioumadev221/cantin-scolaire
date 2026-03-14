import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final UserEntity user;
  const HomeScreen({super.key, required this.user});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _scrollController = ScrollController();
  bool _headerCollapsed = false;
  bool _soldeVisible = true;

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final collapsed = _scrollController.offset > 80;
      if (collapsed != _headerCollapsed) {
        setState(() => _headerCollapsed = collapsed);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(widget.user.uid).snapshots(),
        builder: (context, userSnapshot) {
          final userData =
              userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          final solde = userData['soldeWallet'] ?? 0;
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverHeader(solde),
              _buildActiveOrderBanner(),
              _buildMenuTitle(),
              _buildMenuContent(),
            ],
          );
        },
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildSliverHeader(dynamic solde) {
    return SliverAppBar(
      expandedHeight: 165,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A2E),
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A0A2E), Color(0xFF1A1A5E)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.user.prenom} ${widget.user.nom}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  _buildAvatarMenu(),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showWalletInfo,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text('💰', style: TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Solde wallet',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    _soldeVisible ? '$solde FCFA' : '•••• FCFA',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => setState(
                                      () => _soldeVisible = !_soldeVisible,
                                    ),
                                    child: Icon(
                                      _soldeVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.white54,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _showWalletInfo,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Recharger',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      title: _headerCollapsed
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.user.prenom,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _buildAvatarMenu(),
              ],
            )
          : null,
    );
  }

  Widget _buildAvatarMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      onSelected: (value) async {
        if (value == 'deconnexion') {
          await ref.read(authProvider.notifier).logout();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        } else if (value == 'profil') {
          _showProfil();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profil',
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Mon profil',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'deconnexion',
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout,
                  size: 16,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Se déconnecter',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Center(
          child: Text(
            '${widget.user.prenom[0]}${widget.user.nom[0]}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // ─── BANNER COMMANDE ACTIVE ─────────────────────────────────────────────────

  Widget _buildActiveOrderBanner() {
    return SliverToBoxAdapter(
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('commandes')
            .where('etudiantId', isEqualTo: widget.user.uid)
            .where('statut', whereIn: ['recue', 'en_cuisine', 'prete'])
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const SizedBox();
          final data = docs.first.data() as Map<String, dynamic>;
          final statut = data['statut'] ?? '';
          return GestureDetector(
            onTap: _showMesCommandes,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildOrderProgress(statut),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['numero'] ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getStatutLabel(statut),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (docs.length > 1)
                          Text(
                            '+${docs.length - 1} autre(s)',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Suivre',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildOrderProgress(String statut) {
    final steps = ['recue', 'en_cuisine', 'prete'];
    final index = steps.indexOf(statut);
    return Row(
      children: List.generate(3, (i) {
        final done = i <= index;
        return Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: done ? const Color(0xFFFF6B35) : Colors.white24,
                shape: BoxShape.circle,
              ),
            ),
            if (i < 2)
              Container(
                width: 12,
                height: 2,
                color: done && i < index
                    ? const Color(0xFFFF6B35)
                    : Colors.white24,
              ),
          ],
        );
      }),
    );
  }

  // ─── TITRE MENU ─────────────────────────────────────────────────────────────

  Widget _buildMenuTitle() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Menu du jour',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Text(
              _formatDate(),
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MENU CONTENT ───────────────────────────────────────────────────────────

  Widget _buildMenuContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('menus')
          .where('date', isEqualTo: _todayStr)
          .where('actif', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
              ),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyMenu());
        }

        final menuData = docs.first.data() as Map<String, dynamic>;
        final petitDejIds =
            (menuData['petitDej'] as List?)?.cast<String>() ?? [];
        final dejeunerIds =
            (menuData['dejeuner'] as List?)?.cast<String>() ?? [];
        final dinerIds = (menuData['diner'] as List?)?.cast<String>() ?? [];

        // Tous les IDs ensemble pour fetcher les plats
        final allIds = [...petitDejIds, ...dejeunerIds, ...dinerIds];

        if (allIds.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyMenu());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('plats').snapshots(),
          builder: (context, platsSnapshot) {
            if (!platsSnapshot.hasData) {
              return const SliverToBoxAdapter(child: SizedBox());
            }

            final allPlats = platsSnapshot.data!.docs;

            // Helper pour filtrer plats dispos d'un slot
            List<QueryDocumentSnapshot> getPlats(List<String> ids) {
              return allPlats.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return ids.contains(d.id) && data['disponible'] == true;
              }).toList();
            }

            final petitDejPlats = getPlats(petitDejIds);
            final dejeunerPlats = getPlats(dejeunerIds);
            final dinerPlats = getPlats(dinerIds);

            // Boissons = plats de categorie "boissons" dans n'importe quel slot
            final boissonPlats = allPlats.where((d) {
              final data = d.data() as Map<String, dynamic>;
              return allIds.contains(d.id) &&
                  data['disponible'] == true &&
                  (data['categorie'] ?? '').toString().toLowerCase() ==
                      'boissons';
            }).toList();

            final sections = [
              if (petitDejPlats.isNotEmpty)
                _SlotSection(
                  emoji: '🌅',
                  titre: 'Petit déjeuner',
                  plats: petitDejPlats,
                ),
              if (dejeunerPlats.isNotEmpty)
                _SlotSection(
                  emoji: '☀️',
                  titre: 'Déjeuner',
                  plats: dejeunerPlats,
                ),
              if (dinerPlats.isNotEmpty)
                _SlotSection(emoji: '🌙', titre: 'Dîner', plats: dinerPlats),
              if (boissonPlats.isNotEmpty)
                _SlotSection(
                  emoji: '🥤',
                  titre: 'Boissons',
                  plats: boissonPlats,
                ),
            ];

            if (sections.isEmpty) {
              return SliverToBoxAdapter(child: _buildEmptyMenu());
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildSectionCard(sections[i]),
                  childCount: sections.length,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionCard(_SlotSection section) {
    final firstDoc = section.plats.first;
    final firstData = firstDoc.data() as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(section.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      section.titre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0EB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${section.plats.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    ),
                  ],
                ),
                if (section.plats.length > 1)
                  GestureDetector(
                    onTap: () => _showCategoriePage(section),
                    child: const Text(
                      'Voir plus →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Premier plat preview
          GestureDetector(
            onTap: () => _showCommandeDialog(firstDoc.id, firstData),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        _getEmoji(firstData['categorie'] ?? ''),
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstData['nom'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          firstData['description'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A8A8A),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${firstData['prix'] ?? 0} FCFA',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFF6B35),
                              ),
                            ),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoriePage(_SlotSection section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CategoriePage(
          section: section,
          onCommander: (platId, platData) =>
              _showCommandeDialog(platId, platData),
          getEmoji: _getEmoji,
        ),
      ),
    );
  }

  // ─── DIALOG COMMANDE ────────────────────────────────────────────────────────

  void _showCommandeDialog(String platId, Map<String, dynamic> platData) {
    int quantite = 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('users')
              .doc(widget.user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final userData =
                snapshot.data?.data() as Map<String, dynamic>? ?? {};
            final solde = userData['soldeWallet'] ?? 0;
            final prixRaw = platData['prix'] ?? 0;
            final prix = (prixRaw is double)
                ? prixRaw.toInt()
                : (prixRaw as int? ?? 0);
            final soldeInt = (solde is double)
                ? solde.toInt()
                : (solde as int? ?? 0);
            final total = prix * quantite;
            final suffisant = soldeInt >= total;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                0,
                0,
                0,
                MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEDED),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 160,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        _getEmoji(platData['categorie'] ?? ''),
                        style: const TextStyle(fontSize: 70),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                platData['nom'] ?? '',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            Text(
                              '$prix FCFA',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFF6B35),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          platData['description'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A8A8A),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Quantité
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quantité',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (quantite > 1) {
                                      setModalState(() => quantite--);
                                    }
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: quantite > 1
                                          ? const Color(0xFF1A1A1A)
                                          : const Color(0xFFEDEDED),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      color: quantite > 1
                                          ? Colors.white
                                          : const Color(0xFF8A8A8A),
                                      size: 18,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 48,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$quantite',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setModalState(() => quantite++),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Solde
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: suffisant
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    suffisant ? '✅' : '⚠️',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        suffisant
                                            ? 'Solde suffisant'
                                            : 'Solde insuffisant',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: suffisant
                                              ? const Color(0xFF065F46)
                                              : const Color(0xFF92400E),
                                        ),
                                      ),
                                      Text(
                                        'Solde : $soldeInt FCFA',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: suffisant
                                              ? const Color(0xFF065F46)
                                              : const Color(0xFF92400E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                'Total : $total FCFA',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: suffisant
                                      ? const Color(0xFF065F46)
                                      : const Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: suffisant
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFFEDEDED),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: suffisant
                                ? () => _verifierEtCommander(
                                    platId,
                                    platData,
                                    prix,
                                    quantite,
                                  )
                                : null,
                            child: Text(
                              suffisant
                                  ? 'Commander · $total FCFA'
                                  : 'Solde insuffisant',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: suffisant
                                    ? Colors.white
                                    : const Color(0xFF8A8A8A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _verifierEtCommander(
    String platId,
    Map<String, dynamic> platData,
    int prix,
    int quantite,
  ) async {
    final existing = await _firestore
        .collection('commandes')
        .where('etudiantId', isEqualTo: widget.user.uid)
        .where('statut', whereIn: ['recue', 'en_cuisine', 'prete'])
        .get();

    final dejaCommande = existing.docs.any((d) {
      final data = d.data();
      final platsIds = (data['platsIds'] as List?)?.cast<String>() ?? [];
      return platsIds.contains(platId);
    });

    if (dejaCommande && mounted) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Déjà commandé !',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Vous avez déjà "${platData['nom']}" en cours. Voulez-vous quand même recommander ?',
            style: const TextStyle(color: Color(0xFF8A8A8A)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Color(0xFF8A8A8A)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _passerCommande(platId, platData, prix, quantite);
              },
              child: const Text('Recommander'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.pop(context);
    await _passerCommande(platId, platData, prix, quantite);
  }

  Future<void> _passerCommande(
    String platId,
    Map<String, dynamic> platData,
    int prix,
    int quantite,
  ) async {
    final total = prix * quantite;
    final isBoisson =
        (platData['categorie'] ?? '').toString().toLowerCase() == 'boissons';

    final count = await _firestore.collection('commandes').count().get();
    final numero = 'CMD-${(count.count! + 1).toString().padLeft(3, '0')}';

    await _firestore.collection('commandes').add({
      'numero': numero,
      'etudiantId': widget.user.uid,
      'etudiantNom': '${widget.user.prenom} ${widget.user.nom}',
      'platsIds': [platId],
      'quantite': quantite,
      'montantTotal': total,
      'modePaiement': 'wallet',
      'statut': isBoisson ? 'prete' : 'recue',
      'isBoisson': isBoisson,
      'notifEnvoyee': false,
      'noteClient': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(widget.user.uid).update({
      'soldeWallet': FieldValue.increment(-total),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBoisson
                ? '🥤 $numero prête ! Venez récupérer votre boisson.'
                : '🎉 $numero passée ! On prépare votre commande.',
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ─── MES COMMANDES ──────────────────────────────────────────────────────────

  void _showMesCommandes() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDED),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mes commandes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('commandes')
                    .where('etudiantId', isEqualTo: widget.user.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('📦', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text(
                            'Aucune commande',
                            style: TextStyle(
                              color: Color(0xFF8A8A8A),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      return _buildCommandeDetailCard(docs[i].id, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandeDetailCard(
    String commandeId,
    Map<String, dynamic> data,
  ) {
    final statut = data['statut'] ?? '';
    final ts = data['createdAt'] as Timestamp?;
    final time = ts != null ? _timeAgo(ts.toDate()) : '';
    final isActive = ['recue', 'en_cuisine', 'prete'].contains(statut);
    final isBoisson = data['isBoisson'] == true;
    final peutAnnuler = statut == 'recue';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFFFF6B35).withOpacity(0.3)
              : const Color(0xFFEDEDED),
          width: isActive ? 1.5 : 0.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFFFF3EE)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          isBoisson ? '🥤' : (isActive ? '🍽️' : '✓'),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['numero'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8A8A8A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${data['montantTotal'] ?? 0} FCFA',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                    const SizedBox(height: 3),
                    _buildStatusPill(statut),
                  ],
                ),
              ],
            ),
          ),
          // Progression pour plats normaux
          if (isActive && !isBoisson) ...[
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStep('Reçue', 'recue', statut),
                      _buildStepLine(statut, 'recue'),
                      _buildStep('En cuisine', 'en_cuisine', statut),
                      _buildStepLine(statut, 'en_cuisine'),
                      _buildStep('Prête', 'prete', statut),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: statut == 'prete'
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFFFFF3EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statut == 'prete'
                          ? '🔔 Votre commande est prête ! Venez la récupérer 🎉'
                          : statut == 'en_cuisine'
                          ? '👨‍🍳 En cours de préparation...'
                          : '⏳ Commande reçue, en attente',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statut == 'prete'
                            ? const Color(0xFF065F46)
                            : const Color(0xFFFF6B35),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Boisson prête directement
          if (isBoisson && statut == 'prete') ...[
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '🥤 Votre boisson est prête ! Venez la récupérer.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
            ),
          ],
          // Bouton annuler
          if (peutAnnuler) ...[
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            GestureDetector(
              onTap: () => _annulerCommande(commandeId, data),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Center(
                  child: Text(
                    'Annuler la commande',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _annulerCommande(
    String commandeId,
    Map<String, dynamic> data,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Annuler la commande ?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Le montant sera remboursé sur votre wallet.',
          style: TextStyle(color: Color(0xFF8A8A8A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Non',
              style: TextStyle(color: Color(0xFF8A8A8A)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final montant = data['montantTotal'] ?? 0;
      await _firestore.collection('commandes').doc(commandeId).update({
        'statut': 'annulee',
      });
      await _firestore.collection('users').doc(widget.user.uid).update({
        'soldeWallet': FieldValue.increment(montant),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Commande annulée · Remboursement effectué'),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    }
  }

  // ─── WALLET ─────────────────────────────────────────────────────────────────

  void _showWalletInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(widget.user.uid).snapshots(),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final solde = userData['soldeWallet'] ?? 0;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0A0A2E), Color(0xFF1A1A5E)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mon Wallet',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$solde FCFA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Solde disponible',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choisir un montant',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.8,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [1000, 2000, 5000, 10000].map((montant) {
                    return GestureDetector(
                      onTap: () => _rechargerWallet(montant),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F0EB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFDDCC),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$montant FCFA',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0EB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEDEDED)),
                  ),
                  child: Row(
                    children: [
                      const Text('💰', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Autre montant...',
                            hintStyle: TextStyle(
                              color: Color(0xFFCCCCCC),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (val) {
                            final montant = int.tryParse(val) ?? 0;
                            if (montant > 0) _rechargerWallet(montant);
                          },
                        ),
                      ),
                      const Text(
                        'FCFA',
                        style: TextStyle(
                          color: Color(0xFF8A8A8A),
                          fontSize: 13,
                        ),
                      ),
                    ],
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

  Future<void> _rechargerWallet(int montant) async {
    Navigator.pop(context);
    await _firestore.collection('users').doc(widget.user.uid).update({
      'soldeWallet': FieldValue.increment(montant),
    });
    await _firestore.collection('recharges').add({
      'etudiantId': widget.user.uid,
      'etudiantNom': '${widget.user.prenom} ${widget.user.nom}',
      'montant': montant,
      'statut': 'approuvee',
      'createdAt': FieldValue.serverTimestamp(),
      'traitePar': 'self',
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💰 $montant FCFA ajoutés à votre wallet !'),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ─── PROFIL ─────────────────────────────────────────────────────────────────

  void _showProfil() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A2E),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Text(
                  '${widget.user.prenom[0]}${widget.user.nom[0]}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.user.prenom} ${widget.user.nom}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              widget.user.email,
              style: const TextStyle(fontSize: 13, color: Color(0xFF8A8A8A)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0EB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Étudiant',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                child: const Text(
                  'Se déconnecter',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── WIDGETS HELPERS ────────────────────────────────────────────────────────

  Widget _buildEmptyMenu() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0EB),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Text('😴', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pas de menu aujourd\'hui',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Revenez plus tard',
            style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String label, String stepStatut, String currentStatut) {
    final steps = ['recue', 'en_cuisine', 'prete'];
    final currentIndex = steps.indexOf(currentStatut);
    final stepIndex = steps.indexOf(stepStatut);
    final isDone = stepIndex <= currentIndex;
    final isActive = stepStatut == currentStatut;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFFFF6B35) : const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone ? const Color(0xFFFF6B35) : const Color(0xFFEDEDED),
              width: 2,
            ),
          ),
          child: Center(
            child: isActive
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  )
                : isDone
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : const SizedBox(),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isDone ? const Color(0xFFFF6B35) : const Color(0xFF8A8A8A),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(String currentStatut, String afterStatut) {
    final steps = ['recue', 'en_cuisine', 'prete'];
    final currentIndex = steps.indexOf(currentStatut);
    final afterIndex = steps.indexOf(afterStatut);
    final isDone = afterIndex < currentIndex;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFFFF6B35) : const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(2),
        ),
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
        label = '⏳ Reçue';
        break;
      case 'en_cuisine':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFF92400E);
        label = '👨‍🍳 En cuisine';
        break;
      case 'prete':
        bg = const Color(0xFFD1FAE5);
        text = const Color(0xFF065F46);
        label = '✅ Prête !';
        break;
      case 'recuperee':
        bg = const Color(0xFFF3F4F6);
        text = const Color(0xFF6B7280);
        label = '✓ Récupérée';
        break;
      default:
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFF991B1B);
        label = '✕ Annulée';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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

  // ─── UTILS ──────────────────────────────────────────────────────────────────

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour 👋';
    if (hour < 18) return 'Bon après-midi 👋';
    return 'Bonsoir 👋';
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'recue':
        return 'Commande reçue';
      case 'en_cuisine':
        return 'En cours de préparation...';
      case 'prete':
        return '🔔 Votre commande est prête !';
      default:
        return '';
    }
  }

  String _formatDate() {
    final now = DateTime.now();
    final months = [
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
    final days = ['', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return '${days[now.weekday]} ${now.day} ${months[now.month]}';
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

  String _getEmoji(String categorie) {
    switch (categorie.toLowerCase()) {
      case 'express':
        return '🍳';
      case 'plat du jour':
        return '🍛';
      case 'entrées':
        return '🥗';
      case 'boissons':
        return '🥤';
      default:
        return '🍽️';
    }
  }
}

// ─── MODEL ──────────────────────────────────────────────────────────────────

class _SlotSection {
  final String emoji;
  final String titre;
  final List<QueryDocumentSnapshot> plats;
  const _SlotSection({
    required this.emoji,
    required this.titre,
    required this.plats,
  });
}

// ─── PAGE CATÉGORIE ──────────────────────────────────────────────────────────

class _CategoriePage extends StatelessWidget {
  final _SlotSection section;
  final Function(String, Map<String, dynamic>) onCommander;
  final String Function(String) getEmoji;

  const _CategoriePage({
    required this.section,
    required this.onCommander,
    required this.getEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(section.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              section.titre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: section.plats.length,
        itemBuilder: (context, i) {
          final doc = section.plats[i];
          final data = doc.data() as Map<String, dynamic>;
          return GestureDetector(
            onTap: () {
              Navigator.pop(context);
              onCommander(doc.id, data);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3EE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          getEmoji(data['categorie'] ?? ''),
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['nom'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['description'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8A8A8A),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${data['prix'] ?? 0} FCFA',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFF6B35),
                                ),
                              ),
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
