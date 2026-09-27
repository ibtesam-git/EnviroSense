import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/enviro_sense_app.dart';
import 'core/preferences/app_preferences.dart';
import 'core/repositories/local_demo_history_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: AppPreferences.storageKeys,
    ),
  );

  await LocalDemoHistoryRepository(preferences).ensureSeeded();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesStoreProvider.overrideWithValue(
          preferences,
        ),
      ],
      child: const EnviroSenseApp(),
    ),
  );
}
