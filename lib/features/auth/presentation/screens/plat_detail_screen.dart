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
      case 'express':
        return const Color(0xFFFF6B35);
      case 'plat du jour':
        return const Color(0xFF10B981);
      case 'entrées':
        return const Color(0xFF3B82F6);
      case 'boissons':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final alreadyInCart = cartItems.any((e) => e.platId == widget.platId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: Column(
        children: [
          _buildHero(cartItems.length),
          Expanded(child: _buildBody()),
          _buildBottomBar(alreadyInCart),
        ],
      ),
    );
  }

  // ── HERO ───────────────────────────────────────────────────────────────────

  Widget _buildHero(int cartCount) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F7F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF1A1A1A),
                        size: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      d['nom'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Bouton panier avec badge
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F7F4),
                            borderRadius: BorderRadius.circular(12),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: Center(
                    child: Text(_emoji, style: const TextStyle(fontSize: 64)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BODY ─────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  d['nom'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _isBoisson ? 'Boisson' : (d['categorie'] ?? ''),
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
          Row(
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
                '✅',
                d['disponible'] == true ? 'Dispo' : 'Indispo',
                'Statut',
              ),
            ],
          ),
          const SizedBox(height: 20),
          if ((d['description'] as String?)?.isNotEmpty == true) ...[
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              d['description'] ?? '',
              style: const TextStyle(
                color: Color(0xFF8A8A8A),
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Sélecteur quantité
          Row(
            children: [
              const Text(
                'Quantité',
                style: TextStyle(
                  fontSize: 14,
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
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              _qBtn(Icons.add, () => setState(() => _qty++)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String emoji, String val, String label) => Expanded(
    child: Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
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
      width: 38,
      height: 38,
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total
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
          // Bouton ajouter au panier
          Expanded(
            child: GestureDetector(
              onTap: () => _ajouterAuPanier(alreadyInCart),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 54,
                decoration: BoxDecoration(
                  color: alreadyInCart
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(18),
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
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        alreadyInCart ? 'Voir le panier' : 'Ajouter au panier',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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
      // Naviguer directement vers le panier
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
            categorie: d['categorie'] ?? '',
            isBoisson: _isBoisson,
            quantite: _qty,
          ),
        );

    // Feedback visuel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🛒', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${d['nom']} ajouté au panier',
                style: const TextStyle(fontWeight: FontWeight.w600),
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
