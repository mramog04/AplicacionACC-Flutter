# (b) Casos en los que hubo que añadir o corregir `Semantics`

## 1. Selector de unidades (`SelectorUnidades`)

**Archivo:** `lib/widgets/controles.dart`, líneas 164–254.

**Problema.** Es un componente compuesto (− · número · +).
- En la versión anterior, los botones se llamaban «Quitar una unidad» y «Añadir una unidad» solo mediante `tooltip`.
- El número era un `Text` con `label: 'Unidades'` y el valor dentro del texto.
- Además, Flutter ordenaba por geometría y leía el número **antes** que «−».

**Qué se hizo.**
- Los botones −/+ tienen nombre propio en la **etiqueta** del icono: «Disminuir unidades» y «Aumentar unidades» (`_BotonIcono`, línea 261). El tooltip sigue siendo visible al mantener pulsado, pero se excluye de la semántica (`excludeFromSemantics: true`, línea 278) para que el nombre no se lea dos veces.
- El número es un nodo con `label: 'Unidades'` y `value: '3'` (línea 216). Además tiene `onIncrease`/`onDecrease` con `increasedValue`/`decreasedValue`, así que en TalkBack también se ajusta deslizando arriba/abajo, como un control deslizante. En el mínimo (1) no se ofrece la acción de bajar.
- Las claves `OrdinalSortKey` (línea 195) fuerzan el orden visual: «−», «Unidades 1», «+».
- «−» deshabilitado en 1: además del estado semántico, se muestra el texto «Mínimo: 1 unidad.» para no depender solo del gris.
- Al cambiar el valor, el lector anuncia «3 unidades. Subtotal: 12,30 €» mediante `RegionViva` (`lib/screens/detalle_producto_screen.dart`) **sin mover el foco** del botón.

**Tests:** `semantica_test.dart` («El valor Unidades se ajusta…», «Orden de lectura: detalle de producto») y el Recorrido 2 de `recorridos_test.dart`.

## 2. Título de pantalla que no se anunciaba al navegar

**Archivo:** `lib/widgets/pantalla_base.dart`, línea 31.

**Problema.** El título tenía `header: true`, pero la app no usa `AppBar`, que es quien normalmente marca el título con `namesRoute`. Sin eso, al cambiar de pantalla TalkBack no anunciaba en qué pantalla se estaba.

**Qué se hizo.** Se añadió `namesRoute: true` al `Semantics` del título (h1).

**Test:** «Cada pantalla tiene un único título h1 que nombra la ruta» (`semantica_test.dart`).

## 3. Fila de producto con «6 × 0,95 €»

**Archivo:** `lib/screens/lista_screen.dart`, línea 114 (`etiquetaSemantica`), y `BotonFila` en `lib/widgets/controles.dart`, línea 142.

**Problema.** El texto visible «6 × 0,95 €» lo leería un lector como «6 por 0,95 euros» o «6 multiplicado por…», y el subtotal quedaba suelto.

**Qué se hizo.** `BotonFila` admite una etiqueta semántica opcional que sustituye a los textos, conservando el rol de botón. Ahora se lee: «Leche entera, 6 unidades a 0,95 € cada una, subtotal 5,70 €».

## 4. Mensajes que tienen que oírse sin mover el foco: `RegionViva`

**Archivo:** `lib/widgets/avisos.dart`, líneas 14–72.

**Problema.** `SemanticsService.announce` está obsoleto y Android 16 ha retirado los anuncios. Para que un mensaje se oiga en todas partes hay que hacer lo mismo que Flutter hace internamente (`InputDecorator`, `Form`, `CalendarDatePicker`):
- si `MediaQuery.supportsAnnounce`, usar `SemanticsService.sendAnnouncement`;
- si no, marcar el texto visible como `liveRegion`, con el mensaje en la **etiqueta** (Android solo anuncia la región viva cuando cambia la etiqueta).

**Dónde se usa:**
- el número de resultados de Buscar;
- el subtotal del detalle;
- la instrucción del modo compra;
- la confirmación de «¡Compra completada!».

**Tests:** las dos variantes. En `recorridos_test.dart` se comprueba con anuncios (`takeAnnouncements()`); en el grupo «Sin anuncios de plataforma» de `semantica_test.dart`, con regiones vivas y sin anuncios duplicados.

## 5. Pantalla de carga (corrección de comportamiento, no de etiqueta)

**Archivo:** `lib/screens/carga_screen.dart`, línea 48.

**Problema.** Toda la pantalla es un único botón «Continuar a Mis listas». El contenido estaba en un `IgnorePointer`, que impedía desplazarlo cuando con texto muy grande no cabía.

**Qué se hizo.** El contenido se puede desplazar y tocarlo continúa igual. Para ello se usa un `GestureDetector` con `excludeFromSemantics: true`, así el botón no aparece dos veces para el lector.
