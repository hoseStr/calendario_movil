# VERIFY_RESPONSIVE.md — Checklist de verificación (Fase 4)

Cómo comprobar que la app quedó responsive tras las Fases 0–3.

## 1. Automático — tests de overflow

Corre en local (el sandbox no tiene Flutter):

```bash
flutter analyze
flutter test test/widget/responsive_test.dart
```

`responsive_test.dart` monta la app en una matriz de **3 tamaños × 3 escalas de
fuente** (incluida 1.5, por encima del clamp) y falla si aparece cualquier
`RenderFlex overflowed` en Calendario, Mascota o Ajustes. Verde = sin desbordes.

> Si `flutter analyze` marca `textScaleFactorTestValue` como deprecado, es solo
> un aviso; el test sigue funcionando. Alternativa moderna:
> `tester.platformDispatcher.textScaleFactorTestValue` ya es la vía usada.

## 2. Manual — emulador / DevTools

Con la app corriendo, en un emulador o dispositivo:

- [ ] **Tamaños**: probar en ~320 dp (equipo chico), ~390 dp y ~430 dp de ancho.
- [ ] **Fuente del sistema**: Ajustes de Android → Pantalla → Tamaño de fuente al
      máximo. El texto **no** debe recortarse ni desbordar en ninguna pantalla.
- [ ] Activar en DevTools **"Highlight oversized images"** y revisar la consola:
      no debe haber mensajes `A RenderFlex overflowed by … pixels`.
- [ ] (Opcional) Correr con `flutter run --dart-define … ` y probar
      `debugPaintSizeEnabled = true` para ver los límites de cada caja.

## 3. Manual — tus dos teléfonos reales

Repetir en los dos equipos que mostraban la inconsistencia:

- [ ] **Calendario**: mes visible completo; botón "Mes/2 semanas/Semana" legible;
      tarjetas de evento con título largo se cortan con "…" y no desbordan; el
      último evento no queda tapado por el FAB.
- [ ] **Mascota**: la mascota se ve proporcionada (ni diminuta ni gigante); el
      chip de estado y el mensaje no se recortan.
- [ ] **Nuevo/Editar evento**: los puntos de color se ven bien y no aprietan la
      fila; las filas Inicio/Fin muestran la fecha completa sin desbordar; el
      formulario hace scroll con teclado abierto.
- [ ] **Ajustes**: el selector Sistema/Claro/Oscuro no desborda; las guías por
      marca se expanden sin cortar texto.
- [ ] **Búsqueda**: chips de filtro con scroll horizontal; resultados con título
      largo cortados con "…".
- [ ] **Alarma** (dispara un recordatorio de prueba): con fuente grande, la
      pantalla hace scroll si hace falta y **nunca** desborda; los botones
      Descartar / Aplazar / Ver detalle siempre alcanzables.
- [ ] **Barra inferior y FAB**: no quedan tapados por la barra de gestos ni por
      los botones de navegación del sistema.
- [ ] **Notch / cámara**: el contenido superior no queda debajo del notch
      (lo cubre `SafeArea`).
- [ ] **Claro y oscuro**: repetir un vistazo rápido en ambos temas.

## 4. Criterio de aprobado

- `flutter test` en verde, incluida la matriz de `responsive_test.dart`.
- Cero `RenderFlex overflowed` en consola en los recorridos manuales.
- Apariencia **coherente** entre los dos teléfonos: mismos elementos, mismas
  proporciones, sin recortes de texto.
