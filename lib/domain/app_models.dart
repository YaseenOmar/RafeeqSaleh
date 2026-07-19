enum AppThemeMode { system, light, dark }

class NotificationReminder {
  const NotificationReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    required this.iconCodePoint,
    this.enabled = true,
  });

  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final int iconCodePoint;
  final bool enabled;

  static const defaults = [
    NotificationReminder(
      id: 1001,
      title: 'حان وقت أذكار الصباح',
      body: 'ابدأ صباحك بذكر الله، دقائق قليلة تملأ يومك طمأنينة وبركة.',
      hour: 7,
      minute: 0,
      iconCodePoint: 0xe430,
    ),
    NotificationReminder(
      id: 1002,
      title: 'وردك اليومي من القرآن',
      body: 'لا تنسَ نصيبك اليوم من كلام الله، افتح مصحفك وتابع من حيث توقفت.',
      hour: 9,
      minute: 0,
      iconCodePoint: 0xf53d,
    ),
    NotificationReminder(
      id: 1003,
      title: 'حان وقت أذكار المساء',
      body: 'اختم يومك بحفظ الله وسكينته مع أذكار المساء.',
      hour: 18,
      minute: 0,
      iconCodePoint: 0xe51c,
    ),
    NotificationReminder(
      id: 1004,
      title: 'دقائق للتسبيح',
      body: 'سبحان الله، والحمد لله، والله أكبر. اجعل لك خبيئة من الذكر.',
      hour: 21,
      minute: 0,
      iconCodePoint: 0xf04c,
    ),
    NotificationReminder(
      id: 1101,
      title: 'حان وقت صلاة الفجر',
      body: 'دخل الآن وقت صلاة الفجر.',
      hour: 5,
      minute: 0,
      iconCodePoint: 0xe430,
    ),
    NotificationReminder(
      id: 1102,
      title: 'حان وقت صلاة الظهر',
      body: 'دخل الآن وقت صلاة الظهر.',
      hour: 12,
      minute: 0,
      iconCodePoint: 0xf53d,
    ),
    NotificationReminder(
      id: 1103,
      title: 'حان وقت صلاة العصر',
      body: 'دخل الآن وقت صلاة العصر.',
      hour: 15,
      minute: 0,
      iconCodePoint: 0xe51c,
    ),
    NotificationReminder(
      id: 1104,
      title: 'حان وقت صلاة المغرب',
      body: 'دخل الآن وقت صلاة المغرب.',
      hour: 18,
      minute: 0,
      iconCodePoint: 0xf04c,
    ),
    NotificationReminder(
      id: 1105,
      title: 'حان وقت صلاة العشاء',
      body: 'دخل الآن وقت صلاة العشاء.',
      hour: 20,
      minute: 0,
      iconCodePoint: 0xe3a8,
    ),
  ];

  NotificationReminder copyWith({int? hour, int? minute, bool? enabled}) =>
      NotificationReminder(
        id: id,
        title: title,
        body: body,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        iconCodePoint: iconCodePoint,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'hour': hour,
    'minute': minute,
    'iconCodePoint': iconCodePoint,
    'enabled': enabled,
  };

  factory NotificationReminder.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt();
    final fallback = defaults.where((item) => item.id == id).firstOrNull;
    return NotificationReminder(
      id: id ?? fallback?.id ?? 0,
      title: json['title'] as String? ?? fallback?.title ?? '',
      body: json['body'] as String? ?? fallback?.body ?? '',
      hour: (json['hour'] as num?)?.toInt() ?? fallback?.hour ?? 8,
      minute: (json['minute'] as num?)?.toInt() ?? fallback?.minute ?? 0,
      iconCodePoint:
          (json['iconCodePoint'] as num?)?.toInt() ??
          fallback?.iconCodePoint ??
          0xe7f4,
      enabled: json['enabled'] as bool? ?? fallback?.enabled ?? true,
    );
  }
}

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
    calculationMethodIndex:
        calculationMethodIndex ?? this.calculationMethodIndex,
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
    calculationMethodIndex:
        (json['calculationMethodIndex'] as num?)?.toInt() ?? 1,
  );
}
