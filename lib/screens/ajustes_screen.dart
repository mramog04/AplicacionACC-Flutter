import 'package:flutter/material.dart';

import '../router.dart';
import '../theme.dart';
import '../widgets/controles.dart';
import '../widgets/pantalla_base.dart';

/// 7. Ajustes: idioma y tamaño de texto. Solo maqueta: la selección se
/// guarda en el estado de la pantalla y no se aplica todavía.
class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  String _idioma = 'es';
  String _tamano = 'sistema';

  static const _idiomas = {'es': 'Español', 'en': 'English'};
  static const _tamanos = {
    'sistema': 'Según el sistema',
    'grande': 'Grande (150 %)',
    'muy_grande': 'Muy grande (200 %)',
  };

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Ajustes',
      botonIzquierdo: const BotonAtras(alternativa: Rutas.misListas),
      cuerpo: ListView(
        padding: const EdgeInsets.all(AppSizes.margen),
        children: [
          const Subtitulo('Idioma'),
          const SizedBox(height: AppSizes.separacion),
          _GrupoOpciones(
            opciones: _idiomas,
            valor: _idioma,
            alCambiar: (v) => setState(() => _idioma = v),
          ),
          const SizedBox(height: AppSizes.margen * 2),
          const Subtitulo('Tamaño de texto'),
          const SizedBox(height: AppSizes.separacion),
          _GrupoOpciones(
            opciones: _tamanos,
            valor: _tamano,
            alCambiar: (v) => setState(() => _tamano = v),
          ),
        ],
      ),
    );
  }
}

/// Grupo de botones de opción con 8 px entre ellos y contorno de foco.
class _GrupoOpciones extends StatelessWidget {
  const _GrupoOpciones({
    required this.opciones,
    required this.valor,
    required this.alCambiar,
  });

  final Map<String, String> opciones;
  final String valor;
  final ValueChanged<String> alCambiar;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: valor,
      onChanged: (v) {
        if (v != null) alCambiar(v);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, e) in opciones.entries.indexed) ...[
            if (i > 0) const SizedBox(height: AppSizes.separacion),
            AnilloFoco(
              child: RadioListTile<String>(
                value: e.key,
                title: Text(e.value),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    color: AppColors.bordeControles,
                    width: AppSizes.bordeControl,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radio),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
