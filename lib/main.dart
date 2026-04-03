import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:hydrated_bloc/hydrated_bloc.dart";
import "package:path_provider/path_provider.dart";
import "package:inum/core/config/env_config.dart";
import "package:inum/core/di/dependency_injector.dart";
import "package:inum/core/init/app_widget.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize HydratedBloc storage (for ThemeCubit persistence)
  try {
    if (kIsWeb) {
      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: HydratedStorageDirectory.web,
      );
    } else {
      final dir = await getApplicationDocumentsDirectory();
      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: HydratedStorageDirectory(dir.path),
      );
    }
  } catch (e) {
    debugPrint("HydratedStorage init failed: $e");
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory.web,
    );
  }

  await EnvConfig.instance.initialize();
  await setupDependencies();

  runApp(const AppWidget());
}
