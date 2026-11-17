import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/almacen.dart';
import '../data/datos_ejemplo.dart';
import '../router.dart';
import '../theme.dart';
import '../widgets/avisos.dart';
import '../widgets/controles.dart';
import '../widgets/pantalla_base.dart';

/// 6. Detalle de producto: información y selector de unidades.
///
/// - Si el producto no está en la lista: «Añadir a la lista».
/// - Si ya está: muestra sus unidades actuales y «Guardar unidades».
/// En ambos casos vuelve a la lista con un aviso.
class DetalleProductoScreen extends StatefulWidget {
  const DetalleProductoScreen({
    super.key,
    required this.idLista,
    required this.idProducto,
  });

  final String idLista;
  final String idProducto;

  @override
  State<DetalleProductoScreen> createState() => _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  late final LineaLista? _linea = almacen.linea(
    widget.idLista,
    widget.idProducto,
  );
  late int _unidades = _linea?.unidades ?? 1;

  bool get _enLista => _linea != null;

  void _confirmar(Producto p) {
    final texto = '${contarUnidades(_unidades)} de ${p.nombre}';
    if (_enLista) {
      almacen.fijarUnidades(widget.idLista, p.id, _unidades);
      mostrarAviso(context, 'Guardado: $texto.');
    } else {
      almacen.anadirProducto(widget.idLista, p, _unidades);
      mostrarAviso(context, 'Añadido a la lista: $texto.');
    }
    context.go(Rutas.lista(widget.idLista));
  }

  @override
  Widget build(BuildContext context) {
    final producto = buscarProducto(widget.idProducto);
    final lista = almacen.lista(widget.idLista);
    final atras = BotonAtras(alternativa: Rutas.lista(widget.idLista));

    if (producto == null || lista == null) {
      return PantallaBase(
        titulo: producto == null
            ? 'Producto no encontrado'
            : 'Lista no encontrada',
        botonIzquierdo: atras,
        cuerpo: const Padding(
          padding: EdgeInsets.all(AppSizes.margen),
          child: Text('No existe ese producto o esa lista.'),
        ),
      );
    }

    final textos = Theme.of(context).textTheme;
    final subtotal = formatearPrecio(producto.precio * _unidades);
    return PantallaBase(
      titulo: producto.nombre,
      botonIzquierdo: atras,
      cuerpo: ListView(
        padding: const EdgeInsets.all(AppSizes.margen),
        children: [
          if (_enLista) ...[
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: AppSizes.separacion),
                Expanded(
                  child: Text(
                    'Ya está en «${lista.nombre}» con '
                    '${contarUnidades(_linea!.unidades)}.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.margen),
          ],
          _Dato(etiqueta: 'Marca', valor: producto.marca),
          _Dato(etiqueta: 'Formato', valor: producto.formato),
          _Dato(etiqueta: 'Precio', valor: formatearPrecio(producto.precio)),
          _Dato(etiqueta: 'Descripción', valor: producto.descripcion),
          const SizedBox(height: AppSizes.margen),
          const Subtitulo('Unidades'),
          const SizedBox(height: AppSizes.separacion),
          SelectorUnidades(
            valor: _unidades,
            alCambiar: (v) => setState(() => _unidades = v),
          ),
          if (_unidades == 1) ...[
            const SizedBox(height: 4),
            // Explica con texto por qué «−» está deshabilitado.
            Text('Mínimo: 1 unidad.', style: textos.bodySmall),
          ],
          const SizedBox(height: AppSizes.separacion),
          // Región viva: al pulsar «−»/«+» el lector anuncia las unidades y
          // el subtotal sin que el foco se mueva del botón.
          RegionViva(
            mensaje: '${contarUnidades(_unidades)}. Subtotal: $subtotal',
            anunciarAlAparecer: false,
            child: Text(
              'Subtotal (${contarUnidades(_unidades)}): $subtotal',
              style: textos.bodyLarge,
            ),
          ),
        ],
      ),
      barraInferior: FilledButton(
        onPressed: () => _confirmar(producto),
        child: Text(_enLista ? 'Guardar unidades' : 'Añadir a la lista'),
      ),
    );
  }
}

/// Dato «etiqueta: valor». MergeSemantics hace que se lean juntos como un
/// solo elemento («Marca, Granja del Valle»).
class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.separacion),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: textos.bodySmall),
            Text(valor, style: textos.bodyLarge),
          ],
        ),
      ),
    );
  }
}
