import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:envirosense/app/enviro_sense_app.dart';

void main() {
  testWidgets('EnviroSense dashboard appears', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EnviroSenseApp()),
    );

    expect(find.text('ENVIROSENSE'), findsOneWidget);
    expect(find.text('No device connected'), findsOneWidget);
  });
}
