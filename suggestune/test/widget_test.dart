import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:suggestune/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: 'assets/env');
  });

  testWidgets('Suggestune smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SuggestuneApp());
    await tester.pumpAndSettle();

    expect(find.text('Suggestune'), findsOneWidget);
    expect(find.text('Spotify ile bağlan'), findsOneWidget);
  });
}
