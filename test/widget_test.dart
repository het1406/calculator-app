import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calculator_app/main.dart';

void main() {
  Future<void> tap(WidgetTester tester, String label) async {
    final finder = find.byKey(ValueKey('button_$label'));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('buttons calculate and AC clears result', (tester) async {
    await tester.pumpWidget(const CalculatorApp());
    for (final label in ['8', '×', '7', '=']) {
      await tap(tester, label);
    }
    expect(find.text('56'), findsOneWidget);
    await tap(tester, 'AC');
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '0');
  });

  testWidgets('theme changes while calculation state is preserved', (
    tester,
  ) async {
    await tester.pumpWidget(const CalculatorApp());
    await tap(tester, '8');
    await tap(tester, '+');
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tap(tester, '2');
    await tap(tester, '=');
    expect(find.text('10'), findsOneWidget);
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('error is visible and can recover through a digit', (
    tester,
  ) async {
    await tester.pumpWidget(const CalculatorApp());
    for (final label in ['7', '÷', '0', '=']) {
      await tap(tester, label);
    }
    expect(find.text('Cannot divide by zero'), findsOneWidget);
    await tap(tester, '4');
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '4');
  });

  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets('layout fits $size at double text scale', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: CalculatorScreen(dark: false, onThemeChanged: (_) {}),
        ),
      );
      for (final label in ['8', '×', '7', '=']) {
        await tap(tester, label);
      }
      expect(find.text('56'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('accessible labels and tap targets', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const CalculatorApp());
    expect(find.bySemanticsLabel('All clear'), findsOneWidget);
    expect(find.bySemanticsLabel('Multiply'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Multiply'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(find.bySemanticsLabel('Display 0'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}
