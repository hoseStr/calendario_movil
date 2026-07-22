import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/backup_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/reminder_scheduler.dart';
import 'calendar/calendar_providers.dart';

/// Servicios globales de la app (notificaciones y recordatorios).
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => ReminderScheduler(
    ref.watch(databaseProvider),
    ref.watch(notificationServiceProvider),
  ),
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(databaseProvider)),
);
