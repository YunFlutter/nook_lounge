import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/domain/repository/auth_repository.dart';
import 'package:nook_lounge_app/presentation/state/sign_in_view_state.dart';

class SignInViewModel extends StateNotifier<SignInViewState> {
  SignInViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const SignInViewState());

  final AuthRepository _authRepository;

  Future<void> signInWithApple() async {
    await _run(() => _authRepository.signInWithApple());
  }

  Future<void> signInWithGoogle() async {
    await _run(() => _authRepository.signInWithGoogle());
  }

  Future<void> signInAsGuest() async {
    await _run(() => _authRepository.signInAnonymously());
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> _run(Future<void> Function() task) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await task();
      state = state.copyWith(isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }
}
