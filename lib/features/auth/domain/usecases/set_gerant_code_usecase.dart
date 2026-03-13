import '../repositories/auth_repository.dart';

class SetGerantCodeUsecase {
  final AuthRepository _repository;

  SetGerantCodeUsecase(this._repository);

  Future<void> call(String code) async {
    await _repository.setGerantCode(code);
  }
}
