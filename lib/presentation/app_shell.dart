import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:share_plus/share_plus.dart';
import '../data/azkar_lists.dart';
import '../domain/app_models.dart';
import '../model/ziker.dart';
import 'app_controller.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onNavigate: (i) => setState(() => index = i)),
      const AthkarPage(),
      const SurahListPage(),
      const FavoritesPage(),
      const SettingsPage(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
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
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;
  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context), p = c.progress;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(floating: true, title: Text('الرفيق الصالح')),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                Text(
                  'السلام عليكم ورحمة الله',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('رفيقك اليومي للذكر وقراءة القرآن'),
                const SizedBox(height: 18),
                if (p != null)
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.play_arrow),
                      ),
                      title: const Text('تابع القراءة'),
                      subtitle: Text(
                        '${quran.getSurahNameArabic(p.surah)} • الآية ${p.ayah}',
                      ),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SurahReaderPage(
                            surah: p.surah,
                            initialAyah: p.ayah,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    _Feature(
                      icon: Icons.wb_sunny_outlined,
                      title: 'أذكار الصباح',
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
                      onTap: () => _openAthkar(
                        context,
                        'evening',
                        'أذكار المساء',
                        AzkarLists().eveningAzkar,
                      ),
                    ),
                    _Feature(
                      icon: Icons.menu_book,
                      title: 'قراءة القرآن',
                      onTap: () => onNavigate(2),
                    ),
                    _Feature(
                      icon: Icons.touch_app_outlined,
                      title: 'عداد التسبيح',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TasbihPage()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'جميع بياناتك، بما فيها تقدم القراءة والمفضلة، محفوظة محليًا على جهازك.',
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

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
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

class AthkarReaderPage extends StatelessWidget {
  const AthkarReaderPage({
    super.key,
    required this.category,
    required this.title,
    required this.items,
  });
  final String category, title;
  final List<Ziker> items;
  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final done = [
      for (var i = 0; i < items.length; i++)
        if (c.remainingFor('$category:$i', items[i].numOfCount) == 0) i,
    ].length;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'إعادة الضبط',
            onPressed: () => _confirm(
              context,
              'إعادة ضبط تقدم الأذكار؟',
              () => c.resetAthkar(),
            ),
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: items.isEmpty ? 0 : done / items.length,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final z = items[i],
                    remaining = c.remainingFor('$category:$i', z.numOfCount);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          z.ziker,
                          style: TextStyle(
                            fontSize: c.settings.athkarFontSize,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          z.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FilledButton.tonal(
                              onPressed: remaining == 0
                                  ? null
                                  : () => c.decrementAthkar(
                                      '$category:$i',
                                      z.numOfCount,
                                    ),
                              child: Text(
                                remaining == 0 ? 'تم' : 'المتبقي: $remaining',
                              ),
                            ),
                            Wrap(
                              children: [
                                IconButton(
                                  tooltip: 'نسخ',
                                  onPressed: () => _copy(context, z.ziker),
                                  icon: const Icon(Icons.copy_outlined),
                                ),
                                IconButton(
                                  tooltip: 'مشاركة',
                                  onPressed: () => SharePlus.instance.share(
                                    ShareParams(text: z.ziker),
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
                );
              },
            ),
          ),
        ],
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
      appBar: AppBar(title: const Text('القرآن الكريم')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => setState(() => query = value.trim()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'ابحث باسم السورة',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: surahs.length,
              itemBuilder: (context, index) {
                final surah = surahs[index];
                final makkah = quran.getPlaceOfRevelation(surah) == 'Makkah';
                return ListTile(
                  leading: CircleAvatar(child: Text('$surah')),
                  title: Text(quran.getSurahNameArabic(surah)),
                  subtitle: Text(
                    '${quran.getVerseCount(surah)} آية • ${makkah ? 'مكية' : 'مدنية'}',
                  ),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurahReaderPage(surah: surah),
                    ),
                  ),
                );
              },
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
  late final ScrollController scroll;
  late AppController appController;
  Timer? debounce;
  int visible = 1;
  @override
  void initState() {
    super.initState();
    visible = widget.initialAyah;
    scroll = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialAyah > 1) {
        scroll.jumpTo((widget.initialAyah - 1) * 115.0);
      }
    });
    scroll.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appController = AppScope.of(context);
  }

  @override
  void dispose() {
    debounce?.cancel();
    _save();
    scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    visible =
        (scroll.offset / 115).floor().clamp(
          0,
          quran.getVerseCount(widget.surah) - 1,
        ) +
        1;
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 650), _save);
  }

  void _save() => appController.saveReading(
    widget.surah,
    visible,
    offset: scroll.hasClients ? scroll.offset : 0,
  );
  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context), count = quran.getVerseCount(widget.surah);
    return Scaffold(
      appBar: AppBar(
        title: Text(quran.getSurahNameArabic(widget.surah)),
        actions: [
          IconButton(
            onPressed: () => c.updateSettings(
              c.settings.copyWith(
                quranFontSize: (c.settings.quranFontSize - 2).clamp(18, 40),
              ),
            ),
            icon: const Icon(Icons.text_decrease),
          ),
          IconButton(
            onPressed: () => c.updateSettings(
              c.settings.copyWith(
                quranFontSize: (c.settings.quranFontSize + 2).clamp(18, 40),
              ),
            ),
            icon: const Icon(Icons.text_increase),
          ),
        ],
      ),
      body: ListView.builder(
        controller: scroll,
        padding: const EdgeInsets.all(12),
        itemCount: count,
        itemBuilder: (_, x) {
          final ayah = x + 1,
              text = quran.getVerse(widget.surah, ayah, verseEndSymbol: true),
              marked = c.isBookmarked(widget.surah, ayah);
          return Card(
            color: ayah == widget.initialAyah
                ? Theme.of(context).colorScheme.secondaryContainer
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    text,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: c.settings.quranFontSize,
                      height: 2,
                    ),
                  ),
                  Row(
                    children: [
                      Text('الآية $ayah'),
                      const Spacer(),
                      IconButton(
                        onPressed: () =>
                            _copy(context, quran.getVerse(widget.surah, ayah)),
                        icon: const Icon(Icons.copy_outlined),
                      ),
                      IconButton(
                        onPressed: () => SharePlus.instance.share(
                          ShareParams(
                            text:
                                '${quran.getVerse(widget.surah, ayah)}\n[${quran.getSurahNameArabic(widget.surah)}: $ayah]',
                          ),
                        ),
                        icon: const Icon(Icons.share_outlined),
                      ),
                      IconButton(
                        onPressed: () => c.toggleBookmark(
                          QuranBookmark(
                            surah: widget.surah,
                            ayah: ayah,
                            preview: quran.getVerse(widget.surah, ayah),
                            createdAt: DateTime.now(),
                          ),
                        ),
                        icon: Icon(
                          marked ? Icons.bookmark : Icons.bookmark_outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton.icon(
              onPressed: widget.surah > 1
                  ? () => _replace(widget.surah - 1)
                  : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('السابقة'),
            ),
            TextButton.icon(
              onPressed: widget.surah < 114
                  ? () => _replace(widget.surah + 1)
                  : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('التالية'),
            ),
          ],
        ),
      ),
    );
  }

  void _replace(int s) => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => SurahReaderPage(surah: s)),
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
