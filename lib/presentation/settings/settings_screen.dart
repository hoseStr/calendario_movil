import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/utils/time_picker.dart';
import '../app_providers.dart';
import '../pet/pet_providers.dart';
import 'settings_providers.dart';

/// Ajustes: apariencia, mascota, copia de seguridad y alarmas fiables.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _personalityCtrl = TextEditingController();
  bool _prefsLoaded = false;
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _personalityCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(PetPrefs prefs) {
    if (_prefsLoaded) return;
    if (prefs.name.isNotEmpty || prefs.personality.isNotEmpty) {
      _nameCtrl.text = prefs.name;
      _personalityCtrl.text = prefs.personality;
      _prefsLoaded = true;
    }
  }

  Future<void> _savePetPrefs() async {
    final notifier = ref.read(petPrefsProvider.notifier);
    await notifier.setName(_nameCtrl.text);
    await notifier.setPersonality(_personalityCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mascota actualizada')),
    );
  }

  Future<void> _pickMorningTime() async {
    final prefs = ref.read(petPrefsProvider);
    final picked = await showAmPmTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: prefs.morningMinutes ~/ 60,
        minute: prefs.morningMinutes % 60,
      ),
    );
    if (picked == null) return;
    await ref
        .read(petPrefsProvider.notifier)
        .setMorningMinutes(picked.hour * 60 + picked.minute);
    // Reprograma el mensaje matutino con la nueva hora.
    final latest =
        await ref.read(petMessageRepositoryProvider).latest();
    final now = DateTime.now();
    var next = DateTime(
        now.year, now.month, now.day, picked.hour, picked.minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await ref.read(notificationServiceProvider).scheduleMorningMessage(
          fireAt: next,
          body: latest?.message ?? 'Tu mascota te espera con un mensajito',
        );
  }

  Future<Directory> _backupsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/backups');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Guarda una copia interna y además copia el JSON al portapapeles,
  /// para pegarlo en Drive/notas y tenerlo fuera del teléfono.
  Future<void> _exportBackup() async {
    setState(() => _busy = true);
    try {
      final json = await ref.read(backupServiceProvider).exportJson();
      final dir = await _backupsDir();
      final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      await File('${dir.path}/calendario_backup_$stamp.json')
          .writeAsString(json);

      // Conserva solo las 10 copias más recientes.
      final files = dir.listSync().whereType<File>().toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      for (final old in files.skip(10)) {
        old.deleteSync();
      }

      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Copia interna guardada y JSON copiado al '
              'portapapeles: pégalo en Drive o en una nota para tenerlo '
              'fuera del teléfono'),
          duration: Duration(seconds: 5),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo exportar el backup')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreFromInternal() async {
    final dir = await _backupsDir();
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    if (files.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay copias internas todavía')),
        );
      }
      return;
    }
    if (!mounted) return;
    final selected = await showDialog<File>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Copias internas'),
        children: [
          for (final file in files)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(file),
              child: Text(file.path.split(Platform.pathSeparator).last),
            ),
        ],
      ),
    );
    if (selected == null) return;
    await _restoreFromJsonString(await selected.readAsString());
  }

  Future<void> _restoreFromFile() async {
    final picked = await openFile(acceptedTypeGroups: [
      const XTypeGroup(label: 'Backup', extensions: ['json']),
    ]);
    if (picked == null) return;
    await _restoreFromJsonString(await picked.readAsString());
  }

  Future<void> _restoreFromJsonString(String json) async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Restaurar backup?'),
        content: const Text(
            'Se reemplazará TODO el contenido actual (eventos, ajustes y '
            'mensajes de la mascota) por el del backup.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(backupServiceProvider).restoreFromJson(json);
      await ref.read(reminderSchedulerProvider).rescheduleAll();
      ref.invalidate(themeModeProvider);
      ref.invalidate(petPrefsProvider);
      _prefsLoaded = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restaurado')),
        );
      }
    } on FormatException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo restaurar el backup')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final prefs = ref.watch(petPrefsProvider);
    _syncControllers(prefs);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final morningLabel = DateFormat('h:mm a').format(
      DateTime(2000, 1, 1, prefs.morningMinutes ~/ 60,
          prefs.morningMinutes % 60),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(title: const Text('Ajustes')),
      body: DreamyBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Gap.xl, Gap.sm, Gap.xl, Insets.bottomGap),
            children: [
              Text('Apariencia', style: textTheme.titleMedium),
              Gaps.vMd,
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Sistema'),
                        icon: Icon(Icons.brightness_auto_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Claro'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Oscuro'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (selection) => ref
                        .read(themeModeProvider.notifier)
                        .setMode(selection.first),
                  ),
                ),
              ),
              Gaps.vXxl,
              Text('Mascota', style: textTheme.titleMedium),
              Gaps.vMd,
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de tu mascota',
                        ),
                      ),
                      Gaps.vMd,
                      TextField(
                        controller: _personalityCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Rasgos extra (opcional)',
                          hintText: 'ej. le encanta el café y odia los lunes',
                        ),
                      ),
                      Gaps.vMd,
                      FilledButton(
                        onPressed: _savePetPrefs,
                        child: const Text('Guardar'),
                      ),
                      const Divider(height: 28),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.wb_twilight,
                            color: scheme.primary),
                        title: const Text('Mensaje matutino'),
                        subtitle: Text('Cada día a las $morningLabel'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _pickMorningTime,
                      ),
                    ],
                  ),
                ),
              ),
              Gaps.vXxl,
              Text('Copia de seguridad', style: textTheme.titleMedium),
              Gaps.vMd,
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            Icon(Icons.upload_outlined, color: scheme.primary),
                        title: const Text('Exportar'),
                        subtitle: const Text(
                            'Copia interna + JSON al portapapeles'),
                        onTap: _busy ? null : _exportBackup,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.download_outlined,
                            color: scheme.primary),
                        title: const Text('Restaurar desde archivo'),
                        subtitle: const Text(
                            'Elige un backup .json (Drive, Descargas…)'),
                        onTap: _busy ? null : _restoreFromFile,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.history,
                            color: scheme.primary),
                        title: const Text('Restaurar copia interna'),
                        subtitle: const Text(
                            'Últimas 10 copias guardadas en el teléfono'),
                        onTap: _busy ? null : _restoreFromInternal,
                      ),
                    ],
                  ),
                ),
              ),
              Gaps.vXxl,
              Text('Alarmas fiables', style: textTheme.titleMedium),
              Gaps.vMd,
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          'Algunos fabricantes "matan" las apps en segundo '
                          'plano y las alarmas dejan de sonar. Si te pasa, '
                          'sigue la guía de tu marca:',
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const _BatteryGuideTile(
                        brand: 'Xiaomi / Redmi / POCO',
                        steps:
                            'Ajustes → Apps → Calendario → Ahorro de batería '
                            '→ "Sin restricciones". Además: Apps → Permisos '
                            '→ Inicio automático → activar.',
                      ),
                      const _BatteryGuideTile(
                        brand: 'Huawei / Honor',
                        steps: 'Ajustes → Batería → Inicio de apps → '
                            'Calendario → desactivar "Gestión automática" y '
                            'activar las tres opciones manuales.',
                      ),
                      const _BatteryGuideTile(
                        brand: 'Samsung',
                        steps: 'Ajustes → Batería → Límites de uso en '
                            'segundo plano → quitar Calendario de "Apps '
                            'inactivas" y añadirla a "Nunca inactivas".',
                      ),
                      const _BatteryGuideTile(
                        brand: 'Otros (Android puro, Motorola…)',
                        steps: 'Ajustes → Apps → Calendario → Batería → '
                            '"Sin restricciones". Normalmente basta con '
                            'aceptar el permiso de alarmas exactas.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatteryGuideTile extends StatelessWidget {
  const _BatteryGuideTile({required this.brand, required this.steps});

  final String brand;
  final String steps;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(brand, style: Theme.of(context).textTheme.bodyMedium),
      shape: const Border(),
      collapsedShape: const Border(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              steps,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
