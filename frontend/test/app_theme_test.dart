import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkon/theme/app_theme.dart';
import 'package:checkon/theme/app_tokens.dart';

void main() {
  test('light and dark themes use intentional logo-inspired surfaces', () {
    expect(AppTheme.light.scaffoldBackgroundColor, AppSurfaces.lightBackground);
    expect(AppTheme.light.colorScheme.primary, AppColors.brand600);
    expect(AppTheme.light.colorScheme.secondary, AppColors.cyan);
    expect(AppTheme.light.textTheme.bodyLarge?.fontFamily, 'Anuphan');
    expect(AppTheme.dark.scaffoldBackgroundColor, AppSurfaces.darkBackground);
    expect(AppTheme.dark.colorScheme.surface, AppSurfaces.darkElevated);
    expect(AppTheme.dark.colorScheme.primary, AppColors.brand300);
    expect(AppTheme.dark.colorScheme.secondary, AppColors.aqua);
  });

  test(
      'action buttons use tennis green in light mode and dark green in dark mode',
      () {
    final lightButtons = AppTheme.light;
    final darkButtons = AppTheme.dark;
    expect(
      AppColors.actionButtonBackground(dark: false),
      AppColors.tennisGreen,
    );
    expect(
      AppColors.actionButtonBackground(dark: true),
      AppColors.success,
    );
    expect(
      lightButtons.filledButtonTheme.style!.backgroundColor!.resolve({}),
      AppColors.tennisGreen,
    );
    expect(
      darkButtons.filledButtonTheme.style!.backgroundColor!.resolve({}),
      AppColors.success,
    );
    expect(
      lightButtons.filledButtonTheme.style!.foregroundColor!.resolve({}),
      lightButtons.colorScheme.onPrimary,
    );
    expect(
      darkButtons.filledButtonTheme.style!.foregroundColor!.resolve({}),
      darkButtons.colorScheme.onPrimary,
    );
    expect(
      lightButtons.elevatedButtonTheme.style!.backgroundColor!.resolve({}),
      AppColors.tennisGreen,
    );
    expect(
      darkButtons.elevatedButtonTheme.style!.backgroundColor!.resolve({}),
      AppColors.success,
    );
    expect(lightButtons.floatingActionButtonTheme.backgroundColor,
        AppColors.tennisGreen);
    expect(darkButtons.floatingActionButtonTheme.backgroundColor,
        AppColors.success);
    expect(
      AppTheme.light.outlinedButtonTheme.style!.foregroundColor!.resolve({}),
      AppTheme.light.colorScheme.primary,
    );
    expect(
      AppTheme.light.textButtonTheme.style!.foregroundColor!.resolve({}),
      AppTheme.light.colorScheme.primary,
    );
  });

  test('light blue add action keeps readable foreground contrast', () {
    expect(
      _contrastRatio(AppColors.brand800, AppColors.brand100),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('light brand header gradient stays readable with brand text', () {
    for (final color in AppGradients.brand.colors) {
      expect(
        _contrastRatio(AppColors.brand900, color),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('status labels retain readable contrast in both appearances', () {
    for (final status in StockStatus.values) {
      expect(
        _contrastRatio(
          AppStatus.fg(status),
          AppStatus.bg(status),
        ),
        greaterThanOrEqualTo(4.5),
        reason: 'Light appearance: $status',
      );
      expect(
        _contrastRatio(
          AppStatus.fg(status, dark: true),
          AppStatus.bg(status, dark: true),
        ),
        greaterThanOrEqualTo(4.5),
        reason: 'Dark appearance: $status',
      );
    }
  });
}

double _contrastRatio(Color foreground, Color background) {
  final first = _relativeLuminance(foreground);
  final second = _relativeLuminance(background);
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color color) {
  double linearize(double channel) => channel <= 0.04045
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

  final red = linearize(color.r);
  final green = linearize(color.g);
  final blue = linearize(color.b);
  return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
}
