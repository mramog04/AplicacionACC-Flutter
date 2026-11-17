# Lista de la compra accesible (Grupo Q)

App en Flutter con los 3 recorridos críticos accesibles con lector de pantalla (TalkBack), texto muy aumentado y targets de 48 × 48:

1. **Crear lista:** Mis listas → Añadir lista → Crear lista → ver la lista.
2. **Añadir producto:** Lista → + Añadir producto → buscar → detalle (unidades con −/+) → Añadir a la lista. Si el producto ya está en la lista, se avisa y se abre su ficha para cambiar las unidades.
3. **Hacer la compra:** Lista → Terminar lista → marcar las casillas → «¡Compra completada!».

Los datos se guardan **en memoria**: no hay backend ni base de datos, y al cerrar la app se vuelve a las listas de ejemplo.

## Ejecutar

```bash
flutter pub get
flutter run                 # móvil o emulador Android conectado
flutter run -d chrome       # navegador
```

Para comprobar el texto aumentado en Android: *Ajustes → Accesibilidad → Tamaño de fuente* (y *Tamaño de visualización*). La app no limita el escalado del sistema.

## Tests

```bash
flutter test                         # todo (62 pruebas)
flutter test test/recorridos_test.dart
flutter analyze
```

| Archivo | Qué prueba |
|---|---|
| `test/recorridos_test.dart` | Los 3 recorridos con `find.bySemanticsLabel`, al 100 %, 200 % y 300 % |
| `test/guias_test.dart` | Guías de tap target, etiquetas y contraste, más una separación de al menos 8 px |
| `test/escalado_test.dart` | Cada pantalla clave a 2,0 y 3,0 sin overflow y con todo el contenido alcanzable |
| `test/semantica_test.dart` | Regiones vivas o anuncios, foco, títulos, selector de unidades y orden de lectura |
| `test/widget_test.dart` | Navegación por las 7 pantallas |

Las evidencias de accesibilidad (semántica, orden de lectura, mensajes de error y salida de los tests) están en [`docs/evidencias/`](docs/evidencias/README.md).

## Código

```
lib/
├── main.dart, router.dart, theme.dart   App, rutas (go_router) y tema (colores fijos)
├── data/
│   ├── datos_ejemplo.dart     Modelos y catálogo de productos
│   └── almacen.dart           Estado en memoria (ChangeNotifier): listas, unidades, marcas
├── widgets/
│   ├── pantalla_base.dart     Esqueleto de pantalla: barras, título h1 (namesRoute), «Atrás»
│   ├── controles.dart         CampoTexto, BotonFila, SelectorUnidades, AnilloFoco
│   └── avisos.dart            anunciar(), RegionViva, mostrarAviso() (SnackBar)
└── screens/                   Una pantalla por archivo (carga, mis listas, nueva lista,
                               lista, buscar, detalle, ajustes)
```

Decisiones de accesibilidad principales:

- **No se toca `textScaler`.** Con el texto a partir del 200 %, la barra superior se desplaza con el contenido y la inferior tiene una altura máxima con scroll.
- **Los mensajes se anuncian sin mover el foco.** Se usa `sendAnnouncement` si la plataforma lo admite y, si no, `liveRegion`, igual que hace Flutter internamente.
- **Los estados no dependen solo del color:** tic más texto tachado, icono de error, texto que explica por qué un botón está deshabilitado e iconos ✓/ⓘ en los avisos.
- **«Borrar lista» pide confirmación** con un diálogo.
