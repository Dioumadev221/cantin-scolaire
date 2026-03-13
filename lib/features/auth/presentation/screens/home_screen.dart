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
  int _selectedSlot = 0;

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    final hour = DateTime.now().hour;
    if (hour < 10)
      _selectedSlot = 0;
    else if (hour < 15)
      _selectedSlot = 1;
    else
      _selectedSlot = 2;

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
              _buildSlotSelector(),
              _buildMenuContent(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverHeader(dynamic solde) {
    return SliverAppBar(
      expandedHeight: 160,
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
                  GestureDetector(
                    onTap: _showProfil,
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
                  ),
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
                              Text(
                                '$solde FCFA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
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
                          'Recharger',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$solde FCFA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }

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

  Widget _buildSlotSelector() {
    final slots = [
      {'emoji': '🌅', 'label': 'Petit déj', 'sub': 'Matin'},
      {'emoji': '☀️', 'label': 'Déjeuner', 'sub': 'Midi'},
      {'emoji': '🌙', 'label': 'Dîner', 'sub': 'Soir'},
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(3, (i) {
                final isActive = i == _selectedSlot;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSlot = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF1A1A1A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFEDEDED),
                          width: 1.5,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        children: [
                          Text(
                            slots[i]['emoji']!,
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            slots[i]['label']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            slots[i]['sub']!,
                            style: TextStyle(
                              fontSize: 9,
                              color: isActive
                                  ? Colors.white54
                                  : const Color(0xFF8A8A8A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

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
        final fields = ['petitDej', 'dejeuner', 'diner'];
        final allPlatsIds =
            (menuData[fields[_selectedSlot]] as List?)?.cast<String>() ?? [];

        if (allPlatsIds.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptySlot());
        }

        return _buildPlatsDispoOnly(allPlatsIds);
      },
    );
  }

  Widget _buildPlatsDispoOnly(List<String> platsIds) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('plats').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(child: SizedBox());
        }

        final dispoIds = snapshot.data!.docs
            .where((d) {
              final data = d.data() as Map<String, dynamic>;
              return platsIds.contains(d.id) && data['disponible'] == true;
            })
            .map((d) => d.id)
            .toList();

        if (dispoIds.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptySlot());
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildPlatCard(dispoIds[i]),
              childCount: dispoIds.length,
            ),
          ),
        );
      },
    );
  }

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

  Widget _buildEmptySlot() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: const [
          Text('🍽️', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text(
            'Aucun plat disponible',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Revenez plus tard',
            style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatCard(String platId) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('plats').doc(platId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        }
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final prix = data['prix'] ?? 0;

        return GestureDetector(
          onTap: () => _showCommandeDialog(platId, data),
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
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _getEmoji(data['categorie'] ?? ''),
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F0EB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (data['categorie'] ?? '').toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF6B35),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data['nom'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
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
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$prix FCFA',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 11,
                                      color: Color(0xFF8A8A8A),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${data['tempsPreparation'] ?? 0} min',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF8A8A8A),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
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
    );
  }

  void _showCommandeDialog(String platId, Map<String, dynamic> platData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(widget.user.uid).snapshots(),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final solde = userData['soldeWallet'] ?? 0;
          final prixRaw = platData['prix'] ?? 0;
          final prix = (prixRaw is double)
              ? prixRaw.toInt()
              : (prixRaw as int? ?? 0);
          final soldeInt = (solde is double)
              ? solde.toInt()
              : (solde as int? ?? 0);
          final suffisant = soldeInt >= prix;

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
                  height: 180,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3EE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      _getEmoji(platData['categorie'] ?? ''),
                      style: const TextStyle(fontSize: 80),
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
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          Text(
                            '$prix FCFA',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        platData['description'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8A8A8A),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: suffisant
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  suffisant ? '✅' : '⚠️',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      suffisant
                                          ? 'Solde suffisant'
                                          : 'Solde insuffisant',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: suffisant
                                            ? const Color(0xFF065F46)
                                            : const Color(0xFF92400E),
                                      ),
                                    ),
                                    Text(
                                      'Solde : $solde FCFA',
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: suffisant
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFFEDEDED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: suffisant
                              ? () => _passerCommande(platId, platData, prixRaw)
                              : null,
                          child: Text(
                            suffisant
                                ? 'Commander · $prix FCFA'
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
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _passerCommande(
    String platId,
    Map<String, dynamic> platData,
    dynamic prixRaw,
  ) async {
    final prix = (prixRaw is double) ? prixRaw.toInt() : (prixRaw as int? ?? 0);
    Navigator.pop(context);

    final count = await _firestore.collection('commandes').count().get();
    final numero = 'CMD-${(count.count! + 1).toString().padLeft(3, '0')}';

    await _firestore.collection('commandes').add({
      'numero': numero,
      'etudiantId': widget.user.uid,
      'etudiantNom': '${widget.user.prenom} ${widget.user.nom}',
      'platsIds': [platId],
      'montantTotal': prix,
      'modePaiement': 'wallet',
      'statut': 'recue',
      'notifEnvoyee': false,
      'noteClient': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(widget.user.uid).update({
      'soldeWallet': FieldValue.increment(-prix),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🎉 '),
              Expanded(
                child: Text('$numero passée ! On prépare votre commande.'),
              ),
            ],
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
                      return _buildCommandeDetailCard(data);
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

  Widget _buildCommandeDetailCard(Map<String, dynamic> data) {
    final statut = data['statut'] ?? '';
    final ts = data['createdAt'] as Timestamp?;
    final time = ts != null ? _timeAgo(ts.toDate()) : '';
    final isActive = ['recue', 'en_cuisine', 'prete'].contains(statut);

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
          // Header commande
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
                          isActive ? '🍽️' : '✓',
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
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                    _buildStatusPill(statut),
                  ],
                ),
              ],
            ),
          ),
          // Barre de progression si commande active
          if (isActive) ...[
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: Row(
                      children: [
                        Text(
                          statut == 'prete' ? '🔔' : '⏳',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statut == 'prete'
                              ? 'Votre commande est prête ! Venez la récupérer 🎉'
                              : statut == 'en_cuisine'
                              ? 'En cours de préparation...'
                              : 'Commande reçue, en attente de préparation',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statut == 'prete'
                                ? const Color(0xFF065F46)
                                : const Color(0xFFFF6B35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildCommandeItem(Map<String, dynamic> data) {
    final statut = data['statut'] ?? '';
    final ts = data['createdAt'] as Timestamp?;
    final time = ts != null ? _timeAgo(ts.toDate()) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🍽️', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['numero'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      '${data['montantTotal'] ?? 0} FCFA',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                    _buildStatusPill(statut),
                  ],
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
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Header wallet
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
                // Montants rapides
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
                // Montant personnalisé
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

    // Mettre à jour le solde
    await _firestore.collection('users').doc(widget.user.uid).update({
      'soldeWallet': FieldValue.increment(montant),
    });

    // Sauvegarder la transaction
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
          content: Row(
            children: [
              const Text('💰 '),
              Text('$montant FCFA ajoutés à votre wallet !'),
            ],
          ),
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
