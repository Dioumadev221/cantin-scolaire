import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/entities/user_entity.dart';

/// Service d'authentification Google.
///
/// Retourne un [UserEntity] existant ou crée un nouveau document
/// dans /users avec le rôle 'etudiant' pour les nouveaux comptes.
class GoogleAuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // ── Remplacez cette valeur par votre vrai Web Client ID ────────────────────
  // Console Firebase → Authentication → Sign-in method → Google → Web SDK configuration
  // OU Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 Client ID (type Web)
  static const _webClientId =
      '980873062065-h58t8df5fg0fu9pdqcg5vn15luhhh50u.apps.googleusercontent.com';
  // ──────────────────────────────────────────────────────────────────────────

  static GoogleSignIn get _googleSignIn => GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    // Pas de scope 'profile' → évite l'appel à People API
    scopes: ['email'],
  );

  /// Lance le flux Google Sign-In et retourne le [UserEntity] correspondant.
  static Future<UserEntity> signIn() async {
    // 1. Ouvrir le sélecteur de compte Google
    final googleAccount = await _googleSignIn.signIn();
    if (googleAccount == null) {
      throw Exception('Connexion Google annulée');
    }

    // 2. Obtenir les tokens
    final googleAuth = await googleAccount.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 3. Connexion Firebase
    final result = await _auth.signInWithCredential(credential);
    final firebaseUser = result.user!;

    // 4. Vérifier / créer le document Firestore
    final userDoc = await _db.collection('users').doc(firebaseUser.uid).get();

    if (!userDoc.exists) {
      final nameParts = (firebaseUser.displayName ?? '').split(' ');
      final prenom = nameParts.isNotEmpty ? nameParts.first : '';
      final nom = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await _db.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'nom': nom,
        'prenom': prenom,
        'role': 'etudiant',
        'soldeWallet': 0.0,
        'photoUrl': firebaseUser.photoURL ?? '',
        'notificationsActivees': true,
        'provider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return UserEntity(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        nom: nom,
        prenom: prenom,
        role: 'etudiant',
      );
    }

    final data = userDoc.data()!;
    return UserEntity(
      uid: firebaseUser.uid,
      email: data['email'] ?? firebaseUser.email ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      role: data['role'] ?? 'etudiant',
    );
  }

  /// Déconnexion
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
