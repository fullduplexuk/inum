import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inum/core/constants/enums/auth_failure_enum.dart';
import 'package:inum/core/interfaces/i_auth_repository.dart';
import 'package:inum/presentation/blocs/auth_session/auth_session_state.dart';

class AuthSessionCubit extends Cubit<AuthSessionState> {
  final IAuthRepository _authRepository;

  AuthSessionCubit({required IAuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthSessionInitial());

  Future<void> checkSession() async {
    emit(const AuthSessionLoading());
    final userOption = await _authRepository.getSignedInUser();
    userOption.match(
      () => emit(const AuthSessionUnauthenticated()),
      (user) {
        if (user.isAuthenticated) {
          emit(AuthSessionAuthenticated(user));
        } else {
          emit(const AuthSessionUnauthenticated());
        }
      },
    );
  }

  Future<void> login(String loginId, String password) async {
    emit(const AuthSessionLoading());
    final result = await _authRepository.login(loginId, password);
    result.fold(
      (failure) {
        final message = switch (failure) {
          AuthFailureEnum.invalidCredentials => 'Invalid username or password',
          AuthFailureEnum.networkError => 'Network error. Please check your connection.',
          AuthFailureEnum.sessionExpired => 'Session expired. Please login again.',
          AuthFailureEnum.serverError => 'Server error. Please try again later.',
        };
        emit(AuthSessionError(message));
      },
      (user) => emit(AuthSessionAuthenticated(user)),
    );
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(const AuthSessionUnauthenticated());
  }

  Future<void> updateStatus(String status) async {
    await _authRepository.updateStatus(status);
  }
}
