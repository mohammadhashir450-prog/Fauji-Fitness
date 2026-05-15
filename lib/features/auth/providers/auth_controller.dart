import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

// Controller ka Provider
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncData(null));

  Future<void> login(String email, String password) async {
    state = const AsyncLoading(); // UI me loading spinner dikhane k liye

    state = await AsyncValue.guard(() async {
      await _authRepository.signIn(email, password);
    });
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _authRepository.signUp(email, password);
    });
  }

  Future<void> logout() async {
    await _authRepository.signOut();
  }
}
