import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checkon/theme/app_tokens.dart';
import 'package:checkon/widgets/app_widgets.dart';

void main() {
  testWidgets('password step highlights the second journey stop',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthJourneyIndicator(
            activeStep: 2,
            visible: true,
            firstLabel: 'Account details',
            secondLabel: 'Set password',
            foreground: AppColors.brand900,
            isDark: false,
            onGradient: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account details'), findsOneWidget);
    expect(find.text('Set password'), findsOneWidget);
    final secondStep = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('auth-journey-step-2')),
    );
    expect(
        (secondStep.decoration! as BoxDecoration).color, AppColors.freshGreen);
  });
}
