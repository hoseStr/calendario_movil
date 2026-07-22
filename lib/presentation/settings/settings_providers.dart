import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';
import '../calendar/calendar_providers.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

/// Modo de tema (sistema/claro/oscuro), persistido en la BD.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final saved = await ref.read(settingsRepositoryProvider).get(_key);
    if (saved == null) return;
    state = ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsRepositoryProvider).set(_key, mode.name);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Preferencias de la mascota y del mensaje matutino.
class PetPrefs {
  const PetPrefs({
    this.name = '',
    this.personality = '',
    this.morningMinutes = 480, // 8:00
  });

  final String name;
  final String personality;

  /// Minutos desde medianoche para el mensaje matutino.
  final int morningMinutes;

  PetPrefs copyWith({String? name, String? personality, int? morningMinutes}) =>
      PetPrefs(
        name: name ?? this.name,
        personality: personality ?? this.personality,
        morningMinutes: morningMinutes ?? this.morningMinutes,
      );
}

class PetPrefsNotifier extends Notifier<PetPrefs> {
  @override
  PetPrefs build() {
    _load();
    return const PetPrefs();
  }

  Future<void> _load() async {
    final repo = ref.read(settingsRepositoryProvider);
    final name = await repo.get('pet_name') ?? '';
    final personality = await repo.get('pet_personality') ?? '';
    final minutes =
        int.tryParse(await repo.get('morning_minutes') ?? '') ?? 480;
    state = PetPrefs(
        name: name, personality: personality, morningMinutes: minutes);
  }

  Future<void> setName(String value) async {
    state = state.copyWith(name: value.trim());
    await ref.read(settingsRepositoryProvider).set('pet_name', value.trim());
  }

  Future<void> setPersonality(String value) async {
    state = state.copyWith(personality: value.trim());
    await ref
        .read(settingsRepositoryProvider)
        .set('pet_personality', value.trim());
  }

  Future<void> setMorningMinutes(int minutes) async {
    state = state.copyWith(morningMinutes: minutes);
    await ref
        .read(settingsRepositoryProvider)
        .set('morning_minutes', '$minutes');
  }
}

final petPrefsProvider =
    NotifierProvider<PetPrefsNotifier, PetPrefs>(PetPrefsNotifier.new);
