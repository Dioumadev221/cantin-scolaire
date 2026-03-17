import 'package:cantine_scolaire/features/auth/presentation/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/entities/user_entity.dart';

class PlatDetailScreen extends StatefulWidget {
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
  State<PlatDetailScreen> createState() => _PlatDetailScreenState();
}

class _PlatDetailScreenState extends State<PlatDetailScreen> {
  int _qty = 1;
  bool _isLoading = false;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> get _data => widget.data;
  bool get _isBoisson =>
      (_data['categorie'] ?? '').toString().toLowerCase() == 'boissons';

  String get _emoji {
    if (_isBoisson) {
      switch (_data['typeBoisson'] ?? '') {
        case 'cafe': return '☕';
        case 'the': return '🍵';
        case 'jus': return '🍊';
        case 'eau': return '💧';
        case 'lait': return '🥛';
        default: return '🥤';
      }
    }
    switch ((_data['categorie'] ?? '').toLowerCase()) {
      case 'express': return '🍳';
      case 'plat du jour': return '🍛';
      case 'entrées': return '🥗';
      default: return '🍽️';
    }
  }

  double get _prix => (_data['prix'] ?? 0).toDouble();
  double get _total => _prix * _qty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: Column(
        children: [
          _buildHero(),
          Expanded(child: _buildContent()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── HERO ───────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // Orange blob
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6B35).withOpacity(0.4),
                    const Color(0xFFFF6B35).withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 52,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          // Favorite button
          Positioned(
            top: 52,
            right: 20,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.favorite_border,
                  color: Colors.white, size: 20),
            ),
          ),
          // Food emoji
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(_emoji, style: const TextStyle(fontSize: 110)),
            ),
          ),
          // Name overlay
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Text(
              _data['nom'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CONTENT ─────────────────────────────────────────────────────────────────

  Widget _buildContent() {
    final temps = _data['tempsPreparation'] ?? 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantité + Stats
          Row(
            children: [
              // Quantity selector
              _buildQtySelector(),
              const Spacer(),
              // Mini stats
              if (!_isBoisson) ...[
                _buildStat('⏱️', '${temps}min', 'Temps'),
                const SizedBox(width: 14),
              ],
              _buildStat('⭐', '4.9', 'Note'),
              const SizedBox(width: 14),
              _buildStat('🏷️',
                  _isBoisson
                      ? (_data['typeBoisson'] ?? '—')
                      : (_data['categorie'] ?? '—'),
                  'Type'),
            ],
          ),
          const SizedBox(height: 20),
          // Description
          const Text('Description',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Text(
            (_data['description'] as String?)?.isNotEmpty == true
                ? _data['description']
                : 'Un délice préparé avec soin par nos cuisiniers. '
                    'Savoureux, équilibré et plein de saveurs.',
            style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                height: 1.6),
          ),
          const SizedBox(height: 20),
          // Infos box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFEDEDED), width: 0.5),
            ),
            child: Row(
              children: [
                _buildInfoItem(
                    '💰',
                    '${_data['prix'] ?? 0} F',
                    'Prix unitaire'),
                _buildInfoDivider(),
                _buildInfoItem(
                    _isBoisson ? '🥤' : '🍽️',
                    _isBoisson ? 'Boisson' : 'Plat',
                    'Catégorie'),
                _buildInfoDivider(),
                _buildInfoItem(
                    '✅',
                    (_data['disponible'] == true)
                        ? 'Dispo'
                        : 'Indispo',
                    'Statut'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtySelector() {
    return Row(
      children: [
        GestureDetector(
          onTap: _qty > 1 ? () => setState(() => _qty--) : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _qty > 1
                  ? const Color(0xFFFF6B35)
                  : const Color(0xFFEDEDED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.remove,
                color: _qty > 1 ? Colors.white : const Color(0xFFCCCCCC),
                size: 18),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('$_qty',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        GestureDetector(
          onTap: () => setState(() => _qty++),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.add, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A))),
        Text(label,
            style: const TextStyle(
                fontSize: 9, color: Color(0xFF8A8A8A))),
      ],
    );
  }

  Widget _buildInfoItem(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF8A8A8A))),
        ],
      ),
    );
  }

  Widget _buildInfoDivider() => Container(
        width: 0.5, height: 48, color: const Color(0xFFEDEDED));

  // ── BOTTOM BAR ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: Color(0xFFEDEDED), width: 0.5)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Total',
                  style: TextStyle(
                      color: Color(0xFF8A8A8A), fontSize: 11)),
              Text('${_total.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  )),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : _commander,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8C5A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Ajouter au panier',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
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

  // ── COMMANDER ──────────────────────────────────────────────────────────────

  Future<void> _commander() async {
    setState(() => _isLoading = true);

    try {
      // Vérification du solde
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.user.uid)
          .get();
      final solde = (userDoc.data()?['soldeWallet'] ?? 0).toDouble();
      if (solde < _total) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnack('Solde insuffisant (${solde.toStringAsFixed(0)} FCFA disponible)',
              isError: true);
        }
        return;
      }

      // Numéro commande
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final numero = 'CMD${timestamp.toString().substring(7)}';

      // Créer la commande
      final commandeRef = await _firestore.collection('commandes').add({
        'numero': numero,
        'etudiantId': widget.user.uid,
        'etudiantNom': '${widget.user.prenom} ${widget.user.nom}',
        'platsIds': [widget.platId],
        'nomPlat': _data['nom'] ?? '',
        'quantite': _qty,
        'montantTotal': _total,
        'modePaiement': 'wallet',
        'statut': _isBoisson ? 'prete' : 'recue',
        'isBoisson': _isBoisson,
        'notifEnvoyee': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Débiter le wallet
      await _firestore.collection('users').doc(widget.user.uid).update({
        'soldeWallet': FieldValue.increment(-_total),
      });

      // Notification au gérant
      await NotificationService.notifyNouvelleCommande(
        commandeId: commandeRef.id,
        commandeNumero: numero,
        etudiantNom: '${widget.user.prenom} ${widget.user.nom}',
        nomPlat: _data['nom'] ?? '',
      );

      if (mounted) {
        Navigator.pop(context);
        _showSnack('✅ Commande #$numero passée avec succès !');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Erreur lors de la commande', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }
}