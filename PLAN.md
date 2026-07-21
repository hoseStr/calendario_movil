# Plan de Desarrollo Progresivo

Complemento de `ARCHITECTURE.md`. Cada fase es pequeña, termina con algo **funcional y probable en el teléfono**, y no requiere tocar lo de fases futuras. Marca los checkboxes a medida que avanzas.

**Regla de oro:** no pases a la siguiente fase sin cumplir el "criterio de terminado" de la actual.

---

## Fase 0 — Preparación del entorno (1 sesión)

Objetivo: proyecto Flutter corriendo en tu dispositivo/emulador.

- [ ] Instalar Flutter SDK (canal stable) y Android Studio; correr `flutter doctor` sin errores.
- [ ] En esta carpeta ejecutar: `flutter create . --project-name calendario_movil --org com.jose --platforms android,ios`
  (el nombre con guion no es válido como paquete Dart, por eso `--project-name`). Las carpetas `lib/` ya creadas se conservan.
- [ ] Correr la app de plantilla en el emulador o teléfono real.
- [ ] `git init` + primer commit.

**Terminado cuando:** ves la app de plantilla corriendo y el commit inicial existe.

---

## Fase 1 — Esqueleto de la app (1-2 sesiones)

Objetivo: navegación y tema propios, aún sin datos reales.

- [ ] Añadir dependencias: `flutter_riverpod`, `go_router`.
- [ ] `core/theme/`: colores, tipografía y modo claro/oscuro (aquí nace el "estilo personalizado").
- [ ] `main.dart`: `ProviderScope` + `MaterialApp.router`.
- [ ] Rutas con go_router: `/` (calendario), `/event/new`, `/event/:id`, `/pet`, `/settings` — cada una con pantalla placeholder.
- [ ] Barra de navegación inferior o drawer: Calendario · Mascota · Ajustes.

**Terminado cuando:** navegas entre las 3 secciones con tu tema aplicado.

---

## Fase 2 — Base de datos (2 sesiones)

Objetivo: persistencia lista antes de cualquier UI de eventos.

- [ ] Dependencias: `drift`, `drift_flutter`, `drift_dev`, `build_runner`.
- [ ] `data/db/tables.dart`: tablas `events` y `settings` (deja `reminders` y `pet_messages` para sus fases — menos migraciones tempranas, súbelas cuando toquen).
- [ ] `data/db/database.dart` + generar código con `dart run build_runner build`.
- [ ] `domain/entities/event.dart` (entidad pura, sin drift).
- [ ] `data/repositories/event_repository.dart`: `watchEventsBetween(from, to)` (stream), `create`, `update`, `delete`, `getById`.
- [ ] Tests unitarios del repositorio con base en memoria (`NativeDatabase.memory()`).

**Terminado cuando:** los tests de CRUD pasan.

---

## Fase 3 — Calendario visible (2 sesiones)

Objetivo: ver el mes y los eventos de cada día.

- [ ] Dependencia: `table_calendar`.
- [ ] `presentation/calendar/`: vista mensual con tu estilo (colores de tema, marcadores de días con eventos).
- [ ] Al tocar un día: lista de eventos de ese día debajo del calendario (stream de drift → se actualiza sola).
- [ ] Provider Riverpod que expone eventos del rango visible.
- [ ] Insertar 2-3 eventos "semilla" por código para ver que se pintan.

**Terminado cuando:** los eventos semilla aparecen en el mes y en la lista del día.

---

## Fase 4 — CRUD de eventos (2 sesiones)

Objetivo: gestionar el calendario sin tocar código.

- [ ] `presentation/event_form/`: formulario crear/editar — título, descripción, fecha/hora inicio y fin, color/categoría, minutos de antelación del recordatorio (el selector existe ya, aunque la alarma llegue en Fase 5).
- [ ] Validaciones: título obligatorio, fin > inicio.
- [ ] Detalle de evento con botones editar y eliminar (con confirmación).
- [ ] FAB "+" en el calendario → formulario con el día seleccionado precargado.
- [ ] Quitar los eventos semilla.

**Terminado cuando:** creas, editas y borras eventos desde la app y sobreviven al reinicio de la app.

---

## Fase 5 — Alarmas y recordatorios (2-3 sesiones) ⚠️ la fase más delicada

Objetivo: la app te avisa aunque esté cerrada.

- [ ] Dependencias: `flutter_local_notifications`, `timezone`.
- [ ] Migración drift: tabla `reminders` (`event_id`, `fire_at`, `notification_id`, `status`).
- [ ] `data/services/notification_service.dart`: init, canal Android de importancia máxima con sonido de alarma, `zonedSchedule` con `exactAllowWhileIdle`, `cancel`.
- [ ] Permisos: `POST_NOTIFICATIONS` (Android 13+), `SCHEDULE_EXACT_ALARM` (Android 12+), solicitud en el primer arranque.
- [ ] Integrar al CRUD: crear evento → programar; editar → cancelar y reprogramar; borrar → cancelar.
- [ ] Tap en la notificación → abre el detalle del evento (payload `event_id`).
- [ ] Reprogramación tras reinicio del dispositivo (Android) y tope de 64 pendientes (iOS: programar solo las próximas ~50 y reponer al abrir la app).
- [ ] Probar en teléfono real: app cerrada, modo ahorro de batería, después de reiniciar.

**Terminado cuando:** una alarma suena con la app cerrada y tras reiniciar el teléfono.

---

## Fase 6 — Mascota con mensajes locales (1-2 sesiones)

Objetivo: la mascota existe y anima, sin depender aún de internet.

- [ ] Migración drift: tabla `pet_messages`.
- [ ] `domain/entities/`: `pet_message.dart`, `agenda_summary.dart`, enum `PetMood`.
- [ ] `domain/usecases/summarize_agenda.dart`: cuenta eventos de hoy/semana y clasifica el día (libre, normal, cargado, muy cargado).
- [ ] Banco local de ~30 mensajes por estado (`core/constants/fallback_messages.dart`).
- [ ] `presentation/pet/`: pantalla de la mascota (imagen estática por ahora) + mensaje del día + historial; widget pequeño de la mascota en la pantalla del calendario.
- [ ] Lógica "máx. 1 mensaje por día" cacheado en DB.

**Terminado cuando:** la mascota muestra un mensaje coherente con tu agenda, sin internet.

---

## Fase 7 — Conexión con Gemini (2 sesiones)

Objetivo: mensajes generados por IA con caída elegante al banco local.

- [ ] Dependencias: `dio`, `flutter_secure_storage`.
- [ ] Obtener API key en Google AI Studio (capa gratuita).
- [ ] `data/services/llm_client.dart` (interfaz) + `gemini_client.dart`: REST a `generateContent` con `gemini-2.5-flash-lite`, timeout 10 s.
- [ ] Prompt de sistema: personalidad de la mascota, español, máx. 2 frases, tono de ánimo.
- [ ] Ajustes: campo para pegar la API key (secure storage) y toggle "modo privado" (enviar solo conteos, nunca títulos).
- [ ] Flujo completo: abrir app → ¿mensaje de hoy? → no → resumen → Gemini → guardar / si falla → fallback (el usuario nunca ve un error).

**Terminado cuando:** con internet los mensajes vienen de Gemini; en modo avión, del banco local — sin errores visibles.

---

## Fase 8 — Mascota animada y estados de ánimo (2 sesiones)

Objetivo: darle vida.

- [ ] Elegir `rive` (interactiva) o `lottie` (más fácil, animaciones listas en LottieFiles).
- [ ] Animaciones por `PetMood`: feliz, animando, dormida, celebrando → en `assets/animations/`.
- [ ] Conectar mood al resumen de agenda (día libre → dormida/relajada; día cargado → animando; evento completado → celebrando).
- [ ] Notificación matutina diaria con el mensaje de la mascota (reusa `NotificationService`).

**Terminado cuando:** la mascota cambia de animación según tu semana.

---

## Fase 9 — Detalles finales (2-3 sesiones)

Objetivo: cerrar todo lo que quedó pendiente y pulir.

- [ ] Eventos recurrentes: regla simple (diaria/semanal/mensual) en `events.recurrence_rule`, expansión al consultar el rango visible; al programar alarmas, solo próximas ocurrencias.
- [ ] Vista semanal y/o de agenda además de la mensual.
- [ ] Búsqueda de eventos y filtro por categoría/color.
- [ ] Ajustes finales: nombre y personalidad de la mascota, hora del mensaje matutino, sonido de alarma.
- [ ] Backup/exportar: archivo local del contenido de la DB (JSON) y restauración.
- [ ] Guía in-app para fabricantes agresivos con batería (Xiaomi, Huawei…).
- [ ] Icono, splash screen, nombre final.
- [ ] `flutter build apk --release` e instalar en tu teléfono.

**Terminado cuando:** usas la app a diario y no te falta nada del objetivo original.

---

## Resumen de ritmo

| Fase | Qué obtienes | Sesiones aprox. |
|---|---|---|
| 0 | App plantilla corriendo | 1 |
| 1 | Navegación + tu estilo | 1-2 |
| 2 | Base de datos con tests | 2 |
| 3 | Calendario que muestra eventos | 2 |
| 4 | CRUD completo | 2 |
| 5 | Alarmas reales | 2-3 |
| 6 | Mascota offline | 1-2 |
| 7 | Mascota con Gemini | 2 |
| 8 | Animaciones y moods | 2 |
| 9 | Recurrencia, backup, release | 2-3 |

~16-21 sesiones cortas. Desde la Fase 4 ya tienes un calendario usable; desde la 5, útil de verdad; todo lo demás suma sin bloquear.

## Consejos anti-sobrecarga

1. Una fase (o media) por sesión; termina siempre en estado que compila.
2. Commit al final de cada checkbox importante; un commit con tag al cerrar cada fase.
3. Si una fase se atasca >2 sesiones, recorta alcance (p. ej., recurrencia solo semanal) y anota lo pendiente al final de este archivo.
4. Prueba en teléfono real desde la Fase 5; el emulador miente con las alarmas y la batería.
