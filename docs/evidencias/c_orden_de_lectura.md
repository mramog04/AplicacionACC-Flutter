# (c) Orden de lectura esperado

Estas secuencias las obtiene el test a partir del árbol semántico real, recorrido en orden de navegación (`DebugSemanticsDumpOrder.traversalOrder`). Se comprueban en `test/semantica_test.dart`.

Lo que hace TalkBack en el dispositivo hay que verificarlo en un móvil o emulador. Lo que se documenta aquí es el orden que Flutter le entrega.

`/` separa líneas de un mismo nodo y `|` separa etiqueta y valor.

## Detalle de producto (`/listas/1/producto/p5`), recorrido 2

| # | Se lee | Rol / notas |
|---|---|---|
| 1 | Atrás | botón |
| 2 | Aceite de oliva virgen extra | encabezado h1, nombra la pantalla |
| 3 | Marca / Olivar del Sur | texto (etiqueta + valor fusionados con `MergeSemantics`) |
| 4 | Formato / Botella de 1 litro | texto |
| 5 | Precio / 8,90 € | texto |
| 6 | Descripción / Aceite de oliva virgen extra de primera prensada en frío. | texto |
| 7 | Unidades | encabezado h2 |
| 8 | Disminuir unidades | botón, **deshabilitado** (está en el mínimo) |
| 9 | Unidades \| 1 | valor ajustable (deslizar arriba/abajo) |
| 10 | Aumentar unidades | botón |
| 11 | Mínimo: 1 unidad. | texto que explica por qué «−» está deshabilitado |
| 12 | 1 unidad. Subtotal: 8,90 € | región viva: se anuncia al cambiar las unidades |
| 13 | Añadir a la lista | botón (barra inferior) |

El orden coincide con el visual: barra superior, datos de arriba abajo, selector de izquierda a derecha y, al final, la barra inferior. El orden de «−, valor, +» está forzado con `OrdinalSortKey`, porque sin él Flutter leía el valor primero.

## Lista en modo compra (`/listas/2`, tras «Terminar lista» y marcar «Pasta espagueti»), recorrido 3

| # | Se lee | Rol / notas |
|---|---|---|
| 1 | Atrás | botón |
| 2 | Cena del sábado | encabezado h1 |
| 3 | Modo compra | encabezado h2 |
| 4 | Modo compra. Marca cada producto cuando lo cojas. | región viva, anunciada al entrar en el modo |
| 5 | 1 de 3 marcados | texto (no es región viva: cada casilla ya anuncia su estado) |
| 6 | Pasta espagueti / 2 unidades, Paquete de 500 g | casilla, **marcada** |
| 7 | Queso curado / 1 unidad, Cuña de 250 g | casilla, no marcada |
| 8 | Vino tinto / 1 unidad, Botella de 75 cl | casilla, no marcada |
| 9 | Salir del modo compra | botón (barra inferior) |

Cuando se marcan todas, en la barra inferior aparece «¡Compra completada! Has marcado los 3 productos.» (región viva) y el botón «Volver a Mis listas».

## Elementos excluidos a propósito

- Las flechas «›» de cada fila y los iconos dentro de botones con texto (no tienen `semanticLabel`).
- La etiqueta visible de cada campo de texto, que se excluye y se asigna al propio campo para que se lea una sola vez y asociada a él (`CampoTexto`).
- El texto visual de las regiones vivas, que se excluye porque el mensaje va en la etiqueta del nodo y si no se leería dos veces.
