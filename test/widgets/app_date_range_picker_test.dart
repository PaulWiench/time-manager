/// Picking the days of a vacation: tap the first, tap the last, fine-tune.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/core/theme/app_theme.dart';
import 'package:time_manager/widgets/app_date_picker.dart';
import 'package:time_manager/widgets/press_scale.dart';

void main() {
  // October 2026: the 1st is a Thursday, so the weekends fall on 3/4, 10/11,
  // 17/18, 24/25 and 31.
  final october = DateTime(2026, 10);

  Set<DateTime>? result;

  /// Opened through the real entry point, so confirming actually pops a route
  /// and the returned value can be checked.
  Future<void> pump(WidgetTester tester, {bool Function(DateTime)? bookable}) async {
    result = null;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showAppDateRangePicker(
                context: context,
                initialMonth: october,
                bookable: bookable ?? (date) => date.weekday <= 5,
                now: DateTime(2026, 9, 28),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Taps the cell for [day] in the visible month.
  Future<void> tapDay(WidgetTester tester, int day) async {
    await tester.tap(find.widgetWithText(PressScale, '$day'));
    await tester.pump();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.textContaining('Continue'));
    await tester.pump();
  }

  testWidgets('a range takes the workdays between its ends', (tester) async {
    await pump(tester);
    await tapDay(tester, 12);
    await tapDay(tester, 23);

    expect(find.text('10 days · 2 not workdays'), findsOneWidget);
  });

  testWidgets('tapping a day inside the range drops it and puts it back',
      (tester) async {
    await pump(tester);
    await tapDay(tester, 12);
    await tapDay(tester, 16);
    expect(find.text('5 days'), findsOneWidget);

    await tapDay(tester, 14);
    expect(find.text('4 days · 1 dropped'), findsOneWidget);

    await tapDay(tester, 14);
    expect(find.text('5 days'), findsOneWidget);
  });

  testWidgets('picking backwards works the same way', (tester) async {
    await pump(tester);
    await tapDay(tester, 23);
    await tapDay(tester, 12);

    expect(find.text('10 days · 2 not workdays'), findsOneWidget);
  });

  testWidgets('tapping outside a finished range starts a new one', (tester) async {
    await pump(tester);
    await tapDay(tester, 12);
    await tapDay(tester, 14);
    await tapDay(tester, 13); // inside: drops it
    expect(find.text('2 days · 1 dropped'), findsOneWidget);

    await tapDay(tester, 20); // outside: starts over, and the drop is forgotten
    expect(find.text('Now tap the last day'), findsOneWidget);
    await tapDay(tester, 22);
    expect(find.text('3 days'), findsOneWidget);
  });

  testWidgets('a weekend has no tap target at all', (tester) async {
    await pump(tester);
    // 17 October is a Saturday. It is drawn, but nothing wraps it — a rest day
    // has no hours to take off, so it cannot start or end a range.
    expect(find.widgetWithText(PressScale, '17'), findsNothing);
    expect(find.text('17'), findsOneWidget);
    expect(find.text('Tap the first day'), findsOneWidget);
  });

  testWidgets('a weekend inside the span is skipped, not booked', (tester) async {
    await pump(tester);
    await tapDay(tester, 16); // Friday
    await tapDay(tester, 19); // Monday
    await confirm(tester);

    expect(result, {DateTime(2026, 10, 16), DateTime(2026, 10, 19)});
  });

  testWidgets('a single day is a valid range', (tester) async {
    await pump(tester);
    await tapDay(tester, 12);
    await tapDay(tester, 12);
    await confirm(tester);

    expect(result, {DateTime(2026, 10, 12)});
  });

  testWidgets('the result holds the days themselves, not the two ends',
      (tester) async {
    await pump(tester);
    await tapDay(tester, 15);
    await tapDay(tester, 20);
    await tapDay(tester, 19); // dropped
    await confirm(tester);

    // Thu 15, Fri 16, (Sat/Sun skipped), Mon 19 dropped, Tue 20.
    expect(result, {
      DateTime(2026, 10, 15),
      DateTime(2026, 10, 16),
      DateTime(2026, 10, 20),
    });
  });

  testWidgets('a half-day public holiday is still bookable', (tester) async {
    // The predicate the app passes is `computeTargetHours(...) > 0`, which is
    // true for a half holiday — it is worth half a day of leave, not none.
    await pump(tester, bookable: (date) => date.weekday <= 5);
    await tapDay(tester, 12);
    await tapDay(tester, 13);
    expect(find.text('2 days'), findsOneWidget);
  });

  testWidgets('nothing can be confirmed before a range is picked', (tester) async {
    await pump(tester);
    await confirm(tester);
    expect(result, isNull);
  });
}
