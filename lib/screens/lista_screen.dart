import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/datos_ejemplo.dart';
import '../router.dart';
import '../theme.dart';
import '../widgets/controles.dart';
import '../widgets/pantalla_base.dart';

/// 4. Lista: título, total y productos. «Atrás» arriba; «+ Añadir producto»
/// y «Terminar lista» abajo.
class ListaScreen extends StatelessWidget {
  const ListaScreen({super.key, required this.id, this.nombreNueva});

  final String id;

  /// Nombre recibido desde «Nueva lista» (la lista no existe en los datos).
  final String? nombreNueva;

  @override
  Widget build(BuildContext context) {
    final lista = buscarLista(id);
    final nombre = lista?.nombre ?? nombreNueva ?? 'Nueva lista';
    final lineas = lista?.lineas ?? const <LineaLista>[];
    final total = lista?.total ?? 0;
    final textos = Theme.of(context).textTheme;

    return PantallaBase(
      titulo: nombre,
      botonIzquierdo: const BotonAtras(alternativa: Rutas.misListas),
      cuerpo: ListaSeparada(
        children: [
          // Total: se lee como una sola frase.
          MergeSemantics(
            child: Row(
              children: [
                Expanded(child: Text('Total', style: textos.titleMedium)),
                Text(formatearPrecio(total), style: textos.titleLarge),
              ],
            ),
          ),
          Text(contarProductos(lineas.length), style: textos.bodySmall),
          if (lineas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.margen),
              child: Text(
                'La lista está vacía. Usa «+ Añadir producto» para empezar.',
              ),
            ),
          for (final linea in lineas)
            BotonFila(
              titulo: linea.producto.nombre,
              subtitulo:
                  '${linea.unidades} × ${formatearPrecio(linea.producto.precio)}',
              extra: formatearPrecio(linea.subtotal),
              alPulsar: () => context.go(Rutas.producto(id, linea.producto.id)),
            ),
        ],
      ),
      barraInferior: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => context.go(Rutas.buscar(id)),
            child: const Text('+ Añadir producto'),
          ),
          const SizedBox(height: AppSizes.separacion),
          OutlinedButton(
            // Sin lógica todavía.
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Terminar lista: pendiente.')),
            ),
            child: const Text('Terminar lista'),
          ),
        ],
      ),
    );
  }
}
