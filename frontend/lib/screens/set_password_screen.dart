import 'package:flutter/material.dart';
import '../models/api_error.dart';
import '../theme/app_tokens.dart';
import '../validators/password_policy.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import '../widgets/password_strength_meter.dart';
import '../i18n/locale_scope.dart';
import 'login_screen.dart';

/// Step 3: after OTP verification the user sets a password. Shows the live
/// requirements checklist + strength meter. On success the account is created
/// and logged in, then the root auth gate advances to PIN setup.
class SetPasswordScreen extends StatefulWidget {
  final String email;
  final String setupTicket;
  const SetPasswordScreen({
    super.key,
    required this.email,
    required this.setupTicket,
  });

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  ApiError? _error;
  Object? _otherError;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!PasswordPolicy.isAcceptable(_passwordCtrl.text)) {
      setState(() => _otherError = null);
      _formKey.currentState!.validate();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _otherError = null;
    });
    try {
      await AuthScope.read(context).setPassword(
        email: widget.email,
        setupTicket: widget.setupTicket,
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      // Return to the root auth gate, which now presents PIN setup.
      Navigator.popUntil(context, (route) => route.isFirst);
    } on ApiError catch (e) {
      setState(() => _error = e);
    } catch (e) {
      setState(() => _otherError = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final errorText = _error != null
        ? s.errorForCode(_error!.code, fallback: _error!.message)
        : _otherError != null
            ? '${s.cannotConnect}: $_otherError'
            : null;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              title: s.setPasswordTitle,
              subtitle: s.setPasswordSubtitle,
              leading: HeaderIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: AuthJourneyIndicator(
                activeStep: 2,
                visible: true,
                firstLabel: s.registerJourneyProfile,
                secondLabel: s.registerJourneyPassword,
                foreground: Theme.of(context).colorScheme.onSurface,
                isDark: Theme.of(context).brightness == Brightness.dark,
                onGradient: false,
              ),
            ),
            AuthFlowEntrance(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (errorText != null)
                        AuthErrorBanner(message: errorText),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: s.passwordLabel,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => PasswordPolicy.isAcceptable(v ?? '')
                            ? null
                            : s.passwordTooWeak,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PasswordStrengthMeter(password: _passwordCtrl.text),
                      const SizedBox(height: AppSpacing.lg),
                      PasswordRulesChecklist(password: _passwordCtrl.text),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: s.confirmPassword,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) => v != _passwordCtrl.text
                            ? s.passwordsNotMatch
                            : null,
                        onFieldSubmitted: (_) => _loading ? null : _submit(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(s.createAccountButton),
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
