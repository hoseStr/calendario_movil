import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

/// Localización de Material en español que fuerza el reloj en formato 12 h
/// (AM/PM) en los selectores de hora. Solo cambia [timeOfDayFormat]; el resto
/// de textos (botones, títulos) siguen viniendo de la localización española.
///
/// Necesario porque `showTimePicker` no tiene una opción para forzar 12 h:
/// con `alwaysUse24HourFormat: false` se usa el formato por defecto del idioma,
/// y en español ese formato es de 24 h.
class _EsAmPmMaterialLocalizations extends MaterialLocalizationEs {
  const _EsAmPmMaterialLocalizations({
    required super.fullYearFormat,
    required super.compactDateFormat,
    required super.shortDateFormat,
    required super.mediumDateFormat,
    required super.longDateFormat,
    required super.yearMonthFormat,
    required super.shortMonthDayFormat,
    required super.decimalFormat,
    required super.twoDigitZeroPaddedFormat,
  });

  @override
  TimeOfDayFormat timeOfDayFormat({bool alwaysUse24HourFormat = false}) =>
      alwaysUse24HourFormat
          ? TimeOfDayFormat.HH_colon_mm
          : TimeOfDayFormat.h_colon_mm_space_a;
}

class _EsAmPmDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _EsAmPmDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'es';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    const name = 'es';
    return SynchronousFuture(_EsAmPmMaterialLocalizations(
      fullYearFormat: intl.DateFormat('y', name),
      compactDateFormat: intl.DateFormat('yMd', name),
      shortDateFormat: intl.DateFormat('yMMMd', name),
      mediumDateFormat: intl.DateFormat('EEE, MMM d', name),
      longDateFormat: intl.DateFormat('EEEE, MMMM d, y', name),
      yearMonthFormat: intl.DateFormat('MMMM y', name),
      shortMonthDayFormat: intl.DateFormat('MMM d', name),
      decimalFormat: intl.NumberFormat('#,##0.###', name),
      twoDigitZeroPaddedFormat: intl.NumberFormat('00', name),
    ));
  }

  @override
  bool shouldReload(_EsAmPmDelegate old) => false;
}

/// Igual que [showTimePicker], pero forzando el reloj en 12 h (AM/PM) con los
/// textos del diálogo en español.
Future<TimeOfDay?> showAmPmTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (context, child) => Localizations.override(
      context: context,
      delegates: const [_EsAmPmDelegate()],
      child: child!,
    ),
  );
}
