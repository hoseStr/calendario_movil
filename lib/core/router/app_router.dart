import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/alarm/alarm_screen.dart';
import '../../presentation/calendar/calendar_screen.dart';
import '../../presentation/event_form/event_detail_screen.dart';
import '../../presentation/event_form/event_form_screen.dart';
import '../../presentation/pet/pet_screen.dart';
import '../../presentation/search/search_screen.dart';
import '../../presentation/settings/settings_screen.dart';

/// Router de la app.
/// Tres ramas con barra inferior (Calendario · Mascota · Ajustes) y
/// rutas de evento que se abren por encima de la barra.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Alarma a pantalla completa (fuera del shell, sin barra inferior).
    GoRoute(
      path: '/alarm/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          AlarmScreen(eventId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SearchScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const CalendarScreen(),
              routes: [
                GoRoute(
                  path: 'event/new',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const EventFormScreen(),
                ),
                GoRoute(
                  path: 'event/:id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => EventDetailScreen(
                    eventId: state.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => EventFormScreen(
                        eventId: state.pathParameters['id'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pet',
              builder: (context, state) => const PetScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
  navigatorKey: _rootNavigatorKey,
);

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Scaffold con la barra de navegación inferior compartida.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Volver al inicio de la rama si ya estás en ella.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Mascota',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
