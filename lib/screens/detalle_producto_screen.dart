import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/datos_ejemplo.dart';
import '../router.dart';
import '../theme.dart';
import '../widgets/pantalla_base.dart';

/// 6. Detalle de producto: información, selector de unidades y
/// «Añadir a la lista» (vuelve a la lista sin guardar nada).
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
  int _unidades = 1;

  void _anadir(Producto p) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Añadido: $_unidades × ${p.nombre}')),
    );
    context.go(Rutas.lista(widget.idLista));
  }

  @override
  Widget build(BuildContext context) {
    final producto = buscarProducto(widget.idProducto);
    final atras = BotonAtras(alternativa: Rutas.lista(widget.idLista));

    if (producto == null) {
      return PantallaBase(
        titulo: 'Producto no encontrado',
        botonIzquierdo: atras,
        cuerpo: const Padding(
          padding: EdgeInsets.all(AppSizes.margen),
          child: Text('No existe ningún producto con ese identificador.'),
        ),
      );
    }

    final textos = Theme.of(context).textTheme;
    return PantallaBase(
      titulo: producto.nombre,
      botonIzquierdo: atras,
      cuerpo: ListView(
        padding: const EdgeInsets.all(AppSizes.margen),
        children: [
          _Dato(etiqueta: 'Marca', valor: producto.marca),
          _Dato(etiqueta: 'Formato', valor: producto.formato),
          _Dato(etiqueta: 'Precio', valor: formatearPrecio(producto.precio)),
          _Dato(etiqueta: 'Descripción', valor: producto.descripcion),
          const SizedBox(height: AppSizes.margen),
          const Subtitulo('Unidades'),
          const SizedBox(height: AppSizes.separacion),
          Row(
            children: [
              IconButton(
                onPressed: _unidades > 1
                    ? () => setState(() => _unidades--)
                    : null,
                tooltip: 'Quitar una unidad',
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: AppSizes.separacion),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48),
                child: Semantics(
                  liveRegion: true,
                  label: 'Unidades',
                  child: Text(
                    '$_unidades',
                    textAlign: TextAlign.center,
                    style: textos.titleLarge,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.separacion),
              IconButton(
                onPressed: () => setState(() => _unidades++),
                tooltip: 'Añadir una unidad',
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.separacion),
          Text(
            'Subtotal: ${formatearPrecio(producto.precio * _unidades)}',
            style: textos.bodySmall,
          ),
        ],
      ),
      barraInferior: FilledButton(
        onPressed: () => _anadir(producto),
        child: const Text('Añadir a la lista'),
      ),
    );
  }
}

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
