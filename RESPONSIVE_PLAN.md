# RESPONSIVE_PLAN.md — Hacer Wuola responsive (teléfonos)

Enfoque: **nativo + tokens** (MediaQuery / LayoutBuilder + sistema de espaciado y
tipografía centralizado + clamp del `textScaler`). Sin dependencias nuevas.
Alcance: **solo teléfonos** de distintos tamaños, densidades y ajustes de fuente.

---

## 1. Diagnóstico (por qué cambia según el dispositivo)

La app ya hace bien lo básico: colores y estilos de texto salen del `Theme`
(`app_theme.dart`, `app_typography.dart`), usa `Expanded`/`ListView` en las listas
y respeta `disableAnimations`. Los quiebres reales son:

| # | Problema | Dónde | Efecto entre dispositivos |
|---|---|---|---|
| 1 | **Sin control del `textScaler`** del sistema | toda la app (falta en `main.dart`) | Cada fabricante trae un tamaño de fuente/pantalla por defecto distinto. El texto crece diferente y **desborda** (`Row`, `Chip`, títulos, botón de formato). Causa #1. |
| 2 | **Tamaños fijos en px** | `DreamyPet size: 170` (`pet_screen.dart:68`), `fontSize: 12` (`calendar_screen.dart:77`) | La mascota ocupa proporción distinta en pantallas chicas vs grandes; el `12` no escala con accesibilidad. |
| 3 | **Padding inferior fijo** de 96 | `calendar_screen.dart:158`, `pet_screen.dart:61` | No coincide con la altura real de la barra de navegación de cada equipo (gestos vs botones). Tapa o deja hueco. |
| 4 | **`SafeArea(bottom: false)`** + `extendBody` | pantallas principales | Los insets inferiores varían por equipo; hoy se compensan con un número mágico. |
| 5 | **Números mágicos de espaciado** (16/20/24/28/…) repetidos | ~41 `SizedBox`, ~43 `EdgeInsets` | Sin escala común no se puede ajustar de forma coherente ni densificar en pantallas chicas. |
| 6 | **Sin `LayoutBuilder`/breakpoints** (0 usos) | toda la app | Mismo layout para 320 dp y 430 dp de ancho; en equipos angostos hay riesgo de overflow horizontal. |
| 7 | **Grid de colores fijo 36×36** | `event_form_screen.dart:357` | En pantallas muy chicas + fuente grande puede apretar la fila. |

> Nota: Flutter ya trabaja en dp (density-independent), así que la **densidad**
> por sí sola no es el problema. Los culpables son el **escalado de fuente**, los
> **aspect ratios / insets** distintos y las **medidas absolutas** que no se adaptan.

---

## 2. Objetivo y principios

1. **Consistencia visual** en anchos de ~320 a ~430 dp y con fuente del sistema de 85 % a ~130 %.
2. **Nada de overflow** (ni amarillo-negro ni recorte de texto) en ningún combo tamaño×fuente.
3. **Un único punto de verdad** para espaciado, radios y escalas → ajustes globales en un archivo.
4. **Cero regresiones** de la estética onírica de `DESIGN.md` (radios 24/16/20/28, translucidez, Quicksand).
5. Cambios **incrementales y verificables** pantalla por pantalla.

---

## 3. Fase 0 — Fundamentos (base transversal)

**3.1 Clamp del `textScaler` (arreglo de mayor impacto).**
En `main.dart`, envolver el `MaterialApp.router` con un `builder` que limite el
escalado de fuente a un rango seguro, respetando accesibilidad pero evitando
desbordes:

```dart
builder: (context, child) {
  final mq = MediaQuery.of(context);
  return MediaQuery(
    data: mq.copyWith(
      textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.3),
    ),
    child: child!,
  );
},
```

**3.2 Tokens de diseño.** Nuevo archivo `lib/core/theme/app_dimens.dart` con la
escala de espaciado y radios que hoy están sueltos:

```dart
abstract final class Gap {   // espaciado vertical/horizontal
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 20.0, xxl = 28.0;
}
abstract final class Radii { // radios ya definidos en DESIGN.md
  static const card = 24.0, input = 16.0, fab = 20.0, dialog = 28.0;
}
abstract final class Insets {
  static const screenH = 16.0; // padding horizontal de pantalla
}
```
Y helpers `SizedBox` reutilizables (`Gaps.md`, etc.) para reemplazar los mágicos.

**3.3 Helper responsivo.** Nuevo `lib/core/responsive/responsive.dart`:

```dart
extension ResponsiveX on BuildContext {
  double get w => MediaQuery.sizeOf(this).width;
  double get h => MediaQuery.sizeOf(this).height;
  bool get isCompact => w < 360;          // teléfonos angostos
  /// Interpola un valor entre pantalla chica y grande, con tope.
  double scale(double base, {double min = 0.85, double max = 1.15}) =>
      base * (w / 390).clamp(min, max);   // 390 dp = ancho de referencia
}
```
Se usa para lo que sí debe crecer con la pantalla (p. ej. la mascota), sin tocar
lo que ya está en dp fijo apropiado.

---

## 4. Fase 1 — Tema y espaciado global

- Mover los radios mágicos de `app_theme.dart` a `Radii`.
- Definir el padding horizontal de pantalla en `Insets.screenH` y usarlo en las
  pantallas en vez de `20`/`16` sueltos.
- (Opcional) Añadir un `VisualDensity.adaptivePlatformDensity` explícito para
  densificar controles en pantallas chicas.

---

## 5. Fase 2 — Pantalla por pantalla

Orden por impacto. En cada una: reemplazar mágicos por tokens, blindar `Row`s con
`Flexible/Expanded`, y sustituir tamaños fijos por `context.scale(...)` donde aplique.

1. **Calendar (`calendar_screen.dart`)** — el más visible.
   - `fontSize: 12` del botón de formato → derivar de `textTheme.labelSmall`.
   - Padding inferior fijo `96` → calcular con `MediaQuery.paddingOf` + altura real
     de la nav bar (ver Fase 3).
   - Revisar que el marcador de eventos (3 puntos) no se recorte con fuente grande.
2. **DreamyPet + PetScreen (`dreamy_pet.dart`, `pet_screen.dart`)**
   - `size: 170` → `context.scale(150, max: 1.25)` acotado al ancho disponible
     (`min(170, w * 0.45)`) para que no domine en pantallas chicas.
   - El `_MoodChip` y textos centrados: verificar wrap con fuente 130 %.
3. **EventForm (`event_form_screen.dart`)**
   - Grid de colores 36×36 → `Wrap` con celdas `context.scale(36, max: 1.2)`.
   - Espaciados verticales (16/20/32) → tokens; asegurar scroll sin overflow.
4. **Settings (`settings_screen.dart`)** — muchos `SizedBox` fijos → tokens.
5. **Search (`search_screen.dart`)** y **EventDetail (`event_detail_screen.dart`)**
   — mismas reglas; blindar filas con textos largos (`Expanded` + `ellipsis`).
6. **Alarm (`alarm_screen.dart`)** — pantalla completa; centrar y limitar ancho
   de contenido con `ConstrainedBox(maxWidth: 480)` para que no se estire feo.

---

## 6. Fase 3 — Safe areas e insets de navegación

- Reemplazar el padding inferior mágico (`96`) por el inset real:
  `padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + kBottomNavHeight + Gap.lg)`
  o envolver las listas con `SafeArea(top:false)` cuando corresponda.
- Verificar `extendBody`/`extendBodyBehindAppBar` contra equipos con notch y con
  barra de gestos vs botones.
- Confirmar que el FAB no queda tapado por la nav bar en ningún equipo.

---

## 7. Fase 4 — Verificación

1. **Matriz de tamaños** en el emulador/DevTools (Flutter permite forzar tamaño y
   `textScaleFactor`): probar como mínimo
   - 320×640 (chico), 390×844 (referencia), 430×932 (grande);
   - fuente del sistema al 100 %, 115 % y 130 %.
2. **Buscar overflow**: correr con `debugPaintSizeEnabled` y revisar consola por
   `RenderFlex overflowed`.
3. **Golden tests** (opcional pero recomendado): un golden por pantalla clave a
   dos tamaños × dos escalas de fuente, para evitar regresiones futuras.
4. **`flutter analyze`** limpio y prueba manual en tus 2 teléfonos reales (los que
   mostraban la inconsistencia).

---

## 8. Orden recomendado y esfuerzo

| Fase | Qué | Riesgo | Impacto |
|---|---|---|---|
| 0 | textScaler clamp + tokens + helper | Bajo | **Alto** (arregla la mayoría) |
| 1 | Tema/espaciado global | Bajo | Medio |
| 2 | Pantalla por pantalla | Medio | Alto |
| 3 | Safe areas / insets | Medio | Medio |
| 4 | Verificación | Bajo | — |

**Quick win:** solo la Fase 0.1 (clamp del `textScaler`) probablemente elimina la
mayor parte de la inconsistencia que viste entre las dos marcas. Es el primer
commit sugerido, aislado y fácil de revertir.

---

## 9. Criterio de "terminado"

- Sin `RenderFlex overflowed` en la matriz de Fase 4.
- La mascota, tarjetas y formularios se ven proporcionados en 320–430 dp.
- El texto nunca se recorta con fuente hasta 130 %.
- La barra inferior nunca tapa contenido ni FAB.
- `DESIGN.md` intacto (radios, translucidez, Quicksand).
