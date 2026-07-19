import 'package:flutter/material.dart';

import '../domain/app_models.dart';
import 'app_controller.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

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
            'تُحسب المواعيد حسب موقعك وطريقة الحساب المختارة. قد تؤخر بعض الأجهزة الإشعار دقائق قليلة لتوفير البطارية.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermission(
    BuildContext context,
    AppController controller,
  ) async {
    final granted = await controller.enableNotifications();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'تم تفعيل وجدولة التذكيرات'
              : 'لم يتم منح الإذن. يمكنك تفعيله من إعدادات الجهاز.',
        ),
        action: granted
            ? null
            : SnackBarAction(
                label: 'الإعدادات',
                onPressed: controller.openDeviceAppSettings,
              ),
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
              child: Icon(
                IconData(reminder.iconCodePoint, fontFamily: 'MaterialIcons'),
                color: colors.primary,
              ),
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
}
