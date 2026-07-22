import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_gradients.dart';
import '../../domain/entities/event.dart';
import '../calendar/calendar_providers.dart';

/// Búsqueda de eventos por texto, con filtro por color de categoría.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryCtrl = TextEditingController();
  Timer? _debounce;
  List<Event> _results = const [];
  int? _colorFilter;
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _search);
  }

  Future<void> _search() async {
    final query = _queryCtrl.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _searched = false;
      });
      return;
    }
    final results =
        await ref.read(eventRepositoryProvider).search(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final visible = _colorFilter == null
        ? _results
        : _results.where((e) => e.colorIndex == _colorFilter).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: TextField(
          controller: _queryCtrl,
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Buscar eventos…',
            border: InputBorder.none,
            filled: false,
          ),
        ),
      ),
      body: DreamyBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Insets.screenH, Gap.sm, Insets.screenH, Gap.xs),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Todos'),
                        selected: _colorFilter == null,
                        onSelected: (_) =>
                            setState(() => _colorFilter = null),
                      ),
                      for (var i = 0;
                          i < AppColors.eventCategories.length;
                          i++) ...[
                        const SizedBox(width: 8),
                        FilterChip(
                          avatar: CircleAvatar(
                            backgroundColor: AppColors.eventCategories[i],
                          ),
                          label: const Text(''),
                          labelPadding: EdgeInsets.zero,
                          selected: _colorFilter == i,
                          onSelected: (_) => setState(() =>
                              _colorFilter = _colorFilter == i ? null : i),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: !_searched
                    ? Center(
                        child: Text(
                          'Escribe para buscar en tus eventos',
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : visible.isEmpty
                        ? Center(
                            child: Text(
                              'Sin resultados',
                              style: textTheme.bodyMedium?.copyWith(
                                color:
                                    scheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                Insets.screenH, Gap.xs, Insets.screenH, Gap.xxl),
                            itemCount: visible.length,
                            itemBuilder: (context, index) =>
                                _ResultCard(event: visible[index]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final color = AppColors
        .eventCategories[event.colorIndex % AppColors.eventCategories.length];
    final dateLabel = DateFormat("EEE d 'de' MMM y · HH:mm", 'es')
        .format(event.startAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/event/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (event.recurrenceRule != null)
                Icon(Icons.repeat,
                    size: 16,
                    color: scheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
