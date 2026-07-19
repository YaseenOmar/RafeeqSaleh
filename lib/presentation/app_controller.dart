import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import '../data/local_store.dart';
import '../domain/app_models.dart';
import '../services/local_notification_service.dart';

class AppController extends ChangeNotifier {
  AppController(this.repository, [this.notificationService]);
  final AppRepository repository;
  final LocalNotificationService? notificationService;
  AppSettings settings = const AppSettings();
  ReadingProgress? progress;
  List<ReadingProgress> history = [];
  List<QuranBookmark> bookmarks = [];
  Map<String, int> athkarProgress = {};
  int tasbihCount = 0, tasbihGoal = 33;
  List<NotificationReminder> reminders = NotificationReminder.defaults;
  bool notificationPermissionGranted = false;
  bool notificationSyncInProgress = false;
  int scheduledNotificationCount = 0;
  String? notificationError;
  bool notificationPermissionRequested = false;

  PrayerTimes? prayerTimes;
  Timer? _prayerTimer;
  String? _lastPrayerSyncKey;
  bool _notificationPermissionRequestInProgress = false;

  Future<void> load() async {
    settings = await repository.loadSettings();
    progress = await repository.loadProgress();
    history = await repository.loadHistory();
    bookmarks = await repository.loadBookmarks();
    athkarProgress = await repository.loadAthkarProgress();
    tasbihCount = await repository.loadTasbih();
    tasbihGoal = await repository.loadTasbihGoal();
    reminders = await repository.loadReminders();
    notificationPermissionRequested = await repository
        .loadNotificationPermissionRequested();
    // Notification plugins use a platform channel and must never hold up app
    // startup. Some devices can leave this call pending while Android restores
    // the activity, which otherwise keeps the native splash visible forever.
    unawaited(_loadNotificationState());

    if (settings.latitude != null && settings.longitude != null) {
      _calculatePrayerTimes();
    } else {
      determinePosition()
          .then((pos) {
            updateSettings(
              settings.copyWith(
                latitude: pos.latitude,
                longitude: pos.longitude,
                locationName: 'موقعي الحالي',
              ),
            );
          })
          .catchError((_) {});
    }

    _startPrayerTimer();
    notifyListeners();
  }

  Future<void> refreshNotificationState() async {
    final service = notificationService;
    if (service == null || _notificationPermissionRequestInProgress) return;
    try {
      var granted = await service.permissionGranted().timeout(
        const Duration(seconds: 5),
      );
      // Some Android builds briefly return a stale value while the system
      // permission sheet or app settings activity is closing.
      if (!granted) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        granted = await service.permissionGranted().timeout(
          const Duration(seconds: 5),
        );
      }
      notificationPermissionGranted = granted;
      notifyListeners();
    } catch (error) {
      notificationError = error.toString();
      notifyListeners();
      return;
    }

    if (!notificationPermissionGranted) {
      scheduledNotificationCount = 0;
      return;
    }

    try {
      await _syncNotifications().timeout(const Duration(seconds: 15));
    } catch (_) {
      // Permission remains granted even when an individual device refuses or
      // delays scheduling alarms. The scheduling error is shown separately.
    }
  }

  Future<void> _loadNotificationState() => refreshNotificationState();

  void _startPrayerTimer() {
    _prayerTimer?.cancel();
    _prayerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (settings.latitude != null) {
        _calculatePrayerTimes();
      }
    });
  }

  void _calculatePrayerTimes() {
    if (settings.latitude == null) return;

    final coordinates = Coordinates(settings.latitude!, settings.longitude!);
    final params = _getParams();

    prayerTimes = PrayerTimes.today(coordinates, params);
    _applyTodayPrayerTimes(prayerTimes!);
    if (notificationPermissionGranted) {
      unawaited(_syncNotifications());
    }
    notifyListeners();
  }

  void _applyTodayPrayerTimes(PrayerTimes times) {
    final dates = <int, DateTime>{
      1101: times.fajr,
      1102: times.dhuhr,
      1103: times.asr,
      1104: times.maghrib,
      1105: times.isha,
    };
    reminders = reminders.map((reminder) {
      final date = dates[reminder.id];
      return date == null
          ? reminder
          : reminder.copyWith(hour: date.hour, minute: date.minute);
    }).toList();
  }

  Map<int, List<DateTime>> _prayerDatesForNextWeek() {
    if (settings.latitude == null || settings.longitude == null) return {};
    final coordinates = Coordinates(settings.latitude!, settings.longitude!);
    final dates = <int, List<DateTime>>{
      for (final reminder in NotificationReminder.defaults) reminder.id: [],
    };
    final now = DateTime.now();
    final scheduleDays = notificationService?.prayerScheduleDays ?? 7;
    for (var day = 0; day < scheduleDays; day++) {
      final date = now.add(Duration(days: day));
      final times = PrayerTimes(
        coordinates,
        DateComponents.from(date),
        _getParams(),
      );
      dates[1101]!.add(times.fajr);
      dates[1102]!.add(times.dhuhr);
      dates[1103]!.add(times.asr);
      dates[1104]!.add(times.maghrib);
      dates[1105]!.add(times.isha);
    }
    return dates;
  }

  Future<void> _syncNotifications({bool force = false}) async {
    final service = notificationService;
    if (service == null) return;
    final now = DateTime.now();
    final enabled = reminders
        .map((item) => '${item.id}:${item.enabled}:${item.hour}:${item.minute}')
        .join(',');
    final syncKey =
        '${now.year}-${now.month}-${now.day}:'
        '${settings.latitude}:${settings.longitude}:'
        '${settings.calculationMethodIndex}:$enabled';
    if (!force && _lastPrayerSyncKey == syncKey) {
      scheduledNotificationCount = await service.pendingCount();
      return;
    }
    notificationSyncInProgress = true;
    notificationError = null;
    notifyListeners();
    try {
      scheduledNotificationCount = await service.sync(
        reminders,
        _prayerDatesForNextWeek(),
      );
      _lastPrayerSyncKey = syncKey;
    } catch (error) {
      notificationError = error.toString();
      rethrow;
    } finally {
      notificationSyncInProgress = false;
      notifyListeners();
    }
  }

  CalculationParameters _getParams() {
    CalculationParameters params;
    switch (settings.calculationMethodIndex) {
      case 0:
        params = CalculationMethod.muslim_world_league.getParameters();
        break;
      case 1:
        params = CalculationMethod.egyptian.getParameters();
        break;
      case 2:
        params = CalculationMethod.umm_al_qura.getParameters();
        break;
      case 3:
        params = CalculationMethod.karachi.getParameters();
        break;
      case 4:
        params = CalculationMethod.dubai.getParameters();
        break;
      case 5:
        params = CalculationMethod.kuwait.getParameters();
        break;
      case 6:
        params = CalculationMethod.qatar.getParameters();
        break;
      default:
        params = CalculationMethod.egyptian.getParameters();
    }
    params.madhab = Madhab.shafi;
    return params;
  }

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> updateSettings(AppSettings value) async {
    settings = value;
    _calculatePrayerTimes();
    notifyListeners();
    await repository.saveSettings(value);
  }

  Future<bool> enableNotifications() async {
    final service = notificationService;
    if (service == null) return false;
    _notificationPermissionRequestInProgress = true;
    try {
      var granted = await service.requestPermission();
      if (!notificationPermissionRequested) {
        notificationPermissionRequested = true;
        await repository.saveNotificationPermissionRequested();
      }
      if (!granted) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        granted = await service.permissionGranted();
      }
      notificationPermissionGranted = granted;
      notifyListeners();
      if (notificationPermissionGranted) {
        // Permission and scheduling are separate operations. A scheduling
        // failure must not make a granted permission look disabled in the UI.
        try {
          await _syncNotifications(force: true);
        } catch (_) {}
      }
    } catch (error) {
      notificationError = error.toString();
      notifyListeners();
    } finally {
      _notificationPermissionRequestInProgress = false;
    }
    return notificationPermissionGranted;
  }

  Future<bool?> requestNotificationsOnFirstFeatureUse() async {
    if (notificationPermissionGranted || notificationPermissionRequested) {
      return null;
    }
    return enableNotifications();
  }

  Future<bool> openDeviceAppSettings() => Geolocator.openAppSettings();

  Future<bool> sendTestNotification() async {
    final service = notificationService;
    if (service == null) return false;
    if (!notificationPermissionGranted) {
      final granted = await enableNotifications();
      if (!granted) return false;
    }
    try {
      await service.showTestNotification();
      return true;
    } catch (error) {
      notificationError = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateReminder(NotificationReminder value) async {
    reminders = reminders
        .map((item) => item.id == value.id ? value : item)
        .toList();
    await repository.saveReminders(reminders);
    if (notificationPermissionGranted) {
      await _syncNotifications(force: true);
    }
    notifyListeners();
  }

  Future<void> saveReading(int surah, int ayah, {double offset = 0}) async {
    if (!settings.autoSave) return;
    progress = ReadingProgress(
      surah: surah,
      ayah: ayah,
      updatedAt: DateTime.now(),
      scrollOffset: offset,
    );
    notifyListeners();
    await repository.saveProgress(progress!);
    history = await repository.loadHistory();
  }

  Future<void> resetReading() async {
    progress = null;
    history = [];
    notifyListeners();
    await repository.clearProgress();
  }

  bool isBookmarked(int surah, int ayah) =>
      bookmarks.any((e) => e.surah == surah && e.ayah == ayah);
  Future<void> toggleBookmark(QuranBookmark value) async {
    if (isBookmarked(value.surah, value.ayah)) {
      bookmarks.removeWhere((e) => e.id == value.id);
    } else {
      bookmarks.insert(0, value);
    }
    notifyListeners();
    await repository.saveBookmarks(bookmarks);
  }

  int remainingFor(String id, int original) =>
      athkarProgress[id]?.clamp(0, original) ?? original;
  Future<void> decrementAthkar(String id, int original) async {
    final value = remainingFor(id, original);
    if (value > 0) athkarProgress[id] = value - 1;
    notifyListeners();
    await repository.saveAthkarProgress(athkarProgress);
  }

  Future<void> resetAthkar() async {
    athkarProgress = {};
    notifyListeners();
    await repository.saveAthkarProgress({});
  }

  Future<void> resetAthkarCategory(String category) async {
    athkarProgress.removeWhere((id, _) => id.startsWith('$category:'));
    notifyListeners();
    await repository.saveAthkarProgress(athkarProgress);
  }

  Future<void> incrementTasbih() async {
    tasbihCount++;
    notifyListeners();
    await repository.saveTasbih(tasbihCount, tasbihGoal);
  }

  Future<void> setTasbihGoal(int value) async {
    tasbihGoal = value.clamp(1, 999999);
    notifyListeners();
    await repository.saveTasbih(tasbihCount, tasbihGoal);
  }

  Future<void> resetTasbih() async {
    tasbihCount = 0;
    notifyListeners();
    await repository.saveTasbih(tasbihCount, tasbihGoal);
  }

  @override
  void dispose() {
    _prayerTimer?.cancel();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);
  static AppController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
