import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:envirosense/app/enviro_sense_app.dart';
import 'package:envirosense/core/preferences/app_preferences.dart';
import 'package:envirosense/core/repositories/local_demo_history_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('EnviroSense dashboard appears', (tester) async {
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: AppPreferences.storageKeys,
      ),
    );

    await LocalDemoHistoryRepository(preferences).ensureSeeded();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesStoreProvider.overrideWithValue(
            preferences,
          ),
        ],
        child: const EnviroSenseApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ENVIROSENSE'), findsOneWidget);
    expect(find.text('No device connected'), findsOneWidget);
  });
}
