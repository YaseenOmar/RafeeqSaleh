import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;

void main() {
  test(
    'Given bundled Quran data When validated Then 114 surahs and 6236 ayahs are present',
    () {
      var totalAyahs = 0;
      for (var surah = 1; surah <= 114; surah++) {
        final count = quran.getVerseCount(surah);
        expect(
          quran.getSurahNameArabic(surah),
          isNotEmpty,
          reason: 'Missing name for surah $surah',
        );
        expect(count, greaterThan(0), reason: 'Missing ayahs for surah $surah');
        for (var ayah = 1; ayah <= count; ayah++) {
          expect(
            quran.getVerse(surah, ayah),
            isNotEmpty,
            reason: 'Missing $surah:$ayah',
          );
        }
        totalAyahs += count;
      }
      expect(totalAyahs, 6236);
    },
  );
}
