import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/app_models.dart';

abstract class LocalStore {
  Future<Map<String, dynamic>?> readJson(String key);
  Future<void> writeJson(String key, Map<String, dynamic> value);
  Future<List<dynamic>> readList(String key);
  Future<void> writeList(String key, List<dynamic> value);
  Future<int> readInt(String key, [int fallback = 0]);
  Future<void> writeInt(String key, int value);
  Future<void> remove(String key);
}

class PreferencesLocalStore implements LocalStore {
  PreferencesLocalStore(this.preferences);
  final SharedPreferences preferences;
  @override
  Future<Map<String, dynamic>?> readJson(String key) async {
    try {
      final value = preferences.getString(key);
      return value == null
          ? null
          : Map<String, dynamic>.from(jsonDecode(value) as Map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeJson(String key, Map<String, dynamic> value) =>
      preferences.setString(key, jsonEncode(value));
  @override
  Future<List<dynamic>> readList(String key) async {
    try {
      final value = preferences.getString(key);
      return value == null ? [] : List<dynamic>.from(jsonDecode(value) as List);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> writeList(String key, List<dynamic> value) =>
      preferences.setString(key, jsonEncode(value));
  @override
  Future<int> readInt(String key, [int fallback = 0]) async =>
      preferences.getInt(key) ?? fallback;
  @override
  Future<void> writeInt(String key, int value) =>
      preferences.setInt(key, value);
  @override
  Future<void> remove(String key) => preferences.remove(key);
}

class AppRepository {
  AppRepository(this.store);
  final LocalStore store;
  static const _settings = 'settings_v1',
      _progress = 'quran_progress_v1',
      _history = 'quran_history_v1',
      _bookmarks = 'quran_bookmarks_v1',
      _reminders = 'notification_reminders_v1';
  Future<AppSettings> loadSettings() async =>
      AppSettings.fromJson(await store.readJson(_settings) ?? {});
  Future<void> saveSettings(AppSettings value) =>
      store.writeJson(_settings, value.toJson());
  Future<ReadingProgress?> loadProgress() async {
    final value = await store.readJson(_progress);
    return value == null ? null : ReadingProgress.fromJson(value);
  }

  Future<List<ReadingProgress>> loadHistory() async =>
      (await store.readList(_history))
          .whereType<Map>()
          .map((e) => ReadingProgress.fromJson(Map<String, dynamic>.from(e)))
          .toList();
  Future<void> saveProgress(ReadingProgress value) async {
    await store.writeJson(_progress, value.toJson());
    final history = await loadHistory();
    final updated = [
      value,
      ...history.where((e) => e.surah != value.surah || e.ayah != value.ayah),
    ].take(10).map((e) => e.toJson()).toList();
    await store.writeList(_history, updated);
  }

  Future<void> clearProgress() async {
    await store.remove(_progress);
    await store.remove(_history);
  }

  Future<List<QuranBookmark>> loadBookmarks() async =>
      (await store.readList(_bookmarks))
          .whereType<Map>()
          .map((e) => QuranBookmark.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  Future<void> saveBookmarks(List<QuranBookmark> values) =>
      store.writeList(_bookmarks, values.map((e) => e.toJson()).toList());
  Future<List<NotificationReminder>> loadReminders() async {
    final saved = (await store.readList(_reminders))
        .whereType<Map>()
        .map(
          (value) =>
              NotificationReminder.fromJson(Map<String, dynamic>.from(value)),
        )
        .toList();
    if (saved.isEmpty) return NotificationReminder.defaults;
    return NotificationReminder.defaults.map((fallback) {
      final previous = saved
          .where((item) => item.id == fallback.id)
          .firstOrNull;
      final wasTemporaryPrayerReminder =
          fallback.id < 1100 &&
          (previous?.title.startsWith('حان وقت صلاة') ?? false);
      return wasTemporaryPrayerReminder ? fallback : previous ?? fallback;
    }).toList();
  }

  Future<void> saveReminders(List<NotificationReminder> values) =>
      store.writeList(_reminders, values.map((e) => e.toJson()).toList());
  Future<Map<String, int>> loadAthkarProgress() async {
    final json = await store.readJson('athkar_progress_v1') ?? {};
    return json.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  Future<void> saveAthkarProgress(Map<String, int> value) =>
      store.writeJson('athkar_progress_v1', value);
  Future<int> loadTasbih() => store.readInt('tasbih_count_v1');
  Future<int> loadTasbihGoal() => store.readInt('tasbih_goal_v1', 33);
  Future<void> saveTasbih(int count, int goal) async {
    await store.writeInt('tasbih_count_v1', count);
    await store.writeInt('tasbih_goal_v1', goal);
  }
}
