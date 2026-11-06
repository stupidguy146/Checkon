import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/expiring_item.dart';
import '../models/product.dart';
import '../i18n/app_strings.dart';

/// Schedules **local** notifications (fired by the OS, not a server) that
/// remind the user about household items expiring soon (<= [thresholdDays]).
///
/// Platform support: iOS / Android / macOS. On **web** every method is a
/// safe no-op so the app keeps working in Chrome without throwing.
///
/// Scheduling model: one reminder per expiring item, fired at 09:00 local
/// time on the next eligible day. Re-syncing cancels the previous batch and
/// re-schedules from the latest data (call it on app start / after login and
/// whenever items change).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int thresholdDays = 3;
  static const int _notifyHour = 9; // 09:00 local

  /// Notification ids are namespaced so syncing one category cannot cancel
  /// reminders belonging to another.
  static const String _channelId = 'expiring_items';
  static const String _channelName = 'Expiring items';
  static const String _productChannelId = 'product_status';
  static const String _productChannelName = 'Product status';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void>? _initialization;

  /// Initialise the plugin + timezone database. Safe to call multiple times.
  Future<void> init() {
    if (kIsWeb || _initialized) return Future<void>.value();
    return _initialization ??= _initialize().whenComplete(() {
      if (!_initialized) _initialization = null;
    });
  }

  Future<void> _initialize() async {
    tzdata.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      // fall back to UTC if the platform can't report a zone
    }

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const macInit = DarwinInitializationSettings();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
        macOS: macInit,
      ),
    );
    _initialized = true;
  }

  /// Ask the user for permission to post notifications. Returns true when
  /// granted (or already granted). No-op → true on web.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await init();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final mac = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (mac != null) {
      final granted = await mac.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  /// Replace expiring-item reminders without disturbing product-status
  /// reminders. [strings] localises title/body.
  Future<void> syncExpiring(
    List<ExpiringItem> items,
    AppStrings strings,
  ) async {
    if (kIsWeb) return;
    await init();
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final isLegacyExpiring = request.payload == null &&
          (request.title == strings.notiExpiringTitle ||
              request.title == strings.notiRecurringTitle);
      if (isLegacyExpiring ||
          request.payload?.startsWith('expiring:') == true) {
        await _plugin.cancel(id: request.id);
      }
    }

    final eligible = items.where((it) {
      final d = it.daysUntilExpiry;
      return d != null && d <= thresholdDays;
    }).toList();

    for (final it in eligible) {
      final when = _nextNineAm();
      final days = it.daysUntilExpiry ?? 0;
      final recurring = it.notifyRecurring;
      final title =
          recurring ? strings.notiRecurringTitle : strings.notiExpiringTitle;
      final body = recurring
          ? strings.notiRecurringBody(it.name, days)
          : (days < 0
              ? strings.notiExpiredBody(it.name)
              : strings.notiExpiringBody(it.name, days));

      await _plugin.zonedSchedule(
        id: _idFor('expiring:${it.itemId}'),
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'expiring:${it.itemId}',
      );
    }
  }

  /// Remind the user the next day about products marked low or out. Returning
  /// a product to stock cancels its pending reminder.
  Future<void> syncProductStatusReminder({
    required Product product,
    required AppStrings strings,
  }) async {
    if (kIsWeb) return;
    await init();
    await cancelProductStatusReminder(productId: product.productId);
    if (product.status == ProductStatus.inStock) return;

    final payload = 'product-status:${product.productId}';
    final id = _idFor(payload);
    final isOut = product.status == ProductStatus.out;
    await _plugin.zonedSchedule(
      id: id,
      title: isOut
          ? strings.productOutReminderTitle
          : strings.productLowReminderTitle,
      body: isOut
          ? strings.productOutReminderBody(product.name)
          : strings.productLowReminderBody(product.name),
      scheduledDate: _tomorrowNineAm(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _productChannelId,
          _productChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> syncProductStatusRemindersForMonth({
    required List<Product> products,
    required List<Product> productsToBuy,
    required AppStrings strings,
  }) async {
    if (kIsWeb) return;
    final productsToBuyById = {
      for (final product in productsToBuy) product.productId: product,
    };
    for (final product in products) {
      final activeProduct = productsToBuyById[product.productId];
      if (activeProduct == null) {
        await cancelProductStatusReminder(productId: product.productId);
      } else {
        await syncProductStatusReminder(
          product: activeProduct,
          strings: strings,
        );
      }
    }
  }

  Future<void> cancelProductStatusReminder({
    required String productId,
  }) async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancel(id: _idFor('product-status:$productId'));
  }

  /// Cancel all scheduled reminders (e.g. on logout). No-op on web.
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancelAll();
  }

  /// Next 09:00 local time: today if 09:00 hasn't passed yet, otherwise
  /// tomorrow.
  tz.TZDateTime _nextNineAm() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, _notifyHour);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _tomorrowNineAm() {
    final now = tz.TZDateTime.now(tz.local);
    return tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + 1,
      _notifyHour,
    );
  }

  /// Stable, positive 31-bit id derived from the notification key.
  int _idFor(String key) {
    var hash = 0x811c9dc5;
    for (final codeUnit in key.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}
