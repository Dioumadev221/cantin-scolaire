import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/inscription_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/set_gerant_code_usecase.dart';
import '../../domain/usecases/validate_gerant_code_usecase.dart';

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
  final LogoutUsecase _logoutUsecase;
  final ValidateGerantCodeUsecase _validateGerantCodeUsecase;
  final SetGerantCodeUsecase _setGerantCodeUsecase;

  AuthNotifier(
    this._loginUsecase,
    this._inscriptionUsecase,
    this._logoutUsecase,
    this._validateGerantCodeUsecase,
    this._setGerantCodeUsecase,
  ) : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _loginUsecase(email, password);
      state = state.copyWith(user: user, isLoading: false, isLoggedIn: true);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Aucun compte trouvé avec cet email';
          break;
        case 'invalid-email':
          message = 'Adresse email invalide';
          break;
        case 'too-many-requests':
          message = 'Trop de tentatives, réessayez plus tard';
          break;
        default:
          message = 'Email ou mot de passe incorrect';
      }
      state = state.copyWith(
        isLoading: false,
        error: message,
        isLoggedIn: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Une erreur est survenue : $e',
        isLoggedIn: false,
      );
    }
  }

  Future<void> inscription(
    String nom,
    String prenom,
    String email,
    String password,
    String role,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _inscriptionUsecase(
        nom,
        prenom,
        email,
        password,
        role,
      );
      state = state.copyWith(user: user, isLoading: false, isLoggedIn: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'inscription',
      );
    }
  }

  Future<void> logout() async {
    await _logoutUsecase();
    state = const AuthState();
  }

  Future<bool> validateGerantCode(String code) async {
    return await _validateGerantCodeUsecase(code);
  }

  Future<void> setGerantCode(String code) async {
    await _setGerantCodeUsecase(code);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = AuthRepositoryImpl();
  return AuthNotifier(
    LoginUsecase(repo),
    InscriptionUsecase(repo),
    LogoutUsecase(repo),
    ValidateGerantCodeUsecase(repo),
    SetGerantCodeUsecase(repo),
  );
});
