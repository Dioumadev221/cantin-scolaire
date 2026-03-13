import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class InscriptionUsecase {
  final AuthRepository _repository;

  InscriptionUsecase(this._repository);

  Future<UserEntity> call(
    String nom,
    String prenom,
    String email,
    String password,
  ) async {
    return await _repository.inscription(nom, prenom, email, password);
  }
}
