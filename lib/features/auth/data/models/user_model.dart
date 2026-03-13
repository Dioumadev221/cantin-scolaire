import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.role,
    super.soldeWallet,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'etudiant',
      soldeWallet: (data['soldeWallet'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'role': role,
    'soldeWallet': soldeWallet,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
