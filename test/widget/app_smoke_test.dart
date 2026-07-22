import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:calendario_movil/data/db/database.dart';
import 'package:calendario_movil/main.dart';
import 'package:calendario_movil/presentation/calendar/calendar_providers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  testWidgets('la app arranca y muestra la barra de navegación',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // La UI de la mascota es reactiva (stream de la BD, vacía aquí);
    // la generación solo ocurre en main() o con el botón de refresco,
    // así que el test no dispara ninguna cadena asíncrona externa.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const CalendarioApp(),
      ),
    );
    // pumpAndSettle no sirve aquí: las luciérnagas y la mascota animan
    // en bucle infinito y nunca "se asientan". Pumps fijos en su lugar.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

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
