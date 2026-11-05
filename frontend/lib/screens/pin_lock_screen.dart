import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_lock_scope.dart';
import '../widgets/app_widgets.dart';
import '../widgets/pin_pad.dart';
import '../i18n/locale_scope.dart';

/// Full-screen lock shown on launch when a PIN is configured. Calls
/// [onUnlocked] once the correct PIN (or biometric) is provided.
class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const PinLockScreen({super.key, required this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';
  bool _error = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBiometric());
  }

  Future<void> _checkBiometric() async {
    final lock = AppLockScope.read(context);
    final can = await lock.canUseBiometrics();
    final enabled = await lock.isBiometricEnabled();
    if (!mounted) return;
    setState(() => _biometricAvailable = can && enabled);
  }

  Future<void> _tryBiometric() async {
    final lock = AppLockScope.read(context);
    final ok =
        await lock.authenticateBiometric(context.strings.biometricReason);
    if (ok && mounted) widget.onUnlocked();
  }

  Future<void> _onCompleted(String pin) async {
    final ok = await AppLockScope.read(context).verifyPin(pin);
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = true;
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDark ? AppGradients.backgroundDark : AppGradients.background,
        ),
        child: SafeArea(
          child: Column(
            children: [
              AuthPinHeader(
                title: s.enterPinTitle,
                subtitle: s.appTitle,
              ),
              Expanded(
                child: AuthFlowEntrance(
                  child: LayoutBuilder(
                    builder: (context, contentConstraints) {
                      final keypadHeight =
                          contentConstraints.maxHeight - 28 - AppSpacing.md;
                      final maxKeySize = keypadHeight >= 482
                          ? 86.0
                          : ((keypadHeight - 40) / 5.6)
                              .clamp(40.0, 86.0)
                              .toDouble();
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: AppCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 28,
                                  child: Center(
                                    child: Text(
                                      _error ? s.wrongPin : s.enterSixDigitPin,
                                      style: AppType.bodyMedium.copyWith(
                                        color: _error
                                            ? AppColors.danger
                                            : AppColors.neutral600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                PinPad(
                                  value: _pin,
                                  maxKeySize: maxKeySize,
                                  error: _error,
                                  onChanged: (v) => setState(() {
                                    _pin = v;
                                    _error = false;
                                  }),
                                  onCompleted: _onCompleted,
                                  leadingKey: _biometricAvailable
                                      ? const Icon(Icons.fingerprint_rounded,
                                          color: AppColors.brand500)
                                      : null,
                                  onLeadingKey: _biometricAvailable
                                      ? _tryBiometric
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
