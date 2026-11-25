import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../gaze/gaze_eyes.dart';
import '../gaze/gaze_settings.dart';
import '../router.dart';
import '../theme.dart';
import '../widgets/avisos.dart';
import '../widgets/controles.dart';
import '../widgets/indicador_distancia.dart';
import '../widgets/pantalla_base.dart';

/// 7. Ajustes: idioma y tamaño de texto (solo maqueta: la selección se
/// guarda en el estado de la pantalla y no se aplica todavía) y el control
/// por mirada experimental (solo web, desactivado por defecto).
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
      separacion: 0,
      contenido: [
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
        const SizedBox(height: AppSizes.margen * 2),
        const Subtitulo('Control por mirada'),
        const SizedBox(height: AppSizes.separacion),
        ListenableBuilder(
          listenable: mirada,
          builder: (context, _) =>
              _SeccionMirada(alElegirCamara: () => _elegirCamara(context)),
        ),
      ],
    );
  }

  /// Antes de encender la cámara, aviso de privacidad (una vez).
  Future<void> _elegirCamara(BuildContext context) async {
    if (!mirada.privacidadAceptada) {
      final acepta = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Uso de la cámara'),
          content: const Text(
            'Para estimar hacia dónde miras, la app usa la cámara con '
            'WebGazer.js. El vídeo se procesa solo en este navegador: no se '
            'graba, no se guarda y no sale del dispositivo. Puedes '
            'desactivarlo cuando quieras desde Ajustes.',
          ),
          actionsOverflowButtonSpacing: AppSizes.separacion,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Aceptar y usar la cámara'),
            ),
          ],
        ),
      );
      if (acepta != true) return;
      mirada.privacidadAceptada = true;
    }
    await mirada.usarFuente(FuenteMirada.camara);
  }
}

/// Interruptor, fuente de la mirada y ajustes de cada fuente.
class _SeccionMirada extends StatelessWidget {
  const _SeccionMirada({required this.alElegirCamara});

  final VoidCallback alElegirCamara;

  static const _fuentes = {
    'raton': 'Ratón con temblor simulado (pruebas)',
    'camara': 'Cámara (WebGazer)',
  };

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final borde = RoundedRectangleBorder(
      side: const BorderSide(
        color: AppColors.bordeControles,
        width: AppSizes.bordeControl,
      ),
      borderRadius: BorderRadius.circular(AppSizes.radio),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!mirada.disponible) ...[
          Text(
            'Solo disponible en la versión web (navegador).',
            style: textos.bodySmall,
          ),
          const SizedBox(height: AppSizes.separacion),
        ],
        AnilloFoco(
          child: SwitchListTile(
            title: const Text('Control por mirada (experimental)'),
            subtitle: const Text(
              'Activa un botón mirándolo durante 1,5 segundos.',
            ),
            value: mirada.activo,
            onChanged: mirada.disponible ? mirada.activar : null,
            shape: borde,
          ),
        ),
        if (mirada.activo) ...[
          const SizedBox(height: AppSizes.margen),
          Text('Fuente de la mirada', style: textos.titleSmall),
          const SizedBox(height: AppSizes.separacion),
          _GrupoOpciones(
            opciones: _fuentes,
            // Mientras carga ya se ve marcada la que se ha elegido.
            valor: mirada.esperandoCamara
                ? FuenteMirada.camara.name
                : mirada.fuente.name,
            alCambiar: (v) => v == 'camara'
                ? alElegirCamara()
                : mirada.usarFuente(FuenteMirada.raton),
          ),
          if (mirada.esperandoCamara) ...[
            const SizedBox(height: AppSizes.separacion),
            // Estado de carga: se ve (indicador + texto) y se anuncia.
            const RegionViva(
              mensaje:
                  'Esperando el permiso de la cámara. Mientras tanto se usa '
                  'el ratón.',
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  SizedBox(width: AppSizes.separacion),
                  Expanded(
                    child: Text(
                      'Esperando el permiso de la cámara… Mientras tanto '
                      'se usa el ratón.',
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (mirada.motivoSinCamara != null) ...[
            const SizedBox(height: AppSizes.separacion),
            RegionViva(
              mensaje:
                  'No se puede usar la cámara: ${mirada.motivoSinCamara} '
                  'Se usa el ratón.',
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: AppSizes.separacion),
                  Expanded(
                    child: Text(
                      'No se puede usar la cámara: '
                      '${mirada.motivoSinCamara} Se usa el ratón.',
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSizes.margen),
          Text('Cómo se pulsan los botones', style: textos.titleSmall),
          const SizedBox(height: AppSizes.separacion),
          _GrupoOpciones(
            opciones: {for (final m in ModoMirada.values) m.name: m.nombre},
            ayudas: {for (final m in ModoMirada.values) m.name: m.ayuda},
            valor: mirada.modo.name,
            alCambiar: (v) => mirada.modo = ModoMirada.values.byName(v),
          ),
          if (mirada.modo.usaOjos) ...[
            const SizedBox(height: AppSizes.separacion),
            if (mirada.fuente == FuenteMirada.camara)
              ValueListenableBuilder(
                valueListenable: mirada.ojosCerrados,
                builder: (context, cerrados, _) => Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        cerrados ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                    const SizedBox(width: AppSizes.separacion),
                    Expanded(
                      child: Text(
                        'La cámara ve tus ojos: '
                        '${cerrados ? 'cerrados' : 'abiertos'}.',
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text(
                'Este modo necesita la cámara. Con el ratón se usa «Mirar».',
              ),
          ],
          const SizedBox(height: AppSizes.margen),
          AnilloFoco(
            child: SwitchListTile(
              title: const Text('Mostrar puntero de mirada'),
              subtitle: const Text('Un punto rojo marca dónde estás mirando.'),
              value: mirada.mostrarPuntero,
              onChanged: (v) => mirada.mostrarPuntero = v,
              shape: borde,
            ),
          ),
          const SizedBox(height: AppSizes.margen),
          if (mirada.fuente == FuenteMirada.raton) ...[
            Text(
              'Temblor simulado: ${mirada.ruidoRaton.round()} px',
              style: textos.titleSmall,
            ),
            Slider(
              value: mirada.ruidoRaton,
              max: 150,
              divisions: 15,
              label: '${mirada.ruidoRaton.round()} px',
              semanticFormatterCallback: (v) => '${v.round()} píxeles',
              onChanged: (v) => mirada.ruidoRaton = v,
            ),
          ] else ...[
            Text('Distancia a la cámara', style: textos.titleSmall),
            const IndicadorDistancia(),
            const SizedBox(height: AppSizes.margen),
            OutlinedButton.icon(
              onPressed: () => context.push(Rutas.calibracion),
              icon: const Icon(Icons.center_focus_strong),
              label: const Text('Calibrar (9 puntos)'),
            ),
          ],
        ],
      ],
    );
  }
}

/// Grupo de botones de opción con 8 px entre ellos y contorno de foco.
class _GrupoOpciones extends StatelessWidget {
  const _GrupoOpciones({
    required this.opciones,
    required this.valor,
    required this.alCambiar,
    this.ayudas = const {},
  });

  final Map<String, String> opciones;

  /// Explicación opcional de cada opción.
  final Map<String, String> ayudas;
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
                subtitle: ayudas[e.key] == null ? null : Text(ayudas[e.key]!),
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
