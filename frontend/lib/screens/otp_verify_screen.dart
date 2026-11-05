import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/api_error.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import '../widgets/app_snackbar.dart';
import '../i18n/locale_scope.dart';
import 'login_screen.dart';
import 'set_password_screen.dart';

/// Step 2: the user enters the 6-digit OTP emailed to them. On success we get
/// a setup ticket and continue to [SetPasswordScreen].
class OtpVerifyScreen extends StatefulWidget {
  final String email;
  final int otpExpiresInSec;
  const OtpVerifyScreen({
    super.key,
    required this.email,
    required this.otpExpiresInSec,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _otpCtrl = TextEditingController();
  final _focus = FocusNode();
  bool _loading = false;
  bool _resending = false;
  ApiError? _error;
  Object? _otherError;

  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown(widget.otpExpiresInSec);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _secondsLeft = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) return;
    setState(() {
      _loading = true;
      _error = null;
      _otherError = null;
    });
    try {
      final ticket = await AuthScope.read(context)
          .verifyOtp(email: widget.email, otp: otp);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SetPasswordScreen(email: widget.email, setupTicket: ticket),
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

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
      _otherError = null;
    });
    try {
      final sec = await AuthScope.read(context).resendOtp(widget.email);
      if (!mounted) return;
      _otpCtrl.clear();
      _startCountdown(sec);
      AppSnackBar.success(context, context.strings.otpResent);
    } on ApiError catch (e) {
      setState(() => _error = e);
    } catch (e) {
      setState(() => _otherError = e);
    } finally {
      if (mounted) setState(() => _resending = false);
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
    final canResend = _secondsLeft == 0 && !_resending;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              title: s.verifyEmailTitle,
              subtitle: s.enterOtp,
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
                    const SizedBox(height: AppSpacing.sm),
                    const Icon(Icons.mark_email_unread_outlined,
                        size: 64, color: AppColors.brand500),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      s.otpSentTo(widget.email),
                      textAlign: TextAlign.center,
                      style: AppType.bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (errorText != null) AuthErrorBanner(message: errorText),
                    TextField(
                      controller: _otpCtrl,
                      focusNode: _focus,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 12,
                          color: Theme.of(context).colorScheme.onSurface),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        labelText: s.enterOtp,
                      ),
                      onChanged: (v) {
                        if (v.length == 6 && !_loading) _verify();
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      s.otpDevHint,
                      textAlign: TextAlign.center,
                      style:
                          AppType.caption.copyWith(color: AppColors.neutral400),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _loading ? null : _verify,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(s.verifyOtpButton),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(s.didntGetCode,
                            style: Theme.of(context).textTheme.bodyMedium),
                        TextButton(
                          onPressed: canResend ? _resend : null,
                          child: _resending
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(_secondsLeft > 0
                                  ? s.resendOtpIn(_secondsLeft)
                                  : s.resendOtp),
                        ),
                      ],
                    ),
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
