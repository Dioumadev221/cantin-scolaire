import '../repositories/auth_repository.dart';

class ValidateGerantCodeUsecase {
  final AuthRepository _repository;

  ValidateGerantCodeUsecase(this._repository);

  Future<bool> call(String code) async {
    return await _repository.validateGerantCode(code);
  }
}
