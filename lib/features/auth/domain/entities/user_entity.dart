class UserEntity {
  final String uid;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final double soldeWallet;

  const UserEntity({
    required this.uid,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.soldeWallet = 0.0,
  });
}
