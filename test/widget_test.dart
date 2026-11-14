import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:development/main.dart';

void main() {
  testWidgets('PlantTrackerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PlantTrackerApp()),
    );

    expect(find.byType(PlantTrackerApp), findsOneWidget);
  });
}