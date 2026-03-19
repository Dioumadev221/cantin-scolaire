import 'package:cantine_scolaire/features/auth/presentation/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../presentation/providers/cart_provider.dart';
import 'plat_detail_screen.dart';
import 'profil_etudiant_screen.dart';
import 'notifications_etudiant_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final UserEntity user;
  const HomeScreen({super.key, required this.user});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _cat = 'Tous';
  int _tab = 0;
  late final AnimationController _fadeCtrl;

  static const _categories = [
    {'label': 'Tous',    'emoji': '🍽️', 'color': '0xFF1A1A1A'},
    {'label': 'Petit déjeuner', 'emoji': '🌅', 'color': '0xFF6366F1'},
    {'label': 'Déjeuner',      'emoji': '☀️',  'color': '0xFF10B981'},
    {'label': 'Dîner',         'emoji': '🌙',  'color': '0xFF8B5CF6'},
    {'label': 'Boissons','emoji': '🥤',  'color': '0xFF8B5CF6'},
  ];

  @override
  void initState() {
    super.initState();
    NotificationService().initialize(widget.user.uid);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final nbArticles = ref.read(cartProvider.notifier).nbArticles;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: _tab == 0 ? _buildHome() : _buildCommandes(),
      floatingActionButton: _tab == 0 && cartItems.isNotEmpty
          ? _buildCartFab(cartItems.length, nbArticles)
          : null,
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildCartFab(int nbPlats, int nbArticles) {
    final total = ref.read(cartProvider.notifier).total;
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CartScreen(user: widget.user))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.25),
                blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            const Icon(Icons.shopping_bag_outlined,
                color: Colors.white, size: 22),
            Positioned(top: -6, right: -6,
              child: Container(
                width: 18, height: 18,
                decoration: const BoxDecoration(
                    color: Color(0xFFFF6B35), shape: BoxShape.circle),
                child: Center(child: Text('$nbArticles',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 9, fontWeight: FontWeight.w800))),
              )),
          ]),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, children: [
            Text('$nbPlats article${nbPlats > 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
            Text('${total.toStringAsFixed(0)} FCFA',
                style: const TextStyle(color: Colors.white,
                    fontSize: 14, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(12)),
            child: const Text('Voir', style: TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    );
  }

  // ── BOTTOM NAV ─────────────────────────────────────────────────────────────

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
            blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(children: [
            _navBtn(0, Icons.home_rounded, Icons.home_outlined, 'Accueil'),
            _navBtn(1, Icons.receipt_long, Icons.receipt_long_outlined, 'Commandes'),
          ]),
        ),
      ),
    );
  }

  Widget _navBtn(int idx, IconData activeIcon, IconData icon, String label) {
    final active = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFF6B35).withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(active ? activeIcon : icon,
                color: active ? const Color(0xFFFF6B35) : const Color(0xFFB0B0B0),
                size: 22),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
                fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? const Color(0xFFFF6B35) : const Color(0xFFB0B0B0))),
          ]),
        ),
      ),
    );
  }

  // ── RECHARGE WALLET ────────────────────────────────────────────────────────

  void _showRecharge() {
    final _libreCtrl = TextEditingController();
    const montants = [500, 1000, 2000, 5000];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setS) {
          int? selected;
          bool loading = false;
          String? err;

          Future<void> recharger(double montant) async {
            setS(() { loading = true; err = null; });
            try {
              await _db.collection('users').doc(widget.user.uid).update({
                'soldeWallet': FieldValue.increment(montant),
              });
              await _db.collection('recharges').add({
                'etudiantId': widget.user.uid,
                'etudiantNom': '${widget.user.prenom} ${widget.user.nom}',
                'montant': montant,
                'statut': 'validee',
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (c.mounted) Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${montant.toStringAsFixed(0)} FCFA ajoutés 🎉'),
                backgroundColor: const Color(0xFF22C55E),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ));
            } catch (e) {
              setS(() { loading = false; err = 'Erreur : $e'; });
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(c).viewInsets.bottom + 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                // Titre
                const Row(children: [
                  Text('💳', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 10),
                  Text('Recharger mon wallet', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A))),
                ]),
                const SizedBox(height: 6),
                const Text('Choisissez un montant ou entrez un montant libre',
                    style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 12)),
                const SizedBox(height: 20),

                // Montants fixes
                const Text('Montants rapides', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: Color(0xFF6B6B6B))),
                const SizedBox(height: 10),
                Row(children: montants.map((m) {
                  final sel = selected == m;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setS(() { selected = m; _libreCtrl.clear(); }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.only(right: m != montants.last ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFFFF6B35) : const Color(0xFFF8F7F4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: sel ? const Color(0xFFFF6B35) : const Color(0xFFEEEEEE),
                              width: sel ? 2 : 1),
                        ),
                        child: Column(children: [
                          Text('$m', style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800,
                              color: sel ? Colors.white : const Color(0xFF1A1A1A))),
                          Text('F', style: TextStyle(
                              fontSize: 10,
                              color: sel ? Colors.white70 : const Color(0xFFB0B0B0))),
                        ]),
                      ),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 16),

                // Montant libre
                const Text('Montant libre', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: Color(0xFF6B6B6B))),
                const SizedBox(height: 8),
                TextField(
                  controller: _libreCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setS(() => selected = null),
                  decoration: InputDecoration(
                    hintText: 'Ex : 3000',
                    hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                    suffixText: 'FCFA',
                    suffixStyle: const TextStyle(
                        color: Color(0xFFFF6B35), fontWeight: FontWeight.w700),
                    filled: true,
                    fillColor: const Color(0xFFF8F7F4),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFFFF6B35), width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),

                if (err != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(err!, style: const TextStyle(
                        color: Color(0xFFEF4444), fontSize: 12)),
                  ),
                ],
                const SizedBox(height: 20),

                // Bouton confirmer
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: loading ? null : () {
                      final montant = selected?.toDouble()
                          ?? double.tryParse(_libreCtrl.text.trim());
                      if (montant == null || montant <= 0) {
                        setS(() => err = 'Veuillez choisir ou saisir un montant valide');
                        return;
                      }
                      recharger(montant);
                    },
                    child: loading
                        ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : const Text('Confirmer la recharge', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ONGLET ACCUEIL
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHome() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(child: _buildGreeting()),
        SliverToBoxAdapter(child: _buildWallet()),
        SliverToBoxAdapter(child: _buildSearchBar()),
        _buildPlatsList(),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  // ── APP BAR ────────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: const Color(0xFFF8F7F4),
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              // Logo / Brand
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(12)),
                child: const Center(
                    child: Text('🍽️', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Cantine', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A))),
                    Text('Scolaire', style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w500,
                        color: Color(0xFFB0B0B0))),
                  ],
                ),
              ),
              // Cloche
              StreamBuilder<int>(
                stream: NotificationService.compteurNonLus(widget.user.uid),
                builder: (_, snap) {
                  final n = snap.data ?? 0;
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => NotificationsEtudiantScreen(user: widget.user))),
                    child: Stack(clipBehavior: Clip.none, children: [
                      Container(width: 42, height: 42,
                        decoration: BoxDecoration(color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                                blurRadius: 8, offset: const Offset(0, 2))]),
                        child: const Icon(Icons.notifications_outlined,
                            color: Color(0xFF1A1A1A), size: 20)),
                      if (n > 0) Positioned(top: -2, right: -2,
                        child: Container(
                          width: 16, height: 16,
                          decoration: const BoxDecoration(
                              color: Color(0xFFFF6B35), shape: BoxShape.circle),
                          child: Center(child: Text(n > 9 ? '9+' : '$n',
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 8, fontWeight: FontWeight.w800))),
                        )),
                    ]),
                  );
                },
              ),
              const SizedBox(width: 10),
              // Avatar
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ProfilEtudiantScreen(user: widget.user))),
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(
                    '${widget.user.prenom[0]}${widget.user.nom[0]}',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 13, fontWeight: FontWeight.w800))),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── GREETING ───────────────────────────────────────────────────────────────

  Widget _buildGreeting() {
    final h = DateTime.now().hour;
    final greeting = h < 12 ? 'Bonjour' : h < 18 ? 'Bon après-midi' : 'Bonsoir';
    final sub = h < 11 ? 'Que prenez-vous ce matin ?' 
        : h < 14 ? 'Heure du déjeuner 🌞'
        : h < 19 ? 'Une petite faim ?'
        : 'Le dîner est servi 🌙';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: '$greeting, ', style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w400,
                  color: Color(0xFF8A8A8A))),
              TextSpan(text: widget.user.prenom, style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A))),
              const TextSpan(text: ' 👋', style: TextStyle(fontSize: 20)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(sub, style: const TextStyle(
            color: Color(0xFFB0B0B0), fontSize: 13)),
      ]),
    );
  }

  // ── WALLET MINI CARD ───────────────────────────────────────────────────────

  Widget _buildWallet() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('users').doc(widget.user.uid).snapshots(),
      builder: (_, snap) {
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};
        final solde = (data['soldeWallet'] ?? 0).toDouble();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('💳', style: TextStyle(fontSize: 22)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Mon wallet', style: TextStyle(
                    color: Colors.white60, fontSize: 11)),
                Text('${solde.toStringAsFixed(0)} FCFA', style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              ])),
              GestureDetector(
                onTap: () => _showRecharge(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Text('Recharger', style: TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  // ── SEARCH BAR ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          const Icon(Icons.search, color: Color(0xFFCCCCCC), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Burger, pizza, jus...',
                hintStyle: TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_search.isNotEmpty)
            GestureDetector(
              onTap: () { setState(() => _search = ''); _searchCtrl.clear(); },
              child: const Icon(Icons.close, color: Color(0xFFCCCCCC), size: 18),
            ),
        ]),
      ),
    );
  }

  // ── CATÉGORIES ─────────────────────────────────────────────────────────────

  Widget _buildCategories() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final c = _categories[i];
          final active = c['label'] == _cat;
          final color = Color(int.parse(c['color']!));
          return GestureDetector(
            onTap: () => setState(() => _cat = c['label']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? color : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: active ? color : const Color(0xFFEEEEEE), width: 1.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(c['emoji']!, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                Text(c['label']!, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: active ? Colors.white : const Color(0xFF6B6B6B))),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ── LISTE PLATS par catégorie (menu actif du jour) ─────────────────────────

  Widget _buildPlatsList() {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('menus')
          .where('date', isEqualTo: dateStr)
          .where('actif', isEqualTo: true)
          .snapshots(),
      builder: (_, menuSnap) {
        if (menuSnap.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(
                color: Color(0xFFFF6B35), strokeWidth: 2)),
          ));
        }

        // Pas de menu actif
        if ((menuSnap.data?.docs ?? []).isEmpty) {
          return SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                      blurRadius: 12, offset: const Offset(0, 4))]),
              child: const Column(children: [
                Text('📋', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('Aucun menu publié aujourd\'hui',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A))),
                SizedBox(height: 6),
                Text('L\'administration n\'a pas encore publié\nle menu de la journée.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 13)),
              ]),
            ),
          ));
        }

        final menuData = menuSnap.data!.docs.first.data() as Map<String, dynamic>;
        final allPlatIds = <String>{
          ...((menuData['petitDej'] as List?)?.cast<String>() ?? []),
          ...((menuData['dejeuner'] as List?)?.cast<String>() ?? []),
          ...((menuData['diner'] as List?)?.cast<String>() ?? []),
        };

        if (allPlatIds.isEmpty) {
          return SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(20)),
              child: const Column(children: [
                Text('🍽️', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('Menu vide', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text('Aucun plat n\'a encore été ajouté au menu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 13)),
              ]),
            ),
          ));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _db.collection('plats').where('disponible', isEqualTo: true).snapshots(),
          builder: (_, platsSnap) {
            if (platsSnap.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }

            // Plats du menu actif + disponibles
            var docs = (platsSnap.data?.docs ?? [])
                .where((d) => allPlatIds.contains(d.id))
                .toList();

            // Filtre recherche
            if (_search.isNotEmpty) {
              docs = docs.where((d) {
                final m = d.data() as Map;
                return (m['nom'] ?? '').toString().toLowerCase().contains(_search) ||
                    (m['description'] ?? '').toString().toLowerCase().contains(_search);
              }).toList();
            }

            if (docs.isEmpty) {
              return SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  const Text('🔍', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    _search.isNotEmpty
                        ? 'Aucun résultat pour "$_search"'
                        : 'Aucun plat au menu',
                    style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ));
            }

            // ── Grouper par catégorie ──────────────────────────────────────
            const catOrder = ['petit_dejeuner', 'dejeuner', 'diner', 'boissons'];
            const catLabels = {
              'petit_dejeuner': {'label': 'Petit déjeuner', 'emoji': '🌅'},
              'dejeuner':       {'label': 'Déjeuner',       'emoji': '☀️'},
              'diner':          {'label': 'Dîner',          'emoji': '🌙'},
              'boissons':   {'label': 'Boissons',      'emoji': '🥤'},
            };

            final grouped = <String, List<QueryDocumentSnapshot>>{};
            for (final doc in docs) {
              final cat = (doc.data() as Map)['categorie']
                  ?.toString().toLowerCase() ?? 'autres';
              grouped.putIfAbsent(cat, () => []).add(doc);
            }

            // Construire les sliver widgets
            final widgets = <Widget>[];
            for (final cat in catOrder) {
              final catDocs = grouped[cat];
              if (catDocs == null || catDocs.isEmpty) continue;
              final info = catLabels[cat] ?? {'label': cat, 'emoji': '🍽️'};

              // En-tête catégorie
              widgets.add(Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(children: [
                  Text(info['emoji']!, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(info['label']!, style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('${catDocs.length}',
                        style: const TextStyle(
                            color: Color(0xFFFF6B35), fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
              ));

              // Cards de la catégorie
              for (final doc in catDocs) {
                widgets.add(Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _PlatCard(
                    platId: doc.id,
                    data: doc.data() as Map<String, dynamic>,
                    user: widget.user,
                  ),
                ));
              }
            }

            // Catégories inconnues
            final others = grouped.entries
                .where((e) => !catOrder.contains(e.key))
                .toList();
            if (others.isNotEmpty) {
              widgets.add(const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text('🍽️ Autres', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
              ));
              for (final entry in others) {
                for (final doc in entry.value) {
                  widgets.add(Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _PlatCard(
                      platId: doc.id,
                      data: doc.data() as Map<String, dynamic>,
                      user: widget.user,
                    ),
                  ));
                }
              }
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => widgets[i],
                childCount: widgets.length,
              ),
            );
          },
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ONGLET COMMANDES
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCommandes() {
    return Column(children: [
      // Header
      Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
        child: Row(children: [
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mes commandes', style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              SizedBox(height: 2),
              Text('Suivi en temps réel', style: TextStyle(
                  color: Colors.white60, fontSize: 12)),
            ],
          )),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => NotificationsEtudiantScreen(user: widget.user))),
            child: StreamBuilder<int>(
              stream: NotificationService.compteurNonLus(widget.user.uid),
              builder: (_, snap) {
                final n = snap.data ?? 0;
                return Stack(clipBehavior: Clip.none, children: [
                  Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white12,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 20)),
                  if (n > 0) Positioned(top: -3, right: -3,
                    child: Container(width: 16, height: 16,
                      decoration: const BoxDecoration(
                          color: Color(0xFFFF6B35), shape: BoxShape.circle),
                      child: Center(child: Text('$n', style: const TextStyle(
                          color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))))),
                ]);
              },
            ),
          ),
        ]),
      ),
      Expanded(child: _buildCommandesList()),
    ]);
  }

  Widget _buildCommandesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('commandes')
          .where('etudiantId', isEqualTo: widget.user.uid)
          .snapshots(),
      builder: (_, snap) {
        final docs = List.from(snap.data?.docs ?? []);
        docs.sort((a, b) {
          final ta = ((a.data() as Map)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final tb = ((b.data() as Map)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          return tb.compareTo(ta);
        });

        if (docs.isEmpty) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🛍️', style: TextStyle(fontSize: 52)),
              SizedBox(height: 14),
              Text('Aucune commande', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              SizedBox(height: 6),
              Text('Explorez le menu et passez votre première commande',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 13)),
            ],
          ));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _CommandeCard(data: data);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAT CARD — propre et proportionnée
// ─────────────────────────────────────────────────────────────────────────────
class _PlatCard extends StatelessWidget {
  final String platId;
  final Map<String, dynamic> data;
  final UserEntity user;

  const _PlatCard({required this.platId, required this.data, required this.user});

  String get _emoji {
    final cat = (data['categorie'] ?? '').toString().toLowerCase();
    if (cat == 'boissons') {
      switch (data['typeBoisson'] ?? '') {
        case 'cafe': return '☕'; case 'the': return '🍵';
        case 'jus': return '🍊'; case 'eau': return '💧';
        case 'lait': return '🥛'; default: return '🥤';
      }
    }
    switch (cat) {
      case 'petit_dejeuner': return '🌅'; case 'dejeuner': return '☀️';
      case 'diner': return '🌙'; default: return '🍽️';
    }
  }

  Color get _catColor {
    switch ((data['categorie'] ?? '').toString().toLowerCase()) {
      case 'petit_dejeuner': return const Color(0xFF6366F1);
      case 'dejeuner': return const Color(0xFF10B981);
      case 'diner': return const Color(0xFF8B5CF6);
      case 'boissons': return const Color(0xFF8B5CF6);
      default: return const Color(0xFF6B7280);
    }
  }

  String get _catLabel {
    final cat = (data['categorie'] ?? '').toString().toLowerCase();
    if (cat == 'boissons') {
      final m = {'cafe':'Café','the':'Thé','jus':'Jus','eau':'Eau','lait':'Lait'};
      return m[data['typeBoisson']] ?? 'Boisson';
    }
    const labels = {
      'petit_dejeuner': 'Petit déjeuner',
      'dejeuner': 'Déjeuner',
      'diner': 'Dîner',
    };
    return labels[cat] ?? (data['categorie'] ?? '');
  }

  bool get _isBoisson => (data['categorie'] ?? '').toString().toLowerCase() == 'boissons';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => PlatDetailScreen(platId: platId, data: data, user: user))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // ── Emoji carré coloré ──────────────────────────────────────
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _catColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(_emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(width: 14),
            // ── Infos ───────────────────────────────────────────────────
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Badge catégorie
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _catColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_catLabel, style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: _catColor)),
                  ),
                  if (!_isBoisson && data['tempsPreparation'] != null) ...[
                    const SizedBox(width: 6),
                    Row(children: [
                      const Icon(Icons.timer_outlined,
                          size: 10, color: Color(0xFFB0B0B0)),
                      const SizedBox(width: 2),
                      Text('${data['tempsPreparation']} min',
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFFB0B0B0))),
                    ]),
                  ],
                ]),
                const SizedBox(height: 6),
                Text(data['nom'] ?? '',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if ((data['description'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(data['description'] ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFB0B0B0), height: 1.3),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: Text('${data['prix'] ?? 0} FCFA',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A))),
                  ),
                  // Bouton commander
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMANDE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _CommandeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CommandeCard({required this.data});

  static Map<String, dynamic> _info(String s) {
    switch (s) {
      case 'recue':      return {'label':'⏳ Reçue',     'bg':const Color(0xFFFEF3C7),'fg':const Color(0xFFD97706)};
      case 'en_cuisine': return {'label':'👨‍🍳 En cuisine','bg':const Color(0xFFEFF6FF),'fg':const Color(0xFF2563EB)};
      case 'prete':      return {'label':'🔔 Prête !',   'bg':const Color(0xFFF0FDF4),'fg':const Color(0xFF16A34A)};
      case 'recuperee':  return {'label':'✅ Livrée',    'bg':const Color(0xFFF5F5F5),'fg':const Color(0xFF6B7280)};
      case 'annulee':    return {'label':'❌ Annulée',   'bg':const Color(0xFFFEE2E2),'fg':const Color(0xFFDC2626)};
      default:           return {'label':s,              'bg':const Color(0xFFF5F5F5),'fg':const Color(0xFF6B7280)};
    }
  }

  @override
  Widget build(BuildContext context) {
    final statut = data['statut'] ?? '';
    final info = _info(statut);
    final steps = data['isBoisson'] == true
        ? ['recue', 'prete', 'recuperee']
        : ['recue', 'en_cuisine', 'prete', 'recuperee'];
    final stepLabels = data['isBoisson'] == true
        ? ['Reçue', 'Prête', 'Livrée']
        : ['Reçue', 'Cuisine', 'Prête', 'Livrée'];
    final idx = steps.indexOf(statut).clamp(0, steps.length - 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 46, height: 46,
              decoration: BoxDecoration(
                  color: const Color(0xFFF8F7F4),
                  borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(
                  data['isBoisson'] == true ? '🥤' : '🍽️',
                  style: const TextStyle(fontSize: 22)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('#${data['numero'] ?? '—'}', style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
              Text(data['nomPlat'] ?? '—', style: const TextStyle(
                  fontSize: 12, color: Color(0xFFB0B0B0)),
                  overflow: TextOverflow.ellipsis),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: info['bg'] as Color, borderRadius: BorderRadius.circular(20)),
                child: Text(info['label'] as String,
                    style: TextStyle(color: info['fg'] as Color,
                        fontSize: 11, fontWeight: FontWeight.w700))),
              const SizedBox(height: 4),
              Text('${(data['montantTotal'] ?? 0).toStringAsFixed(0)} F',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                      color: Color(0xFFFF6B35))),
            ]),
          ]),
        ),
        // Progress bar
        if (statut != 'annulee')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: [
              Row(children: List.generate(steps.length, (i) {
                final done = i <= idx;
                return Expanded(child: Row(children: [
                  Container(width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: done ? const Color(0xFF22C55E) : const Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: done ? const Color(0xFF22C55E) : const Color(0xFFDDDDDD),
                          width: 2),
                    ),
                    child: done ? const Icon(Icons.check, size: 12, color: Colors.white) : null),
                  if (i < steps.length - 1)
                    Expanded(child: Container(height: 2,
                        color: i < idx ? const Color(0xFF22C55E) : const Color(0xFFEEEEEE))),
                ]));
              })),
              const SizedBox(height: 6),
              Row(children: List.generate(steps.length, (i) => Expanded(
                child: Text(stepLabels[i],
                    textAlign: i == 0 ? TextAlign.left
                        : i == steps.length - 1 ? TextAlign.right
                        : TextAlign.center,
                    style: TextStyle(fontSize: 9,
                        fontWeight: i <= idx ? FontWeight.w700 : FontWeight.w400,
                        color: i <= idx ? const Color(0xFF22C55E) : const Color(0xFFCCCCCC))),
              ))),
            ]),
          ),
      ]),
    );
  }
}