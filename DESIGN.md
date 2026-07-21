# DESIGN.md — Referencia oficial de diseño

Estética **onírica**: brumosa, suave, flotante. Aprobada el 2026-07-21. Toda pantalla nueva debe seguir esto.

## Paleta (lib/core/theme/app_colors.dart)

| Rol | Color | Hex |
|---|---|---|
| Semilla/primario | Lavanda | `#8E7CC3` |
| Acento | Rosa bruma | `#F2A6C8` |
| Fondo claro | Niebla clara | `#F6F3FB` |
| Fondo oscuro | Noche violeta | `#17132A` |

Categorías de eventos (pasteles): lavanda `#A99BE0`, menta `#8FD8CE`, rosa `#F2A6C8`, durazno `#F4B8A0`, azul cielo `#9EC9F0`, lila `#E8C9F0`.

## Degradados (lib/core/theme/app_gradients.dart)

- Claro — "amanecer brumoso": `#EDE7FA → #FBEFF5 → #E7EFFA` (diagonal).
- Oscuro — "noche de sueño": `#1F1838 → #17132A → #141B33` (diagonal).
- Se aplican con `DreamyBackground` en pantallas principales; AppBar transparente encima.

## Tipografía

Quicksand (google_fonts) en toda la app. Títulos w600-w700, cuerpo con height 1.45.

## Formas y superficies

- Esquinas: tarjetas 24, inputs 16, FAB 20, diálogos 28.
- Tarjetas y barra de navegación **semitranslúcidas** sobre el degradado (blanco 75% claro / blanco 8% oscuro).
- Sin elevación/sombras fuertes; la profundidad la da la translucidez.

## Patrones de componentes (del mockup aprobado)

- Calendario: día seleccionado = círculo lavanda relleno; días con eventos = punto pastel de su categoría debajo del número.
- Tarjeta de evento: barrita vertical de color de categoría (4px, redondeada) + título en tono oscuro de la misma gama + hora en gris violáceo.
- Subtítulo bajo el mes: estado del día escrito por la mascota (Fase 6+).
- Barra inferior: 3 pestañas (Calendario · Mascota · Ajustes), pestaña activa en lavanda.

## Reglas

1. Ningún color hardcodeado en pantallas: siempre tema o `AppColors`.
2. Todo debe verse bien en claro **y** oscuro antes de dar por terminada una pantalla.
3. Efectos avanzados (blur real, partículas, animaciones flotantes) llegan en Fase 8 — no antes.
