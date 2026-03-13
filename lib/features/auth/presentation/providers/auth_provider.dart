import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/inscription_usecase.dart';

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
  });

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUsecase _loginUsecase;
  final InscriptionUsecase _inscriptionUsecase;

  AuthNotifier(this._loginUsecase, this._inscriptionUsecase)
    : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _loginUsecase(email, password);
      state = state.copyWith(user: user, isLoading: false, isLoggedIn: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Email ou mot de passe incorrect',
        isLoggedIn: false,
      );
    }
  }

  Future<void> inscription(
    String nom,
    String prenom,
    String email,
    String password,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _inscriptionUsecase(nom, prenom, email, password);
      state = state.copyWith(user: user, isLoading: false, isLoggedIn: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'inscription',
      );
    }
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = AuthRepositoryImpl();
  return AuthNotifier(LoginUsecase(repo), InscriptionUsecase(repo));
});
