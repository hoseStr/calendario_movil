import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/app_providers.dart';
import 'presentation/settings/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  final container = ProviderContainer();
  final notifications = container.read(notificationServiceProvider);
  await notifications.init(onSelect: _openEventFromPayload);

  runApp(UncontrolledProviderScope(
    container: container,
    child: const CalendarioApp(),
  ));

  // Tras el arranque: permisos, reprogramación de alarmas (red de
  // seguridad post-reinicio / tope iOS) y navegación si la app fue
  // abierta tocando una notificación.
  unawaited(_bootstrapReminders(container));
}

Future<void> _bootstrapReminders(ProviderContainer container) async {
  final notifications = container.read(notificationServiceProvider);
  await notifications.requestPermissions();
  await container.read(reminderSchedulerProvider).rescheduleAll();

  final payload = await notifications.launchPayload();
  if (payload != null) {
    // Pequeño margen para que el router ya esté montado.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _openEventFromPayload(payload);
  }
}

void _openEventFromPayload(String? payload) {
  final id = int.tryParse(payload ?? '');
  if (id != null) {
    // La notificación es una alarma: abre la pantalla de alarma
    // (con Descartar / Aplazar), no el detalle plano.
    appRouter.push('/alarm/$id');
  }
}

class CalendarioApp extends ConsumerWidget {
  const CalendarioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Calendario',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
