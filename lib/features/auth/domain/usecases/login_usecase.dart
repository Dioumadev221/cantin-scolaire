import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUsecase {
  final AuthRepository _repository;

  LoginUsecase(this._repository);

  Future<UserEntity> call(String email, String password) async {
    return await _repository.login(email, password);
  }
}
