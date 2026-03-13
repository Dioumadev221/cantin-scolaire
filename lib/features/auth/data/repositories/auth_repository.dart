import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource = AuthRemoteDatasource();

  @override
  Future<UserEntity> login(String email, String password) async {
    return await _datasource.login(email, password);
  }

  @override
  Future<UserEntity> inscription(
    String nom,
    String prenom,
    String email,
    String password,
    String role,
  ) async {
    return await _datasource.inscription(nom, prenom, email, password, role);
  }

  @override
  Future<void> logout() async {
    await _datasource.logout();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return await _datasource.getCurrentUser();
  }

  @override
  Future<bool> validateGerantCode(String code) async {
    return await _datasource.validateGerantCode(code);
  }

  @override
  Future<void> setGerantCode(String code) async {
    await _datasource.setGerantCode(code);
  }
}
