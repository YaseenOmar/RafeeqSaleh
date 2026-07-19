import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/app_models.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void>? _initializing;

  int get prayerScheduleDays => Platform.isIOS ? 12 : 60;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
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
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    } catch (_) {
      // tz.local remains UTC only on an unsupported platform. Android and iOS
      // return an IANA identifier through flutter_timezone.
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: false, sound: true) ??
          false;
    }
    return false;
  }

  Future<bool> permissionGranted() async {
    await initialize();
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          true;
    }
    if (Platform.isIOS) {
      final settings = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    return false;
  }

  Future<void> sync(
    List<NotificationReminder> reminders,
    Map<int, List<DateTime>> prayerDates,
  ) async {
    await initialize();
    await _plugin.cancelAllPendingNotifications();
    var notificationId = 20000;
    for (final reminder in reminders.where(
      (item) => item.enabled && item.id < 1100,
    )) {
      await _scheduleDaily(reminder);
    }
    for (final reminder in reminders.where((item) => item.enabled)) {
      if (reminder.id < 1100) continue;
      for (final date in prayerDates[reminder.id] ?? const <DateTime>[]) {
        if (date.isAfter(DateTime.now())) {
          await _schedule(reminder, date, notificationId++);
        }
      }
    }
  }

  Future<void> _scheduleDaily(NotificationReminder reminder) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminder.hour,
      reminder.minute,
    );
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: scheduledDate,
      notificationDetails: _details(reminder),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'reminder:${reminder.id}',
    );
  }

  Future<void> _schedule(
    NotificationReminder reminder,
    DateTime date,
    int notificationId,
  ) async {
    final scheduledDate = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
    );

    await _plugin.zonedSchedule(
      id: notificationId,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: scheduledDate,
      notificationDetails: _details(reminder),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'reminder:${reminder.id}',
    );
  }

  NotificationDetails _details(NotificationReminder reminder) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'التذكيرات اليومية',
          channelDescription: 'تذكيرات الأذكار والورد اليومي ومواقيت الصلاة',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xff063b30),
          styleInformation: BigTextStyleInformation(reminder.body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        ),
      );
}
