# (a) Widget estándar cuya semántica ya es suficiente

## Casilla de producto en el modo compra: `CheckboxListTile`

**Archivo:** `lib/screens/lista_screen.dart`, línea 246 (`_CasillaProducto`).

```dart
CheckboxListTile(
  value: linea.marcada,
  onChanged: (v) => alCambiar(v ?? false),
  controlAffinity: ListTileControlAffinity.leading,
  title: Text(linea.producto.nombre, ...),
  subtitle: Text('${contarUnidades(linea.unidades)}, ${linea.producto.formato}', ...),
  ...
)
```

Sin añadir ningún `Semantics`, Flutter genera **un único nodo** con:

| Propiedad | Valor | Cómo lo comprueba un test |
|---|---|---|
| Nombre | «Pasta espagueti, 2 unidades, Paquete de 500 g» (título + subtítulo unidos) | `semantica_test.dart` → «Orden de lectura: lista en modo compra» |
| Rol | casilla de verificación (`hasCheckedState`) | `recorridos_test.dart` → Recorrido 3 |
| Estado | marcado / no marcado (`isChecked`) | `recorridos_test.dart` → Recorrido 3, antes y después de cada toque |
| Acción | tocar (alterna el estado) | `guias_test.dart` → `labeledTapTargetGuideline` |
| Tamaño | ≥ 48 × 48 | `guias_test.dart` → `androidTapTargetGuideline` |

La casilla y los textos se fusionan solos (el `ListTile` usa `MergeSemantics`), de modo que TalkBack no lee por separado «casilla» y «Pasta espagueti».

Lo único que se añadió fue la parte **visual** para no depender solo del color: cuando está marcado, aparece el tic, el texto se tacha y el borde pasa a ser más grueso.

## Otros ejemplos

- **Botones de texto** (`FilledButton` / `OutlinedButton`), por ejemplo «Crear lista» (`lib/screens/nueva_lista_screen.dart`, línea 73): el texto visible es el nombre, el rol es botón y el estado deshabilitado sale de `onPressed: null`. Este último caso se comprueba con «Terminar lista» en una lista vacía (`recorridos_test.dart`).
- **`BotonFila`** (`lib/widgets/controles.dart`, línea 153): un `OutlinedButton` cuyo `Row` de textos se une en un solo nodo con rol de botón. El icono «›» es decorativo y, como no tiene `semanticLabel`, no genera nodo («Los iconos decorativos no generan nodos», en `semantica_test.dart`).
