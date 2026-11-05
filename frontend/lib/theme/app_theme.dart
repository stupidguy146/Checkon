import 'package:flutter/material.dart';
import 'app_tokens.dart';

/// Builds the app's light and deep-ocean themes from the shared design tokens.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand600,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.brand600,
      onPrimary: AppColors.neutral0,
      primaryContainer: AppColors.brand100,
      onPrimaryContainer: AppColors.brand900,
      secondary: AppColors.cyan,
      onSecondary: AppColors.brand900,
      secondaryContainer: AppColors.iceBlue,
      onSecondaryContainer: AppColors.brand900,
      tertiary: AppColors.cyan,
      onTertiary: AppColors.neutral0,
      surface: AppSurfaces.lightElevated,
      onSurface: AppColors.neutral900,
      surfaceContainerLowest: AppColors.neutral0,
      surfaceContainerLow: AppColors.softWhite,
      surfaceContainer: AppSurfaces.lightSecondary,
      surfaceContainerHigh: AppColors.iceBlue,
      surfaceContainerHighest: AppColors.brand100,
      error: AppColors.danger,
      onError: AppColors.neutral0,
      outline: AppColors.neutral400,
      outlineVariant: AppBorders.subtle,
      shadow: AppColors.brand900.withValues(alpha: 0.08),
      surfaceTint: AppColors.brand500,
    );
    return _build(
      scheme: scheme,
      background: AppSurfaces.lightBackground,
      surface: AppSurfaces.lightElevated,
      inputSurface: AppSurfaces.lightSecondary,
      mutedText: AppColors.neutral600,
      separator: AppBorders.separator,
      glassSurface: AppSurfaces.lightGlass,
      selectedSurface: AppColors.brand100,
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand400,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.brand300,
      onPrimary: AppColors.darkBg,
      primaryContainer: AppColors.darkSurfaceAlt,
      onPrimaryContainer: AppColors.darkText,
      secondary: AppColors.aqua,
      onSecondary: AppColors.darkBg,
      secondaryContainer: AppColors.darkSurfaceAlt,
      onSecondaryContainer: AppColors.darkText,
      tertiary: const Color(0xFF79D8A0),
      onTertiary: AppColors.darkBg,
      surface: AppSurfaces.darkElevated,
      onSurface: AppColors.darkText,
      surfaceContainerLowest: AppSurfaces.darkBackground,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppSurfaces.darkElevated,
      surfaceContainerHigh: AppColors.darkSurfaceAlt,
      surfaceContainerHighest: const Color(0xFF19435A),
      error: const Color(0xFFFF8A80),
      onError: AppColors.darkBg,
      outline: const Color(0xFF7895A7),
      outlineVariant: const Color(0xFF29485C),
      shadow: Colors.black.withValues(alpha: 0.28),
      surfaceTint: AppColors.brand300,
    );
    return _build(
      scheme: scheme,
      background: AppSurfaces.darkBackground,
      surface: AppSurfaces.darkElevated,
      inputSurface: AppColors.darkSurfaceAlt,
      mutedText: AppColors.darkTextMuted,
      separator: const Color(0xFF29485C),
      glassSurface: AppSurfaces.darkGlass,
      selectedSurface: const Color(0xFF164564),
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color background,
    required Color surface,
    required Color inputSurface,
    required Color mutedText,
    required Color separator,
    required Color glassSurface,
    required Color selectedSurface,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    final actionButtonColor = AppColors.actionButtonBackground(dark: isDark);
    final onSurface = scheme.onSurface;
    final textTheme = TextTheme(
      displayLarge: AppType.display.copyWith(color: onSurface),
      displayMedium: AppType.largeTitle.copyWith(color: onSurface),
      displaySmall: AppType.title1.copyWith(color: onSurface),
      headlineLarge: AppType.title1.copyWith(color: onSurface),
      headlineMedium: AppType.title2.copyWith(color: onSurface),
      headlineSmall: AppType.title3.copyWith(color: onSurface),
      titleLarge: AppType.title2.copyWith(color: onSurface),
      titleMedium: AppType.titleMedium.copyWith(color: onSurface),
      titleSmall: AppType.headline.copyWith(color: onSurface),
      bodyLarge: AppType.body.copyWith(color: onSurface),
      bodyMedium: AppType.bodySecondary.copyWith(color: mutedText),
      bodySmall: AppType.footnote.copyWith(color: mutedText),
      labelLarge: AppType.label.copyWith(color: onSurface),
      labelMedium: AppType.caption.copyWith(color: mutedText),
      labelSmall: AppType.smallCaption.copyWith(color: mutedText),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: separator),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Anuphan',
      scaffoldBackgroundColor: background,
      canvasColor: surface,
      dividerColor: separator,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppType.title2.copyWith(color: onSurface),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: separator,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(
            color: AppBorders.focus,
            width: AppBorders.focusWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: mutedText),
        floatingLabelStyle: TextStyle(color: scheme.primary),
        hintStyle: TextStyle(color: mutedText),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: actionButtonColor,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor:
              isDark ? AppColors.darkSurfaceAlt : AppColors.neutral200,
          disabledForegroundColor: mutedText,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppType.titleMedium,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: actionButtonColor,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor:
              isDark ? AppColors.darkSurfaceAlt : AppColors.neutral200,
          disabledForegroundColor: mutedText,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppType.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppType.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: AppType.titleMedium,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: actionButtonColor,
        foregroundColor: scheme.onPrimary,
        elevation: AppGlass.elevation,
        focusElevation: AppGlass.elevation,
        hoverElevation: AppGlass.elevation,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: glassSurface,
        indicatorColor: selectedSurface,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : mutedText,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppType.caption.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : mutedText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rSm),
        side: BorderSide(color: scheme.outline),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : mutedText,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : separator,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: selectedSurface,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.brand900,
        contentTextStyle: AppType.bodySecondary.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rXl),
        titleTextStyle: AppType.title2.copyWith(color: onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.modal),
          ),
        ),
      ),
    );
  }
}
