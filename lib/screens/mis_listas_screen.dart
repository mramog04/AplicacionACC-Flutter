import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/almacen.dart';
import '../data/datos_ejemplo.dart';
import '../router.dart';
import '../theme.dart';
import '../widgets/controles.dart';
import '../widgets/pantalla_base.dart';

/// 2. Mis listas: listas guardadas en memoria, «Ajustes» arriba a la derecha
/// y botón cuadrado «Añadir lista» abajo a la derecha.
class MisListasScreen extends StatelessWidget {
  const MisListasScreen({super.key});

  static const double _ladoBotonAnadir = 104;

  @override
  Widget build(BuildContext context) {
    // El botón flotante crece con el texto; se reserva su alto aproximado al
    // final de la lista para que no tape la última fila.
    final escala = MediaQuery.textScalerOf(context).scale(1);
    final altoBoton = 12 * 2 + 32 + 4 + 2 * AppSizes.textoBase * 1.4 * escala;
    final huecoFinal =
        (altoBoton > _ladoBotonAnadir ? altoBoton : _ladoBotonAnadir) +
        2 * AppSizes.margen;

    return PantallaBase(
      titulo: 'Mis listas',
      botonDerecho: OutlinedButton.icon(
        onPressed: () => context.push(Rutas.ajustes),
        icon: const Icon(Icons.settings),
        label: const Text('Ajustes'),
      ),
      cuerpo: ListenableBuilder(
        listenable: almacen,
        builder: (context, _) {
          final listas = almacen.listas;
          return ListaSeparada(
            margenInferior: huecoFinal,
            children: [
              if (listas.isEmpty)
                const Text(
                  'Aún no tienes listas. Usa «Añadir lista» para crear una.',
                ),
              for (final lista in listas)
                BotonFila(
                  titulo: lista.nombre,
                  subtitulo: contarProductos(lista.lineas.length),
                  extra: formatearPrecio(lista.total),
                  alPulsar: () => context.go(Rutas.lista(lista.id)),
                ),
            ],
          );
        },
      ),
      botonFlotante: FilledButton(
        onPressed: () => context.go(Rutas.nuevaLista),
        style: FilledButton.styleFrom(
          minimumSize: const Size.square(_ladoBotonAnadir),
          padding: const EdgeInsets.all(12),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 32),
            SizedBox(height: 4),
            Text('Añadir lista', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
