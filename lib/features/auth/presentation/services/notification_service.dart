import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// NotificationService — champs Firestore : lu, titre, corps, type, userId,
/// targetRole, commandeId, commandeNumero, createdAt.
///
/// Méthodes exposées (noms français pour correspondre à NotificationsScreen) :
///   streamNonLues(uid)       → Stream<QuerySnapshot>  notifications non lues
///   streamToutes(uid)        → Stream<QuerySnapshot>  toutes notifications
///   streamGerantNonLues()    → Stream<QuerySnapshot>  non lues gérant
///   streamToutes_gerant()    → Stream<QuerySnapshot>  toutes notifs gérant
///   marquerLue(id)           → Future<void>
///   marquerToutesLues(uid)   → Future<void>
///   marquerToutesLuesGerant()→ Future<void>
///   supprimer(id)            → Future<void>
///   creer(...)               → Future<void>            (alias : create)
///   notifierStatutCommande() → Future<void>
///   notifierNouvelleCommande()→Future<void>
///   timeAgo(ts)              → String
///   iconForType(type, titre) → String
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final _db = FirebaseFirestore.instance;

  // ──────────────────────────────────────────────────────────────────────────
  // INIT FCM
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> initialize(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
          alert: true, badge: true, sound: true);
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (token != null) await _saveToken(uid, token);
        messaging.onTokenRefresh.listen((t) => _saveToken(uid, t));
      }
    } catch (_) {
      // FCM peut échouer en émulateur — on ignore
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({
      'fcmToken': token,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CRÉER UNE NOTIFICATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Crée un document dans /notifications.
  /// [userId]     → étudiant destinataire (null si broadcast gérant)
  /// [targetRole] → 'gerant_cantine' pour broadcast
  static Future<void> creer({
    String? userId,
    String? targetRole,
    required String titre,
    required String corps,
    required String type,    // 'commande_status' | 'nouvelle_commande' | 'wallet' | 'systeme'
    String? commandeId,
    String? commandeNumero,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'targetRole': targetRole,
      'titre': titre,
      'corps': corps,
      'type': type,
      'commandeId': commandeId,
      'commandeNumero': commandeNumero,
      'lu': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Alias anglais pour compatibilité
  static Future<void> create({
    String? userId,
    String? targetRole,
    required String titre,
    required String corps,
    required String type,
    String? commandeId,
    String? commandeNumero,
  }) => creer(
      userId: userId, targetRole: targetRole,
      titre: titre, corps: corps, type: type,
      commandeId: commandeId, commandeNumero: commandeNumero);

  // ──────────────────────────────────────────────────────────────────────────
  // NOTIFICATIONS PRÊTES À L'EMPLOI
  // ──────────────────────────────────────────────────────────────────────────

  /// Notifie l'étudiant quand son statut de commande change.
  static Future<void> notifierStatutCommande({
    required String etudiantId,
    required String commandeId,
    required String commandeNumero,
    required String nouveauStatut,
    required String nomPlat,
  }) async {
    String titre;
    String corps;
    switch (nouveauStatut) {
      case 'en_cuisine':
        titre = '👨‍🍳 Commande en préparation';
        corps = 'Votre commande #$commandeNumero ($nomPlat) est en cours de préparation.';
        break;
      case 'prete':
        titre = '🔔 Commande prête !';
        corps = 'Votre commande #$commandeNumero est prête. Venez la récupérer !';
        break;
      case 'recuperee':
        titre = '✅ Bonne dégustation !';
        corps = 'Commande #$commandeNumero récupérée. Bon appétit !';
        break;
      case 'annulee':
        titre = '❌ Commande annulée';
        corps = 'Votre commande #$commandeNumero a été annulée. Montant remboursé.';
        break;
      default:
        return;
    }
    await creer(
      userId: etudiantId,
      titre: titre,
      corps: corps,
      type: 'commande_status',
      commandeId: commandeId,
      commandeNumero: commandeNumero,
    );
  }

  /// Alias anglais
  static Future<void> notifyStatutCommande({
    required String etudiantId,
    required String commandeId,
    required String commandeNumero,
    required String nouveauStatut,
    required String nomPlat,
  }) => notifierStatutCommande(
      etudiantId: etudiantId, commandeId: commandeId,
      commandeNumero: commandeNumero, nouveauStatut: nouveauStatut,
      nomPlat: nomPlat);

  /// Notifie tous les gérants d'une nouvelle commande.
  static Future<void> notifierNouvelleCommande({
    required String commandeId,
    required String commandeNumero,
    required String etudiantNom,
    required String nomPlat,
  }) async {
    await creer(
      targetRole: 'gerant_cantine',
      titre: '📦 Nouvelle commande #$commandeNumero',
      corps: '$etudiantNom a commandé : $nomPlat',
      type: 'nouvelle_commande',
      commandeId: commandeId,
      commandeNumero: commandeNumero,
    );
  }

  /// Alias anglais
  static Future<void> notifyNouvelleCommande({
    required String commandeId,
    required String commandeNumero,
    required String etudiantNom,
    required String nomPlat,
  }) => notifierNouvelleCommande(
      commandeId: commandeId, commandeNumero: commandeNumero,
      etudiantNom: etudiantNom, nomPlat: nomPlat);

  // ──────────────────────────────────────────────────────────────────────────
  // STREAMS — ÉTUDIANT
  // ──────────────────────────────────────────────────────────────────────────

  /// Toutes les notifications d'un étudiant (triées côté client)
  static Stream<QuerySnapshot> streamToutes(String uid) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map(_sortedSnap);
  }

  /// Notifications non lues d'un étudiant
  static Stream<QuerySnapshot> streamNonLues(String uid) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('lu', isEqualTo: false)
        .snapshots();
  }

  /// Compteur non lus — Stream<int>
  static Stream<int> compteurNonLus(String uid) =>
      streamNonLues(uid).map((s) => s.docs.length);

  // ──────────────────────────────────────────────────────────────────────────
  // STREAMS — GÉRANT
  // ──────────────────────────────────────────────────────────────────────────

  /// Toutes les notifications gérant (broadcast par rôle)
  static Stream<QuerySnapshot> streamToutesGerant() {
    return _db
        .collection('notifications')
        .where('targetRole', isEqualTo: 'gerant_cantine')
        .snapshots()
        .map(_sortedSnap);
  }

  /// Non lues gérant
  static Stream<QuerySnapshot> streamGerantNonLues() {
    return _db
        .collection('notifications')
        .where('targetRole', isEqualTo: 'gerant_cantine')
        .where('lu', isEqualTo: false)
        .snapshots();
  }

  /// Compteur non lus gérant — Stream<int>
  static Stream<int> compteurNonLusGerant() =>
      streamGerantNonLues().map((s) => s.docs.length);

  // ──────────────────────────────────────────────────────────────────────────
  // ACTIONS
  // ──────────────────────────────────────────────────────────────────────────

  static Future<void> marquerLue(String id) async =>
      _db.collection('notifications').doc(id).update({'lu': true});

  static Future<void> marquerToutesLues(String uid) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('lu', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) batch.update(doc.reference, {'lu': true});
    await batch.commit();
  }

  static Future<void> marquerToutesLuesGerant() async {
    final snap = await _db
        .collection('notifications')
        .where('targetRole', isEqualTo: 'gerant_cantine')
        .where('lu', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) batch.update(doc.reference, {'lu': true});
    await batch.commit();
  }

  static Future<void> supprimer(String id) async =>
      _db.collection('notifications').doc(id).delete();

  // ──────────────────────────────────────────────────────────────────────────
  // HELPERS D'AFFICHAGE
  // ──────────────────────────────────────────────────────────────────────────

  static String timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    final d = ts.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  static String iconForType(String type, [String titre = '']) {
    // Priorité aux emojis dans le titre
    for (final e in ['🔔', '👨‍🍳', '✅', '❌', '💰', '📦', '🎉', '⚙️']) {
      if (titre.startsWith(e)) return e;
    }
    switch (type) {
      case 'commande_status': return '📦';
      case 'nouvelle_commande': return '🛒';
      case 'wallet': return '💰';
      case 'systeme': return '⚙️';
      default: return '🔔';
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PRIVATE
  // ──────────────────────────────────────────────────────────────────────────

  /// Trie un QuerySnapshot par createdAt décroissant côté client
  /// (évite l'obligation de créer un index composite Firestore)
  static QuerySnapshot _sortedSnap(QuerySnapshot snap) {
    final docs = List<QueryDocumentSnapshot>.from(snap.docs);
    docs.sort((a, b) {
      final ta = ((a.data() as Map)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      final tb = ((b.data() as Map)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      return tb.compareTo(ta);
    });
    return _SortedQuerySnapshot(snap, docs);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// QuerySnapshot wrapper pour le tri client-side
// ────────────────────────────────────────────────────────────────────────────
class _SortedQuerySnapshot implements QuerySnapshot {
  final QuerySnapshot _original;
  @override
  final List<QueryDocumentSnapshot> docs;

  _SortedQuerySnapshot(this._original, this.docs);

  @override
  List<DocumentChange> get docChanges => _original.docChanges;

  @override
  SnapshotMetadata get metadata => _original.metadata;

  @override
  int get size => docs.length;
}