# (e) Control por mirada (experimental, PASO 5)

Es un modo **solo para Flutter web**, que viene **desactivado por defecto**. Se activa en *Ajustes → Control por mirada (experimental)* y permite activar un botón mirándolo durante 1,5 s. Con el modo apagado, la app se comporta igual que antes: `GazeTarget` devuelve el control tal cual y todos los tests anteriores siguen pasando.

## Qué funciona y qué está comprobado

| Parte | Estado |
|---|---|
| **Fuente de ratón con temblor simulado** | Funciona. Probada con pruebas automáticas y **en Chrome**, con eventos de puntero reales sobre la compilación web: bloqueo con borde y barra de progreso, activación, rearme tras navegar y el recorrido 3 completo (marcar las 3 casillas y ver «¡Compra completada!»). |
| **Cámara (WebGazer)** | Probada por el grupo en un PC con cámara: funciona, pero costaba elegir entre botones próximos (de ahí los cambios de separación y de decisión entre vecinos, que con cámara **están pendientes de volver a probar**). La precisión no está medida. Con un vídeo simulado en Chrome está comprobado que el modelo facial carga, que la cámara se apaga al desactivar el modo y que se puede volver a encender. |
| Calibración de 9 puntos × 5 clics | Con vídeo simulado: se registran los 45 clics en los 9 puntos. |
| Estado «Esperando el permiso de la cámara…» | Cubierto por pruebas unitarias con una cámara simulada (`test/gaze_settings_test.dart`). En el navegador automatizado el permiso se denegaba solo, así que no se pudo ver el aviso de permiso. |

## Parámetros (`lib/gaze/gaze_config.dart`)

| Parámetro | Valor | Qué hace |
|---|---|---|
| `muestrasSuavizado` | 12 | Media móvil de las últimas N muestras |
| `radioEntrada` | 100 px | Distancia máxima al rectángulo de un control para bloquearlo (el más cercano) |
| `radioSalida` | 200 px | Una vez bloqueado, solo se suelta si la mirada se aleja más de esto… |
| `tiempoGracia` | 400 ms | …durante más de este tiempo (histéresis). Mientras dura, el dwell se congela |
| `dwell` | 1500 ms | Tiempo con el control bloqueado para activarlo. El progreso se reinicia al soltar o cambiar de control |
| `repetirSinSoltar` | `false` | Tras activar, no se repite hasta soltar el control |
| `ruidoRatonPorDefecto` | 30 px | Temblor simulado de la fuente de ratón (ajustable de 0 a 150 en Ajustes) |
| `ladoMinimoMirada` / `separacionMirada` | 88 / 72 px | Con el modo activo, tamaño mínimo de cada control y hueco entre vecinos (filas, casillas, −/+, barra inferior y diálogo) |
| `margenDecision` | 24 px | Un control gana a otro si está más cerca por este margen; si ninguno gana, no se bloquea ninguno |
| `radioCambio` / `tiempoCambio` | 30 px / 400 ms | Mirando así a un vecino, pasa a ser el bloqueado |
| `anchoCarrilMirada` / `fraccionDesplazamiento` | 96 px / 0,7 | Botones «Subir» y «Bajar», y cuánto desplazan |

### Añadidos a la especificación (detectados al probar)

1. **Mirada estable antes de bloquear un control nuevo** (`bloquearSoloConMiradaEstable`).
   - **Problema:** al saltar con la vista de un control a otro, la media móvil «barre» los controles intermedios. Bloquea uno de ellos y, por la histéresis, ya no lo suelta. El test de widget del recorrido 2 abría «Pasta espagueti» al mirar «Aceite».
   - **Solución:** una muestra suelta a más de `radioSalida` de la media se descarta como valor atípico. Tres seguidas cuentan como salto y el suavizado se reinicia con ellas. Además, solo se bloquea con el buffer lleno y sus dos mitades coherentes.
2. **Rearme tras activar.**
   - **Problema:** en Chrome, al activar «Atrás» con la vista quieta, en la pantalla nueva se activaba solo el control que quedaba bajo la vista («Compra semanal»), y luego otra vez «Atrás».
   - **Solución:** tras una activación no se bloquea nada nuevo hasta que la mirada se aleja más de `radioEntrada` del punto de activación.
3. **Soltar enseguida un control que deja de verse.** Si un diálogo lo tapa o se cambia de pantalla, el control se suelta sin esperar la gracia.

4. **Paso directo a un control vecino** (cambia la regla inicial).
   - **Problema:** un control a menos de `radioSalida` del bloqueado no se alcanzaba sin apartar antes la vista, y mientras tanto podía activarse el que no se quería.
   - **Solución:** si un vecino está claramente más cerca, el dwell del bloqueado se congela; si se le mira durante `tiempoCambio`, pasa a ser el bloqueado. Entre dos sin ganador claro no se elige ninguno.
5. **«Subir» y «Bajar».** Con más separación cabe menos contenido y con la vista no se puede arrastrar la pantalla. Solo aparecen con el modo activo y si el contenido no cabe.

Son constantes o código aislado en `gaze_controller.dart` y tienen su prueba en `test/gaze_controller_test.dart`.

## Accesibilidad y seguridad

- **Desactivado por defecto.** El interruptor es un `SwitchListTile` de al menos 48 px y anuncia su estado (activado o desactivado).
- **Feedback visual sin depender solo del color.** El control bloqueado muestra un borde grueso (5 px, #0B4F9C) y una barra de progreso del dwell. **No se dibuja ningún punto de mirada.**
- **Activar por mirada equivale a tocar.** `GazeTarget` llama a la misma función que `onPressed` y anuncia «Activado con la mirada: …» al lector de pantalla.
- **Privacidad.** Antes de encender la cámara aparece un diálogo que explica que el vídeo se procesa en el navegador, que no se graba, no se guarda y no sale del dispositivo. Además:
  - WebGazer se configura con `saveDataAcrossSessions(false)` y sin vista previa ni puntos;
  - al desactivar el modo, la cámara se apaga (`stopVideo()` además de `end()`, que por sí solo la dejaba encendida);
  - solo se aprende de los clics de calibración, no de los movimientos del ratón.

  Que el vídeo no sale del dispositivo es lo que declara WebGazer y cómo está planteado (la estimación se calcula en el navegador); no se ha auditado su tráfico de red.
- **Acciones destructivas.** Con la mirada, «Borrar lista» necesita dos pasos dentro del diálogo:
  1. La primera activación de «Sí, borrar» lo convierte en «Confirmar borrado» y lo anuncia.
  2. Hay que apartar la vista y volver a mirarlo.

  Con el dedo o el teclado basta una pulsación, porque el diálogo ya es la confirmación.
- **Más separación con el modo activo:** controles de al menos 88 px con 72 px entre vecinos. Un control que solo asoma por el borde no se puede bloquear hasta verse bien.

## Limitaciones

- **Solo web.** En Android o escritorio, Ajustes lo indica y el interruptor está deshabilitado.
- **Precisión limitada de la cámara.** Depende de la luz, la postura y la calibración. **No está medida**; por eso los controles son grandes y están separados.
- **«Subir»/«Bajar» no se repiten solos:** para repetir hay que apartar la vista y volver. En pantallas estrechas el carril quita ancho al contenido.
- **No se puede escribir con la mirada.** «Nueva lista» necesita un nombre, así que el recorrido 1 no se completa solo con la mirada.
- **La calibración no se guarda:** se pierde al recargar o cambiar el tamaño de la ventana.
- **Licencia.** WebGazer 3.5.3 es GPL-3.0-or-later.
- **Privacidad.** El modelo facial (unos 10 MB) se descarga de jsDelivr al encender la cámara. WebGazer.js se descarga desde jsDelivr al abrir la app (con SRI), aunque el modo esté apagado. La cámara solo se enciende si el usuario la elige y acepta.

## Cómo probarlo con `MouseGazeSource`

```bash
flutter build web --no-web-resources-cdn    # sin depender de la CDN de Google
cd build/web && python3 -m http.server 8765    # o: flutter run -d chrome
# abrir http://localhost:8765  (localhost cuenta como contexto seguro)
```

1. *Ajustes → Control por mirada (experimental)*: actívalo. La fuente por defecto es «Ratón con temblor simulado».
2. Deja el puntero **quieto** sobre un botón sin hacer clic. Unos 0,4 s después aparece el borde y la barra se llena; a los 1,5 s se activa.
3. Sube «Temblor simulado» (por ejemplo, a 120 px) para ver que el objetivo no salta por el ruido.
4. Para pasar a un control vecino, muévete a él: el primero se congela y a los 0,4 s cambia.
5. Para probar la cámara: elige «Cámara (WebGazer)», acepta el aviso y el permiso del navegador, y después pulsa *Calibrar (9 puntos)*.

> Si recompilas, el navegador puede seguir usando el `main.dart.js` antiguo desde su caché. Me pasó al probar: usa una ventana privada o vacía la caché.

## Pruebas automáticas

| Archivo | Qué prueba |
|---|---|
| `test/gaze_controller_test.dart` | Bloqueo dentro del radio de entrada. El ruido de hasta 150 px no cambia el objetivo. Se suelta solo tras la gracia; un parpadeo no lo suelta. El dwell activa una vez, se reinicia al cambiar de objetivo y se congela en la gracia. Suavizado y valores atípicos, pausa, salto de la vista, rearme tras activar, y paso entre controles vecinos (cambio, congelado, vistazo breve, duda entre dos). |
| `test/gaze_settings_test.dart` | Desactivado por defecto; espera del permiso; permiso concedido tarde tras volver al ratón; fallo con motivo; apagado de la cámara. |
| `test/gaze_widget_test.dart` | Activación desde Ajustes con aviso de privacidad y uso del ratón cuando no hay cámara; «Aumentar unidades» por mirada con su anuncio; recorrido 2 completo por mirada; «Borrar lista» en dos pasos; guías con el modo activo; separación real en 6 pantallas (móvil y escritorio); recorrido 3 con temblor de casilla en casilla; «Subir»/«Bajar». |
