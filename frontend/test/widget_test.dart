// Basic widget smoke test for CheckonApp.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:checkon/main.dart';
import 'package:checkon/services/auth_service.dart';
import 'package:checkon/services/app_lock_service.dart';
import 'package:checkon/i18n/locale_controller.dart';
import 'package:checkon/i18n/theme_controller.dart';
import 'package:checkon/screens/main_shell.dart';
import 'package:checkon/screens/pin_lock_screen.dart';
import 'package:checkon/screens/register_screen.dart';
import 'package:checkon/screens/setup_pin_screen.dart';
import 'package:checkon/widgets/app_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Unauthenticated app shows the login screen',
      (WidgetTester tester) async {
    final auth = AuthService();
    await auth.bootstrap();
    final lock = AppLockService();
    final locale = LocaleController();
    await locale.load();
    final theme = ThemeController();
    await theme.load();

    await tester.pumpWidget(
      CheckonApp(auth: auth, lock: lock, locale: locale, theme: theme),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final thai = find.text('ยินดีต้อนรับกลับ');
    final english = find.text('Welcome back');
    expect(thai.evaluate().isNotEmpty || english.evaluate().isNotEmpty, isTrue);
    expect(find.byType(AuthHeroHeader), findsOneWidget);
    expect(find.byType(AuthFormSurface), findsOneWidget);
    final loginHeaderHeight =
        tester.getSize(find.byType(AuthHeroHeader)).height;
    expect(find.byIcon(Icons.water_drop_rounded), findsNothing);
    expect(find.byIcon(Icons.shopping_basket_rounded), findsNothing);
    expect(
      find.descendant(
        of: find.byType(AuthHeroHeader),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );

    final signUp = find.text('สมัครสมาชิก').evaluate().isNotEmpty
        ? find.text('สมัครสมาชิก')
        : find.text('Sign up');
    await tester.ensureVisible(signUp);
    await tester.tap(signUp);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.byType(AuthHeroHeader), findsOneWidget);
    expect(find.byType(AuthFormSurface), findsOneWidget);
    expect(
      tester.getSize(find.byType(AuthHeroHeader)).height,
      loginHeaderHeight,
    );
    expect(
      find.text('ข้อมูลบัญชี').evaluate().isNotEmpty ||
          find.text('Account details').evaluate().isNotEmpty,
      isTrue,
    );
    expect(
      find.text('ตั้งรหัสผ่าน').evaluate().isNotEmpty ||
          find.text('Set password').evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('Startup displays the loading page artwork', (tester) async {
    final auth = AuthService();

    await tester.pumpWidget(
      CheckonApp(
        auth: auth,
        lock: AppLockService(),
        locale: LocaleController(),
        theme: ThemeController(),
      ),
    );

    expect(find.byKey(const ValueKey('startup-artwork')), findsOneWidget);
  });

  testWidgets('Authenticated user without a PIN must set one', (tester) async {
    final auth = await _authenticatedAuthService();
    final lock = _TestAppLockService(hasPin: false);

    await tester.pumpWidget(
      CheckonApp(
        auth: auth,
        lock: lock,
        locale: LocaleController(),
        theme: ThemeController(),
      ),
    );
    await tester.pump();

    expect(find.byType(SetupPinScreen), findsOneWidget);

    for (final digit in '123456'.split('')) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SetupPinScreen), findsOneWidget);
    expect(
      find.text('ยืนยันรหัส PIN').evaluate().isNotEmpty ||
          find.text('Confirm your PIN').evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.byType(MainShell), findsNothing);

    for (final digit in '123456'.split('')) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 500));

    expect(lock.pinWasSet, isTrue);
    expect(find.byType(MainShell), findsOneWidget);
  });

  testWidgets(
      'New registration must set and confirm a PIN despite an existing device PIN',
      (tester) async {
    final auth = AuthService(
      client: MockClient((_) async => http.Response(
            '{"accessToken":"new-access","refreshToken":"new-refresh"}',
            200,
          )),
    );
    await auth.bootstrap();
    final lock = _TestAppLockService(hasPin: true, pinIsValid: true);

    await tester.pumpWidget(
      CheckonApp(
        auth: auth,
        lock: lock,
        locale: LocaleController(),
        theme: ThemeController(),
      ),
    );
    await tester.pump();

    await auth.setPassword(
      email: 'new@example.com',
      setupTicket: 'setup-ticket',
      password: 'StrongPassword1!',
    );
    await tester.pump();

    expect(find.byType(SetupPinScreen), findsOneWidget);
    expect(find.byType(PinLockScreen), findsNothing);

    for (final digit in '123456'.split('')) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SetupPinScreen), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);

    for (final digit in '123456'.split('')) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 500));

    expect(lock.pinWasSet, isTrue);
    expect(find.byType(MainShell), findsOneWidget);
  });

  testWidgets('Authenticated user with a PIN is asked to unlock',
      (tester) async {
    final auth = await _authenticatedAuthService();

    await tester.pumpWidget(
      CheckonApp(
        auth: auth,
        lock: _TestAppLockService(hasPin: true),
        locale: LocaleController(),
        theme: ThemeController(),
      ),
    );
    await tester.pump();

    expect(find.byType(PinLockScreen), findsOneWidget);
    expect(find.byType(AuthPinHeader), findsOneWidget);
  });

  testWidgets('Wrong PIN does not shift keypad inside the PIN card',
      (tester) async {
    final auth = await _authenticatedAuthService();

    await tester.pumpWidget(
      CheckonApp(
        auth: auth,
        lock: _TestAppLockService(hasPin: true),
        locale: LocaleController(),
        theme: ThemeController(),
      ),
    );
    await tester.pump();

    final keypadTop = tester.getTopLeft(find.text('1')).dy;
    expect(find.text('จัดการของใช้ในบ้าน ให้ชีวิตง่ายขึ้น'), findsNothing);
    expect(find.byType(AppCard), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('กรุณาใส่ PIN 6 ตัว'), findsOneWidget);

    for (final digit in '123456'.split('')) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pump();

    expect(find.text('PIN ไม่ถูกต้อง'), findsOneWidget);
    expect(find.text('กรุณาใส่ PIN 6 ตัว'), findsNothing);
    expect(tester.getTopLeft(find.text('1')).dy, keypadTop);
  });

  testWidgets('Login prompts PIN setup when the device has no PIN',
      (tester) async {
    final auth = AuthService(
      client: MockClient((_) async => http.Response(
            '{"accessToken":"access","refreshToken":"refresh"}',
            200,
          )),
    );
    await auth.bootstrap();
    final lock = _TestAppLockService(hasPin: false);

    await tester.pumpWidget(
      CheckonApp(
        auth: auth,
        lock: lock,
        locale: LocaleController(),
        theme: ThemeController(),
      ),
    );
    await tester.pump();

    await auth.login(identifier: 'user@example.com', password: 'password');
    await tester.pump();

    expect(find.byType(SetupPinScreen), findsOneWidget);
    expect(find.byType(AuthPinHeader), findsOneWidget);
    expect(find.byKey(const ValueKey('startup-artwork')), findsNothing);
  });

  testWidgets('Login prompts PIN entry when the device already has a PIN',
      (tester) async {
    final auth = AuthService(
      client: MockClient((_) async => http.Response(
            '{"accessToken":"access","refreshToken":"refresh"}',
            200,
          )),
    );
    await auth.bootstrap();

    await tester.pumpWidget(
      CheckonApp(
        auth: auth,
        lock: _TestAppLockService(hasPin: true),
        locale: LocaleController(),
        theme: ThemeController(),
      ),
    );
    await tester.pump();

    await auth.login(identifier: 'user@example.com', password: 'password');
    await tester.pump();

    expect(find.byType(PinLockScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('startup-artwork')), findsNothing);
  });

  testWidgets('Unlocking with PIN shows Home skeleton, not startup artwork',
      (tester) async {
    final auth = await _authenticatedAuthService();

    await tester.pumpWidget(
      CheckonApp(
        auth: auth,
        lock: _TestAppLockService(hasPin: true, pinIsValid: true),
        locale: LocaleController(),
        theme: ThemeController(),
      ),
    );
    await tester.pump();

    for (final digit in '123456'.split('')) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pump();

    expect(find.byKey(const ValueKey('startup-artwork')), findsNothing);
    expect(find.byType(MainShell), findsOneWidget);
  });
}

Future<AuthService> _authenticatedAuthService() async {
  final auth = AuthService(
    client: MockClient((_) => Completer<http.Response>().future),
  );
  await auth.tokens.save(accessToken: 'access', refreshToken: 'refresh');
  await auth.bootstrap();
  return auth;
}

class _TestAppLockService extends AppLockService {
  final bool _hasPin;
  final bool _pinIsValid;
  bool _pinWasSet = false;

  bool get pinWasSet => _pinWasSet;

  _TestAppLockService({
    required bool hasPin,
    bool pinIsValid = false,
  })  : _hasPin = hasPin,
        _pinIsValid = pinIsValid;

  @override
  Future<bool> hasPin() async => _hasPin;

  @override
  Future<void> setPin(String pin) async {
    _pinWasSet = true;
  }

  @override
  Future<bool> verifyPin(String pin) async => _pinIsValid;

  @override
  Future<bool> isBiometricEnabled() async => false;

  @override
  Future<bool> canUseBiometrics() async => false;
}
