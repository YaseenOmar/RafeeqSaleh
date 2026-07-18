import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import '../data/local_store.dart';
import '../domain/app_models.dart';

class AppController extends ChangeNotifier {
  AppController(this.repository);
  final AppRepository repository;
  AppSettings settings = const AppSettings();
  ReadingProgress? progress;
  List<ReadingProgress> history = [];
  List<QuranBookmark> bookmarks = [];
  Map<String, int> athkarProgress = {};
  int tasbihCount = 0, tasbihGoal = 33;

  PrayerTimes? prayerTimes;
  Timer? _prayerTimer;

  Future<void> load() async {
    settings = await repository.loadSettings();
    progress = await repository.loadProgress();
    history = await repository.loadHistory();
    bookmarks = await repository.loadBookmarks();
    athkarProgress = await repository.loadAthkarProgress();
    tasbihCount = await repository.loadTasbih();
    tasbihGoal = await repository.loadTasbihGoal();
    
    if (settings.latitude != null && settings.longitude != null) {
      _calculatePrayerTimes();
    } else {
      determinePosition().then((pos) {
        updateSettings(settings.copyWith(
          latitude: pos.latitude,
          longitude: pos.longitude,
          locationName: 'موقعي الحالي',
        ));
      }).catchError((_) {});
    }

    _startPrayerTimer();
    notifyListeners();
  }

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
    notifyListeners();
  }

  CalculationParameters _getParams() {
    CalculationParameters params;
    switch (settings.calculationMethodIndex) {
      case 0: params = CalculationMethod.muslim_world_league.getParameters(); break;
      case 1: params = CalculationMethod.egyptian.getParameters(); break;
      case 2: params = CalculationMethod.umm_al_qura.getParameters(); break;
      case 3: params = CalculationMethod.karachi.getParameters(); break;
      case 4: params = CalculationMethod.dubai.getParameters(); break;
      case 5: params = CalculationMethod.kuwait.getParameters(); break;
      case 6: params = CalculationMethod.qatar.getParameters(); break;
      default: params = CalculationMethod.egyptian.getParameters();
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
