import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/event.dart';
import '../calendar/calendar_providers.dart';

/// Evento observado por id (se refresca solo tras editar o borrar).
final eventByIdProvider =
    StreamProvider.autoDispose.family<Event?, int>((ref, id) {
  return ref.watch(eventRepositoryProvider).watchById(id);
});
