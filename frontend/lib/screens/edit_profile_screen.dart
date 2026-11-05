import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../i18n/locale_scope.dart';
import '../models/api_error.dart';
import '../models/customer_profile.dart';
import '../services/customer_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _titles = ['mr', 'mrs', 'ms', 'unspecified'];

  CustomerService? _service;
  Future<CustomerProfile>? _future;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _statusCtrl = TextEditingController();

  String _title = 'unspecified';
  String? _avatar; // data URL or null
  bool _avatarTouched = false;
  DateTime? _birthDate;
  bool _saving = false;
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service ??= CustomerService(auth: AuthScope.of(context));
    _future ??= _load();
  }

  Future<CustomerProfile> _load() async {
    final p = await _service!.getMyProfile();
    if (!_loadedOnce) {
      _title = _titles.contains(p.title) ? p.title : 'unspecified';
      _firstNameCtrl.text = p.firstName;
      _lastNameCtrl.text = p.lastName;
      _usernameCtrl.text = p.username;
      _statusCtrl.text = p.status ?? '';
      _avatar = p.avatarBase64;
      if (p.birthDate != null) {
        _birthDate = DateTime.tryParse(p.birthDate!);
      }
      _loadedOnce = true;
    }
    return p;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _statusCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    // infer a reasonable mime from extension
    final ext = file.name.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    setState(() {
      _avatar = 'data:$mime;base64,$b64';
      _avatarTouched = true;
    });
  }

  void _removeAvatar() {
    setState(() {
      _avatar = null;
      _avatarTouched = true;
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final s = context.strings;
    final dataRefresh = DataScope.of(context);
    setState(() => _saving = true);
    try {
      await _service!.updateMyProfile(
        title: _title,
        username: _usernameCtrl.text.trim(),
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        status:
            _statusCtrl.text.trim().isEmpty ? null : _statusCtrl.text.trim(),
        avatarBase64: _avatarTouched ? _avatar : CustomerService.leaveAvatar,
        birthDate: _birthDate?.toIso8601String().substring(0, 10),
      );
      dataRefresh.bump();
      if (mounted) {
        AppSnackBar.show(messenger, s.profileSaved, SnackKind.success);
        Navigator.pop(context, true);
      }
    } on ApiError catch (e) {
      if (mounted) {
        AppSnackBar.show(messenger, s.errorForCode(e.code, fallback: e.message),
            SnackKind.error);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(messenger, s.errorWith(e), SnackKind.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final df = DateFormat('d MMM yyyy', context.locale.lang);
    return Scaffold(
      body: FutureBuilder<CustomerProfile>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
              error: snapshot.error!,
              onRetry: () => setState(() {
                _future = _load();
              }),
            );
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                GradientHeader(
                  subtitle: s.myProfile,
                  title: s.editProfile,
                  leading: _HeaderIconButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -36),
                  child: _AvatarPicker(
                    avatar: _avatar,
                    onPick: _pickAvatar,
                    onRemove: _avatar != null ? _removeAvatar : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _VerifyEmailBanner(),
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
                        onChanged: _saving
                            ? null
                            : (v) =>
                                setState(() => _title = v ?? 'unspecified'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _firstNameCtrl,
                              decoration: InputDecoration(
                                labelText: s.firstName,
                                prefixIcon: const Icon(Icons.badge_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextField(
                              controller: _lastNameCtrl,
                              decoration:
                                  InputDecoration(labelText: s.lastName),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _usernameCtrl,
                        decoration: InputDecoration(
                          labelText: s.username,
                          prefixIcon: const Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _statusCtrl,
                        maxLength: 280,
                        decoration: InputDecoration(
                          labelText: s.statusField,
                          prefixIcon:
                              const Icon(Icons.chat_bubble_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _BirthDateField(
                        value: _birthDate,
                        label: _birthDate == null
                            ? s.pickBirthDate
                            : s.birthDateOn(df.format(_birthDate!)),
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showAdaptiveDatePicker(
                            context: context,
                            initialDate: _birthDate ?? DateTime(now.year - 20),
                            firstDate: DateTime(1900),
                            lastDate: now,
                          );
                          if (picked != null) {
                            setState(() => _birthDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(s.save),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final String? avatar;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  const _AvatarPicker({
    required this.avatar,
    required this.onPick,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = _decode(avatar);
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brand100,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: AppShadows.md,
                image: bytes != null
                    ? DecorationImage(
                        image: MemoryImage(bytes), fit: BoxFit.cover)
                    : null,
              ),
              child: bytes == null
                  ? const Icon(Icons.person_rounded,
                      size: 52, color: AppColors.brand500)
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: AppColors.brand500,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPick,
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Icon(Icons.camera_alt_rounded,
                        size: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (onRemove != null)
          TextButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(context.strings.removePhoto),
          ),
      ],
    );
  }

  static dynamic _decode(String? avatar) {
    if (avatar == null || avatar.isEmpty) return null;
    try {
      final b64 = avatar.contains(',') ? avatar.split(',').last : avatar;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }
}

class _BirthDateField extends StatelessWidget {
  final DateTime? value;
  final String label;
  final VoidCallback onTap;

  const _BirthDateField({
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.rMd,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor ??
              AppColors.neutral100,
          borderRadius: AppRadius.rMd,
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined,
                color: AppColors.neutral500, size: 20),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: TextStyle(
                color: value == null
                    ? AppColors.neutral500
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifyEmailBanner extends StatefulWidget {
  const _VerifyEmailBanner();

  @override
  State<_VerifyEmailBanner> createState() => _VerifyEmailBannerState();
}

class _VerifyEmailBannerState extends State<_VerifyEmailBanner> {
  bool _sending = false;
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final auth = AuthScope.of(context);
    final user = auth.user;
    if (user == null || user.emailVerified) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: AppRadius.rMd,
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_outlined,
              color: AppColors.accent600, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              _sent ? s.verificationSent : s.emailNotVerified,
              style: AppType.bodyMedium.copyWith(
                color: AppColors.accent600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!_sent)
            TextButton(
              onPressed: _sending
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _sending = true);
                      try {
                        await auth.resendVerification();
                        if (mounted) setState(() => _sent = true);
                      } catch (_) {
                        AppSnackBar.show(
                            messenger, s.sendFailed, SnackKind.error);
                      } finally {
                        if (mounted) setState(() => _sending = false);
                      }
                    },
              child: Text(_sending ? s.sending : s.resend),
            ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HeaderIconButton(icon: icon, onTap: onTap);
  }
}
