import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:calendario_movil/data/db/database.dart';
import 'package:calendario_movil/data/repositories/event_repository.dart';
import 'package:calendario_movil/domain/entities/event.dart';
import 'package:calendario_movil/main.dart';
import 'package:calendario_movil/presentation/calendar/calendar_providers.dart';

/// Verificación de responsividad (RESPONSIVE_PLAN.md, Fase 4).
///
/// Estrategia: montar la app en una matriz de tamaños de teléfono y escalas
/// de fuente del sistema, navegar por las tres pestañas y comprobar que NO se
/// produce ningún `RenderFlex overflowed` (en tests, un overflow provoca una
/// excepción que `tester` acumula y hace fallar la prueba).
///
/// La escala 1.5 comprueba además que el clamp de `main.dart` (0.9–1.3)
/// impide el desborde aunque el usuario ponga la fuente al máximo.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  // (ancho, alto) lógicos representativos: angosto, referencia, grande.
  const sizes = <Size>[
    Size(320, 640),
    Size(390, 844),
    Size(430, 932),
  ];
  // Escalas de fuente: normal, grande y extrema (por encima del clamp).
  const textScales = <double>[1.0, 1.15, 1.5];
  const dpr = 2.0;

  Future<void> pumpApp(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const CalendarioApp(),
      ),
    );
    // Las luciérnagas y la mascota animan en bucle: pumps fijos, no settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  for (final size in sizes) {
    for (final scale in textScales) {
      testWidgets(
        'sin overflow @ ${size.width.toInt()}x${size.height.toInt()} '
        '· fuente x$scale',
        (tester) async {
          tester.view.physicalSize = size * dpr;
          tester.view.devicePixelRatio = dpr;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearAllTestValues);

          final db = AppDatabase.forTesting(NativeDatabase.memory());
          addTearDown(db.close);

          // Un evento con título largo estresa las tarjetas y filas.
          await EventRepository(db).create(Event(
            title: 'Reunión larguísima de planificación trimestral del equipo',
            startAt: DateTime.now().add(const Duration(hours: 1)),
            endAt: DateTime.now().add(const Duration(hours: 2)),
            reminderMinutes: 30,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));

          await pumpApp(tester, db);
          expect(tester.takeException(), isNull,
              reason: 'overflow en Calendario');

          await tapTab(tester, 'Mascota');
          expect(tester.takeException(), isNull,
              reason: 'overflow en Mascota');

          await tapTab(tester, 'Ajustes');
          expect(tester.takeException(), isNull,
              reason: 'overflow en Ajustes');

          // Desmonta el árbol DENTRO del cuerpo del test para que los timers
          // de cierre de streams de drift se vacíen antes del teardown
          // (si no, salta el assert `!timersPending`).
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 1));
        },
      );
    }
  }
}
