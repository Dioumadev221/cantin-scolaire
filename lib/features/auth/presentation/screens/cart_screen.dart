import 'package:cantine_scolaire/features/auth/presentation/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../presentation/providers/cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  final UserEntity user;
  const CartScreen({super.key, required this.user});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _loading = false;
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: Column(children: [
        _buildHeader(context, items),
        Expanded(
          child: items.isEmpty
              ? _buildEmpty(context)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  children: [
                    ...items.map((item) => _ItemCard(
                          item: item,
                          onIncrement: () => cart.setQuantite(
                              item.platId, item.quantite + 1),
                          onDecrement: () => cart.setQuantite(
                              item.platId, item.quantite - 1),
                          onRemove: () => cart.retirer(item.platId),
                        )),
                    const SizedBox(height: 14),
                    _buildSummary(items, cart.total),
                    const SizedBox(height: 100),
                  ],
                ),
        ),
        if (items.isNotEmpty) _buildCheckoutBar(items, cart),
      ]),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, List<CartItem> items) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 22),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white12,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Mon panier', style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            Text('${items.length} article${items.length > 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
        if (items.isNotEmpty)
          GestureDetector(
            onTap: () => _confirmVider(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white10,
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('Vider', style: TextStyle(
                  color: Colors.white60, fontSize: 12,
                  fontWeight: FontWeight.w600)),
            ),
          ),
      ]),
    );
  }

  // ── EMPTY ────────────────────────────────────────────────────────────────────

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 100, height: 100,
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(28)),
          child: const Center(
              child: Text('🛒', style: TextStyle(fontSize: 48)))),
        const SizedBox(height: 20),
        const Text('Panier vide', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        const Text('Ajoutez des plats depuis le menu\npour passer commande',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 13)),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(16)),
            child: const Text('Voir le menu', style: TextStyle(
                color: Colors.white, fontSize: 14,
                fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }

  // ── RÉCAP ────────────────────────────────────────────────────────────────────

  Widget _buildSummary(List<CartItem> items, double total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(children: [
        const Row(children: [
          Text('Récapitulatif', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A))),
        ]),
        const SizedBox(height: 14),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Text(item.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(child: Text(item.nom,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B6B6B)))),
            Text('×${item.quantite}', style: const TextStyle(
                fontSize: 12, color: Color(0xFFB0B0B0))),
            const SizedBox(width: 12),
            Text('${item.sousTotal.toStringAsFixed(0)} F',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A))),
          ]),
        )),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: Color(0xFFF0F0F0)),
        ),
        Row(children: [
          const Text('Total', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A))),
          const Spacer(),
          Text('${total.toStringAsFixed(0)} FCFA', style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900,
              color: Color(0xFFFF6B35))),
        ]),
        const SizedBox(height: 10),
        // Indicateur solde
        StreamBuilder<DocumentSnapshot>(
          stream: _db.collection('users').doc(widget.user.uid).snapshots(),
          builder: (_, snap) {
            final solde =
                (snap.data?.data() as Map?)?['soldeWallet']?.toDouble() ?? 0;
            final ok = solde >= total;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: ok
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(
                  ok
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_outlined,
                  size: 16,
                  color: ok
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ok
                        ? 'Solde suffisant · ${solde.toStringAsFixed(0)} FCFA disponible'
                        : 'Solde insuffisant · ${solde.toStringAsFixed(0)} FCFA disponible',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: ok
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626)),
                  ),
                ),
              ]),
            );
          },
        ),
      ]),
    );
  }

  // ── BARRE COMMANDE ────────────────────────────────────────────────────────────

  Widget _buildCheckoutBar(List<CartItem> items, CartNotifier cart) {
    final total = cart.total;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20, offset: const Offset(0, -6))],
      ),
      child: GestureDetector(
        onTap: _loading ? null : () => _passerCommande(items, total),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 56,
          decoration: BoxDecoration(
            color: _loading
                ? const Color(0xFFCCCCCC)
                : const Color(0xFFFF6B35),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_loading)
              const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
            else ...[
              const Icon(Icons.shopping_bag_outlined,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Text('Passer la commande', style: TextStyle(
                  color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${total.toStringAsFixed(0)} F',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  // ── PASSER LA COMMANDE (UNE SEULE commande groupée) ──────────────────────────

  Future<void> _passerCommande(List<CartItem> items, double total) async {
    setState(() => _loading = true);

    try {
      // Vérifier le solde
      final userDoc =
          await _db.collection('users').doc(widget.user.uid).get();
      final solde =
          (userDoc.data()?['soldeWallet'] ?? 0).toDouble();

      if (solde < total) {
        if (mounted) {
          setState(() => _loading = false);
          _snack(
              'Solde insuffisant (${solde.toStringAsFixed(0)} FCFA disponible)',
              error: true);
        }
        return;
      }

      // Numéro unique pour la commande groupée
      final numero =
          'CMD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // Statut global : si au moins un plat (non boisson), statut = recue
      // Si tout est boisson, statut = prete
      final toutBoisson = items.every((i) => i.isBoisson);

      // Construire la liste détaillée des articles
      final platsDetails = items
          .map((i) => {
                'platId': i.platId,
                'nom': i.nom,
                'emoji': i.emoji,
                'prix': i.prix,
                'quantite': i.quantite,
                'sousTotal': i.sousTotal,
                'isBoisson': i.isBoisson,
              })
          .toList();

      // Résumé lisible : "Riz + Thiebou + Jus"
      final resumePlats = items.length == 1
          ? items.first.nom
          : items.map((i) => i.nom).join(' + ');

      // Créer la commande unique
      final commandeRef = await _db.collection('commandes').add({
        'numero': numero,
        'etudiantId': widget.user.uid,
        'etudiantNom': '${widget.user.prenom} ${widget.user.nom}',
        // Compatibilité ancienne structure
        'platsIds': items.map((i) => i.platId).toList(),
        'nomPlat': resumePlats,
        // Nouveau champ : liste complète des articles
        'platsDetails': platsDetails,
        'nbArticles': items.fold<int>(0, (s, i) => s + i.quantite),
        'montantTotal': total,
        'modePaiement': 'wallet',
        'statut': toutBoisson ? 'prete' : 'recue',
        'isBoisson': toutBoisson,
        'notifEnvoyee': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Débiter le wallet
      await _db.collection('users').doc(widget.user.uid).update({
        'soldeWallet': FieldValue.increment(-total),
      });

      // Notifier les gérants (une seule notification groupée)
      await NotificationService.notifierNouvelleCommande(
        commandeId: commandeRef.id,
        commandeNumero: numero,
        etudiantNom: '${widget.user.prenom} ${widget.user.nom}',
        nomPlat: resumePlats,
      );

      // Vider le panier
      ref.read(cartProvider.notifier).vider();

      if (mounted) {
        Navigator.pop(context);
        _snack('Commande #$numero passée avec succès 🎉');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('Erreur : $e', error: true);
      }
    }
  }

  // ── VIDER CONFIRM ────────────────────────────────────────────────────────────

  void _confirmVider() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Vider le panier ?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Tous les articles seront retirés.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              ref.read(cartProvider.notifier).vider();
              Navigator.pop(context);
            },
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          error ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ITEM CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _ItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.platId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(18)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child:
            const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12, offset: const Offset(0, 4))]),
        child: Row(children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
                color: const Color(0xFFF8F7F4),
                borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(item.emoji,
                style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.nom, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('${item.prix.toStringAsFixed(0)} FCFA / unité',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFFB0B0B0))),
            const SizedBox(height: 8),
            Row(children: [
              _qBtn(Icons.remove, onDecrement,
                  item.quantite > 1
                      ? const Color(0xFFFF6B35)
                      : const Color(0xFFEEEEEE)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('${item.quantite}', style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A)))),
              _qBtn(Icons.add, onIncrement,
                  const Color(0xFFFF6B35)),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${item.sousTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A))),
            const Text('FCFA', style: TextStyle(
                fontSize: 10, color: Color(0xFFB0B0B0))),
          ]),
        ]),
      ),
    );
  }

  Widget _qBtn(IconData icon, VoidCallback onTap, Color color) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: color),
        ),
      );
}