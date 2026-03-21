import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../presentation/providers/cart_provider.dart';
import 'cart_screen.dart';

class PlatDetailScreen extends ConsumerStatefulWidget {
  final String platId;
  final Map<String, dynamic> data;
  final UserEntity user;

  const PlatDetailScreen({
    super.key,
    required this.platId,
    required this.data,
    required this.user,
  });

  @override
  ConsumerState<PlatDetailScreen> createState() => _PlatDetailScreenState();
}

class _PlatDetailScreenState extends ConsumerState<PlatDetailScreen> {
  int _qty = 1;

  Map<String, dynamic> get d => widget.data;
  bool get _isBoisson =>
      (d['categorie'] ?? '').toString().toLowerCase() == 'boissons';
  double get _prix => (d['prix'] ?? 0).toDouble();
  double get _total => _prix * _qty;
  String? get _imageUrl => d['imageUrl'] as String?;

  String get _emoji {
    if (_isBoisson) {
      switch (d['typeBoisson'] ?? '') {
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
    switch ((d['categorie'] ?? '').toString().toLowerCase()) {
      case 'petit_dejeuner':
        return '🌅';
      case 'dejeuner':
        return '☀️';
      case 'diner':
        return '🌙';
      case 'express':
        return '🍳';
      case 'plat du jour':
        return '🍛';
      case 'entrées':
        return '🥗';
      default:
        return '🍽️';
    }
  }

  Color get _color {
    switch ((d['categorie'] ?? '').toString().toLowerCase()) {
      case 'petit_dejeuner':
        return const Color(0xFF6366F1);
      case 'dejeuner':
        return const Color(0xFF10B981);
      case 'diner':
        return const Color(0xFF8B5CF6);
      case 'express':
        return const Color(0xFFFF6B35);
      case 'plat du jour':
        return const Color(0xFF10B981);
      case 'entrées':
        return const Color(0xFF3B82F6);
      case 'boissons':
        return const Color(0xFF0EA5E9);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get _catLabel {
    switch ((d['categorie'] ?? '').toString().toLowerCase()) {
      case 'petit_dejeuner':
        return 'Petit déjeuner';
      case 'dejeuner':
        return 'Déjeuner';
      case 'diner':
        return 'Dîner';
      case 'boissons':
        return 'Boisson';
      case 'express':
        return 'Express';
      case 'plat du jour':
        return 'Plat du jour';
      case 'entrées':
        return 'Entrée';
      default:
        return d['categorie'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final alreadyInCart = cartItems.any((e) => e.platId == widget.platId);
    final cartCount = ref.read(cartProvider.notifier).nbArticles;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: Stack(
        children: [
          // ── Contenu scrollable ───────────────────────────────────────────
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroImage(),
                _buildContent(),
                const SizedBox(height: 110),
              ],
            ),
          ),

          // ── Boutons flottants ────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF1A1A1A),
                          size: 16,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CartScreen(user: widget.user),
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
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Color(0xFF1A1A1A),
                              size: 20,
                            ),
                          ),
                          if (cartCount > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF6B35),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$cartCount',
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
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom bar fixe ──────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(alreadyInCart),
          ),
        ],
      ),
    );
  }

  // ── IMAGE HERO ─────────────────────────────────────────────────────────────

  Widget _buildHeroImage() {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: _imageUrl != null && _imageUrl!.isNotEmpty
                ? Image.network(
                    _imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          // Gradient vers le bas
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFFF8F7F4).withOpacity(0.4),
                    const Color(0xFFF8F7F4),
                  ],
                  stops: const [0.5, 0.82, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: _color.withOpacity(0.1),
    child: Center(child: Text(_emoji, style: const TextStyle(fontSize: 100))),
  );

  // ── CONTENU ────────────────────────────────────────────────────────────────

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom + badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  d['nom'] ?? '',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _catLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _stat('💰', '${d['prix'] ?? 0} F', 'Prix'),
                _statDiv(),
                if (!_isBoisson) ...[
                  _stat('⏱️', '${d['tempsPreparation'] ?? 0} min', 'Prépa'),
                  _statDiv(),
                ],
                _stat('⭐', '4.9', 'Note'),
                _statDiv(),
                _stat(
                  d['disponible'] == true ? '✅' : '❌',
                  d['disponible'] == true ? 'Dispo' : 'Indispo',
                  'Statut',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Description
          if ((d['description'] as String?)?.isNotEmpty == true) ...[
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              d['description'] ?? '',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Quantité
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  'Quantité',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                _qBtn(
                  Icons.remove,
                  _qty > 1 ? () => setState(() => _qty--) : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '$_qty',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                _qBtn(Icons.add, () => setState(() => _qty++)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String emoji, String val, String label) => Expanded(
    child: Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          val,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFFB0B0B0)),
        ),
      ],
    ),
  );

  Widget _statDiv() => Container(
    width: 1,
    height: 40,
    color: const Color(0xFFEEEEEE),
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  Widget _qBtn(IconData icon, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: onTap != null
            ? const Color(0xFFFF6B35)
            : const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: onTap != null ? Colors.white : const Color(0xFFCCCCCC),
        size: 18,
      ),
    ),
  );

  // ── BOTTOM BAR ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar(bool alreadyInCart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sous-total',
                style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 11),
              ),
              Text(
                '${_total.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => _ajouterAuPanier(alreadyInCart),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 56,
                decoration: BoxDecoration(
                  color: alreadyInCart
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (alreadyInCart
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFFFF6B35))
                              .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        alreadyInCart
                            ? Icons.shopping_bag
                            : Icons.add_shopping_cart,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        alreadyInCart ? 'Voir le panier' : 'Ajouter au panier',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AJOUTER AU PANIER ───────────────────────────────────────────────────────

  void _ajouterAuPanier(bool alreadyInCart) {
    if (alreadyInCart) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CartScreen(user: widget.user)),
      );
      return;
    }

    ref
        .read(cartProvider.notifier)
        .ajouter(
          CartItem(
            platId: widget.platId,
            nom: d['nom'] ?? '',
            prix: _prix,
            emoji: _emoji,
            imageUrl: d['imageUrl'] as String?,
            categorie: d['categorie'] ?? '',
            isBoisson: _isBoisson,
            quantite: _qty,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🛒', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${d['nom']} ajouté au panier',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CartScreen(user: widget.user),
                  ),
                );
              },
              child: const Text(
                'Voir',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
