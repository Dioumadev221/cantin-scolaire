import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODÈLE
// ─────────────────────────────────────────────────────────────────────────────
class CartItem {
  final String platId;
  final String nom;
  final double prix;
  final String emoji;
  final String categorie;
  final bool isBoisson;
  int quantite;

  CartItem({
    required this.platId,
    required this.nom,
    required this.prix,
    required this.emoji,
    required this.categorie,
    required this.isBoisson,
    this.quantite = 1,
  });

  double get sousTotal => prix * quantite;

  CartItem copyWith({int? quantite}) => CartItem(
        platId: platId,
        nom: nom,
        prix: prix,
        emoji: emoji,
        categorie: categorie,
        isBoisson: isBoisson,
        quantite: quantite ?? this.quantite,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  // Ajouter ou incrémenter
  void ajouter(CartItem item) {
    final index = state.indexWhere((e) => e.platId == item.platId);
    if (index >= 0) {
      final updated = List<CartItem>.from(state);
      updated[index] = updated[index].copyWith(
          quantite: updated[index].quantite + item.quantite);
      state = updated;
    } else {
      state = [...state, item];
    }
  }

  // Modifier la quantité d'un item
  void setQuantite(String platId, int quantite) {
    if (quantite <= 0) {
      retirer(platId);
      return;
    }
    state = state
        .map((e) => e.platId == platId ? e.copyWith(quantite: quantite) : e)
        .toList();
  }

  // Retirer un item
  void retirer(String platId) {
    state = state.where((e) => e.platId != platId).toList();
  }

  // Vider le panier
  void vider() => state = [];

  // Total
  double get total =>
      state.fold(0, (sum, item) => sum + item.sousTotal);

  // Nombre total d'articles
  int get nbArticles =>
      state.fold(0, (sum, item) => sum + item.quantite);
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────
final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(),
);  