import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> envoyer({
    required String destinataireId,
    required String titre,
    required String corps,
    String type = 'commande',
    String? commandeId,
    String? commandeNumero,
  }) async {
    await _db.collection('notifications').add({
      'destinataireId': destinataireId,
      'titre': titre,
      'corps': corps,
      'type': type,
      'commandeId': commandeId,
      'commandeNumero': commandeNumero,
      'lu': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> notifierChangementStatut({
    required String etudiantId,
    required String numero,
    required String commandeId,
    required String nouveauStatut,
  }) async {
    String titre;
    String corps;
    switch (nouveauStatut) {
      case 'en_cuisine':
        titre = '👨‍🍳 Commande en préparation';
        corps = 'Votre commande $numero est en cours de préparation.';
        break;
      case 'prete':
        titre = '🔔 Commande prête !';
        corps = 'Votre commande $numero est prête, venez la récupérer !';
        break;
      case 'recuperee':
        titre = '✅ Commande récupérée';
        corps = 'Merci ! Bonne dégustation. ($numero)';
        break;
      case 'annulee':
        titre = '❌ Commande annulée';
        corps = 'Votre commande $numero a été annulée. Montant remboursé.';
        break;
      default:
        return;
    }
    await envoyer(
      destinataireId: etudiantId,
      titre: titre,
      corps: corps,
      type: 'commande',
      commandeId: commandeId,
      commandeNumero: numero,
    );
  }

  static Stream<QuerySnapshot> streamToutes(String userId) {
    return _db
        .collection('notifications')
        .where('destinataireId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> streamNonLues(String userId) {
    return _db
        .collection('notifications')
        .where('destinataireId', isEqualTo: userId)
        .where('lu', isEqualTo: false)
        .snapshots();
  }

  static Future<void> marquerLue(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({'lu': true});
  }

  static Future<void> marquerToutesLues(String userId) async {
    final batch = _db.batch();
    final snap = await _db
        .collection('notifications')
        .where('destinataireId', isEqualTo: userId)
        .where('lu', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'lu': true});
    }
    await batch.commit();
  }

  static Future<void> supprimer(String notifId) async {
    await _db.collection('notifications').doc(notifId).delete();
  }
}