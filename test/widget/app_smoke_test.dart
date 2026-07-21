import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:calendario_movil/main.dart';

void main() {
  testWidgets('la app arranca y muestra la barra de navegación',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CalendarioApp()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Calendario'), findsWidgets);
    expect(find.text('Mascota'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
  });
}
