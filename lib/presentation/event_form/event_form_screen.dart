import 'package:flutter/material.dart';

/// Formulario de crear/editar evento (contenido real en Fase 4).
/// Si [eventId] es null, es creación; si no, edición.
class EventFormScreen extends StatelessWidget {
  const EventFormScreen({super.key, this.eventId});

  final String? eventId;

  @override
  Widget build(BuildContext context) {
    final isNew = eventId == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'Nuevo evento' : 'Editar evento')),
      body: Center(
        child: Text(
          'Formulario de evento — Fase 4',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
