import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> inscription(
    String nom,
    String prenom,
    String email,
    String password,
  );
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
}
