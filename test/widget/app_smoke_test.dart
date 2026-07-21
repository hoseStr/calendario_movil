import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:calendario_movil/data/db/database.dart';
import 'package:calendario_movil/domain/entities/agenda_summary.dart';
import 'package:calendario_movil/domain/entities/pet_message.dart';
import 'package:calendario_movil/main.dart';
import 'package:calendario_movil/presentation/calendar/calendar_providers.dart';
import 'package:calendario_movil/presentation/pet/pet_providers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  testWidgets('la app arranca y muestra la barra de navegación',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          // Mensaje fijo: la cadena asíncrona real (resumen de agenda +
          // guardado en BD) no se lleva bien con el reloj falso del test
          // y ya está cubierta por los tests unitarios.
          dailyPetMessageProvider.overrideWith(
            (ref) async => PetMessage(
              date: DateTime(2026, 7, 22),
              mood: PetMood.happy,
              message: 'Hola humano',
              source: 'fallback',
            ),
          ),
        ],
        child: const CalendarioApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Calendario'), findsWidgets);
    expect(find.text('Mascota'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);

    // Desmonta el árbol dentro del test: drift programa un timer de
    // duración cero al cerrar sus streams. pump() sin duración NO avanza
    // el reloj falso del test, así que hay que avanzarlo explícitamente
    // para que ese timer se dispare antes de que el test termine.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  });
}
