import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/app_models.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void>? _initializing;

  int get prayerScheduleDays {
    if (foundation.kIsWeb) return 0;
    return Platform.isIOS ? 12 : 60;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (foundation.kIsWeb) return;

    final pending = _initializing;
    if (pending != null) return pending;

    final initialization = _initialize();
    _initializing = initialization;
    try {
      await initialization;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    try {
      final dynamic timezone = await FlutterTimezone.getLocalTimezone();
      final String tzName = timezone is String ? timezone : timezone.identifier;
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('[Notifications] Timezone: $tzName');
    } catch (e) {
      debugPrint('[Notifications] Timezone error: $e');
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    // In version 17+, initialize uses named parameters
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[Notifications] Clicked: ${response.payload}');
      },
    );

    if (Platform.isAndroid) {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(_androidChannel);
    }

    _initialized = true;
  }

  static const _androidChannel = AndroidNotificationChannel(
    'rafeeq_v1',
    'تنبيهات الرفيق الصالح',
    description: 'الأذكار ومواقيت الصلاة',
    importance: Importance.max,
  );

  Future<bool> requestPermission() async {
    if (foundation.kIsWeb) return false;
    await initialize();
    try {
      if (Platform.isAndroid) {
        final android = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final bool? granted = await android?.requestNotificationsPermission();
        return granted ?? false;
      }
      if (Platform.isIOS) {
        final ios = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        return await ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> permissionGranted() async {
    if (foundation.kIsWeb) return false;
    await initialize();
    if (Platform.isAndroid) {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.areNotificationsEnabled() ?? false;
    }
    if (Platform.isIOS) {
      final ios = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final settings = await ios?.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    return false;
  }

  Future<int> sync(
    List<NotificationReminder> reminders,
    Map<int, List<DateTime>> prayerDates,
  ) async {
    await initialize();
    try {
      await _notificationsPlugin.cancelAll();
      var count = 0;
      var id = 40000;

      for (final r in reminders.where((e) => e.enabled && e.id < 1100)) {
        await _scheduleDaily(r);
        count++;
      }

      for (final r in reminders.where((e) => e.enabled && e.id >= 1100)) {
        for (final date in prayerDates[r.id] ?? []) {
          if (date.isAfter(DateTime.now())) {
            await _schedule(r, date, id++);
            count++;
          }
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  Future<void> showTestNotification() async {
    await initialize();
    await _notificationsPlugin.show(
      888,
      'الرفيق الصالح',
      'الإشعارات تعمل بشكل صحيح',
      _details(NotificationReminder.defaults.first),
    );
  }

  Future<void> _scheduleDaily(NotificationReminder r) async {
    final now = tz.TZDateTime.now(tz.local);
    var date = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      r.hour,
      r.minute,
    );
    if (!date.isAfter(now)) date = date.add(const Duration(days: 1));

    await _notificationsPlugin.zonedSchedule(
      r.id,
      r.title,
      r.body,
      date,
      _details(r),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _schedule(NotificationReminder r, DateTime d, int nid) async {
    final date = tz.TZDateTime.from(d, tz.local);
    await _notificationsPlugin.zonedSchedule(
      nid,
      r.title,
      r.body,
      date,
      _details(r),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  NotificationDetails _details(NotificationReminder r) => NotificationDetails(
    android: AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.max,
      color: const Color(0xff063b30),
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    ),
  );

  Future<int> pendingCount() async {
    if (foundation.kIsWeb) return 0;
    return (await _notificationsPlugin.pendingNotificationRequests()).length;
  }
}
