import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/datos_ejemplo.dart';
import '../router.dart';
import '../theme.dart';
import '../widgets/controles.dart';
import '../widgets/pantalla_base.dart';

/// 2. Mis listas: listas de ejemplo, «Ajustes» arriba a la derecha y botón
/// cuadrado «Añadir lista» abajo a la derecha.
class MisListasScreen extends StatelessWidget {
  const MisListasScreen({super.key});

  static const double _ladoBotonAnadir = 104;

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Mis listas',
      botonDerecho: OutlinedButton.icon(
        onPressed: () => context.push(Rutas.ajustes),
        icon: const Icon(Icons.settings),
        label: const Text('Ajustes'),
      ),
      cuerpo: ListaSeparada(
        // Hueco para que el botón flotante no tape la última lista.
        margenInferior: _ladoBotonAnadir + 2 * AppSizes.margen,
        children: [
          for (final lista in listasEjemplo)
            BotonFila(
              titulo: lista.nombre,
              subtitulo: contarProductos(lista.lineas.length),
              extra: formatearPrecio(lista.total),
              alPulsar: () => context.go(Rutas.lista(lista.id)),
            ),
        ],
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
