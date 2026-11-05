import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_lock_scope.dart';
import '../widgets/app_widgets.dart';
import '../widgets/pin_pad.dart';
import '../i18n/locale_scope.dart';

/// Post-registration: create a 6-digit PIN (enter + confirm), then optionally
/// enable biometric unlock. PIN is stored hashed locally; nothing leaves the
/// device. Finishing notifies the auth gate to enter the app.
class SetupPinScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SetupPinScreen({super.key, required this.onComplete});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

enum _Step { enter, confirm, biometric }

class _SetupPinScreenState extends State<SetupPinScreen> {
  _Step _step = _Step.enter;
  String _first = '';
  String _pin = '';
  bool _error = false;
  bool _biometricAvailable = false;
  bool _saving = false;

  Future<void> _onCompleted(String pin) async {
    if (_step == _Step.enter) {
      setState(() {
        _first = pin;
        _pin = '';
        _error = false;
        _step = _Step.confirm;
      });
      return;
    }
    // confirm step
    if (pin != _first) {
      setState(() {
        _error = true;
        _pin = '';
      });
      return;
    }
    setState(() => _saving = true);
    final lock = AppLockScope.read(context);
    await lock.setPin(pin);
    final canBio = await lock.canUseBiometrics();
    if (!mounted) return;
    if (canBio) {
      setState(() {
        _biometricAvailable = true;
        _saving = false;
        _step = _Step.biometric;
      });
    } else {
      _enterApp();
    }
  }

  Future<void> _enableBiometric() async {
    final lock = AppLockScope.read(context);
    final ok =
        await lock.authenticateBiometric(context.strings.biometricReason);
    if (ok) await lock.setBiometricEnabled(true);
    _enterApp();
  }

  void _enterApp() {
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;

    if (_step == _Step.biometric && _biometricAvailable) {
      return Scaffold(
        body: SafeArea(
          child: AuthFlowEntrance(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.fingerprint_rounded,
                      size: 88, color: AppColors.brand500),
                  const SizedBox(height: AppSpacing.xl),
                  Text(s.enableBiometric,
                      textAlign: TextAlign.center,
                      style: AppType.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(s.useBiometric,
                      textAlign: TextAlign.center,
                      style: AppType.bodyLarge
                          .copyWith(color: AppColors.neutral600)),
                  const SizedBox(height: AppSpacing.xxl),
                  FilledButton.icon(
                    onPressed: _enableBiometric,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: Text(s.enableBiometric),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(onPressed: _enterApp, child: Text(s.skipForNow)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final title = _step == _Step.enter ? s.setupPinTitle : s.confirmPinTitle;
    final subtitle =
        _step == _Step.enter ? s.setupPinSubtitle : s.confirmPinSubtitle;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDark ? AppGradients.backgroundDark : AppGradients.background,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AuthPinHeader(
                        title: title,
                        subtitle: s.appTitle,
                      ),
                      AuthFlowEntrance(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg),
                          child: AppCard(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.xl,
                              AppSpacing.lg,
                              AppSpacing.lg,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.aqua,
                                    borderRadius: AppRadius.rXl,
                                    boxShadow:
                                        AppShadows.brandGlow(AppColors.aqua),
                                  ),
                                  child: Icon(
                                    _step == _Step.enter
                                        ? Icons.lock_outline_rounded
                                        : Icons.verified_user_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 320),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: Tween<double>(
                                        begin: 0.96,
                                        end: 1,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                                  child: Text(
                                    subtitle,
                                    key: ValueKey(subtitle),
                                    textAlign: TextAlign.center,
                                    style: AppType.bodyMedium.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.neutral600,
                                    ),
                                  ),
                                ),
                                if (_error) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.coralTint,
                                      borderRadius: AppRadius.rMd,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          size: 18,
                                          color: AppColors.danger,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(
                                          s.pinMismatch,
                                          style: AppType.bodyMedium.copyWith(
                                            color: AppColors.danger,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.lg),
                                if (_saving)
                                  const Padding(
                                    padding: EdgeInsets.all(AppSpacing.xxl),
                                    child: CircularProgressIndicator(),
                                  )
                                else
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 320),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.035),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    ),
                                    child: PinPad(
                                      key: ValueKey(_step),
                                      value: _pin,
                                      error: _error,
                                      onChanged: (v) => setState(() {
                                        _pin = v;
                                        _error = false;
                                      }),
                                      onCompleted: _onCompleted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
