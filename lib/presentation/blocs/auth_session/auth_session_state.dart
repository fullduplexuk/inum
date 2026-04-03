import 'package:equatable/equatable.dart';
import 'package:inum/domain/models/auth/auth_user_model.dart';

abstract class AuthSessionState extends Equatable {
  const AuthSessionState();

  @override
  List<Object?> get props => [];
}

class AuthSessionInitial extends AuthSessionState {
  const AuthSessionInitial();
}

class AuthSessionLoading extends AuthSessionState {
  const AuthSessionLoading();
}

class AuthSessionAuthenticated extends AuthSessionState {
  final AuthUserModel user;
  const AuthSessionAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthSessionUnauthenticated extends AuthSessionState {
  const AuthSessionUnauthenticated();
}

class AuthSessionError extends AuthSessionState {
  final String message;
  const AuthSessionError(this.message);

  @override
  List<Object?> get props => [message];
}
