import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/api_error.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import '../i18n/locale_scope.dart';
import '../i18n/language_toggle.dart';
import 'login_screen.dart';
import 'otp_verify_screen.dart';

/// Step 1 of the new registration flow: collect title + name + username +
/// email (no password here). On submit we create a pending account and the
/// backend emails a 6-digit OTP, then we move to [OtpVerifyScreen].
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _titles = ['mr', 'mrs', 'ms', 'unspecified'];

  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _title = 'unspecified';
  bool _loading = false;
  ApiError? _error;
  Object? _otherError;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _otherError = null;
    });
    final email = _emailCtrl.text.trim();
    try {
      final expiresInSec = await AuthScope.read(context).register(
        email: email,
        title: _title,
        username: _usernameCtrl.text.trim(),
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(
            email: email,
            otpExpiresInSec: expiresInSec,
          ),
        ),
      );
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
            AuthHeroHeader(
              title: s.createAccount,
              subtitle: s.registerSubtitle,
              journeyStep: 1,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: AuthFormSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (errorText != null)
                        AuthErrorBanner(message: errorText),
                      AdaptiveDropdownFormField<String>(
                        initialValue: _title,
                        decoration: InputDecoration(
                          labelText: s.title,
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                        items: [
                          for (final t in _titles)
                            DropdownMenuItem(
                              value: t,
                              child: Text(s.titleLabel(t)),
                            ),
                        ],
                        onChanged: _loading
                            ? null
                            : (v) =>
                                setState(() => _title = v ?? 'unspecified'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: s.firstName,
                                prefixIcon: const Icon(Icons.badge_outlined),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? s.enterFirstName
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameCtrl,
                              textInputAction: TextInputAction.next,
                              decoration:
                                  InputDecoration(labelText: s.lastName),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? s.enterLastName
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _usernameCtrl,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9._-]')),
                        ],
                        decoration: InputDecoration(
                          labelText: s.username,
                          prefixIcon: const Icon(Icons.alternate_email_rounded),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          final re = RegExp(r'^[a-zA-Z0-9._-]{3,30}$');
                          return re.hasMatch(value) ? null : s.usernameRule;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: s.email,
                          prefixIcon: const Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          return re.hasMatch(value) ? null : s.invalidEmail;
                        },
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
                            : Text(s.continueLabel),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.haveAccount,
                              style: Theme.of(context).textTheme.bodyMedium),
                          TextButton(
                            onPressed:
                                _loading ? null : () => Navigator.pop(context),
                            child: Text(s.signIn),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Center(child: LanguageToggle(onGradient: false)),
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
