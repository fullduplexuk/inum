import "package:connectivity_plus/connectivity_plus.dart";
import "package:flutter/foundation.dart" show kIsWeb;
import "package:get_it/get_it.dart";
import "package:inum/core/interfaces/i_auth_repository.dart";
import "package:inum/core/interfaces/i_chat_repository.dart";
import "package:inum/core/interfaces/i_connectivity_repository.dart";
import "package:inum/data/api/livekit/livekit_service.dart";
import "package:inum/data/api/mattermost/mattermost_api_client.dart";
import "package:inum/data/api/mattermost/mattermost_ws_client.dart";
import "package:inum/data/repository/auth/auth_repository.dart";
import "package:inum/data/repository/call/call_history_repository.dart";
import "package:inum/data/repository/call/call_history_repository_web.dart";
import "package:inum/data/repository/call/recordings_repository.dart";
import "package:inum/data/repository/call/recordings_repository_web.dart";
import "package:inum/data/repository/chat/chat_repository.dart";
import "package:inum/data/repository/connectivity/connectivity_repository.dart";
import "package:inum/data/repository/offline/offline_repository.dart";
import "package:inum/presentation/blocs/auth_session/auth_session_cubit.dart";
import "package:inum/presentation/blocs/call/call_cubit.dart";
import "package:inum/presentation/blocs/call_history/call_history_cubit.dart";
import "package:inum/presentation/blocs/channel_list/channel_list_cubit.dart";
import "package:inum/presentation/blocs/chat_session/chat_session_cubit.dart";
import "package:inum/presentation/blocs/connectivity/connectivity_cubit.dart";
import "package:inum/presentation/blocs/contacts/contacts_cubit.dart";
import "package:inum/presentation/blocs/recordings/recordings_cubit.dart";
import "package:inum/presentation/blocs/sms/sms_cubit.dart";

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

  // Call history & recordings — use stubs on web, SQLite on native
  if (kIsWeb) {
    getIt.registerLazySingleton<ICallHistoryRepository>(
      () => CallHistoryRepositoryWeb(),
    );
    getIt.registerLazySingleton<IRecordingsRepository>(
      () => RecordingsRepositoryWeb(),
    );
  } else {
    try {
      final callHistoryRepo = CallHistoryRepository();
      await callHistoryRepo.init();
      getIt.registerLazySingleton<ICallHistoryRepository>(() => callHistoryRepo);

      final recordingsRepo = RecordingsRepository();
      await recordingsRepo.init();
      getIt.registerLazySingleton<IRecordingsRepository>(() => recordingsRepo);

      final offlineRepo = OfflineRepository();
      await offlineRepo.init();
      getIt.registerLazySingleton<OfflineRepository>(() => offlineRepo);
    } catch (e) {
      // Fallback to stubs if SQLite init fails on native
      print("SQLite init failed, using web stubs: $e");
      if (!getIt.isRegistered<ICallHistoryRepository>()) {
        getIt.registerLazySingleton<ICallHistoryRepository>(
          () => CallHistoryRepositoryWeb(),
        );
      }
      if (!getIt.isRegistered<IRecordingsRepository>()) {
        getIt.registerLazySingleton<IRecordingsRepository>(
          () => RecordingsRepositoryWeb(),
        );
      }
    }
  }

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

  // Always register — repos are guaranteed to exist (stubs on web)
  getIt.registerFactory<CallHistoryCubit>(
    () => CallHistoryCubit(repository: getIt<ICallHistoryRepository>()),
  );
  getIt.registerFactory<RecordingsCubit>(
    () => RecordingsCubit(repository: getIt<IRecordingsRepository>()),
  );

  getIt.registerFactory<ContactsCubit>(
    () => ContactsCubit(apiClient: getIt<MattermostApiClient>()),
  );
  getIt.registerFactory<SmsCubit>(
    () => SmsCubit(),
  );
}
