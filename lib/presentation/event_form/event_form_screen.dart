import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_gradients.dart';
import '../../domain/entities/event.dart';
import '../../domain/usecases/expand_recurrences.dart';
import '../app_providers.dart';
import '../calendar/calendar_providers.dart';

const _reminderOptions = <int?, String>{
  null: 'Sin recordatorio',
  0: 'Al momento del evento',
  5: '5 minutos antes',
  10: '10 minutos antes',
  15: '15 minutos antes',
  30: '30 minutos antes',
  60: '1 hora antes',
  120: '2 horas antes',
  1440: '1 día antes',
};

/// Formulario de crear/editar evento.
/// Si [eventId] es null, crea; si no, edita.
class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, this.eventId});

  final String? eventId;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  late DateTime _startAt;
  late DateTime _endAt;
  int _colorIndex = 0;
  int? _reminderMinutes;
  String? _recurrenceRule;
  Event? _original;
  bool _loading = false;
  bool _saving = false;
  String? _rangeError;

  bool get _isEditing => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    // Precarga: día seleccionado en el calendario, a la siguiente hora
    // en punto si es hoy, o a las 9:00 si es otro día.
    final selectedDay = ref.read(selectedDayProvider);
    final now = DateTime.now();
    final isToday = dayKey(now) == selectedDay;
    _startAt = isToday
        ? DateTime(now.year, now.month, now.day, now.hour + 1)
        : selectedDay.add(const Duration(hours: 9));
    _endAt = _startAt.add(const Duration(hours: 1));

    if (_isEditing) {
      _loading = true;
      _loadEvent();
    }
  }

  Future<void> _loadEvent() async {
    final id = int.tryParse(widget.eventId!);
    final event = id == null
        ? null
        : await ref.read(eventRepositoryProvider).getById(id);
    if (!mounted) return;
    setState(() {
      if (event != null) {
        _original = event;
        _titleCtrl.text = event.title;
        _descCtrl.text = event.description ?? '';
        _startAt = event.startAt;
        _endAt = event.endAt;
        _colorIndex = event.colorIndex;
        _reminderMinutes = event.reminderMinutes;
        _recurrenceRule = event.recurrenceRule;
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _startAt : _endAt;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    final picked =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      _rangeError = null;
      if (isStart) {
        // Mover el inicio conserva la duración.
        final duration = _endAt.difference(_startAt);
        _startAt = picked;
        _endAt = picked.add(duration);
      } else {
        _endAt = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_endAt.isAfter(_startAt)) {
      setState(() => _rangeError = 'El fin debe ser posterior al inicio');
      return;
    }

    setState(() => _saving = true);
    final description = _descCtrl.text.trim();
    final now = DateTime.now();
    final event = Event(
      id: _original?.id,
      title: _titleCtrl.text.trim(),
      description: description.isEmpty ? null : description,
      startAt: _startAt,
      endAt: _endAt,
      colorIndex: _colorIndex,
      category: _original?.category,
      recurrenceRule: _recurrenceRule,
      reminderMinutes: _reminderMinutes,
      createdAt: _original?.createdAt ?? now,
      updatedAt: now,
    );

    final repo = ref.read(eventRepositoryProvider);
    final Event saved;
    if (_isEditing) {
      await repo.update(event);
      saved = event;
    } else {
      saved = await repo.create(event);
    }
    // Programa (o reprograma) la alarma del evento.
    await ref.read(reminderSchedulerProvider).syncEvent(saved);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat("EEE d 'de' MMM · HH:mm", 'es');
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar evento' : 'Nuevo evento'),
      ),
      body: DreamyBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        Gap.xl, Gap.sm, Gap.xl, Gap.xxxl),
                    children: [
                      TextFormField(
                        controller: _titleCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration:
                            const InputDecoration(labelText: 'Título'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'El título es obligatorio'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Descripción (opcional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DateTile(
                        label: 'Inicio',
                        value: dateFormat.format(_startAt),
                        onTap: () => _pickDateTime(isStart: true),
                      ),
                      const SizedBox(height: 8),
                      _DateTile(
                        label: 'Fin',
                        value: dateFormat.format(_endAt),
                        onTap: () => _pickDateTime(isStart: false),
                        errorText: _rangeError,
                      ),
                      const SizedBox(height: 20),
                      Text('Color', style: textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        children: [
                          for (var i = 0;
                              i < AppColors.eventCategories.length;
                              i++)
                            _ColorDot(
                              color: AppColors.eventCategories[i],
                              selected: i == _colorIndex,
                              onTap: () => setState(() => _colorIndex = i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String?>(
                        initialValue: _recurrenceRule,
                        decoration:
                            const InputDecoration(labelText: 'Repetición'),
                        items: [
                          for (final entry in RecurrenceRules.labels.entries)
                            DropdownMenuItem<String?>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _recurrenceRule = value),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int?>(
                        initialValue: _reminderMinutes,
                        decoration:
                            const InputDecoration(labelText: 'Recordatorio'),
                        items: [
                          for (final entry in _reminderOptions.entries)
                            DropdownMenuItem<int?>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _reminderMinutes = value),
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _isEditing ? 'Guardar cambios' : 'Crear evento',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 20, color: scheme.primary),
                  const SizedBox(width: 12),
                  Text(label,
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6),
            child: Text(
              errorText!,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dot = context.scale(36, max: 1.2);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: dot,
        height: dot,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: scheme.onSurface, width: 2.5)
              : null,
        ),
        child: selected
            ? Icon(Icons.check, size: dot * 0.5, color: Colors.black54)
            : null,
      ),
    );
  }
}
