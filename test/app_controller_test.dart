import 'package:flutter_test/flutter_test.dart';
import 'package:rafeeq_saleh/data/local_store.dart';
import 'package:rafeeq_saleh/domain/app_models.dart';
import 'package:rafeeq_saleh/presentation/app_controller.dart';

class FakeLocalStore implements LocalStore {
  final Map<String, Object> data = {};
  @override
  Future<Map<String, dynamic>?> readJson(String key) async =>
      data[key] == null ? null : Map<String, dynamic>.from(data[key]! as Map);
  @override
  Future<void> writeJson(String key, Map<String, dynamic> value) async =>
      data[key] = Map<String, dynamic>.from(value);
  @override
  Future<List<dynamic>> readList(String key) async =>
      List<dynamic>.from(data[key] as List? ?? []);
  @override
  Future<void> writeList(String key, List<dynamic> value) async =>
      data[key] = List<dynamic>.from(value);
  @override
  Future<int> readInt(String key, [int fallback = 0]) async =>
      data[key] as int? ?? fallback;
  @override
  Future<void> writeInt(String key, int value) async => data[key] = value;
  @override
  Future<void> remove(String key) async => data.remove(key);
}

void main() {
  late FakeLocalStore store;
  late AppController controller;
  setUp(() {
    store = FakeLocalStore();
    controller = AppController(AppRepository(store));
  });
  test(
    'Given no local data When loading Then safe defaults are used',
    () async {
      await controller.load();
      expect(controller.progress, isNull);
      expect(controller.bookmarks, isEmpty);
      expect(controller.tasbihGoal, 33);
    },
  );
  test(
    'Given a reading position When saved Then it is restored with history',
    () async {
      await controller.load();
      await controller.saveReading(2, 15, offset: 120);
      final restored = AppController(AppRepository(store));
      await restored.load();
      expect(restored.progress?.surah, 2);
      expect(restored.progress?.ayah, 15);
      expect(restored.history, hasLength(1));
    },
  );
  test(
    'Given an ayah When bookmarked twice Then duplicate is prevented',
    () async {
      await controller.load();
      final bookmark = QuranBookmark(
        surah: 1,
        ayah: 1,
        preview: 'نص',
        createdAt: DateTime(2026),
      );
      await controller.toggleBookmark(bookmark);
      expect(controller.bookmarks, hasLength(1));
      await controller.toggleBookmark(bookmark);
      expect(controller.bookmarks, isEmpty);
    },
  );
  test('Given athkar count When decremented Then progress persists', () async {
    await controller.load();
    await controller.decrementAthkar('morning:0', 3);
    final restored = AppController(AppRepository(store));
    await restored.load();
    expect(restored.remainingFor('morning:0', 3), 2);
  });
  test('Given settings and tasbih When changed Then values persist', () async {
    await controller.load();
    await controller.updateSettings(
      controller.settings.copyWith(
        themeMode: AppThemeMode.dark,
        quranFontSize: 30,
      ),
    );
    await controller.incrementTasbih();
    await controller.setTasbihGoal(100);
    final restored = AppController(AppRepository(store));
    await restored.load();
    expect(restored.settings.themeMode, AppThemeMode.dark);
    expect(restored.settings.quranFontSize, 30);
    expect(restored.tasbihCount, 1);
    expect(restored.tasbihGoal, 100);
  });
}
