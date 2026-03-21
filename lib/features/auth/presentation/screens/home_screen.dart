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
  int _tab = 0;
  String _mode = 'menu';
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    NotificationService().initialize(widget.user.uid);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CartScreen(user: widget.user)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B35),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$nbArticles',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$nbPlats article${nbPlats > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                Text(
                  '${total.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Voir',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _navBtn(0, Icons.home_rounded, Icons.home_outlined, 'Accueil'),
              _navBtn(
                1,
                Icons.receipt_long,
                Icons.receipt_long_outlined,
                'Commandes',
              ),
            ],
          ),
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
            color: active
                ? const Color(0xFFFF6B35).withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? activeIcon : icon,
                color: active
                    ? const Color(0xFFFF6B35)
                    : const Color(0xFFB0B0B0),
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? const Color(0xFFFF6B35)
                      : const Color(0xFFB0B0B0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecharge() {
    final libreCtrl = TextEditingController();
    const montants = [500, 1000, 2000, 5000];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setS) {
          int? selected;
          bool loading = false;
          String? err;
          Future<void> recharger(double montant) async {
            setS(() {
              loading = true;
              err = null;
            });
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${montant.toStringAsFixed(0)} FCFA ajoutés 🎉',
                  ),
                  backgroundColor: const Color(0xFF22C55E),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              );
            } catch (e) {
              setS(() {
                loading = false;
                err = 'Erreur : $e';
              });
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(c).viewInsets.bottom + 28,
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
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Text('💳', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 10),
                    Text(
                      'Recharger mon wallet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choisissez un montant ou entrez un montant libre',
                  style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Montants rapides',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: montants.map((m) {
                    final sel = selected == m;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setS(() {
                          selected = m;
                          libreCtrl.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: EdgeInsets.only(
                            right: m != montants.last ? 8 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFFF6B35)
                                : const Color(0xFFF8F7F4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFFFF6B35)
                                  : const Color(0xFFEEEEEE),
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$m',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: sel
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                              Text(
                                'F',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: sel
                                      ? Colors.white70
                                      : const Color(0xFFB0B0B0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Montant libre',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: libreCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setS(() => selected = null),
                  decoration: InputDecoration(
                    hintText: 'Ex : 3000',
                    hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                    suffixText: 'FCFA',
                    suffixStyle: const TextStyle(
                      color: Color(0xFFFF6B35),
                      fontWeight: FontWeight.w700,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F7F4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF6B35),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: loading
                        ? null
                        : () {
                            final montant =
                                selected?.toDouble() ??
                                double.tryParse(libreCtrl.text.trim());
                            if (montant == null || montant <= 0) {
                              setS(
                                () => err =
                                    'Veuillez choisir ou saisir un montant valide',
                              );
                              return;
                            }
                            recharger(montant);
                          },
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Confirmer la recharge',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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
        SliverToBoxAdapter(child: _buildModeToggle()),
        _buildPlatsList(),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(child: _modeBtn('menu', '🍽️', 'Menu')),
          const SizedBox(width: 12),
          Expanded(child: _modeBtn('boissons', '🥤', 'Boissons')),
        ],
      ),
    );
  }

  Widget _modeBtn(String mode, String emoji, String label) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
          border: Border.all(
            color: active ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : const Color(0xFF6B6B6B),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🍽️', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Cantine',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        'Scolaire',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFB0B0B0),
                        ),
                      ),
                    ],
                  ),
                ),
                StreamBuilder<int>(
                  stream: NotificationService.compteurNonLus(widget.user.uid),
                  builder: (_, snap) {
                    final n = snap.data ?? 0;
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              NotificationsEtudiantScreen(user: widget.user),
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Color(0xFF1A1A1A),
                              size: 20,
                            ),
                          ),
                          if (n > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF6B35),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    n > 9 ? '9+' : '$n',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilEtudiantScreen(user: widget.user),
                    ),
                  ),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.user.prenom[0]}${widget.user.nom[0]}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final h = DateTime.now().hour;
    final greeting = h < 12
        ? 'Bonjour'
        : h < 18
        ? 'Bon après-midi'
        : 'Bonsoir';
    final sub = h < 11
        ? 'Que prenez-vous ce matin ?'
        : h < 14
        ? 'Heure du déjeuner 🌞'
        : h < 19
        ? 'Une petite faim ?'
        : 'Le dîner est servi 🌙';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$greeting, ',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
                TextSpan(
                  text: widget.user.prenom,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const TextSpan(text: ' 👋', style: TextStyle(fontSize: 20)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 13),
          ),
        ],
      ),
    );
  }

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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('💳', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mon wallet',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      Text(
                        '${solde.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _showRecharge,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Recharger',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFFCCCCCC), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un plat...',
                  hintStyle: TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_search.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() => _search = '');
                  _searchCtrl.clear();
                },
                child: const Icon(
                  Icons.close,
                  color: Color(0xFFCCCCCC),
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── LISTE PLATS ─────────────────────────────────────────────────────────────

  Widget _buildPlatsList() {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (_mode == 'boissons') {
      return StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('plats')
            .where('disponible', isEqualTo: true)
            .snapshots(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF6B35),
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          }
          var docs = snap.data?.docs ?? [];
          docs = docs.where((d) {
            final m = d.data() as Map;
            final repas = (m['repas'] ?? '').toString().toLowerCase();
            final cat = (m['categorie'] ?? '').toString().toLowerCase();
            return repas == 'boisson' || cat == 'boissons';
          }).toList();
          if (_search.isNotEmpty) {
            docs = docs.where((d) {
              final m = d.data() as Map;
              return (m['nom'] ?? '').toString().toLowerCase().contains(
                _search,
              );
            }).toList();
          }
          if (docs.isEmpty)
            return SliverToBoxAdapter(
              child: _emptyBox('🥤', 'Aucune boisson disponible'),
            );
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((_, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                return _PlatCard(
                  platId: docs[i].id,
                  data: data,
                  user: widget.user,
                );
              }, childCount: docs.length),
            ),
          );
        },
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('menus')
          .where('date', isEqualTo: dateStr)
          .where('actif', isEqualTo: true)
          .snapshots(),
      builder: (_, menuSnap) {
        if (menuSnap.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF6B35),
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }
        if ((menuSnap.data?.docs ?? []).isEmpty) {
          return SliverToBoxAdapter(
            child: _emptyBox(
              '📋',
              'Aucun menu publié aujourd\'hui',
              sub:
                  'L\'administration n\'a pas encore publié\nle menu de la journée.',
            ),
          );
        }
        final menuData =
            menuSnap.data!.docs.first.data() as Map<String, dynamic>;
        final petitDejIds =
            (menuData['petitDej'] as List?)?.cast<String>() ?? [];
        final dejeunerIds =
            (menuData['dejeuner'] as List?)?.cast<String>() ?? [];
        final dinerIds = (menuData['diner'] as List?)?.cast<String>() ?? [];
        final allIds = {...petitDejIds, ...dejeunerIds, ...dinerIds};
        if (allIds.isEmpty)
          return SliverToBoxAdapter(
            child: _emptyBox(
              '🍽️',
              'Menu vide',
              sub: 'Aucun plat n\'a encore été ajouté au menu.',
            ),
          );

        return StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('plats')
              .where('disponible', isEqualTo: true)
              .snapshots(),
          builder: (_, platsSnap) {
            if (platsSnap.connectionState == ConnectionState.waiting)
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            final allDocs = (platsSnap.data?.docs ?? [])
                .where((d) => allIds.contains(d.id))
                .toList();
            var filtered = allDocs;
            if (_search.isNotEmpty) {
              filtered = allDocs.where((d) {
                final m = d.data() as Map;
                return (m['nom'] ?? '').toString().toLowerCase().contains(
                      _search,
                    ) ||
                    (m['description'] ?? '').toString().toLowerCase().contains(
                      _search,
                    );
              }).toList();
            }
            if (filtered.isEmpty)
              return SliverToBoxAdapter(
                child: _emptyBox('🔍', 'Aucun résultat pour "$_search"'),
              );

            final petitDejDocs = filtered
                .where((d) => petitDejIds.contains(d.id))
                .toList();
            final dejeunerDocs = filtered
                .where((d) => dejeunerIds.contains(d.id))
                .toList();
            final dinerDocs = filtered
                .where((d) => dinerIds.contains(d.id))
                .toList();

            final sections = <Map<String, dynamic>>[];
            if (petitDejDocs.isNotEmpty)
              sections.add({
                'key': 'petitDej',
                'emoji': '🌅',
                'titre': 'Petit déjeuner',
                'docs': petitDejDocs,
              });
            if (dejeunerDocs.isNotEmpty)
              sections.add({
                'key': 'dejeuner',
                'emoji': '☀️',
                'titre': 'Déjeuner',
                'docs': dejeunerDocs,
              });
            if (dinerDocs.isNotEmpty)
              sections.add({
                'key': 'diner',
                'emoji': '🌙',
                'titre': 'Dîner',
                'docs': dinerDocs,
              });

            return SliverList(
              delegate: SliverChildListDelegate([
                if (petitDejDocs.isNotEmpty)
                  _SectionCard(
                    emoji: '🌅',
                    titre: 'Petit déjeuner',
                    docs: petitDejDocs,
                    user: widget.user,
                    allSections: sections,
                    currentSection: 'petitDej',
                    db: _db,
                  ),
                if (dejeunerDocs.isNotEmpty)
                  _SectionCard(
                    emoji: '☀️',
                    titre: 'Déjeuner',
                    docs: dejeunerDocs,
                    user: widget.user,
                    allSections: sections,
                    currentSection: 'dejeuner',
                    db: _db,
                  ),
                if (dinerDocs.isNotEmpty)
                  _SectionCard(
                    emoji: '🌙',
                    titre: 'Dîner',
                    docs: dinerDocs,
                    user: widget.user,
                    allSections: sections,
                    currentSection: 'diner',
                    db: _db,
                  ),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _emptyBox(String icon, String title, {String? sub}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (sub != null) ...[
              const SizedBox(height: 6),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ONGLET COMMANDES
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCommandes() {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes commandes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Suivi en temps réel',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        NotificationsEtudiantScreen(user: widget.user),
                  ),
                ),
                child: StreamBuilder<int>(
                  stream: NotificationService.compteurNonLus(widget.user.uid),
                  builder: (_, snap) {
                    final n = snap.data ?? 0;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        if (n > 0)
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B35),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$n',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildCommandesList()),
      ],
    );
  }

  Widget _buildCommandesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('commandes')
          .where('etudiantId', isEqualTo: widget.user.uid)
          .snapshots(),
      builder: (_, snap) {
        final docs = List.from(snap.data?.docs ?? []);
        docs.sort((a, b) {
          final ta =
              ((a.data() as Map)['createdAt'] as Timestamp?)?.toDate() ??
              DateTime(0);
          final tb =
              ((b.data() as Map)['createdAt'] as Timestamp?)?.toDate() ??
              DateTime(0);
          return tb.compareTo(ta);
        });
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🛍️', style: TextStyle(fontSize: 52)),
                SizedBox(height: 14),
                Text(
                  'Aucune commande',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Explorez le menu et passez votre première commande',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 13),
                ),
              ],
            ),
          );
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
// SECTION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String emoji;
  final String titre;
  final List<QueryDocumentSnapshot> docs;
  final UserEntity user;
  final List<Map<String, dynamic>> allSections;
  final String currentSection;
  final FirebaseFirestore db;

  const _SectionCard({
    required this.emoji,
    required this.titre,
    required this.docs,
    required this.user,
    required this.allSections,
    required this.currentSection,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    final firstDoc = docs.first;
    final firstData = firstDoc.data() as Map<String, dynamic>;
    final imageUrl = firstData['imageUrl'] as String?;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => docs.length > 1
              ? _CategoriePage(
                  emoji: emoji,
                  titre: titre,
                  docs: docs,
                  user: user,
                  allSections: allSections,
                  currentSection: currentSection,
                )
              : PlatDetailScreen(
                  platId: firstDoc.id,
                  data: firstData,
                  user: user,
                ),
        ),
      ),

      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // ── Background image ──────────────────────────────────────────
              SizedBox(
                height: 200,
                width: double.infinity,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: _catColor(firstData).withOpacity(0.15),
                          child: Center(
                            child: Text(
                              _emoji(firstData),
                              style: const TextStyle(fontSize: 80),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: _catColor(firstData).withOpacity(0.15),
                        child: Center(
                          child: Text(
                            _emoji(firstData),
                            style: const TextStyle(fontSize: 80),
                          ),
                        ),
                      ),
              ),
              // ── Gradient overlay ──────────────────────────────────────────
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.75),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Titre catégorie en haut ───────────────────────────────────
              Positioned(
                top: 14,
                left: 16,
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      titre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Infos plat en bas ─────────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstData['nom'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if ((firstData['description'] as String?)?.isNotEmpty ==
                          true) ...[
                        const SizedBox(height: 3),
                        Text(
                          firstData['description'] ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${firstData['prix'] ?? 0} FCFA',
                        style: const TextStyle(
                          color: Color(0xFFFF6B35),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
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
    );
  }

  String _emoji(Map<String, dynamic> data) {
    final cat = (data['categorie'] ?? '').toString().toLowerCase();
    if (cat == 'boissons') return '🥤';
    switch (cat) {
      case 'petit_dejeuner':
        return '🌅';
      case 'dejeuner':
        return '☀️';
      case 'diner':
        return '🌙';
      default:
        return '🍽️';
    }
  }

  Color _catColor(Map<String, dynamic> data) {
    switch ((data['categorie'] ?? '').toString().toLowerCase()) {
      case 'petit_dejeuner':
        return const Color(0xFF6366F1);
      case 'dejeuner':
        return const Color(0xFF10B981);
      case 'diner':
        return const Color(0xFF8B5CF6);
      case 'boissons':
        return const Color(0xFF0EA5E9);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE CATÉGORIE
// ─────────────────────────────────────────────────────────────────────────────
class _CategoriePage extends StatefulWidget {
  final String emoji;
  final String titre;
  final List<QueryDocumentSnapshot> docs;
  final UserEntity user;
  final List<Map<String, dynamic>> allSections;
  final String currentSection;

  const _CategoriePage({
    required this.emoji,
    required this.titre,
    required this.docs,
    required this.user,
    required this.allSections,
    required this.currentSection,
  });

  @override
  State<_CategoriePage> createState() => _CategoriePageState();
}

class _CategoriePageState extends State<_CategoriePage> {
  late String _currentSection;
  late String _currentEmoji;
  late String _currentTitre;
  late List<QueryDocumentSnapshot> _currentDocs;

  @override
  void initState() {
    super.initState();
    _currentSection = widget.currentSection;
    _currentEmoji = widget.emoji;
    _currentTitre = widget.titre;
    _currentDocs = widget.docs;
  }

  void _switchSection(Map<String, dynamic> section) {
    setState(() {
      _currentSection = section['key'] as String;
      _currentEmoji = section['emoji'] as String;
      _currentTitre = section['titre'] as String;
      _currentDocs = section['docs'] as List<QueryDocumentSnapshot>;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(_currentEmoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentTitre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentDocs.length} plat${_currentDocs.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.allSections.length > 1) ...[
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.allSections.map((s) {
                        final isActive = s['key'] == _currentSection;
                        return GestureDetector(
                          onTap: () => _switchSection(s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFFF6B35)
                                  : Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFFFF6B35)
                                    : Colors.white24,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  s['emoji'] as String,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  s['titre'] as String,
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: ListView.builder(
                key: ValueKey(_currentSection),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                itemCount: _currentDocs.length,
                itemBuilder: (_, i) {
                  final doc = _currentDocs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  return _PlatCard(
                    platId: doc.id,
                    data: data,
                    user: widget.user,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _PlatCard extends StatelessWidget {
  final String platId;
  final Map<String, dynamic> data;
  final UserEntity user;

  const _PlatCard({
    required this.platId,
    required this.data,
    required this.user,
  });

  String get _emoji {
    final cat = (data['categorie'] ?? '').toString().toLowerCase();
    if (cat == 'boissons') return '🥤';
    switch (cat) {
      case 'petit_dejeuner':
        return '🌅';
      case 'dejeuner':
        return '☀️';
      case 'diner':
        return '🌙';
      default:
        return '🍽️';
    }
  }

  Color get _catColor {
    switch ((data['categorie'] ?? '').toString().toLowerCase()) {
      case 'petit_dejeuner':
        return const Color(0xFF6366F1);
      case 'dejeuner':
        return const Color(0xFF10B981);
      case 'diner':
        return const Color(0xFF8B5CF6);
      case 'boissons':
        return const Color(0xFF0EA5E9);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PlatDetailScreen(platId: platId, data: data, user: user),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── IMAGE ────────────────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: hasImage
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: _catColor.withOpacity(0.1),
                              child: Center(
                                child: Text(
                                  _emoji,
                                  style: const TextStyle(fontSize: 64),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: _catColor.withOpacity(0.08),
                            child: Center(
                              child: Text(
                                _emoji,
                                style: const TextStyle(fontSize: 64),
                              ),
                            ),
                          ),
                  ),
                  // Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.12),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Badge prix
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        '${data['prix'] ?? 0} FCFA',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── INFOS ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['nom'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((data['description'] as String?)?.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 3),
                          Text(
                            data['description'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB0B0B0),
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),
          ],
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
      case 'recue':
        return {
          'label': '⏳ Reçue',
          'bg': const Color(0xFFFEF3C7),
          'fg': const Color(0xFFD97706),
        };
      case 'en_cuisine':
        return {
          'label': '👨‍🍳 En cuisine',
          'bg': const Color(0xFFEFF6FF),
          'fg': const Color(0xFF2563EB),
        };
      case 'prete':
        return {
          'label': '🔔 Prête !',
          'bg': const Color(0xFFF0FDF4),
          'fg': const Color(0xFF16A34A),
        };
      case 'recuperee':
        return {
          'label': '✅ Livrée',
          'bg': const Color(0xFFF5F5F5),
          'fg': const Color(0xFF6B7280),
        };
      case 'annulee':
        return {
          'label': '❌ Annulée',
          'bg': const Color(0xFFFEE2E2),
          'fg': const Color(0xFFDC2626),
        };
      default:
        return {
          'label': s,
          'bg': const Color(0xFFF5F5F5),
          'fg': const Color(0xFF6B7280),
        };
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F7F4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      data['isBoisson'] == true ? '🥤' : '🍽️',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${data['numero'] ?? '—'}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        data['nomPlat'] ?? '—',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB0B0B0),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: info['bg'] as Color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        info['label'] as String,
                        style: TextStyle(
                          color: info['fg'] as Color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(data['montantTotal'] ?? 0).toStringAsFixed(0)} F',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (statut != 'annulee')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: List.generate(steps.length, (i) {
                      final done = i <= idx;
                      return Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: done
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFF0F0F0),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: done
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFDDDDDD),
                                  width: 2,
                                ),
                              ),
                              child: done
                                  ? const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            if (i < steps.length - 1)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: i < idx
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFEEEEEE),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(
                      steps.length,
                      (i) => Expanded(
                        child: Text(
                          stepLabels[i],
                          textAlign: i == 0
                              ? TextAlign.left
                              : i == steps.length - 1
                              ? TextAlign.right
                              : TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: i <= idx
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: i <= idx
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFCCCCCC),
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
}
