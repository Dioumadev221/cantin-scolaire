import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Chercher le document dans Firestore
    final doc = await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .get();

    // Si le document n'existe pas encore → on le crée
    if (!doc.exists) {
      final user = UserModel(
        uid: credential.user!.uid,
        nom: '',
        prenom: '',
        email: email,
        role: 'etudiant',
        soldeWallet: 0.0,
      );
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toFirestore());
      return user;
    }

    return UserModel.fromFirestore(doc);
  }

  Future<UserModel> inscription(
    String nom,
    String prenom,
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = UserModel(
        uid: credential.user!.uid,
        nom: nom,
        prenom: prenom,
        email: email,
        role: 'etudiant',
        soldeWallet: 0.0,
      );
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toFirestore());
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      // Auth créé mais Firestore a échoué
      // On retourne quand même l'utilisateur
      final user = UserModel(
        uid: _auth.currentUser!.uid,
        nom: nom,
        prenom: prenom,
        email: email,
        role: 'etudiant',
        soldeWallet: 0.0,
      );
      return user;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return UserModel.fromFirestore(doc);
  }
}
