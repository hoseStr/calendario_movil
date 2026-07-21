import 'package:drift/drift.dart';

/// Tabla de eventos del calendario.
/// La clase generada se llama EventRow para no chocar con la
/// entidad de dominio Event.
@DataClassName('EventRow')
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime()();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  TextColumn get category => text().nullable()();
  TextColumn get recurrenceRule => text().nullable()();
  IntColumn get reminderMinutes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Recordatorios programados (bitácora de notificaciones).
/// Estados: 'scheduled' | 'fired' | 'cancelled'.
@DataClassName('ReminderRow')
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId =>
      integer().references(Events, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get fireAt => dateTime()();
  IntColumn get notificationId => integer()();
  TextColumn get status => text().withDefault(const Constant('scheduled'))();
}

/// Mensajes diarios de la mascota (máx. 1 por día).
/// source: 'gemini' | 'fallback'.
@DataClassName('PetMessageRow')
class PetMessages extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Día normalizado (sin hora).
  DateTimeColumn get date => dateTime()();
  TextColumn get mood => text()();
  TextColumn get message => text()();
  TextColumn get source => text().withDefault(const Constant('fallback'))();
}

/// Preferencias clave-valor (nombre de la mascota, hora del mensaje, etc.).
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
