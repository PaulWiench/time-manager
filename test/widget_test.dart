import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_manager/app.dart';

void main() {
  testWidgets('app boots and shows the scaffold placeholder', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: TimeManagerApp()),
    );

    expect(find.text('TimeManager — scaffold OK'), findsOneWidget);
  });
}
