import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/almacen.dart';
import '../data/datos_ejemplo.dart';
import '../gaze/gaze_config.dart';
import '../gaze/gaze_settings.dart';
import '../gaze/gaze_target.dart';
import '../router.dart';
import '../theme.dart';
import '../widgets/avisos.dart';
import '../widgets/controles.dart';
import '../widgets/pantalla_base.dart';

/// 4. Lista: título, total y productos.
///
/// - Modo normal: «Atrás» y «Borrar lista» arriba; «+ Añadir producto» y
///   «Terminar lista» abajo.
/// - Modo compra (tras «Terminar lista»): cada producto es una casilla que se
///   marca al cogerlo. Cuando están todos, aparece la confirmación abajo.
class ListaScreen extends StatefulWidget {
  const ListaScreen({super.key, required this.id});

  final String id;

  @override
  State<ListaScreen> createState() => _ListaScreenState();
}

class _ListaScreenState extends State<ListaScreen> {
  bool _modoCompra = false;

  /// Copia de la lista mientras se borra, para que la pantalla no muestre
  /// «Lista no encontrada» durante la animación de salida.
  ListaCompra? _borrada;

  Future<void> _borrar(ListaCompra lista) async {
    final confirmado = await confirmarBorrado(context, lista);
    if (confirmado != true || !mounted) return;
    setState(() => _borrada = lista);
    almacen.borrarLista(lista.id);
    mostrarAviso(context, 'Lista «${lista.nombre}» borrada.');
    context.go(Rutas.misListas);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // También el modo mirada: cambia la separación de los botones.
      listenable: Listenable.merge([almacen, mirada]),
      builder: (context, _) {
        final lista = almacen.lista(widget.id) ?? _borrada;
        if (lista == null) {
          return const PantallaBase(
            titulo: 'Lista no encontrada',
            botonIzquierdo: BotonAtras(alternativa: Rutas.misListas),
            contenido: [Text('Esta lista no existe o se ha borrado.')],
          );
        }
        return _modoCompra ? _compra(lista) : _normal(lista);
      },
    );
  }

  /// Botón que cambia entre modos. Lleva la misma clave en los dos para que
  /// sea el mismo elemento: así, si tenía el foco, lo conserva.
  Widget _botonModo(String texto, VoidCallback? alPulsar) => GazeTarget(
    key: const ValueKey('boton-modo'),
    etiqueta: texto,
    alActivar: alPulsar,
    child: OutlinedButton(onPressed: alPulsar, child: Text(texto)),
  );

  Widget _normal(ListaCompra lista) {
    final textos = Theme.of(context).textTheme;
    final vacia = lista.lineas.isEmpty;
    final anadir = GazeTarget(
      key: const ValueKey('boton-anadir'),
      etiqueta: '+ Añadir producto',
      alActivar: () => context.push(Rutas.buscar(lista.id)),
      child: FilledButton(
        onPressed: () => context.push(Rutas.buscar(lista.id)),
        child: const Text('+ Añadir producto'),
      ),
    );
    final terminar = _botonModo(
      'Terminar lista',
      vacia ? null : () => setState(() => _modoCompra = true),
    );
    return PantallaBase(
      titulo: lista.nombre,
      botonIzquierdo: const BotonAtras(alternativa: Rutas.misListas),
      botonDerecho: GazeTarget(
        etiqueta: 'Borrar lista',
        alActivar: () => _borrar(lista),
        child: OutlinedButton.icon(
          onPressed: () => _borrar(lista),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            iconColor: AppColors.error,
          ),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Borrar lista'),
        ),
      ),
      contenido: [
        // Total: se lee como una sola frase. Wrap: con el texto muy grande
        // el importe baja a la línea siguiente en vez de desbordar.
        MergeSemantics(
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSizes.separacion,
            children: [
              Text('Total', style: textos.titleMedium),
              Text(formatearPrecio(lista.total), style: textos.titleLarge),
            ],
          ),
        ),
        Text(contarProductos(lista.lineas.length), style: textos.bodySmall),
        if (vacia)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.margen),
            child: Text(
              'La lista está vacía. Usa «+ Añadir producto» para empezar.',
            ),
          ),
        for (final linea in lista.lineas)
          BotonFila(
            titulo: linea.producto.nombre,
            subtitulo:
                '${linea.unidades} × ${formatearPrecio(linea.producto.precio)}',
            extra: formatearPrecio(linea.subtotal),
            // «6 × 0,95 €» se leería «6 por 0,95 euros» o «6 multiplicado
            // por…»: se da una frase completa.
            etiquetaSemantica:
                '${linea.producto.nombre}, ${contarUnidades(linea.unidades)} '
                'a ${formatearPrecio(linea.producto.precio)} cada una, '
                'subtotal ${formatearPrecio(linea.subtotal)}',
            alPulsar: () =>
                context.push(Rutas.producto(lista.id, linea.producto.id)),
          ),
      ],
      barraInferior: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En modo mirada y con ancho, uno al lado del otro: la separación
          // no le quita alto a la lista.
          if (mirada.activo && MediaQuery.sizeOf(context).width >= 600)
            Row(
              children: [
                Expanded(child: anadir),
                SizedBox(width: mirada.separacionBotones),
                Expanded(child: terminar),
              ],
            )
          else ...[
            anadir,
            SizedBox(height: mirada.separacionBotones),
            terminar,
          ],
          if (vacia) ...[
            const SizedBox(height: 4),
            // El estado deshabilitado se explica con texto, no solo con el
            // color gris del botón.
            Text(
              'Añade productos para poder terminar la lista.',
              style: textos.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _compra(ListaCompra lista) {
    final textos = Theme.of(context).textTheme;
    final total = lista.lineas.length;
    return PantallaBase(
      titulo: lista.nombre,
      botonIzquierdo: const BotonAtras(alternativa: Rutas.misListas),
      contenido: [
        const Subtitulo('Modo compra'),
        // Se anuncia al entrar en el modo: el cambio lo ha pedido el
        // usuario, pero así sabe qué ha cambiado sin tener que explorar.
        // El contador va aparte y no es región viva: cada casilla ya
        // anuncia su estado al marcarla y repetirlo sería ruido.
        const RegionViva(
          mensaje: 'Modo compra. Marca cada producto cuando lo cojas.',
          child: Text('Marca cada producto cuando lo cojas.'),
        ),
        Text('${lista.marcadas} de $total marcados', style: textos.bodySmall),
        for (final linea in lista.lineas)
          _CasillaProducto(
            linea: linea,
            alCambiar: (v) => almacen.marcar(lista.id, linea.producto.id, v),
          ),
      ],
      barraInferior: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (lista.completa) ...[
            _Confirmacion(total: total),
            SizedBox(height: mirada.separacionBotones),
            GazeTarget(
              etiqueta: 'Volver a Mis listas',
              alActivar: () => context.go(Rutas.misListas),
              child: FilledButton(
                onPressed: () => context.go(Rutas.misListas),
                child: const Text('Volver a Mis listas'),
              ),
            ),
          ],
          // Con todo marcado, la salida es «Volver a Mis listas»; si se
          // desmarca algo, vuelve a aparecer.
          if (!lista.completa)
            _botonModo(
              'Salir del modo compra',
              () => setState(() => _modoCompra = false),
            ),
        ],
      ),
    );
  }
}

/// Casilla de un producto en el modo compra. CheckboxListTile ya da rol de
/// casilla, estado marcado/no marcado y nombre (título + subtítulo); no hace
/// falta Semantics. Visualmente, marcado = tic + texto tachado (no solo
/// color).
class _CasillaProducto extends StatelessWidget implements ControlDeMirada {
  const _CasillaProducto({required this.linea, required this.alCambiar});

  final LineaLista linea;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    final tachado = linea.marcada ? TextDecoration.lineThrough : null;
    final casilla = GazeTarget(
      etiqueta: linea.producto.nombre,
      alActivar: () => alCambiar(!linea.marcada),
      child: AnilloFoco(
        child: CheckboxListTile(
          value: linea.marcada,
          onChanged: (v) => alCambiar(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            linea.producto.nombre,
            style: TextStyle(decoration: tachado),
          ),
          subtitle: Text(
            '${contarUnidades(linea.unidades)}, ${linea.producto.formato}',
            style: TextStyle(decoration: tachado),
          ),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: linea.marcada
                  ? AppColors.acento
                  : AppColors.bordeControles,
              width: linea.marcada ? AppSizes.bordeFoco : AppSizes.bordeControl,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radio),
          ),
        ),
      ),
    );
    // Que la casilla agrandada por el modo mirada centre su contenido.
    return ListTileTheme.merge(
      minTileHeight: mirada.activo ? GazeConfig.altoFilaMirada : null,
      child: casilla,
    );
  }
}

/// Mensaje de compra completada: icono + texto + borde, en una región viva.
class _Confirmacion extends StatelessWidget {
  const _Confirmacion({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final detalle = total == 1
        ? 'Has marcado el único producto.'
        : 'Has marcado los $total productos.';
    return RegionViva(
      mensaje: '¡Compra completada! $detalle',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.fondo,
          border: Border.all(
            color: AppColors.acento,
            width: AppSizes.bordeFoco,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radio),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.acento, size: 32),
              const SizedBox(width: AppSizes.separacion),
              Expanded(
                child: Text(
                  '¡Compra completada!\n$detalle',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diálogo de confirmación de «Borrar lista». Devuelve `true` si se confirma.
/// El AlertDialog ya mueve el foco del lector al diálogo y lo anuncia.
///
/// En modo mirada, «Sí, borrar» necesita un segundo paso: la primera
/// activación por mirada lo cambia a «Confirmar borrado» y hay que apartar
/// la vista y volver a mirarlo. Con toque o teclado basta una pulsación (el
/// diálogo ya es la confirmación).
Future<bool?> confirmarBorrado(BuildContext context, ListaCompra lista) {
  var armado = false;
  return showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        void cancelar() => Navigator.of(context).pop(false);
        void borrar() => Navigator.of(context).pop(true);
        void borrarPorMirada() {
          if (armado) return borrar();
          setState(() => armado = true);
          anunciar(
            context,
            'Segundo paso: aparta la vista y mira otra vez «Confirmar '
            'borrado» para borrar la lista.',
          );
        }

        return AlertDialog(
          title: Text('¿Borrar «${lista.nombre}»?'),
          content: Text(
            armado
                ? 'Mira otra vez «Confirmar borrado» para borrar la lista. '
                      'No se puede deshacer.'
                : 'Se borrará la lista con '
                      '${contarProductos(lista.lineas.length)}. '
                      'No se puede deshacer.',
          ),
          actions: [
            Wrap(
              alignment: WrapAlignment.end,
              spacing: mirada.separacionBotones,
              runSpacing: mirada.separacionBotones,
              children: [
                GazeTarget(
                  etiqueta: 'Cancelar',
                  alActivar: cancelar,
                  child: OutlinedButton(
                    onPressed: cancelar,
                    child: const Text('Cancelar'),
                  ),
                ),
                GazeTarget(
                  etiqueta: armado ? 'Confirmar borrado' : 'Sí, borrar',
                  alActivar: borrarPorMirada,
                  child: FilledButton.icon(
                    onPressed: borrar,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      side: const BorderSide(
                        color: AppColors.error,
                        width: AppSizes.bordeControl,
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(armado ? 'Confirmar borrado' : 'Sí, borrar'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}
