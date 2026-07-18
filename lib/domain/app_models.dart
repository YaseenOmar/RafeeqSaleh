enum AppThemeMode { system, light, dark }

class ReadingProgress {
  const ReadingProgress({
    required this.surah,
    required this.ayah,
    required this.updatedAt,
    this.scrollOffset = 0,
  });

  final int surah;
  final int ayah;
  final DateTime updatedAt;
  final double scrollOffset;

  Map<String, dynamic> toJson() => {
    'surah': surah,
    'ayah': ayah,
    'updatedAt': updatedAt.toIso8601String(),
    'scrollOffset': scrollOffset,
  };

  factory ReadingProgress.fromJson(Map<String, dynamic> json) =>
      ReadingProgress(
        surah: (json['surah'] as num?)?.toInt() ?? 1,
        ayah: (json['ayah'] as num?)?.toInt() ?? 1,
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        scrollOffset: (json['scrollOffset'] as num?)?.toDouble() ?? 0,
      );
}

class QuranBookmark {
  const QuranBookmark({
    required this.surah,
    required this.ayah,
    required this.preview,
    required this.createdAt,
  });
  final int surah;
  final int ayah;
  final String preview;
  final DateTime createdAt;
  String get id => '$surah:$ayah';
  Map<String, dynamic> toJson() => {
    'surah': surah,
    'ayah': ayah,
    'preview': preview,
    'createdAt': createdAt.toIso8601String(),
  };
  factory QuranBookmark.fromJson(Map<String, dynamic> json) => QuranBookmark(
    surah: (json['surah'] as num).toInt(),
    ayah: (json['ayah'] as num).toInt(),
    preview: json['preview'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.athkarFontSize = 20,
    this.quranFontSize = 25,
    this.haptics = true,
    this.autoSave = true,
    this.latitude,
    this.longitude,
    this.locationName,
    this.calculationMethodIndex = 1, // Egyptian as default
  });
  final AppThemeMode themeMode;
  final double athkarFontSize;
  final double quranFontSize;
  final bool haptics;
  final bool autoSave;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final int calculationMethodIndex;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    double? athkarFontSize,
    double? quranFontSize,
    bool? haptics,
    bool? autoSave,
    double? latitude,
    double? longitude,
    String? locationName,
    int? calculationMethodIndex,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    athkarFontSize: athkarFontSize ?? this.athkarFontSize,
    quranFontSize: quranFontSize ?? this.quranFontSize,
    haptics: haptics ?? this.haptics,
    autoSave: autoSave ?? this.autoSave,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    locationName: locationName ?? this.locationName,
    calculationMethodIndex: calculationMethodIndex ?? this.calculationMethodIndex,
  );
  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'athkarFontSize': athkarFontSize,
    'quranFontSize': quranFontSize,
    'haptics': haptics,
    'autoSave': autoSave,
    'latitude': latitude,
    'longitude': longitude,
    'locationName': locationName,
    'calculationMethodIndex': calculationMethodIndex,
  };
  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    themeMode:
        AppThemeMode.values
            .where((e) => e.name == json['themeMode'])
            .firstOrNull ??
        AppThemeMode.system,
    athkarFontSize: (json['athkarFontSize'] as num?)?.toDouble() ?? 20,
    quranFontSize: (json['quranFontSize'] as num?)?.toDouble() ?? 25,
    haptics: json['haptics'] as bool? ?? true,
    autoSave: json['autoSave'] as bool? ?? true,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    locationName: json['locationName'] as String?,
    calculationMethodIndex: (json['calculationMethodIndex'] as num?)?.toInt() ?? 1,
  );
}
