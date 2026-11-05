import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../i18n/locale_scope.dart';
import '../theme/app_tokens.dart';

/// ============================================================
/// REUSABLE COMPONENTS — ใช้ซ้ำได้ทุกหน้า
/// ============================================================

class AdaptiveDropdownFormField<T> extends StatelessWidget {
  final T? initialValue;
  final InputDecoration decoration;
  final List<DropdownMenuItem<T>> items;
  final DropdownButtonBuilder? selectedItemBuilder;
  final Color? dropdownColor;
  final BorderRadius? borderRadius;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;

  const AdaptiveDropdownFormField({
    super.key,
    required this.initialValue,
    required this.decoration,
    required this.items,
    this.selectedItemBuilder,
    this.dropdownColor,
    this.borderRadius,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform != TargetPlatform.iOS) {
      return DropdownButtonFormField<T>(
        initialValue: initialValue,
        decoration: decoration,
        items: items,
        selectedItemBuilder: selectedItemBuilder,
        dropdownColor: dropdownColor,
        borderRadius: borderRadius,
        onChanged: onChanged,
        validator: validator,
      );
    }

    return FormField<T>(
      initialValue: initialValue,
      validator: validator,
      builder: (field) {
        final valueIndex =
            items.indexWhere((item) => item.value == field.value);
        final selected = valueIndex < 0
            ? null
            : selectedItemBuilder?.call(context)[valueIndex] ??
                items[valueIndex].child;
        final enabled = onChanged != null;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled
              ? () async {
                  final value = await showCupertinoModalPopup<T>(
                    context: context,
                    builder: (context) => CupertinoActionSheet(
                      actions: [
                        for (final item in items)
                          CupertinoActionSheetAction(
                            isDefaultAction: item.value == field.value,
                            onPressed: () =>
                                Navigator.of(context).pop(item.value),
                            child: item.child,
                          ),
                      ],
                      cancelButton: CupertinoActionSheetAction(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          MaterialLocalizations.of(context).cancelButtonLabel,
                        ),
                      ),
                    ),
                  );
                  if (value != null) {
                    field.didChange(value);
                    onChanged?.call(value);
                  }
                }
              : null,
          child: InputDecorator(
            decoration: decoration.copyWith(
              enabled: enabled,
              errorText: field.errorText,
            ),
            isEmpty: selected == null,
            child: Row(
              children: [
                Expanded(
                  child: selected ??
                      Text(
                        decoration.hintText ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                ),
                const Icon(CupertinoIcons.chevron_down, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<DateTime?> showAdaptiveDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  if (Theme.of(context).platform != TargetPlatform.iOS) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
  final first = dateOnly(firstDate);
  final last = dateOnly(lastDate);
  var selected = dateOnly(initialDate);
  if (selected.isBefore(first)) selected = first;
  if (selected.isAfter(last)) selected = last;

  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (context) => SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
                CupertinoButton(
                  onPressed: () => Navigator.of(context).pop(selected),
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
              ],
            ),
            SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: selected,
                minimumDate: first,
                maximumDate: last,
                onDateTimeChanged: (date) => selected = dateOnly(date),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Shared surface card with a soft brand-tinted border and atmospheric shadow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius? radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final r = radius ?? BorderRadius.circular(AppRadius.card);
    final bg = color ?? Theme.of(context).cardTheme.color;
    final borderColor = Theme.of(context).dividerColor;
    return Material(
      color: bg,
      borderRadius: r,
      child: InkWell(
        onTap: onTap,
        borderRadius: r,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: r,
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? borderColor
                  : AppBorders.subtle,
              width: AppBorders.defaultWidth,
            ),
            boxShadow: AppShadows.card,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// หัวข้อ gradient ขนาดใหญ่ (hero header) ใช้ด้านบนของหน้า
class GradientHeader extends StatelessWidget {
  final String title;
  final IconData? titleIcon;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> stats;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;

  /// Optional brand logo shown above the title (e.g. on the login/register
  /// entry screens). null hides it.
  final String? logoAsset;
  final Widget? logoWidget;
  final Widget? logoTrailing;
  final double logoHeight;
  final bool logoBackground;

  /// Force-center the logo + subtitle + title. When null, falls back to the
  /// legacy behaviour (centered only when a [leading] back button exists).
  final bool? centerTitle;

  const GradientHeader({
    super.key,
    required this.title,
    this.titleIcon,
    this.subtitle,
    this.leading,
    this.trailing,
    this.stats = const [],
    this.gradient,
    this.logoAsset,
    this.logoWidget,
    this.logoTrailing,
    this.logoHeight = 44,
    this.logoBackground = true,
    this.centerTitle,
    this.padding = const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final centered = centerTitle ?? (leading != null);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerForeground =
        gradient != null || isDark ? Colors.white : AppColors.brand900;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: padding,
      decoration: BoxDecoration(
        gradient:
            gradient ?? (isDark ? AppGradients.brandDark : AppGradients.brand),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: AppShadows.brandGlow(AppColors.oceanBlue),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (logoAsset != null || logoWidget != null) ...[
              if (logoTrailing == null)
                Align(
                  alignment: centered ? Alignment.center : Alignment.centerLeft,
                  child: _logo(),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _logo(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    logoTrailing!,
                  ],
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
            SizedBox(
              width: double.infinity,
              height: subtitle == null ? 48 : 68,
              child: Stack(
                // centre the title on screens that have a back button;
                // left-align it on entry screens (no back button)
                alignment: centered ? Alignment.center : Alignment.centerLeft,
                children: [
                  if (leading != null)
                    Align(alignment: Alignment.centerLeft, child: leading!),
                  if (trailing != null)
                    Align(alignment: Alignment.centerRight, child: trailing!),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: leading != null || trailing != null
                          ? AppSpacing.xxxl + AppSpacing.md
                          : 0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: centered
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        if (subtitle != null) ...[
                          Text(
                            subtitle!,
                            style: AppType.label.copyWith(
                              color: headerForeground.withValues(alpha: 0.82),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign:
                                centered ? TextAlign.center : TextAlign.start,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        if (titleIcon == null)
                          Text(
                            title,
                            style: AppType.headlineMedium.copyWith(
                              color: headerForeground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign:
                                centered ? TextAlign.center : TextAlign.start,
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: centered
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            children: [
                              Icon(
                                titleIcon,
                                size: AppType.headlineMedium.fontSize,
                                color: headerForeground,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  title,
                                  style: AppType.headlineMedium.copyWith(
                                    color: headerForeground,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: centered
                                      ? TextAlign.center
                                      : TextAlign.start,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (stats.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  for (int i = 0; i < stats.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(child: stats[i]),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _logo() => Container(
        padding: logoBackground
            ? const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              )
            : EdgeInsets.zero,
        decoration: logoBackground
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.rLg,
                boxShadow: AppShadows.sm,
              )
            : null,
        child: logoWidget ??
            Image.asset(
              logoAsset!,
              height: logoHeight,
              fit: BoxFit.contain,
            ),
      );
}

class AuthHeroHeader extends StatefulWidget {
  final String title;
  final String subtitle;
  final int? journeyStep;

  const AuthHeroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.journeyStep,
  });

  @override
  State<AuthHeroHeader> createState() => _AuthHeroHeaderState();
}

class _AuthHeroHeaderState extends State<AuthHeroHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _motion
        ..stop()
        ..value = 0.5;
    } else {
      _motion.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : AppColors.brand900;
    final subtitleStyle = AppType.bodySecondary.copyWith(
      color: foreground.withValues(alpha: 0.82),
    );
    final subtitleLineHeight = (subtitleStyle.fontSize ?? 14) *
        (subtitleStyle.height ?? 1) *
        MediaQuery.textScalerOf(context).scale(1);
    final borderRadius = BorderRadius.vertical(
      bottom: Radius.circular(AppRadius.xxl),
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.brandDark : AppGradients.brand,
        borderRadius: borderRadius,
        boxShadow: AppShadows.brandGlow(AppColors.oceanBlue),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: CustomPaint(
                  painter: _AuthHeroGraphicPainter(
                    animation: _motion,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 56),
                      Image.asset(
                        'assets/images/logos/checkon_wordmark.png',
                        height: 58,
                        fit: BoxFit.contain,
                        semanticLabel: 'Checkon',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: AppType.title1.copyWith(color: foreground),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 300,
                          minHeight: subtitleLineHeight * 3 + 2,
                        ),
                        child: Center(
                          child: Text(
                            widget.subtitle,
                            textAlign: TextAlign.center,
                            style: subtitleStyle,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AuthJourneyIndicator(
                        activeStep: widget.journeyStep ?? 1,
                        visible: widget.journeyStep != null,
                        firstLabel: context.strings.registerJourneyProfile,
                        secondLabel: context.strings.registerJourneyPassword,
                        foreground: foreground,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthJourneyIndicator extends StatelessWidget {
  final int activeStep;
  final bool visible;
  final String firstLabel;
  final String secondLabel;
  final Color foreground;
  final bool isDark;
  final bool onGradient;

  const AuthJourneyIndicator({
    super.key,
    required this.activeStep,
    required this.visible,
    required this.firstLabel,
    required this.secondLabel,
    required this.foreground,
    required this.isDark,
    this.onGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = onGradient
        ? foreground.withValues(alpha: isDark ? 0.52 : 0.48)
        : (isDark ? AppColors.darkTextMuted : AppColors.neutral500);
    final inactiveLine = onGradient
        ? Colors.white.withValues(alpha: 0.48)
        : Theme.of(context).dividerColor;
    final inactiveFill = onGradient
        ? Colors.white.withValues(alpha: 0.24)
        : Theme.of(context).colorScheme.surface;
    final activeColor = onGradient && isDark
        ? AppColors.tennisGreen
        : (isDark ? AppColors.success : AppColors.freshGreen);
    final activeForeground =
        onGradient && isDark ? AppColors.brand900 : Colors.white;
    final labels = [firstLabel, secondLabel];

    return Visibility(
      visible: visible,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                for (var step = 1; step <= 2; step++) ...[
                  AnimatedContainer(
                    key: ValueKey('auth-journey-step-$step'),
                    duration: const Duration(milliseconds: 320),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: step <= activeStep ? activeColor : inactiveFill,
                      border: Border.all(
                        color: step <= activeStep
                            ? (onGradient
                                ? Colors.white.withValues(alpha: 0.72)
                                : activeColor)
                            : inactiveLine,
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$step',
                        style: AppType.caption.copyWith(
                          color: step <= activeStep
                              ? activeForeground
                              : foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (step == 1)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 420),
                        height: 2,
                        color: activeStep == 2 ? activeColor : inactiveLine,
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (var index = 0; index < labels.length; index++)
                  Expanded(
                    child: Align(
                      alignment: index == 0
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Text(
                        labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.smallCaption.copyWith(
                          color:
                              index + 1 <= activeStep ? foreground : inactive,
                          fontWeight:
                              index + 1 == activeStep ? FontWeight.w700 : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AuthPinHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthPinHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => GradientHeader(
        title: title,
        subtitle: subtitle,
        logoAsset: 'assets/images/logos/checkon_wordmark.png',
        logoHeight: 58,
        logoBackground: false,
        centerTitle: true,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.md,
        ),
      );
}

class _AuthHeroGraphicPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isDark;

  _AuthHeroGraphicPainter({required this.animation, required this.isDark})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;
    final drift = math.sin((progress - 0.5) * math.pi);
    final leavesAlpha = isDark ? 0.38 : 0.34;

    _paintLeaf(
      canvas,
      Offset(size.width * 0.43, 126 + drift * 9),
      length: 38,
      angle: -0.42 + drift * 0.16,
      color: AppColors.freshGreen,
      alpha: leavesAlpha,
    );
    _paintLeaf(
      canvas,
      Offset(size.width * 0.57, 130 - drift * 8),
      length: 32,
      angle: math.pi - 0.48 - drift * 0.14,
      color: AppColors.aqua,
      alpha: leavesAlpha,
    );

    _paintGlassBubble(
      canvas,
      Offset(size.width * 0.25, 117 - drift * 8),
      8,
      isDark,
    );
    _paintGlassBubble(
      canvas,
      Offset(size.width * 0.76, 137 + drift * 7),
      6,
      isDark,
    );
  }

  void _paintLeaf(
    Canvas canvas,
    Offset center, {
    required double length,
    required double angle,
    required Color color,
    required double alpha,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final leaf = Path()
      ..moveTo(-length / 2, 0)
      ..cubicTo(-length * 0.14, -length * 0.3, length * 0.28, -length * 0.26,
          length / 2, 0)
      ..cubicTo(length * 0.23, length * 0.26, -length * 0.2, length * 0.25,
          -length / 2, 0)
      ..close();
    canvas.drawPath(
      leaf,
      Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: alpha * 0.65),
            color.withValues(alpha: alpha),
          ],
        ).createShader(Rect.fromCenter(
          center: Offset.zero,
          width: length,
          height: length * 0.6,
        )),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-length * 0.38, 0)
        ..quadraticBezierTo(0, -length * 0.01, length * 0.38, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: alpha * 1.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _paintGlassBubble(
    Canvas canvas,
    Offset center,
    double radius,
    bool dark,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.42, -0.58),
          colors: [
            Colors.white.withValues(alpha: dark ? 0.34 : 0.48),
            const Color(0xFF9BE5FF).withValues(alpha: dark ? 0.14 : 0.2),
            Colors.white.withValues(alpha: 0.025),
          ],
          stops: const [0, 0.38, 1],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      radius - 0.7,
      Paint()
        ..color = Colors.white.withValues(alpha: dark ? 0.32 : 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-radius * 0.28, -radius * 0.42),
        width: radius * 0.58,
        height: radius * 0.24,
      ),
      Paint()..color = Colors.white.withValues(alpha: dark ? 0.42 : 0.52),
    );
  }

  @override
  bool shouldRepaint(covariant _AuthHeroGraphicPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class AuthFormSurface extends StatelessWidget {
  final Widget child;

  const AuthFormSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.duration(context, AppDurations.slow),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - progress)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadius.rXl,
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
          ),
          boxShadow: AppShadows.card,
        ),
        child: child,
      ),
    );
  }
}

class AuthFlowEntrance extends StatefulWidget {
  final Widget child;

  const AuthFlowEntrance({super.key, required this.child});

  @override
  State<AuthFlowEntrance> createState() => _AuthFlowEntranceState();
}

class _AuthFlowEntranceState extends State<AuthFlowEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, 0.045),
    end: Offset.zero,
  ).animate(_opacity);
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _offset,
          child: widget.child,
        ),
      );
}

/// ปุ่มไอคอนบน [GradientHeader] (เช่น ปุ่มย้อนกลับ) — พื้นขาวโปร่งแสง
/// ใช้ร่วมกันทุกหน้าเพื่อให้ header หน้าตาเหมือนกันทั้งแอป
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
      child: ClipRRect(
        borderRadius: AppRadius.rMd,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppGlass.blurSigma,
            sigmaY: AppGlass.blurSigma,
          ),
          child: Material(
            color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.58),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.rMd,
              side: BorderSide(
                color: Colors.white.withValues(
                  alpha: isDark ? 0.62 : AppGlass.borderOpacity,
                ),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.rMd,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Icon(
                  icon,
                  color: isDark ? Colors.white : AppColors.brand800,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// กล่องสถิติเล็ก ๆ (โปร่งแสงบน header หรือทึบบนพื้นขาว)
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool onGradient;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.onGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = onGradient
        ? (isDark ? Colors.white : AppColors.brand900)
        : AppColors.neutral900;
    final mutedFg =
        onGradient ? fg.withValues(alpha: 0.8) : AppColors.neutral500;
    final bg = onGradient
        ? Colors.white.withValues(alpha: isDark ? 0.18 : 0.4)
        : Theme.of(context).cardTheme.color;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.rMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(value,
              style: AppType.titleMedium.copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: AppType.caption.copyWith(color: mutedFg)),
        ],
      ),
    );
  }
}

/// ป้าย pill เล็ก (สถานะ / แท็ก)
class AppPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const AppPill(
      {super.key, required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            text,
            style: AppType.caption
                .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// หัวข้อ section
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// สถานะว่าง (empty state) พร้อมไอคอนวงกลม
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppGradients.card,
                borderRadius: AppRadius.rXl,
                border: Border.all(color: AppBorders.subtle),
                boxShadow: AppShadows.glass,
              ),
              child: Icon(icon, size: 40, color: AppColors.brand600),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(message!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// มุมมอง error ที่ใช้ได้ทุกหน้า
class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'เชื่อมต่อไม่ได้',
      message: '$error',
      action: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('ลองใหม่'),
      ),
    );
  }
}

class StartupLoadingView extends StatelessWidget {
  const StartupLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.asset(
        'assets/images/loading page/image.png',
        key: ValueKey('startup-artwork'),
        fit: BoxFit.cover,
      ),
    );
  }
}

/// loading แบบ center
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2.5),
    );
  }
}

/// Checkon status chip using tinted pills for the four stock states.
class StatusChip extends StatelessWidget {
  final StockStatus status;
  final String label;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.status,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = AppStatus.fg(status, dark: isDark);
    final bg = AppStatus.bg(status, dark: isDark);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppType.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer effect — animated gradient sweep used for skeleton placeholders.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width * (_c.value * 2 - 1);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppColors.neutral200,
                AppColors.neutral100,
                AppColors.neutral200,
              ],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(dx),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double dx;
  const _SlideGradient(this.dx);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

/// A single grey rounded placeholder block.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? radius;
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.neutral200,
        borderRadius: radius ?? AppRadius.rSm,
      ),
    );
  }
}

/// Skeleton list of card rows (used while a list is loading).
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardTheme.color;
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: AppRadius.rLg,
            boxShadow: AppShadows.sm,
          ),
          child: const Row(
            children: [
              SkeletonBox(
                  width: 52,
                  height: 52,
                  radius: BorderRadius.all(Radius.circular(12))),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 14),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonBox(width: 90, height: 12),
                  ],
                ),
              ),
              SkeletonBox(
                  width: 48,
                  height: 22,
                  radius: BorderRadius.all(Radius.circular(999))),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// MONTH NAVIGATOR — shared across Items + Budget screens
/// prev / next arrows + a tappable label that opens a month-year picker.
/// `onGradient` switches to white colors for use on a gradient header.
/// ============================================================
class MonthNavigator extends StatelessWidget {
  final DateTime month; // any day in the month
  final ValueChanged<DateTime> onChanged;
  final String locale;
  final String prevTooltip;
  final String nextTooltip;
  final String pickerTitle;

  /// Lowest / highest selectable month. [lastMonth] also disables the "next"
  /// arrow once reached (e.g. the current month).
  final DateTime firstMonth;
  final DateTime lastMonth;

  /// White styling for placement on a gradient header.
  final bool onGradient;

  const MonthNavigator({
    super.key,
    required this.month,
    required this.onChanged,
    required this.locale,
    required this.firstMonth,
    required this.lastMonth,
    required this.prevTooltip,
    required this.nextTooltip,
    required this.pickerTitle,
    this.onGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabledFg = onGradient
        ? Colors.white.withValues(alpha: 0.35)
        : AppColors.neutral300;

    // prev enabled if the previous month is >= firstMonth
    final prev = DateTime(month.year, month.month - 1);
    final canPrev = !prev.isBefore(DateTime(firstMonth.year, firstMonth.month));
    // next enabled if the current selection is before lastMonth
    final canNext = month.year < lastMonth.year ||
        (month.year == lastMonth.year && month.month < lastMonth.month);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget arrow(IconData icon, bool enabled, VoidCallback onTap, String tip) {
      if (onGradient) {
        return IconButton(
          tooltip: tip,
          onPressed: enabled ? onTap : null,
          color: Colors.white,
          disabledColor: disabledFg,
          icon: Icon(icon),
        );
      }
      return IconButton.filledTonal(
        tooltip: tip,
        onPressed: enabled ? onTap : null,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.actionButtonBackground(dark: isDark),
        ),
        icon: Icon(icon),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        arrow(
            Icons.chevron_left_rounded,
            canPrev,
            () => onChanged(DateTime(month.year, month.month - 1)),
            prevTooltip),
        Expanded(
          child: _MonthLabelButton(
            label: DateFormat('MMMM yyyy', locale).format(month),
            onGradient: onGradient,
            onTap: () async {
              final picked = await showMonthYearPicker(
                context,
                initial: month,
                firstMonth: firstMonth,
                lastMonth: lastMonth,
                title: pickerTitle,
                locale: locale,
              );
              if (picked != null) onChanged(picked);
            },
          ),
        ),
        arrow(
            Icons.chevron_right_rounded,
            canNext,
            () => onChanged(DateTime(month.year, month.month + 1)),
            nextTooltip),
      ],
    );
  }
}

class _MonthLabelButton extends StatelessWidget {
  final String label;
  final bool onGradient;
  final VoidCallback onTap;
  const _MonthLabelButton(
      {required this.label, required this.onGradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = onGradient ? Colors.white : AppColors.neutral900;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: AppType.titleLarge.copyWith(color: fg),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.arrow_drop_down_rounded, color: fg),
          ],
        ),
      ),
    );
  }
}

/// A month+year picker dialog: a year stepper on top + a 12-month grid.
/// Returns the chosen month (first day) or null if cancelled.
Future<DateTime?> showMonthYearPicker(
  BuildContext context, {
  required DateTime initial,
  required DateTime firstMonth,
  required DateTime lastMonth,
  required String title,
  required String locale,
}) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (_) => _CupertinoMonthYearPicker(
        initial: DateTime(initial.year, initial.month),
        firstMonth: DateTime(firstMonth.year, firstMonth.month),
        lastMonth: DateTime(lastMonth.year, lastMonth.month),
        title: title,
        locale: locale,
      ),
    );
  }

  return showDialog<DateTime>(
    context: context,
    builder: (_) => _MonthYearPickerDialog(
      initial: DateTime(initial.year, initial.month),
      firstMonth: DateTime(firstMonth.year, firstMonth.month),
      lastMonth: DateTime(lastMonth.year, lastMonth.month),
      title: title,
      locale: locale,
    ),
  );
}

class _CupertinoMonthYearPicker extends StatefulWidget {
  final DateTime initial;
  final DateTime firstMonth;
  final DateTime lastMonth;
  final String title;
  final String locale;

  const _CupertinoMonthYearPicker({
    required this.initial,
    required this.firstMonth,
    required this.lastMonth,
    required this.title,
    required this.locale,
  });

  @override
  State<_CupertinoMonthYearPicker> createState() =>
      _CupertinoMonthYearPickerState();
}

class _CupertinoMonthYearPickerState extends State<_CupertinoMonthYearPicker> {
  late int _year;
  late int _month;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _yearController;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _month = widget.initial.month;
    _monthController = FixedExtentScrollController(
      initialItem: _month - _firstMonth,
    );
    _yearController = FixedExtentScrollController(
      initialItem: _year - widget.firstMonth.year,
    );
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int get _firstMonth =>
      _year == widget.firstMonth.year ? widget.firstMonth.month : 1;

  int get _lastMonth =>
      _year == widget.lastMonth.year ? widget.lastMonth.month : 12;

  @override
  Widget build(BuildContext context) {
    final years = [
      for (var year = widget.firstMonth.year;
          year <= widget.lastMonth.year;
          year++)
        year,
    ];
    final months = [
      for (var month = _firstMonth; month <= _lastMonth; month++) month,
    ];
    final cupertino = CupertinoTheme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: cupertino.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    widget.title,
                    style: cupertino.textTheme.navTitleTextStyle,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        MaterialLocalizations.of(context).cancelButtonLabel,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CupertinoButton(
                      onPressed: () =>
                          Navigator.of(context).pop(DateTime(_year, _month)),
                      child: Text(
                        MaterialLocalizations.of(context).okButtonLabel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 216,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CupertinoPicker(
                      scrollController: _monthController,
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        setState(() => _month = months[index]);
                      },
                      children: [
                        for (final month in months)
                          Center(
                            child: Text(
                              DateFormat('MMMM', widget.locale)
                                  .format(DateTime(_year, month)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: _yearController,
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        final year = years[index];
                        setState(() {
                          _year = year;
                          _month = _month.clamp(_firstMonth, _lastMonth);
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _monthController.jumpToItem(
                              _month - _firstMonth,
                            );
                          }
                        });
                      },
                      children: [
                        for (final year in years) Center(child: Text('$year')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initial;
  final DateTime firstMonth;
  final DateTime lastMonth;
  final String title;
  final String locale;
  const _MonthYearPickerDialog({
    required this.initial,
    required this.firstMonth,
    required this.lastMonth,
    required this.title,
    required this.locale,
  });

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
  }

  bool _enabled(int year, int month) {
    final d = DateTime(year, month);
    final lo = DateTime(widget.firstMonth.year, widget.firstMonth.month);
    final hi = DateTime(widget.lastMonth.year, widget.lastMonth.month);
    return !d.isBefore(lo) && !d.isAfter(hi);
  }

  @override
  Widget build(BuildContext context) {
    final canPrevYear = _year > widget.firstMonth.year;
    final canNextYear = _year < widget.lastMonth.year;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rXl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: AppType.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            // year stepper
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: canPrevYear ? () => setState(() => _year--) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text('$_year', style: AppType.titleLarge),
                IconButton(
                  onPressed: canNextYear ? () => setState(() => _year++) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // 12-month grid (3 cols x 4 rows)
            SizedBox(
              width: 300,
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 2.1,
                children: [
                  for (int m = 1; m <= 12; m++)
                    _MonthCell(
                      label: DateFormat('MMM', widget.locale)
                          .format(DateTime(_year, m)),
                      selected: _year == widget.initial.year &&
                          m == widget.initial.month,
                      enabled: _enabled(_year, m),
                      onTap: () =>
                          Navigator.of(context).pop(DateTime(_year, m)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  const _MonthCell({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = selected
        ? AppColors.brand500
        : (Theme.of(context).cardTheme.color ?? AppColors.neutral100);
    final Color fg = !enabled
        ? AppColors.neutral300
        : (selected ? Colors.white : AppColors.neutral700);
    return Material(
      color: enabled ? bg : AppColors.neutral100,
      borderRadius: AppRadius.rMd,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadius.rMd,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rMd,
            border: Border.all(
              color: selected ? AppColors.brand500 : AppColors.neutral200,
            ),
          ),
          child: Text(label, style: AppType.titleMedium.copyWith(color: fg)),
        ),
      ),
    );
  }
}
