import 'package:flutter_test/flutter_test.dart';

import 'package:calendario_movil/domain/entities/agenda_summary.dart';
import 'package:calendario_movil/domain/usecases/summarize_agenda.dart';

void main() {
  const summarize = SummarizeAgenda();

  test('0 eventos hoy → día libre, mascota dormida', () {
    final s = summarize(todayCount: 0, weekCount: 3);
    expect(s.load, DayLoad.free);
    expect(s.mood, PetMood.sleeping);
  });

  test('1-2 eventos → día normal, mascota feliz', () {
    expect(summarize(todayCount: 1, weekCount: 1).load, DayLoad.normal);
    expect(summarize(todayCount: 2, weekCount: 2).load, DayLoad.normal);
    expect(summarize(todayCount: 2, weekCount: 2).mood, PetMood.happy);
  });

  test('3-4 eventos → día cargado, mascota animando', () {
    expect(summarize(todayCount: 3, weekCount: 3).load, DayLoad.busy);
    expect(summarize(todayCount: 4, weekCount: 4).load, DayLoad.busy);
    expect(summarize(todayCount: 4, weekCount: 4).mood, PetMood.cheering);
  });

  test('5+ eventos → día muy cargado, mascota animando', () {
    final s = summarize(todayCount: 5, weekCount: 9);
    expect(s.load, DayLoad.veryBusy);
    expect(s.mood, PetMood.cheering);
  });

  test('conserva los conteos', () {
    final s = summarize(todayCount: 2, weekCount: 7);
    expect(s.todayCount, 2);
    expect(s.weekCount, 7);
  });
}
