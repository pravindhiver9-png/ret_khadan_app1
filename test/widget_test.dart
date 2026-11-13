import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ret_khadan_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Quarry app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const QuarryApp());
    await tester.pumpAndSettle();

    expect(find.byType(QuarryApp), findsOneWidget);
  });
}
