import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:inum/core/interfaces/i_auth_repository.dart';
import 'package:inum/core/interfaces/i_chat_repository.dart';
import 'package:inum/core/interfaces/i_connectivity_repository.dart';
import 'package:inum/data/api/mattermost/mattermost_api_client.dart';
import 'package:inum/data/api/mattermost/mattermost_ws_client.dart';
import 'package:inum/data/repository/auth/auth_repository.dart';
import 'package:inum/data/repository/chat/chat_repository.dart';
import 'package:inum/data/repository/connectivity/connectivity_repository.dart';
import 'package:inum/presentation/blocs/auth_session/auth_session_cubit.dart';
import 'package:inum/presentation/blocs/channel_list/channel_list_cubit.dart';
import 'package:inum/presentation/blocs/chat_session/chat_session_cubit.dart';
import 'package:inum/presentation/blocs/connectivity/connectivity_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // API Clients
  getIt.registerLazySingleton<MattermostApiClient>(() => MattermostApiClient());
  getIt.registerLazySingleton<MattermostWsClient>(() => MattermostWsClient());

  // Repositories
  getIt.registerLazySingleton<IAuthRepository>(
    () => AuthRepository(apiClient: getIt<MattermostApiClient>()),
  );
  getIt.registerLazySingleton<IChatRepository>(
    () => ChatRepository(
      apiClient: getIt<MattermostApiClient>(),
      wsClient: getIt<MattermostWsClient>(),
    ),
  );
  getIt.registerLazySingleton<IConnectivityRepository>(
    () => ConnectivityRepository(Connectivity()),
  );

  // Cubits
  getIt.registerFactory<AuthSessionCubit>(
    () => AuthSessionCubit(authRepository: getIt<IAuthRepository>()),
  );
  getIt.registerFactory<ChatSessionCubit>(
    () => ChatSessionCubit(chatRepository: getIt<IChatRepository>()),
  );
  getIt.registerFactory<ChannelListCubit>(
    () => ChannelListCubit(chatRepository: getIt<IChatRepository>()),
  );
  getIt.registerFactory<ConnectivityCubit>(
    () => ConnectivityCubit(),
  );
}
