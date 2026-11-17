import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/datos_ejemplo.dart';
import '../router.dart';
import '../theme.dart';
import '../widgets/controles.dart';
import '../widgets/pantalla_base.dart';

/// 3. Nueva lista: campo «Nombre de la lista», «Cancelar» arriba y
/// «Crear lista» abajo. No guarda nada: navega a una lista vacía con el
/// nombre escrito.
class NuevaListaScreen extends StatefulWidget {
  const NuevaListaScreen({super.key});

  @override
  State<NuevaListaScreen> createState() => _NuevaListaScreenState();
}

class _NuevaListaScreenState extends State<NuevaListaScreen> {
  final _nombre = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _crear() {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Escribe un nombre para la lista.');
      return;
    }
    // Id ficticio: la siguiente a las de ejemplo.
    final id = '${listasEjemplo.length + 1}';
    context.go(
      Uri(
        path: Rutas.lista(id),
        queryParameters: {'nombre': nombre},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Nueva lista',
      botonIzquierdo: BotonAtras(
        alternativa: Rutas.misListas,
        texto: 'Cancelar',
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.all(AppSizes.margen),
        children: [
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
      ),
      barraInferior: FilledButton(
        onPressed: _crear,
        child: const Text('Crear lista'),
      ),
    );
  }
}
