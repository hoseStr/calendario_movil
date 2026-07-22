import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Envoltorio de flutter_local_notifications.
/// Programa por instante absoluto (TZDateTime.from conserva el momento
/// exacto aunque la zona local del paquete quede en UTC), así no se
/// necesita flutter_timezone.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // v2: el patrón de vibración se fija al CREAR el canal (los canales de
  // Android son inmutables), por eso el id cambió de 'event_alarms' a v2.
  static final Int64List _vibrationPattern =
      Int64List.fromList([0, 500, 250, 500, 250, 800]);

  static final AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'event_alarms_v2',
    'Alarmas de eventos',
    description: 'Recordatorios de los eventos del calendario',
    importance: Importance.max,
    enableVibration: true,
    vibrationPattern: _vibrationPattern,
  );

  static final NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'event_alarms_v2',
      'Alarmas de eventos',
      channelDescription: 'Recordatorios de los eventos del calendario',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      vibrationPattern: _vibrationPattern,
      // Pantalla completa sobre el bloqueo (estilo Google Calendar).
      fullScreenIntent: true,
    ),
    iOS: const DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  /// Notificación matutina de la mascota (id fijo: reprogramar reemplaza).
  static const int morningNotificationId = 900001;

  static const AndroidNotificationChannel _petChannel =
      AndroidNotificationChannel(
    'pet_messages',
    'Mensajes de la mascota',
    description: 'El mensajito diario de tu mascota',
    importance: Importance.defaultImportance,
  );

  static const NotificationDetails _morningDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'pet_messages',
      'Mensajes de la mascota',
      channelDescription: 'El mensajito diario de tu mascota',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// [onSelect] se dispara al tocar una notificación con la app abierta
  /// o en segundo plano. El payload es el id del evento.
  Future<void> init({
    required void Function(String? payload) onSelect,
  }) async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) =>
          onSelect(response.payload),
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);
    await android?.createNotificationChannel(_petChannel);
    _initialized = true;
  }

  /// Programa (o reemplaza) el mensaje matutino de la mascota.
  /// Se reprograma en cada apertura de la app, así el texto siempre es
  /// el mensaje más reciente y la hora respeta la zona local.
  Future<void> scheduleMorningMessage({
    required DateTime fireAt,
    required String body,
  }) async {
    if (!fireAt.isAfter(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id: morningNotificationId,
        title: 'Tu mascota amaneció con algo que decirte',
        body: body,
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        notificationDetails: _morningDetails,
        // Inexacta a propósito: no es una alarma, ahorra batería.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'pet',
      );
    } on PlatformException {
      // Sin permisos: simplemente no habrá mensaje matutino.
    }
  }

  /// Payload si la app fue ABIERTA desde una notificación (app cerrada).
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details!.notificationResponse?.payload;
    }
    return null;
  }

  Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
      // Android 14+: permiso especial para pantalla completa.
      try {
        await android.requestFullScreenIntentPermission();
      } on PlatformException {
        // Algunos dispositivos no exponen el ajuste; la notificación
        // normal seguirá funcionando.
      }
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Programa una alarma exacta; si el permiso de alarmas exactas fue
  /// revocado, cae a inexacta (mejor tarde que nunca).
  Future<void> schedule({
    required int id,
    required String title,
    String? body,
    required DateTime fireAt,
    String? payload,
  }) async {
    if (!fireAt.isAfter(DateTime.now())) return;
    final scheduledDate = tz.TZDateTime.from(fireAt, tz.local);
    try {
      await _zonedSchedule(
          id, title, body, scheduledDate, payload,
          AndroidScheduleMode.exactAllowWhileIdle);
    } on PlatformException {
      await _zonedSchedule(
          id, title, body, scheduledDate, payload,
          AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> _zonedSchedule(
    int id,
    String title,
    String? body,
    tz.TZDateTime scheduledDate,
    String? payload,
    AndroidScheduleMode mode,
  ) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _details,
      androidScheduleMode: mode,
      payload: payload,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();
}
