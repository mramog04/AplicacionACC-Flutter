# (d) Mensaje de error y cómo se anuncia

## Caso: crear una lista sin nombre (recorrido 1)

**Archivo:** `lib/screens/nueva_lista_screen.dart`, líneas 32–45.

```dart
void _crear() {
  final nombre = _nombre.text.trim();
  if (nombre.isEmpty) {
    setState(() => _error = errorNombreVacio);   // 'Escribe un nombre para la lista.'
    anunciar(context, 'Error: $errorNombreVacio');
    return;
  }
  ...
}
```

### Visualmente (sin depender solo del color)

- Aparece el texto «Escribe un nombre para la lista.» debajo del campo, en rojo #B00020. Se usa `errorText` de `InputDecoration`.
- El borde del campo pasa a rojo.
- Al final del campo aparece un **icono de error** (`Icons.error_outline`) que marca el error con la forma, además del color (`lib/widgets/controles.dart`, línea 78).

### Para el lector de pantalla

Depende de lo que admita la plataforma (`MediaQuery.supportsAnnounce`):

| Plataforma | Mecanismo | Lo que se oye |
|---|---|---|
| Admite anuncios (Android anterior a 16, iOS, web) | `anunciar()` llama a `SemanticsService.sendAnnouncement` | «Error: Escribe un nombre para la lista.» |
| No los admite (Android 16 y posteriores) | El propio `errorText` de Flutter es una región viva (`liveRegion`) en ese caso | «Escribe un nombre para la lista.» |

Nunca se usan los dos mecanismos a la vez, así que el mensaje no se lee dos veces (se comprueba en un test).

### El foco no se mueve

Tras pulsar «Crear lista», el foco de entrada sigue donde estaba (el campo de texto, que tiene `autofocus`). No se salta al campo ni a otro sitio de forma inesperada. El usuario oye el error y puede escribir directamente. Al escribir, el error desaparece.

### Tests

| Comprobación | Test |
|---|---|
| El error aparece y se anuncia («Error: …») | `recorridos_test.dart` → Recorrido 1 (×1, ×2, ×3) |
| Sin anuncios de plataforma: es región viva y no hay anuncio duplicado | `semantica_test.dart` → «Sin anuncios de plataforma: regiones vivas» → «error de nombre vacío» |
| El foco no se mueve | `semantica_test.dart` → «El error no mueve el foco» |
| Contraste, tamaño y etiquetas con el error visible | `guias_test.dart` → «Nueva lista con error» |

## Otros avisos

- **Éxito** («Lista "Fiesta" creada.», «Añadido a la lista: …», «Lista … borrada.») y **aviso** («"Leche entera" ya está en la lista…») se muestran con un SnackBar que lleva icono (✓ o ⓘ) y texto. El lector los oye con el prefijo «Hecho:» o «Aviso:». El SnackBar de Flutter es una región viva y no roba el foco (`mostrarAviso`, en `lib/widgets/avisos.dart`).
- Con el texto a partir del 150 %, el SnackBar es fijo en vez de flotante. El test al 300 % detectó que el flotante quedaba fuera de la pantalla.
