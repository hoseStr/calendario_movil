import 'package:flutter/material.dart';

/// Detalle de un evento (contenido real en Fase 4).
class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del evento')),
      body: Center(
        child: Text(
          'Evento $eventId — Fase 4',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
