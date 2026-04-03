import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:inum/core/interfaces/i_auth_repository.dart';
import 'package:inum/core/interfaces/i_chat_repository.dart';
import 'package:inum/core/interfaces/i_connectivity_repository.dart';
import 'package:inum/data/api/livekit/livekit_service.dart';
import 'package:inum/data/api/mattermost/mattermost_api_client.dart';
import 'package:inum/data/api/mattermost/mattermost_ws_client.dart';
import 'package:inum/data/repository/auth/auth_repository.dart';
import 'package:inum/data/repository/call/call_history_repository.dart';
import 'package:inum/data/repository/call/recordings_repository.dart';
import 'package:inum/data/repository/chat/chat_repository.dart';
import 'package:inum/data/repository/connectivity/connectivity_repository.dart';
import 'package:inum/data/repository/offline/offline_repository.dart';
import 'package:inum/presentation/blocs/auth_session/auth_session_cubit.dart';
import 'package:inum/presentation/blocs/call/call_cubit.dart';
import 'package:inum/presentation/blocs/call_history/call_history_cubit.dart';
import 'package:inum/presentation/blocs/channel_list/channel_list_cubit.dart';
import 'package:inum/presentation/blocs/chat_session/chat_session_cubit.dart';
import 'package:inum/presentation/blocs/connectivity/connectivity_cubit.dart';
import 'package:inum/presentation/blocs/contacts/contacts_cubit.dart';
import 'package:inum/presentation/blocs/recordings/recordings_cubit.dart';
import 'package:inum/presentation/blocs/sms/sms_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // API Clients
  getIt.registerLazySingleton<MattermostApiClient>(() => MattermostApiClient());
  getIt.registerLazySingleton<MattermostWsClient>(() => MattermostWsClient());
  getIt.registerLazySingleton<LiveKitService>(() => LiveKitService());

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

  // Call History Repository (SQLite-backed)
  final callHistoryRepo = CallHistoryRepository();
  await callHistoryRepo.init();
  getIt.registerLazySingleton<ICallHistoryRepository>(() => callHistoryRepo);

  // Recordings Repository (SQLite-backed)
  final recordingsRepo = RecordingsRepository();
  await recordingsRepo.init();
  getIt.registerLazySingleton<IRecordingsRepository>(() => recordingsRepo);

  // Offline Repository (SQLite-backed)
  final offlineRepo = OfflineRepository();
  await offlineRepo.init();
  getIt.registerLazySingleton<OfflineRepository>(() => offlineRepo);

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
  getIt.registerFactory<CallCubit>(
    () => CallCubit(
      liveKitService: getIt<LiveKitService>(),
      wsClient: getIt<MattermostWsClient>(),
    ),
  );
  getIt.registerFactory<CallHistoryCubit>(
    () => CallHistoryCubit(repository: getIt<ICallHistoryRepository>()),
  );
  getIt.registerFactory<ContactsCubit>(
    () => ContactsCubit(apiClient: getIt<MattermostApiClient>()),
  );
  getIt.registerFactory<RecordingsCubit>(
    () => RecordingsCubit(repository: getIt<IRecordingsRepository>()),
  );
  // Phase 7: SMS Cubit
  getIt.registerFactory<SmsCubit>(
    () => SmsCubit(),
  );
}
