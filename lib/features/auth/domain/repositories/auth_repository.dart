import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> inscription(
    String nom,
    String prenom,
    String email,
    String password,
    String role,
  );
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();

  /// Vérifie si le code fourni correspond au code actuel pour la création de gérants.
  Future<bool> validateGerantCode(String code);

  /// Définit le code partagé pour la création de gérants (réservé à l'administrateur).
  Future<void> setGerantCode(String code);
}
