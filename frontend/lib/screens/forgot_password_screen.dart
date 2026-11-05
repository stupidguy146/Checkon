import 'package:flutter/material.dart';
import '../i18n/locale_scope.dart';
import '../models/api_error.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import '../widgets/app_snackbar.dart';

/// Step 1: request a reset email. Step 2 (ResetPasswordScreen) completes it
/// with the token from the email (pasted manually in dev — no deep links yet).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      await AuthScope.read(context).forgotPassword(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      // forgot-password always succeeds server-side; treat as sent
      if (mounted) setState(() => _sent = true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              title: s.forgotTitle,
              leading: HeaderIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            AuthFlowEntrance(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_sent) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.10),
                          borderRadius: AppRadius.rMd,
                        ),
                        child: Text(
                          s.resetSentInfo,
                          style: AppType.bodyMedium
                              .copyWith(color: AppColors.neutral800),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ResetPasswordScreen()),
                        ),
                        child: Text(s.haveTokenAlready),
                      ),
                    ] else ...[
                      Text(
                        s.forgotHint,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: s.email,
                          prefixIcon: const Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: _sending ? null : _submit,
                        child: _sending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(s.sendResetLink),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  bool _saving = false;
  ApiError? _error;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthScope.read(context).resetPassword(
        token: _tokenCtrl.text.trim(),
        newPassword: _newCtrl.text,
      );
      if (mounted) {
        AppSnackBar.success(context, context.strings.resetSuccess);
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    } on ApiError catch (e) {
      setState(() => _error = e);
    } catch (e) {
      setState(() => _error = ApiError(statusCode: 0, message: '$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              title: s.resetTitle,
              leading: HeaderIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => Navigator.pop(context),
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
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.10),
                            borderRadius: AppRadius.rMd,
                          ),
                          child: Text(
                              s.errorForCode(_error!.code,
                                  fallback: _error!.message),
                              style: AppType.bodyMedium
                                  .copyWith(color: AppColors.danger)),
                        ),
                      TextFormField(
                        controller: _tokenCtrl,
                        decoration: InputDecoration(
                          labelText: s.tokenFromEmail,
                          prefixIcon: const Icon(Icons.vpn_key_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? s.enterToken
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _newCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: s.newPasswordMin8,
                          prefixIcon: const Icon(Icons.lock_reset_rounded),
                        ),
                        validator: (v) => (v == null || v.length < 8)
                            ? s.newPasswordMin8Rule
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(s.resetTitle),
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
