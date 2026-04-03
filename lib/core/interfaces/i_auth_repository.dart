import 'package:fpdart/fpdart.dart';
import 'package:inum/core/constants/enums/auth_failure_enum.dart';
import 'package:inum/domain/models/auth/auth_user_model.dart';

abstract class IAuthRepository {
  Future<Either<AuthFailureEnum, AuthUserModel>> login(String loginId, String password);
  Future<void> logout();
  Future<Option<AuthUserModel>> getSignedInUser();
  Stream<AuthUserModel> get authStateChanges;
  Future<void> updateStatus(String status);
}
