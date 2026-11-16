# lista_compra

App accesible de lista de la compra en Flutter. De momento contiene solo el
**tema** y la **navegación base** entre las 7 pantallas: no hay lógica real
ni se guarda nada (los datos de ejemplo están fijos en el código).

## Cómo ejecutar

```bash
flutter pub get
flutter run -d chrome     # o cualquier otro dispositivo
flutter analyze
flutter test              # recorre las 7 pantallas al 100 % y al 200 % de texto
```

## Organización del código

```
lib/
├── main.dart                  Punto de entrada: MaterialApp.router con tema, rutas y locale «es»
├── theme.dart                 Colores, medidas y ThemeData (Material 3)
├── router.dart                Rutas con go_router (clase Rutas + appRouter)
├── data/
│   └── datos_ejemplo.dart     Modelos (Producto, LineaLista, ListaCompra) y datos fijos
├── widgets/
│   ├── pantalla_base.dart     Esqueleto común de pantalla, título h1/h2, botón «Atrás»
│   └── controles.dart         CampoTexto, BotonFila, AnilloFoco, ListaSeparada
└── screens/                   Una pantalla por fichero
    ├── carga_screen.dart              1. Carga                /
    ├── mis_listas_screen.dart         2. Mis listas           /listas
    ├── nueva_lista_screen.dart        3. Nueva lista          /listas/nueva
    ├── lista_screen.dart              4. Lista                /listas/:id
    ├── buscar_producto_screen.dart    5. Buscar producto      /listas/:id/buscar
    ├── detalle_producto_screen.dart   6. Detalle de producto  /listas/:id/producto/:pid
    └── ajustes_screen.dart            7. Ajustes              /ajustes
test/
└── widget_test.dart           Pruebas de navegación, texto al 200 %, h1 único y tamaño 48×48
```

### Tema (`lib/theme.dart`)

- `AppColors`: la paleta (texto `#111111`/`#444444`, fondo `#FFFFFF`, barras
  `#F2F2F2`, bordes `#222222`/`#343434`, acento y éxito `#0B4F9C`, error
  `#B00020`, deshabilitado `#595959`).
- `AppSizes`: texto base 16 px, título 1,25× (20 px, negrita), secundario 0,9×
  (14,4 px), controles de 48 px como mínimo, separación de 8 px, esquinas de 8 px,
  bordes de 2 px y foco de 3 px.
- `buildAppTheme()`: los botones *Filled/Elevated* son el **primario** (fondo de
  acento y texto blanco). Los *Outlined/Text/Icon* son el **secundario** (fondo
  blanco y borde oscuro). Los campos de texto tienen borde de 2 px y pasan a
  3 px en color de acento al recibir el foco.
- `BordeConFoco`: forma de los botones que, cuando tienen el foco, dibuja un
  contorno exterior de 3 px en el color de acento, separado 2 px. Así se ve
  incluso sobre el botón primario, que ya es de ese color. Para los controles
  que no son botones (opciones de Ajustes, pantalla de carga) se usa el widget
  `AnilloFoco`.
- Tipografía Arial con alternativas Helvetica/Arimo/Liberation Sans. En la web
  (CanvasKit) solo se usan las fuentes del sistema si están disponibles; si no,
  Flutter usa su fuente por defecto.
- **Escala de texto**: no se toca `MediaQuery.textScaler`, así que se respeta el
  tamaño del sistema sin límite. Ningún control tiene altura fija, solo altura
  mínima, y el contenido de cada pantalla se puede desplazar.

### Navegación (`lib/router.dart`)

- Las rutas están **anidadas** (`/listas` → `:id` → `buscar` / `producto/:pid`).
  Con `context.go(...)` la pila contiene las pantallas padre, así que «Atrás»
  y el botón Atrás del navegador vuelven a ellas.
- `nueva` se declara antes que `:id` para que no se tome como un identificador.
- Las pantallas no escriben URL a mano: usan `Rutas.lista(id)`,
  `Rutas.producto(id, pid)`, etc.
- `volver(context, alternativa)` (en `pantalla_base.dart`) hace `pop` si hay
  pantalla anterior y, si no (p. ej. si se ha entrado escribiendo la URL), va a
  la ruta alternativa.
- Buscar → Detalle usa `context.push` para que «Atrás» en el detalle vuelva a la
  búsqueda. Detalle → «Añadir a la lista» hace `go` a la lista.
- «Crear lista» navega a `/listas/3?nombre=…`: como no se guarda nada, la lista
  nueva solo existe en la URL. Por eso su nombre se pierde al salir de ella y
  aparece como «Nueva lista».

| Desde        | Hacia                                          |
|--------------|------------------------------------------------|
| Carga        | Mis listas (al tocar la pantalla)              |
| Mis listas   | Nueva lista, Lista, Ajustes                    |
| Nueva lista  | Lista (al crear) o atrás (Cancelar)            |
| Lista        | Buscar (+ Añadir producto), Detalle (producto) |
| Buscar       | Detalle                                        |
| Detalle      | Lista (al añadir) o atrás                      |

### Pantallas y accesibilidad

Todas (salvo Carga) se montan con `PantallaBase`. Tienen una barra superior gris
con los botones de navegación y, debajo y en su propia línea, el **único h1**
(`TituloPantalla`: `Semantics(header: true, headingLevel: 1)`). Debajo va el
cuerpo desplazable y, si la hay, una barra inferior con las acciones
principales. El título va en una línea aparte para que, con el texto al 200 %,
no compita por el ancho con los botones.

- Todos los controles miden al menos 48×48 y van separados 8 px (`ListaSeparada`,
  `SizedBox`).
- Los botones con icono llevan texto («Atrás», «Ajustes», «Añadir lista»). Los
  que solo tienen icono (– / + de unidades) llevan `tooltip`, que les da la
  etiqueta semántica.
- `CampoTexto` muestra la etiqueta encima del campo, siempre visible, y la asigna
  al campo para el lector de pantalla.
- El contador de resultados de búsqueda y el de unidades son `liveRegion`, así
  que se anuncian al cambiar.
- En Carga, si el sistema pide reducir animaciones, el círculo se queda quieto.
- Ajustes (idioma y tamaño de texto) es solo una maqueta: la selección no se
  aplica todavía.
# AplicacionACC-Flutter
