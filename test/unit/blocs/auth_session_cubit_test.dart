import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:inum/core/constants/enums/auth_failure_enum.dart';
import 'package:inum/domain/models/auth/auth_user_model.dart';
import 'package:inum/presentation/blocs/auth_session/auth_session_cubit.dart';
import 'package:inum/presentation/blocs/auth_session/auth_session_state.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockIAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockIAuthRepository();
  });

  group('AuthSessionCubit', () {
    test('initial state is AuthSessionInitial', () {
      final cubit = AuthSessionCubit(authRepository: mockAuthRepo);
      expect(cubit.state, isA<AuthSessionInitial>());
      cubit.close();
    });

    blocTest<AuthSessionCubit, AuthSessionState>(
      'login emits [Loading, Authenticated] on success',
      build: () {
        when(() => mockAuthRepo.login(any(), any()))
            .thenAnswer((_) async => Right(TestData.authUser()));
        return AuthSessionCubit(authRepository: mockAuthRepo);
      },
      act: (cubit) => cubit.login('user', 'pass'),
      expect: () => [
        isA<AuthSessionLoading>(),
        isA<AuthSessionAuthenticated>(),
      ],
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'login emits [Loading, Error] on invalid credentials',
      build: () {
        when(() => mockAuthRepo.login(any(), any())).thenAnswer(
            (_) async => const Left(AuthFailureEnum.invalidCredentials));
        return AuthSessionCubit(authRepository: mockAuthRepo);
      },
      act: (cubit) => cubit.login('user', 'wrong'),
      expect: () => [
        isA<AuthSessionLoading>(),
        isA<AuthSessionError>(),
      ],
      verify: (cubit) {
        final state = cubit.state as AuthSessionError;
        expect(state.message, contains('Invalid'));
      },
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'login emits [Loading, Error] on network error',
      build: () {
        when(() => mockAuthRepo.login(any(), any()))
            .thenAnswer((_) async => const Left(AuthFailureEnum.networkError));
        return AuthSessionCubit(authRepository: mockAuthRepo);
      },
      act: (cubit) => cubit.login('user', 'pass'),
      expect: () => [
        isA<AuthSessionLoading>(),
        isA<AuthSessionError>(),
      ],
      verify: (cubit) {
        final state = cubit.state as AuthSessionError;
        expect(state.message, contains('Network'));
      },
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'login emits [Loading, Error] on server error',
      build: () {
        when(() => mockAuthRepo.login(any(), any()))
            .thenAnswer((_) async => const Left(AuthFailureEnum.serverError));
        return AuthSessionCubit(authRepository: mockAuthRepo);
      },
      act: (cubit) => cubit.login('user', 'pass'),
      expect: () => [
        isA<AuthSessionLoading>(),
        isA<AuthSessionError>(),
      ],
      verify: (cubit) {
        final state = cubit.state as AuthSessionError;
        expect(state.message, contains('Server'));
      },
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'checkSession emits [Loading, Authenticated] when session exists',
      build: () {
        when(() => mockAuthRepo.getSignedInUser())
            .thenAnswer((_) async => Some(TestData.authUser()));
        return AuthSessionCubit(authRepository: mockAuthRepo);
      },
      act: (cubit) => cubit.checkSession(),
      expect: () => [
        isA<AuthSessionLoading>(),
        isA<AuthSessionAuthenticated>(),
      ],
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'checkSession emits [Loading, Unauthenticated] when no session',
      build: () {
        when(() => mockAuthRepo.getSignedInUser())
            .thenAnswer((_) async => const None());
        return AuthSessionCubit(authRepository: mockAuthRepo);
      },
      act: (cubit) => cubit.checkSession(),
      expect: () => [
        isA<AuthSessionLoading>(),
        isA<AuthSessionUnauthenticated>(),
      ],
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'checkSession emits Unauthenticated for empty user',
      build: () {
        when(() => mockAuthRepo.getSignedInUser())
            .thenAnswer((_) async => Some(AuthUserModel.empty()));
        return AuthSessionCubit(authRepository: mockAuthRepo);
      },
      act: (cubit) => cubit.checkSession(),
      expect: () => [
        isA<AuthSessionLoading>(),
        isA<AuthSessionUnauthenticated>(),
      ],
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'logout emits Unauthenticated',
      build: () {
        when(() => mockAuthRepo.logout()).thenAnswer((_) async {});
        return AuthSessionCubit(authRepository: mockAuthRepo);
      },
      act: (cubit) => cubit.logout(),
      expect: () => [isA<AuthSessionUnauthenticated>()],
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'login error for session expired',
      build: () {
        when(() => mockAuthRepo.login(any(), any())).thenAnswer(
            (_) async => const Left(AuthFailureEnum.sessionExpired));
        return AuthSessionCubit(authRepository: mockAuthRepo);
      },
      act: (cubit) => cubit.login('user', 'pass'),
      expect: () => [
        isA<AuthSessionLoading>(),
        isA<AuthSessionError>(),
      ],
      verify: (cubit) {
        final state = cubit.state as AuthSessionError;
        expect(state.message, contains('expired'));
      },
    );
  });

  group('AuthSessionState', () {
    test('AuthSessionAuthenticated contains user', () {
      final user = TestData.authUser();
      final state = AuthSessionAuthenticated(user);
      expect(state.user, user);
      expect(state.props, [user]);
    });

    test('AuthSessionError contains message', () {
      const state = AuthSessionError('Something went wrong');
      expect(state.message, 'Something went wrong');
      expect(state.props, ['Something went wrong']);
    });

    test('states are equatable', () {
      expect(const AuthSessionInitial(), const AuthSessionInitial());
      expect(const AuthSessionLoading(), const AuthSessionLoading());
      expect(
          const AuthSessionUnauthenticated(), const AuthSessionUnauthenticated());
    });
  });
}
