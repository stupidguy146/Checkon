import 'package:flutter/material.dart';

/// ============================================================
/// DESIGN TOKENS — single source of truth สำหรับทั้งแอป
/// ค่าทุกอย่างในนี้ถูกส่งออกไปยัง design/figma-tokens-2.json ด้วย
/// (Tokens Studio for Figma format) จึงใช้ตรงกันทั้งโค้ดและ Figma
/// ============================================================

/// ---------- COLOR ----------
class AppColors {
  AppColors._();

  // Clear sky blue is the primary brand color; green remains the secondary.
  static const Color brand50 = Color(0xFFF1F7FE);
  static const Color brand100 = Color(0xFFDDEBFB);
  static const Color brand200 = Color(0xFFBAD5F6);
  static const Color brand300 = Color(0xFF90BDF3);
  static const Color brand400 = Color(0xFF63A2EF);
  static const Color brand500 = Color(0xFF3D88E0);
  static const Color brand600 = Color(0xFF246FC4);
  static const Color brand700 = Color(0xFF205C9F);
  static const Color brand800 = Color(0xFF1B4B7D);
  static const Color brand900 = Color(0xFF173A60);

  static const Color skyBlue = Color(0xFF62A5F5);
  static const Color oceanBlue = Color(0xFF246FC4);
  static const Color aqua = Color(0xFF35C4D8);
  static const Color cyan = Color(0xFF12AFC7);
  static const Color freshGreen = Color(0xFF35A96D);
  static const Color tennisGreen = Color(0xFFC6E82F);
  static const Color tennisGreenSurface = Color(0xFFEAF6B2);
  static const Color mint = Color(0xFFBDEFD8);
  static const Color softWhite = Color(0xFFFCFEFF);
  static const Color cloudWhite = Color(0xFFF1F7FE);
  static const Color iceBlue = Color(0xFFE8F2FE);

  // Amber remains a distinct financial/highlight accent.
  static const Color accent400 = Color(0xFFFFE6A8);
  static const Color accent500 = Color(0xFFE8B65C);
  static const Color accent600 = Color(0xFF9B6500);

  // Semantic colors remain distinct from the decorative brand palette.
  static const Color success = Color(0xFF237A4A);
  static const Color sage = Color(0xFFDDF4E6);
  static const Color warning = Color(0xFF8A5D00);
  static const Color amberTint = Color(0xFFFFF0C2);
  static const Color statusLow = Color(0xFFFFC857);
  static const Color statusLowForeground = Color(0xFF5C3A00);
  static const Color shouldBuy = Color(0xFFAC5614);
  static const Color danger = Color(0xFFB42318);
  static const Color coralTint = Color(0xFFFCE4E0);
  static const Color info = brand600;

  static Color actionButtonBackground({required bool dark}) =>
      dark ? success : tennisGreen;

  // Cool neutral scale keeps long-form text calm and highly legible.
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF6FBFE);
  static const Color neutral100 = Color(0xFFEDF5F9);
  static const Color neutral200 = Color(0xFFDCE8EF);
  static const Color neutral300 = Color(0xFFC2D2DE);
  static const Color neutral400 = Color(0xFF8DA3B2);
  static const Color neutral500 = Color(0xFF607989);
  static const Color neutral600 = Color(0xFF476171);
  static const Color neutral700 = Color(0xFF304B5B);
  static const Color neutral800 = Color(0xFF1E394A);
  static const Color neutral900 = Color(0xFF102D3F);

  static const Color darkBg = Color(0xFF061827);
  static const Color darkSurface = Color(0xFF0B2639);
  static const Color darkSurfaceAlt = Color(0xFF12374D);
  static const Color darkText = Color(0xFFEAF7FF);
  static const Color darkTextMuted = Color(0xFFA8C1D0);
}

/// Appearance-aware surfaces used by the app theme and native-style chrome.
class AppSurfaces {
  AppSurfaces._();

  static const Color lightBackground = Color(0xFFF4F8FF);
  static const Color lightSecondary = Color(0xFFEDF4FE);
  static const Color lightElevated = Color(0xFFFFFFFF);
  static const Color lightGlass = Color(0xE0FFFFFF);
  static const Color darkBackground = Color(0xFF061827);
  static const Color darkSecondary = Color(0xFF092033);
  static const Color darkElevated = Color(0xFF0B2639);
  static const Color darkGlass = Color(0xE0102B40);
}

/// Glass effects are deliberately reserved for chrome and highlighted panels.
class AppGlass {
  AppGlass._();

  static const double surfaceOpacity = 0.88;
  static const double borderOpacity = 0.72;
  static const double highlightOpacity = 0.62;
  static const double blurSigma = 16;
  static const double elevation = 2;
}

/// ---------- GRADIENT ----------
class AppGradients {
  AppGradients._();

  static const LinearGradient sky = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.skyBlue, AppColors.brand500, AppColors.oceanBlue],
  );

  static const LinearGradient ocean = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand500, AppColors.brand700],
  );

  static const LinearGradient aqua = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.aqua, AppColors.brand500],
  );

  static const LinearGradient freshGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.freshGreen, AppColors.aqua],
  );

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.skyBlue, AppColors.brand300, AppColors.brand100],
  );

  static const LinearGradient brandDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A5684), Color(0xFF07385D)],
  );

  static const LinearGradient brandSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand400, AppColors.brand600],
  );

  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accent600, Color(0xFF704400)],
  );

  static const LinearGradient accentDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF704A10), Color(0xFF392B16)],
  );

  static const LinearGradient glassHighlight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x9EFFFFFF), Color(0x26FFFFFF)],
  );

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppSurfaces.lightBackground, AppColors.iceBlue],
  );

  static const LinearGradient backgroundDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppSurfaces.darkBackground, AppSurfaces.darkSecondary],
  );

  static const LinearGradient button = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand600, AppColors.brand700],
  );

  static const LinearGradient card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.softWhite, AppColors.brand50],
  );
}

/// ---------- SPACING ----------
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xlg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double xxxxl = 64;
}

/// ---------- RADIUS ----------
class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double card = 20;
  static const double button = 14;
  static const double input = 14;
  static const double modal = 28;
  static const double pill = 999;

  static BorderRadius get rSm => BorderRadius.circular(sm);
  static BorderRadius get rMd => BorderRadius.circular(md);
  static BorderRadius get rLg => BorderRadius.circular(lg);
  static BorderRadius get rXl => BorderRadius.circular(xl);
  static BorderRadius get rXxl => BorderRadius.circular(xxl);
}

/// ---------- SHADOW / ELEVATION ----------
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: AppColors.brand900.withValues(alpha: 0.035),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.brand900.withValues(alpha: 0.055),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ];

  static List<BoxShadow> get floating => [
        BoxShadow(
          color: AppColors.brand900.withValues(alpha: 0.085),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: AppColors.brand900.withValues(alpha: 0.11),
          blurRadius: 34,
          offset: const Offset(0, 16),
        ),
      ];

  static List<BoxShadow> get glass => [
        BoxShadow(
          color: AppColors.oceanBlue.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get highlight => [
        BoxShadow(
          color: AppColors.softWhite.withValues(alpha: 0.85),
          blurRadius: 12,
          offset: const Offset(0, -2),
        ),
      ];

  static List<BoxShadow> get sm => subtle;
  static List<BoxShadow> get md => card;
  static List<BoxShadow> get lg => floating;

  static List<BoxShadow> brandGlow(Color c) => [
        BoxShadow(
          color: c.withValues(alpha: 0.22),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
}

class AppBorders {
  AppBorders._();

  static const Color subtle = Color(0xFFDCECF5);
  static const Color glass = Color(0xB8FFFFFF);
  static const Color highlight = Color(0xEFFFFFFF);
  static const Color focus = AppColors.brand600;
  static const Color disabled = Color(0xFFDCE5EB);
  static const Color separator = Color(0xFFDCE8EF);
  static const double defaultWidth = 1;
  static const double focusWidth = 2;
}

/// ---------- TYPOGRAPHY ----------
/// Uses Anuphan for friendly, readable Thai and English UI text. All styles
/// remain text-scalable and retain platform fallback for unsupported glyphs.
class AppType {
  AppType._();

  static TextStyle _uiFont(TextStyle base) =>
      base.copyWith(fontFamily: 'Anuphan');

  static TextStyle get largeDisplay => _uiFont(const TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.8,
      ));
  static TextStyle get display => _uiFont(const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.5,
      ));
  static TextStyle get displayLarge => display;
  static TextStyle get largeTitle => _uiFont(const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.16,
        letterSpacing: -0.4,
      ));
  static TextStyle get title1 => _uiFont(const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ));
  static TextStyle get headlineMedium => title1;
  static TextStyle get title2 => _uiFont(const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.24,
      ));
  static TextStyle get titleLarge => title2;
  static TextStyle get title3 => _uiFont(const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ));
  static TextStyle get titleMedium => _uiFont(const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ));
  static TextStyle get headline => _uiFont(const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ));
  static TextStyle get body => _uiFont(const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.42,
      ));
  static TextStyle get bodyLarge => _uiFont(const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ));
  static TextStyle get bodySecondary => _uiFont(const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ));
  static TextStyle get bodyMedium => bodySecondary;
  static TextStyle get callout => _uiFont(const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ));
  static TextStyle get subheadline => _uiFont(const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.35,
      ));
  static TextStyle get footnote => _uiFont(const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.35,
      ));
  static TextStyle get caption => _uiFont(const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ));
  static TextStyle get smallCaption => _uiFont(const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ));
  static TextStyle get label => _uiFont(const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ));
}

/// ---------- MOTION ----------
class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration spring = Duration(milliseconds: 380);
  static const Duration fade = Duration(milliseconds: 180);
  static const Duration scale = Duration(milliseconds: 220);
  static const Duration interactiveTransition = Duration(milliseconds: 200);
}

class AppMotion {
  AppMotion._();

  static Duration duration(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

/// ---------- STATUS (4 แบบตาม Checkon) ----------
/// ปกติ / ใกล้หมด / ควรซื้อ / หมดแล้ว — ใช้กับ status chip
enum StockStatus { normal, low, shouldBuy, out }

class AppStatus {
  AppStatus._();

  /// สีตัวอักษร/ไอคอนของแต่ละสถานะ
  static Color fg(StockStatus s, {bool dark = false}) {
    switch (s) {
      case StockStatus.normal:
        return dark ? const Color(0xFF79D8A0) : AppColors.success;
      case StockStatus.low:
        return dark ? const Color(0xFFFFCE63) : AppColors.warning;
      case StockStatus.shouldBuy:
        return dark ? const Color(0xFFFFAD67) : AppColors.shouldBuy;
      case StockStatus.out:
        return dark ? const Color(0xFFFF8A80) : AppColors.danger;
    }
  }

  /// สีพื้นชิป (tint อ่อน) ของแต่ละสถานะ
  static Color bg(StockStatus s, {bool dark = false}) {
    switch (s) {
      case StockStatus.normal:
        return dark ? const Color(0xFF173D31) : AppColors.sage;
      case StockStatus.low:
        return dark ? const Color(0xFF473812) : AppColors.amberTint;
      case StockStatus.shouldBuy:
        return dark ? const Color(0xFF4A2C1C) : AppColors.amberTint;
      case StockStatus.out:
        return dark ? const Color(0xFF4A2426) : AppColors.coralTint;
    }
  }

  /// map จาก daysUntilExpiry → สถานะ (null = ไม่ระบุวันหมด → ปกติ)
  /// out: เลยกำหนด, shouldBuy: <=3, low: <=7, normal: อื่น ๆ
  static StockStatus fromDays(int? days) {
    if (days == null) return StockStatus.normal;
    if (days < 0) return StockStatus.out;
    if (days <= 3) return StockStatus.shouldBuy;
    if (days <= 7) return StockStatus.low;
    return StockStatus.normal;
  }
}
