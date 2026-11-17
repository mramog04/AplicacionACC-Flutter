import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/almacen.dart';
import '../data/datos_ejemplo.dart';
import '../router.dart';
import '../widgets/avisos.dart';
import '../widgets/controles.dart';
import '../widgets/pantalla_base.dart';

/// 5. Buscar producto: campo de búsqueda y resultados (filtrado simple por
/// nombre o marca sobre el catálogo de ejemplo).
///
/// Si se elige un producto que ya está en la lista, se avisa y se abre su
/// ficha para cambiar las unidades, en lugar de duplicarlo.
class BuscarProductoScreen extends StatefulWidget {
  const BuscarProductoScreen({super.key, required this.idLista});

  final String idLista;

  @override
  State<BuscarProductoScreen> createState() => _BuscarProductoScreenState();
}

class _BuscarProductoScreenState extends State<BuscarProductoScreen> {
  String _consulta = '';

  void _elegir(Producto p) {
    if (almacen.linea(widget.idLista, p.id) != null) {
      mostrarAviso(
        context,
        '«${p.nombre}» ya está en la lista. Puedes cambiar sus unidades.',
        tipo: TipoAviso.informacion,
      );
    }
    // push para que «Atrás» en el detalle vuelva a la búsqueda.
    context.push(Rutas.producto(widget.idLista, p.id));
  }

  @override
  Widget build(BuildContext context) {
    final q = _consulta.trim().toLowerCase();
    final resultados = productosEjemplo
        .where(
          (p) =>
              p.nombre.toLowerCase().contains(q) ||
              p.marca.toLowerCase().contains(q),
        )
        .toList();
    final n = resultados.length;
    final textoResultados = n == 1 ? '1 resultado' : '$n resultados';

    return PantallaBase(
      titulo: 'Buscar producto',
      botonIzquierdo: BotonAtras(alternativa: Rutas.lista(widget.idLista)),
      cuerpo: ListenableBuilder(
        listenable: almacen,
        builder: (context, _) => ListaSeparada(
          children: [
            CampoTexto(
              etiqueta: 'Buscar producto',
              pista: 'Nombre o marca',
              iconoPrefijo: Icons.search,
              autofocus: true,
              accionTeclado: TextInputAction.search,
              alCambiar: (v) => setState(() => _consulta = v),
            ),
            // Se anuncia al cambiar (no al abrir la pantalla).
            RegionViva(
              mensaje: textoResultados,
              anunciarAlAparecer: false,
              child: Text(
                textoResultados,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (n == 0)
              Text('No hay productos que coincidan con «$_consulta».'),
            for (final p in resultados) _resultado(p),
          ],
        ),
      ),
    );
  }

  Widget _resultado(Producto p) {
    final linea = almacen.linea(widget.idLista, p.id);
    final enLista = linea == null
        ? ''
        : '. Ya en tu lista: ${contarUnidades(linea.unidades)}';
    return BotonFila(
      titulo: p.nombre,
      subtitulo: '${p.marca}, ${p.formato}$enLista',
      extra: formatearPrecio(p.precio),
      alPulsar: () => _elegir(p),
    );
  }
}
