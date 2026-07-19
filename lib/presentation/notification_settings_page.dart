import 'package:flutter/material.dart';

import '../domain/app_models.dart';
import 'app_controller.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeNotificationFeature();
      }
    });
  }

  Future<void> _initializeNotificationFeature() async {
    final controller = AppScope.of(context);
    await controller.refreshNotificationState();
    if (!mounted) return;
    await controller.requestNotificationsOnFirstFeatureUse();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppScope.of(context).refreshNotificationState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('التذكيرات اليومية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primaryContainer,
                  colors.primaryContainer.withValues(alpha: 0.45),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  child: const Icon(Icons.notifications_active_outlined),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تذكير لطيف في وقته',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'إشعار نصي عند دخول وقت كل صلاة حسب موقعك، دون تشغيل صوت الأذان.',
                        style: TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!controller.notificationPermissionGranted) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'الإشعارات غير مفعّلة',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'اسمح للتطبيق بعرض الإشعارات حتى تصلك التذكيرات المختارة.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _requestPermission(context, controller),
                      icon: const Icon(Icons.notifications_outlined),
                      label: const Text('تفعيل الإشعارات'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.notificationSyncInProgress
                            ? 'جارٍ تجهيز التذكيرات...'
                            : '${controller.scheduledNotificationCount} إشعارًا مجدولًا حاليًا',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: controller.notificationSyncInProgress
                          ? null
                          : () => _sendTest(context, controller),
                      child: const Text('اختبار الآن'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'التذكيرات اليومية',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...controller.reminders
              .where((item) => item.id < 1100)
              .map(
                (reminder) => _ReminderCard(
                  reminder: reminder,
                  onToggle: (enabled) => _toggle(
                    context,
                    controller,
                    reminder.copyWith(enabled: enabled),
                  ),
                  onTime: () => _pickTime(context, controller, reminder),
                ),
              ),
          const SizedBox(height: 18),
          Text(
            'إشعارات مواقيت الصلاة',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...controller.reminders
              .where((item) => item.id >= 1100)
              .map(
                (reminder) => _ReminderCard(
                  reminder: reminder,
                  onToggle: (enabled) => _toggle(
                    context,
                    controller,
                    reminder.copyWith(enabled: enabled),
                  ),
                ),
              ),
          const SizedBox(height: 8),
          Text(
            controller.settings.latitude == null
                ? 'التذكيرات اليومية جاهزة. إشعارات الصلاة تحتاج تحديد الموقع أولًا من إعدادات مواقيت الصلاة.'
                : 'تُحسب المواعيد حسب موقعك وطريقة الحساب المختارة. قد تؤخر بعض الأجهزة الإشعار دقائق قليلة لتوفير البطارية.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _sendTest(BuildContext context, AppController controller) async {
    final sent = await controller.sendTestNotification();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? 'تم إرسال إشعار تجريبي'
              : 'تعذّر إرسال الإشعار. تأكد من إذن الإشعارات.',
        ),
      ),
    );
  }

  Future<void> _requestPermission(
    BuildContext context,
    AppController controller,
  ) async {
    final granted = await controller.enableNotifications();
    if (!context.mounted) return;
    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تفعيل وجدولة التذكيرات')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.notifications_off_outlined),
        title: const Text('السماح بالإشعارات'),
        content: const Text(
          'لم يمنح Android صلاحية الإشعارات. إذا سبق أن رفضت الطلب، '
          'يمنع النظام ظهور نافذة السماح مرة أخرى ويجب تفعيلها من إعدادات التطبيق.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('لاحقًا'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.openDeviceAppSettings();
            },
            icon: const Icon(Icons.settings_outlined),
            label: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    AppController controller,
    NotificationReminder reminder,
  ) async {
    if (reminder.enabled && !controller.notificationPermissionGranted) {
      final granted = await controller.enableNotifications();
      if (!granted) return;
    }
    await controller.updateReminder(reminder);
  }

  Future<void> _pickTime(
    BuildContext context,
    AppController controller,
    NotificationReminder reminder,
  ) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
      helpText: 'اختر وقت التذكير',
      cancelText: 'إلغاء',
      confirmText: 'حفظ',
    );
    if (time == null) return;
    await controller.updateReminder(
      reminder.copyWith(hour: time.hour, minute: time.minute),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.onToggle,
    this.onTime,
  });

  final NotificationReminder reminder;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTime;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final time = TimeOfDay(
      hour: reminder.hour,
      minute: reminder.minute,
    ).format(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_iconForReminder(reminder.id), color: colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: reminder.enabled ? onTime : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 17),
                          const SizedBox(width: 5),
                          Text(time),
                          if (onTime != null) ...[
                            const SizedBox(width: 3),
                            const Icon(Icons.edit_outlined, size: 15),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: reminder.enabled, onChanged: onToggle),
          ],
        ),
      ),
    );
  }

  IconData _iconForReminder(int id) => switch (id) {
    1001 || 1101 => Icons.wb_twilight_outlined,
    1002 => Icons.menu_book_outlined,
    1003 || 1104 => Icons.nights_stay_outlined,
    1004 => Icons.auto_awesome_outlined,
    1102 => Icons.wb_sunny_outlined,
    1103 => Icons.light_mode_outlined,
    1105 => Icons.dark_mode_outlined,
    _ => Icons.notifications_outlined,
  };
}
