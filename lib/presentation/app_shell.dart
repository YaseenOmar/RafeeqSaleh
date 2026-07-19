import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:quran/quran.dart' as quran;
import 'package:share_plus/share_plus.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart' as intl;
import '../data/azkar_lists.dart';
import '../domain/app_models.dart';
import '../model/ziker.dart';
import 'app_controller.dart';
import 'notification_settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  DateTime? _lastBackPress;

  void _selectPage(int value) {
    setState(() {
      index = value;
      _lastBackPress = null;
    });
  }

  void _handleBack(bool didPop, Object? result) {
    if (didPop) return;

    if (index != 0) {
      _selectPage(0);
      return;
    }

    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }

    _lastBackPress = now;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'اضغط رجوع مرة أخرى للخروج',
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onNavigate: _selectPage),
      const AthkarPage(),
      const SurahListPage(),
      const FavoritesPage(),
      const SettingsPage(),
    ];
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: _handleBack,
      child: Scaffold(
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: _selectPage,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              label: 'الأذكار',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              label: 'القرآن',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_outline),
              label: 'المفضلة',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showHijri = true;

  static const _hijriMonths = [
    '',
    'محرّم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوّال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  String get _dateText {
    if (!_showHijri) {
      return intl.DateFormat('d MMMM yyyy', 'ar').format(DateTime.now());
    }
    final date = HijriCalendar.now();
    return '${date.hDay} ${_hijriMonths[date.hMonth]} ${date.hYear} هـ';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context), p = c.progress;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 70,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'الرفيق الصالح',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            centerTitle: false,
            actions: [
              Semantics(
                button: true,
                label: _showHijri
                    ? 'التاريخ الهجري، اضغط لعرض الميلادي'
                    : 'التاريخ الميلادي، اضغط لعرض الهجري',
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _showHijri = !_showHijri),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedRotation(
                          turns: _showHijri ? 0 : .5,
                          duration: const Duration(milliseconds: 350),
                          child: Icon(
                            Icons.swap_horiz_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: Text(
                            _dateText,
                            key: ValueKey(_showHijri),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                // Daily Ziker Card (Inspiration from Seerat Dua card)
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    final dailyZiker = AzkarLists().getDailyZiker();
                    final colors = Theme.of(context).colorScheme;
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Card(
                          elevation: 0,
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? colors.primary.withOpacity(0.05)
                              : colors.primaryContainer.withOpacity(0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.light
                                  ? colors.primary.withOpacity(0.1)
                                  : colors.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 18,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ذكر اليوم',
                                      style: TextStyle(
                                        color: colors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  dailyZiker.ziker,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    height: 1.6,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Colors.black87
                                        : Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  dailyZiker.virtue ?? dailyZiker.description,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.light
                                            ? Colors.black54
                                            : Colors.white70,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Progress Cards (Row of small activity cards)
                if (p != null)
                  Row(
                    children: [
                      Expanded(
                        child: _HomeCard(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SurahReaderPage(
                                surah: p.surah,
                                initialAyah: p.ayah,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.menu_book,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'آخر قراءة',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        '${quran.getSurahNameArabic(p.surah)} - آية ${p.ayah}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HomeCard(
                          onTap: () => widget.onNavigate(3),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bookmark,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'المفضلة',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        '${c.bookmarks.length} علامة',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),
                _PrayerCard(
                  prayerTimes: c.prayerTimes,
                  onLocationTap: () => _showLocationPicker(context, c),
                ),
                const SizedBox(height: 16),

                // Feature Grid (3 Columns like Seerat)
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.9,
                  children: [
                    _Feature(
                      icon: Icons.menu_book,
                      title: 'القرآن الكريم',
                      color: Colors.teal,
                      onTap: () => widget.onNavigate(2),
                    ),
                    _Feature(
                      icon: Icons.wb_sunny_outlined,
                      title: 'أذكار الصباح',
                      color: Colors.orange,
                      onTap: () => _openAthkar(
                        context,
                        'morning',
                        'أذكار الصباح',
                        AzkarLists().morningAzkar,
                      ),
                    ),
                    _Feature(
                      icon: Icons.nightlight_outlined,
                      title: 'أذكار المساء',
                      color: Colors.indigo,
                      onTap: () => _openAthkar(
                        context,
                        'evening',
                        'أذكار المساء',
                        AzkarLists().eveningAzkar,
                      ),
                    ),
                    _Feature(
                      icon: Icons.touch_app_outlined,
                      title: 'المسبحة',
                      color: Colors.brown,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TasbihPage()),
                      ),
                    ),
                    _Feature(
                      icon: Icons.mosque_outlined,
                      title: 'مواقيت الصلاة',
                      color: Colors.green,
                      onTap: () => c.prayerTimes != null
                          ? _showMonthlyPrayers(context, c.prayerTimes!)
                          : null,
                    ),
                    _Feature(
                      icon: Icons.favorite_border,
                      title: 'أدعية',
                      color: Colors.redAccent,
                      onTap: () => _openAthkar(
                        context,
                        'varied',
                        'أدعية متنوعة',
                        AzkarLists().variedAzkar,
                      ),
                    ),
                    _Feature(
                      icon: Icons.compass_calibration,
                      title: 'القبلة',
                      color: Colors.blueGrey,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QiblaPage()),
                      ),
                    ),
                    _Feature(
                      icon: Icons.mosque_outlined,
                      title: 'أذكار الصلاة',
                      color: Colors.amber,
                      onTap: () => _openAthkar(
                        context,
                        'prayer',
                        'أذكار بعد الصلاة',
                        AzkarLists().afterPrayerAzkar,
                      ),
                    ),
                    _Feature(
                      icon: Icons.bedtime_outlined,
                      title: 'أذكار النوم',
                      color: Colors.purple,
                      onTap: () => _openAthkar(
                        context,
                        'sleep',
                        'أذكار النوم',
                        AzkarLists().sleepAzkar,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Privacy info...
                const _HomeCard(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.grey),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'جميع بياناتك محفوظة محليًا على جهازك لخصوصية تامة.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
        ),
      ),
      child: InkWell(onTap: onTap, child: child),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.color,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Expanded(
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: color.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Center(child: Icon(icon, size: 28, color: color)),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.black87
              : Colors.white.withOpacity(0.9),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({this.prayerTimes, required this.onLocationTap});
  final PrayerTimes? prayerTimes;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    if (prayerTimes == null) {
      return _HomeCard(
        onTap: onLocationTap,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.location_off_outlined, color: Colors.orange),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مواقيت الصلاة غير مفعلة',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('اضغط لتحديد الموقع يدوياً أو تفعيل GPS'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final next = prayerTimes!.nextPrayer();
    final actualNext = next == Prayer.none ? Prayer.fajr : next;
    final nextTime = prayerTimes!.timeForPrayer(actualNext)!;
    final diff = nextTime.difference(DateTime.now());
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    String remaining = '';
    if (hours > 0) remaining += '$hours ساعة و ';
    remaining += '$minutes دقيقة';

    final colors = Theme.of(context).colorScheme;

    return _HomeCard(
      onTap: () => _showMonthlyPrayers(context, prayerTimes!),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.light
                ? [
                    colors.primary.withOpacity(0.12),
                    colors.primary.withOpacity(0.04),
                  ]
                : [
                    colors.primaryContainer.withOpacity(0.25),
                    colors.primaryContainer.withOpacity(0.1),
                  ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الصلاة القادمة: ${_prayerName(actualNext)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'متبقي $remaining',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.mosque, color: colors.primary, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SmallPrayer(
                      name: 'فجر',
                      time: prayerTimes!.fajr,
                      isNext: actualNext == Prayer.fajr,
                    ),
                    _SmallPrayer(
                      name: 'ظهر',
                      time: prayerTimes!.dhuhr,
                      isNext: actualNext == Prayer.dhuhr,
                    ),
                    _SmallPrayer(
                      name: 'عصر',
                      time: prayerTimes!.asr,
                      isNext: actualNext == Prayer.asr,
                    ),
                    _SmallPrayer(
                      name: 'مغرب',
                      time: prayerTimes!.maghrib,
                      isNext: actualNext == Prayer.maghrib,
                    ),
                    _SmallPrayer(
                      name: 'عشاء',
                      time: prayerTimes!.isha,
                      isNext: actualNext == Prayer.isha,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onLocationTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: colors.primary.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      settings.locationName ?? 'غير محدد',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.primary.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _prayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      default:
        return '';
    }
  }
}

class _SmallPrayer extends StatelessWidget {
  const _SmallPrayer({
    required this.name,
    required this.time,
    required this.isNext,
  });
  final String name;
  final DateTime time;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
              color: isNext
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
          ),
          Text(
            intl.DateFormat.jm(
              'ar',
            ).format(time).replaceAll('م', '').replaceAll('ص', ''),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

void _showMonthlyPrayers(BuildContext context, PrayerTimes current) {
  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined),
                const SizedBox(width: 12),
                Text(
                  'مواقيت ${intl.DateFormat('MMMM yyyy', 'ar').format(now)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: daysInMonth,
              itemBuilder: (context, index) {
                final day = index + 1;
                final coords = Coordinates(
                  AppScope.of(context).settings.latitude ?? 0,
                  AppScope.of(context).settings.longitude ?? 0,
                );

                // Consistency in calculation method
                CalculationParameters params;
                switch (AppScope.of(context).settings.calculationMethodIndex) {
                  case 0:
                    params = CalculationMethod.muslim_world_league
                        .getParameters();
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

                final times = PrayerTimes.today(coords, params);
                final isToday = day == now.day;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withOpacity(0.3)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _TimeCol('فجر', times.fajr),
                              _TimeCol('ظهر', times.dhuhr),
                              _TimeCol('عصر', times.asr),
                              _TimeCol('مغرب', times.maghrib),
                              _TimeCol('عشاء', times.isha),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _TimeCol extends StatelessWidget {
  const _TimeCol(this.label, this.time);
  final String label;
  final DateTime time;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          intl.DateFormat.jm(
            'ar',
          ).format(time).replaceAll('م', '').replaceAll('ص', ''),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}

void _showLocationPicker(BuildContext context, AppController c) {
  final cities = [
    ('القدس', 31.7683, 35.2137),
    ('غزة', 31.5017, 34.4667),
    ('مكة المكرمة', 21.4225, 39.8262),
    ('المدينة المنورة', 24.4672, 39.6024),
    ('عمان', 31.9454, 35.9284),
    ('القاهرة', 30.0444, 31.2357),
    ('الرياض', 24.7136, 46.6753),
    ('دبي', 25.2048, 55.2708),
  ];

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'تحديد الموقع',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final pos = await c.determinePosition();
                c.updateSettings(
                  c.settings.copyWith(
                    latitude: pos.latitude,
                    longitude: pos.longitude,
                    locationName: 'موقعي الحالي',
                  ),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                }
              }
            },
            icon: const Icon(Icons.my_location),
            label: const Text('استخدام الموقع الحالي (GPS)'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'أو اختر مدينة قريبة:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: cities.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(cities[i].$1),
                trailing: const Icon(Icons.chevron_left),
                onTap: () {
                  c.updateSettings(
                    c.settings.copyWith(
                      latitude: cities[i].$2,
                      longitude: cities[i].$3,
                      locationName: cities[i].$1,
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void _openAthkar(
  BuildContext context,
  String id,
  String title,
  List<Ziker> items,
) => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AthkarReaderPage(category: id, title: title, items: items),
  ),
);

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  late Future<LocationStatus> _locationStatus;
  bool _sensorSupported = true;

  @override
  void initState() {
    super.initState();
    _locationStatus = _prepareLocation();
  }

  Future<LocationStatus> _prepareLocation() async {
    if (Platform.isAndroid) {
      _sensorSupported =
          await FlutterQiblah.androidDeviceSensorSupport() ?? false;
    }
    var status = await FlutterQiblah.checkLocationStatus();
    if (status.enabled && status.status == LocationPermission.denied) {
      await FlutterQiblah.requestPermissions();
      status = await FlutterQiblah.checkLocationStatus();
    }
    return status;
  }

  void _retry() {
    setState(() => _locationStatus = _prepareLocation());
  }

  @override
  void dispose() {
    FlutterQiblah().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('اتجاه القبلة')),
    body: FutureBuilder<LocationStatus>(
      future: _locationStatus,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _QiblaError(
            message: 'تعذّر تجهيز البوصلة. تأكد من تفعيل الموقع وحاول مجددًا.',
            onRetry: _retry,
          );
        }
        final status = snapshot.data!;
        if (!_sensorSupported) {
          return _QiblaError(
            message:
                'هذا الجهاز لا يحتوي على حساس بوصلة، لذلك لا يمكن عرض اتجاه القبلة المباشر.',
            onRetry: _retry,
          );
        }
        if (!status.enabled) {
          return _QiblaError(
            message: 'خدمة الموقع متوقفة. فعّل الموقع ثم اضغط إعادة المحاولة.',
            onRetry: _retry,
          );
        }
        if (status.status == LocationPermission.deniedForever) {
          return _QiblaError(
            message:
                'صلاحية الموقع مرفوضة نهائيًا. فعّلها من إعدادات التطبيق ثم حاول مجددًا.',
            onRetry: _retry,
          );
        }
        if (status.status == LocationPermission.denied) {
          return _QiblaError(
            message: 'نحتاج صلاحية الموقع لحساب اتجاه الكعبة من مكانك.',
            onRetry: _retry,
          );
        }
        return StreamBuilder<QiblahDirection>(
          stream: FlutterQiblah.qiblahStream,
          builder: (context, directionSnapshot) {
            if (!directionSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final direction = directionSnapshot.data!;
            final deviation = ((direction.qiblah + 180) % 360 - 180)
                .abs()
                .toDouble();
            final aligned = deviation <= 3;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    aligned
                        ? 'أنت الآن باتجاه القبلة'
                        : 'حرّك الهاتف حتى يتجه السهم نحو الأعلى',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: aligned
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CustomPaint(
                          painter: _CompassPainter(
                            qiblaAngle: -direction.qiblah,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'الانحراف ${deviation.toStringAsFixed(1)}°',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ضع الهاتف بشكل أفقي وبعيدًا عن المعادن للحصول على قراءة أدق.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

class _QiblaError extends StatelessWidget {
  const _QiblaError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_off_outlined, size: 64),
          const SizedBox(height: 20),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter({required this.qiblaAngle, required this.color});
  final double qiblaAngle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 12;
    final ring = Paint()
      ..color = color.withOpacity(.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    for (var i = 0; i < 36; i++) {
      final angle = i * 10 * math.pi / 180;
      final outer = Offset(
        center.dx + math.sin(angle) * radius,
        center.dy - math.cos(angle) * radius,
      );
      final length = i % 9 == 0 ? 18.0 : 9.0;
      final inner = Offset(
        center.dx + math.sin(angle) * (radius - length),
        center.dy - math.cos(angle) * (radius - length),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = color.withOpacity(i % 9 == 0 ? 1 : .5)
          ..strokeWidth = i % 9 == 0 ? 3 : 1.5,
      );
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(qiblaAngle * math.pi / 180);
    final needle = Path()
      ..moveTo(0, -radius + 34)
      ..lineTo(-15, 18)
      ..lineTo(0, 7)
      ..lineTo(15, 18)
      ..close();
    canvas.drawPath(needle, Paint()..color = color);
    canvas.drawCircle(Offset.zero, 8, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.qiblaAngle != qiblaAngle || oldDelegate.color != color;
}

class AthkarPage extends StatelessWidget {
  const AthkarPage({super.key});
  @override
  Widget build(BuildContext context) {
    final d = AzkarLists();
    final items = [
      ('morning', 'أذكار الصباح', d.morningAzkar, Icons.wb_sunny_outlined),
      ('evening', 'أذكار المساء', d.eveningAzkar, Icons.nightlight_outlined),
      ('sleep', 'أذكار النوم', d.sleepAzkar, Icons.bedtime_outlined),
      ('prayer', 'أذكار بعد الصلاة', d.afterPrayerAzkar, Icons.mosque_outlined),
      ('wake', 'أذكار الاستيقاظ', d.wakeUpAzkar, Icons.alarm),
      ('varied', 'أذكار وأدعية متنوعة', d.variedAzkar, Icons.favorite_outline),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('الأذكار والأدعية')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (_, i) => Card(
          child: ListTile(
            leading: Icon(items[i].$4),
            title: Text(items[i].$2),
            subtitle: Text('${items[i].$3.length} أذكار'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () =>
                _openAthkar(context, items[i].$1, items[i].$2, items[i].$3),
          ),
        ),
      ),
    );
  }
}

class AthkarReaderPage extends StatefulWidget {
  const AthkarReaderPage({
    super.key,
    required this.category,
    required this.title,
    required this.items,
  });
  final String category, title;
  final List<Ziker> items;

  @override
  State<AthkarReaderPage> createState() => _AthkarReaderPageState();
}

class _AthkarReaderPageState extends State<AthkarReaderPage> {
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<int> _visibleIndices;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final c = AppScope.of(context);
    _visibleIndices = [
      for (var i = 0; i < widget.items.length; i++)
        if (c.remainingFor(
              '${widget.category}:$i',
              widget.items[i].numOfCount,
            ) >
            0)
          i,
    ];
    _initialized = true;
  }

  void _decrement(AppController c, int itemIndex) {
    final z = widget.items[itemIndex];
    final id = '${widget.category}:$itemIndex';
    final remaining = c.remainingFor(id, z.numOfCount);

    if (remaining > 1) {
      c.decrementAthkar(id, z.numOfCount);
      return;
    }

    final position = _visibleIndices.indexOf(itemIndex);
    if (position < 0) return;
    _visibleIndices.removeAt(position);
    _listKey.currentState?.removeItem(
      position,
      (context, animation) => SizeTransition(
        sizeFactor: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        ),
        child: FadeTransition(
          opacity: animation,
          child: _AthkarCard(ziker: z, remaining: 0, onDecrement: null),
        ),
      ),
      duration: const Duration(milliseconds: 500),
    );
    c.decrementAthkar(id, z.numOfCount);
  }

  Future<void> _reset(AppController c) async {
    await c.resetAthkarCategory(widget.category);
    if (!mounted) return;
    setState(() {
      _visibleIndices = List.generate(widget.items.length, (i) => i);
      _listKey = GlobalKey<AnimatedListState>();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final done = [
      for (var i = 0; i < widget.items.length; i++)
        if (c.remainingFor(
              '${widget.category}:$i',
              widget.items[i].numOfCount,
            ) ==
            0)
          i,
    ].length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'إعادة الضبط',
            onPressed: () =>
                _confirm(context, 'إعادة ضبط تقدم الأذكار؟', () => _reset(c)),
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: widget.items.isEmpty ? 0 : done / widget.items.length,
          ),
          Expanded(
            child: Stack(
              children: [
                AnimatedList(
                  key: _listKey,
                  padding: const EdgeInsets.all(12),
                  initialItemCount: _visibleIndices.length,
                  itemBuilder: (_, position, animation) {
                    final itemIndex = _visibleIndices[position];
                    final z = widget.items[itemIndex];
                    final remaining = c.remainingFor(
                      '${widget.category}:$itemIndex',
                      z.numOfCount,
                    );
                    return SizeTransition(
                      sizeFactor: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: _AthkarCard(
                          ziker: z,
                          remaining: remaining,
                          onDecrement: () => _decrement(c, itemIndex),
                        ),
                      ),
                    );
                  },
                ),
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.88, end: 1.0).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _visibleIndices.isEmpty
                        ? _AthkarCompletion(
                            key: const ValueKey('completed'),
                            onRestart: () => _reset(c),
                          )
                        : const SizedBox.shrink(key: ValueKey('reading')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AthkarCompletion extends StatelessWidget {
  const _AthkarCompletion({super.key, required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.16),
                    blurRadius: 24,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Icon(Icons.check_rounded, size: 54, color: colors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'أتممت أذكارك',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'تقبّل الله منك، وكتب لك الأجر والطمأنينة',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('إعادة البدء'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AthkarCard extends StatelessWidget {
  const _AthkarCard({
    required this.ziker,
    required this.remaining,
    required this.onDecrement,
  });

  final Ziker ziker;
  final int remaining;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final virtue = ziker.virtue;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDecrement,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ziker.ziker,
                style: TextStyle(
                  fontSize: AppScope.of(context).settings.athkarFontSize,
                  height: 1.8,
                ),
              ),
              if (virtue == null || virtue != ziker.description) ...[
                const SizedBox(height: 8),
                Text(
                  ziker.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (virtue != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.tertiary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 19,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'فضل الذكر',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(virtue, style: const TextStyle(height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      remaining == 0 ? 'تم' : 'المتبقي: $remaining',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Wrap(
                    children: [
                      IconButton(
                        tooltip: 'نسخ',
                        onPressed: () => _copy(context, ziker.ziker),
                        icon: const Icon(Icons.copy_outlined),
                      ),
                      IconButton(
                        tooltip: 'مشاركة',
                        onPressed: () => SharePlus.instance.share(
                          ShareParams(text: ziker.ziker),
                        ),
                        icon: const Icon(Icons.share_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SurahListPage extends StatefulWidget {
  const SurahListPage({super.key});
  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final surahs = [
      for (int i = 1; i <= 114; i++) i,
    ].where((i) => quran.getSurahNameArabic(i).contains(query)).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            title: const Text('القرآن الكريم'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  onChanged: (value) => setState(() => query = value.trim()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'ابحث باسم السورة',
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final surah = surahs[index];
                final makkah = quran.getPlaceOfRevelation(surah) == 'Makkah';

                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + (index % 10 * 50)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$surah',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(
                        quran.getSurahNameArabic(surah),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        '${quran.getVerseCount(surah)} آية • ${makkah ? 'مكية' : 'مدنية'}',
                      ),
                      trailing: Icon(
                        Icons.chevron_left,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.5),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SurahReaderPage(surah: surah),
                        ),
                      ),
                    ),
                  ),
                );
              }, childCount: surahs.length),
            ),
          ),
        ],
      ),
    );
  }
}

class SurahReaderPage extends StatefulWidget {
  const SurahReaderPage({super.key, required this.surah, this.initialAyah = 1});
  final int surah, initialAyah;
  @override
  State<SurahReaderPage> createState() => _SurahReaderPageState();
}

class _SurahReaderPageState extends State<SurahReaderPage> {
  late final PageController pages;
  late AppController appController;
  late int currentPage;

  @override
  void initState() {
    super.initState();
    currentPage = quran.getPageNumber(widget.surah, widget.initialAyah);
    pages = PageController(initialPage: currentPage - 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appController = AppScope.of(context);
  }

  @override
  void dispose() {
    _save();
    pages.dispose();
    super.dispose();
  }

  void _save() {
    final first = quran.getPageData(currentPage).first;
    appController.saveReading(first['surah'] as int, first['start'] as int);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xffeee8da),
      appBar: AppBar(
        title: Text('صفحة $currentPage'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'تصغير الخط',
            onPressed: () => c.updateSettings(
              c.settings.copyWith(
                quranFontSize: (c.settings.quranFontSize - 2).clamp(18, 40),
              ),
            ),
            icon: const Icon(Icons.text_decrease),
          ),
          IconButton(
            tooltip: 'تكبير الخط',
            onPressed: () => c.updateSettings(
              c.settings.copyWith(
                quranFontSize: (c.settings.quranFontSize + 2).clamp(18, 40),
              ),
            ),
            icon: const Icon(Icons.text_increase),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: PageView.builder(
          controller: pages,
          itemCount: quran.totalPagesCount,
          onPageChanged: (index) {
            setState(() => currentPage = index + 1);
            _save();
          },
          itemBuilder: (_, index) => _MushafPage(
            pageNumber: index + 1,
            fontSize: c.settings.quranFontSize,
            initialSurah: widget.surah,
            initialAyah: widget.initialAyah,
          ),
        ),
      ),
    );
  }
}

class _MushafPage extends StatelessWidget {
  const _MushafPage({
    required this.pageNumber,
    required this.fontSize,
    required this.initialSurah,
    required this.initialAyah,
  });
  final int pageNumber, initialSurah, initialAyah;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final sections = quran.getPageData(pageNumber);
    final first = sections.first;
    final surah = first['surah'] as int;
    final juz = quran.getJuzNumber(surah, first['start'] as int);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xfffffbef),
          border: Border.all(color: const Color(0xffad9363), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Text('الجزء $juz'),
                  const Spacer(),
                  Text('سورة ${quran.getSurahNameArabic(surah)}'),
                ],
              ),
              const Divider(color: Color(0xffad9363), height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final section in sections)
                        _MushafSection(
                          surah: section['surah'] as int,
                          start: section['start'] as int,
                          end: section['end'] as int,
                          fontSize: fontSize,
                          initialSurah: initialSurah,
                          initialAyah: initialAyah,
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(color: Color(0xffad9363), height: 12),
              Text(
                '$pageNumber',
                style: const TextStyle(color: Color(0xff756b57), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MushafSection extends StatelessWidget {
  const _MushafSection({
    required this.surah,
    required this.start,
    required this.end,
    required this.fontSize,
    required this.initialSurah,
    required this.initialAyah,
  });

  final int surah, start, end, initialSurah, initialAyah;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final startsSurah = start == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (startsSurah) _SurahBanner(surah: surah),
        if (startsSurah && surah != 1 && surah != 9)
          const Padding(
            padding: EdgeInsets.only(top: 3, bottom: 7),
            child: Text(
              quran.basmala,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: Color(0xff19160f),
                fontSize: 21,
                height: 1.5,
                fontFamily: 'NotoSerif',
              ),
            ),
          ),
        Text.rich(
          TextSpan(
            children: [
              for (var ayah = start; ayah <= end; ayah++)
                TextSpan(
                  text: '${_verseText(surah, ayah)} ',
                  style: surah == initialSurah && ayah == initialAyah
                      ? const TextStyle(backgroundColor: Color(0x33c6a15b))
                      : null,
                ),
            ],
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            color: const Color(0xff19160f),
            fontSize: fontSize,
            height: 1.9,
            fontFamily: 'NotoSerif',
          ),
        ),
      ],
    );
  }

  static String _verseText(int surah, int ayah) {
    var text = quran.getVerse(surah, ayah);
    if (ayah == 1 && surah != 1 && surah != 9) {
      const basmalaEnd = 'الرَّحِيمِ';
      final end = text.indexOf(basmalaEnd);
      if (end >= 0) {
        text = text.substring(end + basmalaEnd.length).trimLeft();
      }
    }
    return '$text${quran.getVerseEndSymbol(ayah)}';
  }
}

class _SurahBanner extends StatelessWidget {
  const _SurahBanner({required this.surah});
  final int surah;

  @override
  Widget build(BuildContext context) => Container(
    width: MediaQuery.sizeOf(context).width - 54,
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xffeee4cb),
      border: Border.all(color: const Color(0xffad9363)),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      'سُورَةُ ${quran.getSurahNameArabic(surah)}',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xff4f4027),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'NotoSerif',
      ),
    ),
  );
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة والعلامات')),
      body: c.bookmarks.isEmpty
          ? const Center(child: Text('لا توجد علامات مرجعية بعد'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: c.bookmarks.length,
              itemBuilder: (_, i) {
                final b = c.bookmarks[i];
                return Dismissible(
                  key: ValueKey(b.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => c.toggleBookmark(b),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    child: ListTile(
                      title: Text(
                        '${quran.getSurahNameArabic(b.surah)} • الآية ${b.ayah}',
                      ),
                      subtitle: Text(
                        b.preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SurahReaderPage(
                            surah: b.surah,
                            initialAyah: b.ayah,
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () => c.toggleBookmark(b),
                        icon: const Icon(Icons.bookmark_remove),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class TasbihPage extends StatelessWidget {
  const TasbihPage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final value = (c.tasbihCount / c.tasbihGoal).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('عداد التسبيح'),
        actions: [
          IconButton(
            onPressed: () =>
                _confirm(context, 'إعادة العداد إلى الصفر؟', c.resetTasbih),
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Text(
              '${c.tasbihCount}',
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: value, minHeight: 10),
            Text('الهدف: ${c.tasbihGoal} • ${(value * 100).round()}٪'),
            const SizedBox(height: 24),
            SizedBox(
              width: 240,
              height: 240,
              child: FilledButton(
                style: FilledButton.styleFrom(shape: const CircleBorder()),
                onPressed: () {
                  if (c.settings.haptics) HapticFeedback.lightImpact();
                  c.incrementTasbih();
                },
                child: const Icon(Icons.touch_app, size: 72),
              ),
            ),
            const Spacer(),
            Wrap(
              spacing: 8,
              children: [
                for (final g in [33, 100])
                  ChoiceChip(
                    label: Text('$g'),
                    selected: c.tasbihGoal == g,
                    onSelected: (_) => c.setTasbihGoal(g),
                  ),
                ActionChip(
                  label: const Text('هدف مخصص'),
                  onPressed: () => _customGoal(context, c),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context), s = c.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const _MemorialCard(),
          const SizedBox(height: 16),
          DropdownButtonFormField<AppThemeMode>(
            initialValue: s.themeMode,
            decoration: const InputDecoration(labelText: 'مظهر التطبيق'),
            items: const [
              DropdownMenuItem(
                value: AppThemeMode.system,
                child: Text('حسب النظام'),
              ),
              DropdownMenuItem(value: AppThemeMode.light, child: Text('فاتح')),
              DropdownMenuItem(value: AppThemeMode.dark, child: Text('داكن')),
            ],
            onChanged: (v) {
              if (v != null) c.updateSettings(s.copyWith(themeMode: v));
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: s.calculationMethodIndex,
            decoration: const InputDecoration(
              labelText: 'طريقة حساب مواقيت الصلاة',
            ),
            items: const [
              DropdownMenuItem(value: 0, child: Text('رابطة العالم الإسلامي')),
              DropdownMenuItem(
                value: 1,
                child: Text('الهيئة المصرية العامة للمساحة'),
              ),
              DropdownMenuItem(value: 2, child: Text('جامعة أم القرى، مكة')),
              DropdownMenuItem(
                value: 3,
                child: Text('جامعة العلوم الإسلامية، كراتشي'),
              ),
              DropdownMenuItem(value: 4, child: Text('دبي')),
              DropdownMenuItem(value: 5, child: Text('الكويت')),
              DropdownMenuItem(value: 6, child: Text('قطر')),
            ],
            onChanged: (v) {
              if (v != null)
                c.updateSettings(s.copyWith(calculationMethodIndex: v));
            },
          ),
          const SizedBox(height: 16),
          Text('حجم خط الأذكار: ${s.athkarFontSize.round()}'),
          Slider(
            value: s.athkarFontSize,
            min: 16,
            max: 32,
            onChanged: (v) => c.updateSettings(s.copyWith(athkarFontSize: v)),
          ),
          Text('حجم خط القرآن: ${s.quranFontSize.round()}'),
          Slider(
            value: s.quranFontSize,
            min: 18,
            max: 40,
            onChanged: (v) => c.updateSettings(s.copyWith(quranFontSize: v)),
          ),
          SwitchListTile(
            title: const Text('اهتزاز عداد التسبيح'),
            value: s.haptics,
            onChanged: (v) => c.updateSettings(s.copyWith(haptics: v)),
          ),
          SwitchListTile(
            title: const Text('حفظ موضع القراءة تلقائيًا'),
            value: s.autoSave,
            onChanged: (v) => c.updateSettings(s.copyWith(autoSave: v)),
          ),
          const Divider(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('التذكيرات اليومية'),
              subtitle: Text(
                c.notificationPermissionGranted
                    ? '${c.reminders.where((item) => item.enabled).length} تذكيرات مفعّلة • تعمل دون إنترنت'
                    : 'فعّل إشعارات مواقيت الصلاة',
              ),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationSettingsPage(),
                ),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('إعادة ضبط تقدم الأذكار'),
            leading: const Icon(Icons.restart_alt),
            onTap: () => _confirm(
              context,
              'إعادة ضبط جميع تقدم الأذكار؟',
              c.resetAthkar,
            ),
          ),
          ListTile(
            title: const Text('إعادة ضبط تقدم القرآن'),
            leading: const Icon(Icons.menu_book_outlined),
            onTap: () =>
                _confirm(context, 'حذف سجل تقدم قراءة القرآن؟', c.resetReading),
          ),
          ListTile(
            title: const Text('إعادة ضبط عداد التسبيح'),
            leading: const Icon(Icons.touch_app_outlined),
            onTap: () =>
                _confirm(context, 'إعادة العداد إلى الصفر؟', c.resetTasbih),
          ),
          ListTile(
            title: const Text('حول التطبيق والخصوصية'),
            subtitle: const Text('الإصدار 1.0.0'),
            leading: const Icon(Icons.info_outline),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'الرفيق الصالح',
              applicationVersion: '1.0.0',
              children: [
                const Text(
                  'تطبيق إسلامي يعمل دون حساب. لا يجمع بيانات شخصية، وتُحفظ الإعدادات والتقدم والمفضلة محليًا على جهازك فقط.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemorialCard extends StatelessWidget {
  const _MemorialCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colors.primaryContainer.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volunteer_activism_outlined,
                color: colors.primary,
                size: 29,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'صدقة جارية',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'هذا التطبيق صدقة جارية عن روح الشهيد',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 5),
            Text(
              'عمر حسن زقوت',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSerif',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'نسأل الله أن يرحمه ويتقبّله، وأن يجعل أثر هذا العمل نورًا في ميزان حسناته',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _copy(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم النسخ')));
  }
}

Future<void> _confirm(
  BuildContext context,
  String message,
  Future<void> Function() action,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('تأكيد'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('تأكيد'),
        ),
      ],
    ),
  );
  if (ok == true) await action();
}

Future<void> _customGoal(BuildContext context, AppController c) async {
  final input = TextEditingController(text: '${c.tasbihGoal}');
  final value = await showDialog<int>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('الهدف المخصص'),
      content: TextField(
        controller: input,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'العدد'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, int.tryParse(input.text)),
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
  if (value != null && value > 0) c.setTasbihGoal(value);
}
