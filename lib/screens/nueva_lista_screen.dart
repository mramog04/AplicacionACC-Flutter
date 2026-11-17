import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/almacen.dart';
import '../gaze/gaze_target.dart';
import '../router.dart';
import '../widgets/avisos.dart';
import '../widgets/controles.dart';
import '../widgets/pantalla_base.dart';

/// 3. Nueva lista: campo «Nombre de la lista», «Cancelar» arriba y
/// «Crear lista» abajo. Crea la lista en memoria y abre la lista vacía.
class NuevaListaScreen extends StatefulWidget {
  const NuevaListaScreen({super.key});

  @override
  State<NuevaListaScreen> createState() => _NuevaListaScreenState();
}

class _NuevaListaScreenState extends State<NuevaListaScreen> {
  final _nombre = TextEditingController();
  String? _error;

  static const errorNombreVacio = 'Escribe un nombre para la lista.';

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _crear() {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = errorNombreVacio);
      // El texto de error del campo ya es una región viva cuando la
      // plataforma no admite anuncios; si los admite, se anuncia aquí. El
      // foco no se mueve: se queda donde lo tenía el usuario.
      anunciar(context, 'Error: $errorNombreVacio');
      return;
    }
    final lista = almacen.crearLista(nombre);
    mostrarAviso(context, 'Lista «$nombre» creada.');
    context.go(Rutas.lista(lista.id));
  }

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Nueva lista',
      botonIzquierdo: const BotonAtras(
        alternativa: Rutas.misListas,
        texto: 'Cancelar',
      ),
      separacion: 0,
      contenido: [
        CampoTexto(
          etiqueta: 'Nombre de la lista',
          pista: 'Por ejemplo: Compra semanal',
          controller: _nombre,
          error: _error,
          autofocus: true,
          accionTeclado: TextInputAction.done,
          alCambiar: (_) {
            if (_error != null) setState(() => _error = null);
          },
          alEnviar: (_) => _crear(),
        ),
      ],
      barraInferior: GazeTarget(
        etiqueta: 'Crear lista',
        alActivar: _crear,
        child: FilledButton(
          onPressed: _crear,
          child: const Text('Crear lista'),
        ),
      ),
    );
  }
}
