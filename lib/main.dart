import 'package:flutter/material.dart';
import 'package:inum/core/config/env_config.dart';
import 'package:inum/core/di/dependency_injector.dart';
import 'package:inum/core/init/app_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvConfig.instance.initialize();
  await setupDependencies();

  runApp(const AppWidget());
}
