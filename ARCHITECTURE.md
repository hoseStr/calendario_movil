# Arquitectura — Calendario Móvil Personalizado con Mascota IA

App de calendario personal (estilo Google Calendar) con estilo propio, 100% privada, con alarmas de recordatorio y una mascota virtual que envía mensajes de ánimo generados por un LLM según la agenda del día/semana.

**Stack:** Flutter · SQLite local · Notificaciones/alarmas locales · Google Gemini API

---

## 1. Principios de diseño

1. **Privacidad primero:** todos los eventos viven en SQLite en el dispositivo. Nada sale de él, excepto un resumen mínimo y anonimizado de la agenda que se envía a Gemini para generar los mensajes de la mascota.
2. **Offline-first:** el calendario y las alarmas funcionan sin internet. Solo la mascota requiere conexión (con mensajes de respaldo predefinidos si no hay red).
3. **Capas desacopladas:** Clean Architecture simplificada (presentación → dominio → datos), para poder cambiar el proveedor de LLM o la base de datos sin tocar la UI.

## 2. Vista general

```
┌──────────────────────── PRESENTACIÓN (Flutter) ────────────────────────┐
│  CalendarScreen   EventFormScreen   PetWidget/PetScreen   Settings     │
│                    Riverpod (estado y providers)                       │
└──────────────┬──────────────────────────────┬──────────────────────────┘
               │                              │
┌──────────────▼─────────────┐  ┌─────────────▼─────────────────────────┐
│         DOMINIO            │  │  Casos de uso: crear/editar/borrar    │
│  Entidades: Event,         │  │  evento, programar alarma, generar    │
│  Reminder, PetMessage,     │  │  mensaje de mascota, resumen semanal  │
│  PetMood                   │  │                                       │
└──────────────┬─────────────┘  └─────────────┬─────────────────────────┘
               │                              │
┌──────────────▼──────────────────────────────▼──────────────────────────┐
│                              DATOS                                     │
│  EventRepository ──► SQLite (drift)                                    │
│  NotificationService ──► flutter_local_notifications + alarmas exactas │
│  PetAiService ──► LlmClient (interfaz) ──► GeminiClient (impl)         │
│  SettingsRepository ──► shared_preferences / flutter_secure_storage    │
└────────────────────────────────────────────────────────────────────────┘
```

## 3. Módulos

### 3.1 Calendario (núcleo)

- **UI:** paquete `table_calendar` (vista mensual/semanal personalizable) o `syncfusion_flutter_calendar` (más completo, licencia community). Recomendado empezar con `table_calendar` por flexibilidad de estilo.
- **CRUD de eventos:** título, descripción, fecha/hora inicio-fin, color/categoría, recurrencia (ninguna, diaria, semanal, mensual), minutos de antelación del recordatorio.
- **Recurrencia:** guardar la regla (tipo RRULE simplificada) y expandir ocurrencias al consultar el rango visible, no materializar infinitas filas.

### 3.2 Persistencia

- **drift** (ORM sobre SQLite) — tipado, migraciones, streams reactivos que actualizan la UI automáticamente.

```sql
events(id, title, description, start_at, end_at, color, category,
       recurrence_rule, reminder_minutes, created_at, updated_at)

reminders(id, event_id FK, fire_at, notification_id, status) -- programada/disparada/cancelada

pet_messages(id, date, mood, message, source) -- source: 'gemini' | 'fallback'

settings(key, value) -- nombre mascota, personalidad, hora del mensaje diario, etc.
```

### 3.3 Notificaciones y alarmas

- **flutter_local_notifications:** programación de notificaciones con sonido de alarma, canal propio en Android (importancia máxima, sonido personalizado).
- **Android:** usar `zonedSchedule` con `AndroidScheduleMode.exactAllowWhileIdle` + permiso `SCHEDULE_EXACT_ALARM` (Android 12+) y `POST_NOTIFICATIONS` (Android 13+). Para alarma tipo despertador considerar categoría `alarm` con full-screen intent.
- **iOS:** UNUserNotificationCenter vía el mismo paquete; límite de 64 notificaciones pendientes → programar solo las próximas N y reponer al abrir la app o con background fetch.
- **Flujo:** al crear/editar evento → cancelar notificación anterior (si existe) → programar nueva → guardar `notification_id` en `reminders`. Al borrar evento → cancelar sus notificaciones.
- **Reinicio del dispositivo (Android):** receiver de `BOOT_COMPLETED` (el paquete lo maneja) para reprogramar alarmas.

### 3.4 Mascota IA

- **UI:** widget animado persistente (esquina de la pantalla principal) + pantalla propia con historial de mensajes. Animaciones con **Rive** o **Lottie** (estados: feliz, animando, dormida, celebrando).
- **PetAiService (dominio):**
  1. Consulta eventos del día/semana en el repositorio.
  2. Construye un **resumen anonimizado** (ej: "hoy: 3 eventos, 1 examen por la mañana, tarde libre") — no envía títulos ni descripciones completas si el usuario activa "modo privado".
  3. Llama a `LlmClient.generateMessage(summary, personality)`.
  4. Guarda el mensaje en `pet_messages` y actualiza el `PetMood`.
- **LlmClient (interfaz):** `Future<String> generateMessage(AgendaSummary s, PetPersonality p)`. Implementación inicial: **GeminiClient** con `gemini-2.5-flash-lite` vía REST (capa gratuita, mensajes cortos = costo ~0). Cambiar de proveedor = una clase nueva.
- **Prompt (system):** define personalidad de la mascota, tono de ánimo, longitud máx. ~2 frases, idioma español, prohibido dar consejos médicos.
- **Fallback offline:** banco local de ~30 mensajes por estado de agenda (día cargado, día libre, semana de exámenes...). Si Gemini falla o no hay red, se usa uno aleatorio.
- **Disparadores del mensaje:**
  - Al abrir la app (máx. 1 generación por día para cuidar cuota).
  - Programado: notificación diaria matutina con el mensaje de la mascota (generado y cacheado la noche anterior o al abrir).
  - Opcional: mensaje extra al completar/terminar un evento importante.
- **API key:** guardada en `flutter_secure_storage`, introducida por el usuario en Settings (evita publicar la key en el APK).

### 3.5 Estado y navegación

- **Riverpod** para estado (providers por módulo: `calendarProvider`, `petProvider`, `settingsProvider`).
- **go_router** para navegación declarativa.

## 4. Estructura de carpetas

```
lib/
├── main.dart
├── core/            # tema, constantes, utils, errores
├── data/
│   ├── db/          # drift: tablas, DAOs, migraciones
│   ├── repositories/
│   └── services/    # notification_service, gemini_client, llm_client.dart (interfaz)
├── domain/
│   ├── entities/    # event, reminder, pet_message, agenda_summary
│   └── usecases/
└── presentation/
    ├── calendar/    # pantalla principal, vistas mes/semana/día
    ├── event_form/
    ├── pet/         # widget mascota, historial, animaciones
    └── settings/
```

## 5. Dependencias clave (pubspec)

| Paquete | Uso |
|---|---|
| `table_calendar` | Vista de calendario personalizable |
| `drift` + `drift_flutter` | SQLite tipado y reactivo |
| `flutter_local_notifications` | Alarmas y recordatorios |
| `timezone` | Programación con zona horaria correcta |
| `flutter_riverpod` | Estado |
| `go_router` | Navegación |
| `dio` (REST directo a la API de Gemini) | Cliente Gemini. Nota: el SDK `google_generative_ai` está deprecado; el reemplazo oficial (`firebase_ai`) requiere Firebase, que descartamos por privacidad. REST directo es simple: 1 endpoint `generateContent`. |
| `flutter_secure_storage` | API key |
| `rive` o `lottie` | Animaciones de la mascota |

## 6. Flujos principales

**Crear evento con alarma:**
UI → `CreateEventUseCase` → guarda en drift → `NotificationService.schedule()` → guarda `notification_id` → stream de drift refresca el calendario.

**Mensaje diario de la mascota:**
Apertura de app (o tarea programada) → ¿ya hay mensaje hoy? → si no: `AgendaSummarizer` → `GeminiClient` (timeout 10 s) → éxito: guardar y mostrar con animación / error: mensaje de fallback.

**Recordatorio:**
Alarma dispara notificación (app cerrada incluida) → tap abre la app en el detalle del evento (payload con `event_id`).

## 7. Fases de desarrollo

1. **MVP calendario:** vistas mes/día, CRUD de eventos, drift, tema personalizado.
2. **Alarmas:** notificaciones exactas, permisos, reprogramación tras reinicio, límite iOS.
3. **Mascota estática + Gemini:** cliente LLM, resumen de agenda, mensajes de fallback, settings de API key.
4. **Mascota animada + pulido:** Rive/Lottie, estados de ánimo, notificación matutina, recurrencia de eventos.
5. **Extras:** widget de pantalla de inicio, exportar/backup local cifrado, estadísticas de la semana.

## 8. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Fabricantes Android matan procesos (Xiaomi, Huawei...) | Alarmas exactas + guía in-app para desactivar optimización de batería |
| Límite de 64 notificaciones en iOS | Programar solo próximas ~50 y reponer al abrir |
| Cuota/costo de Gemini | 1 generación/día, caché en DB, fallback local |
| Privacidad de datos enviados al LLM | Resumen anonimizado + "modo privado" configurable |
| Cambio de proveedor LLM | Interfaz `LlmClient` desacoplada |
