import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/datos_ejemplo.dart';
import '../router.dart';
import '../theme.dart';
import '../widgets/controles.dart';
import '../widgets/pantalla_base.dart';

/// 5. Buscar producto: campo de búsqueda y resultados de ejemplo
/// (filtrado simple por nombre o marca sobre los datos fijos).
class BuscarProductoScreen extends StatefulWidget {
  const BuscarProductoScreen({super.key, required this.idLista});

  final String idLista;

  @override
  State<BuscarProductoScreen> createState() => _BuscarProductoScreenState();
}

class _BuscarProductoScreenState extends State<BuscarProductoScreen> {
  String _consulta = '';

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

    return PantallaBase(
      titulo: 'Buscar producto',
      botonIzquierdo: BotonAtras(alternativa: Rutas.lista(widget.idLista)),
      cuerpo: ListaSeparada(
        children: [
          CampoTexto(
            etiqueta: 'Buscar producto',
            pista: 'Nombre o marca',
            iconoPrefijo: Icons.search,
            autofocus: true,
            accionTeclado: TextInputAction.search,
            alCambiar: (v) => setState(() => _consulta = v),
          ),
          const SizedBox(height: AppSizes.separacion),
          // Se anuncia al lector de pantalla cuando cambia.
          Semantics(
            liveRegion: true,
            child: Text(
              n == 1 ? '1 resultado' : '$n resultados',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          for (final p in resultados)
            BotonFila(
              titulo: p.nombre,
              subtitulo: '${p.marca} · ${p.formato}',
              extra: formatearPrecio(p.precio),
              // push para que «Atrás» en el detalle vuelva a la búsqueda.
              alPulsar: () =>
                  context.push(Rutas.producto(widget.idLista, p.id)),
            ),
        ],
      ),
    );
  }
}
