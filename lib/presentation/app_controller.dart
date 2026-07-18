import 'package:flutter/material.dart';
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

  Future<void> load() async {
    settings = await repository.loadSettings();
    progress = await repository.loadProgress();
    history = await repository.loadHistory();
    bookmarks = await repository.loadBookmarks();
    athkarProgress = await repository.loadAthkarProgress();
    tasbihCount = await repository.loadTasbih();
    tasbihGoal = await repository.loadTasbihGoal();
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings value) async {
    settings = value;
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
