import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:checkon/widgets/app_widgets.dart';

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('iOS dropdown uses a Cupertino action sheet', (tester) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: AdaptiveDropdownFormField<String>(
            initialValue: 'first',
            decoration: const InputDecoration(labelText: 'Choice'),
            items: const [
              DropdownMenuItem(value: 'first', child: Text('First')),
              DropdownMenuItem(value: 'second', child: Text('Second')),
            ],
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AdaptiveDropdownFormField<String>));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoActionSheet), findsOneWidget);

    await tester.tap(find.text('Second').last);
    await tester.pumpAndSettle();
    expect(selected, 'second');
  });

  testWidgets('Android dropdown keeps the Material control', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: AdaptiveDropdownFormField<String>(
            initialValue: 'first',
            decoration: const InputDecoration(labelText: 'Choice'),
            items: const [
              DropdownMenuItem(value: 'first', child: Text('First')),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  testWidgets('iOS date picker uses the Cupertino wheel picker',
      (tester) async {
    DateTime? selectedDate;
    final initialDate = DateTime(2026, 6, 15);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selectedDate = await showAdaptiveDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
              },
              child: const Text('Pick date'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick date'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoDatePicker), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(selectedDate, initialDate);
  });

  testWidgets('iOS month picker uses native Cupertino month and year wheels',
      (tester) async {
    DateTime? selectedMonth;
    final initialMonth = DateTime(2026, 6);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selectedMonth = await showMonthYearPicker(
                  context,
                  initial: initialMonth,
                  firstMonth: DateTime(2020, 1),
                  lastMonth: DateTime(2030, 12),
                  title: 'Select month',
                  locale: 'en',
                );
              },
              child: const Text('Pick month'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick month'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPicker), findsNWidgets(2));

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(selectedMonth, initialMonth);
  });
}
