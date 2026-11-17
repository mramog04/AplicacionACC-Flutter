import 'package:flutter/material.dart';

import '../gaze/gaze_settings.dart';
import '../router.dart';
import '../theme.dart';
import '../widgets/avisos.dart';
import '../widgets/pantalla_base.dart';

/// Calibración de la cámara para el modo mirada: 9 puntos, uno cada vez;
/// en cada uno hay que mirarlo y hacer clic 5 veces. Cada clic le dice a
/// WebGazer «ahora miro aquí». Mientras se calibra, la activación por
/// mirada está en pausa.
class CalibracionScreen extends StatefulWidget {
  const CalibracionScreen({super.key});

  static const clicsPorPunto = 5;

  /// Posiciones relativas (x, y) de los 9 puntos dentro de la zona libre.
  static const puntos = [
    (0.1, 0.1), (0.5, 0.1), (0.9, 0.1), //
    (0.1, 0.5), (0.5, 0.5), (0.9, 0.5), //
    (0.1, 0.9), (0.5, 0.9), (0.9, 0.9),
  ];

  @override
  State<CalibracionScreen> createState() => _CalibracionScreenState();
}

class _CalibracionScreenState extends State<CalibracionScreen> {
  int _punto = 0;
  int _clics = 0;

  bool get _terminada => _punto >= CalibracionScreen.puntos.length;

  @override
  void initState() {
    super.initState();
    mirada.controlador.pausado = true;
  }

  @override
  void dispose() {
    mirada.controlador.pausado = false;
    super.dispose();
  }

  void _clic(Offset centroGlobal) {
    mirada.camara.registrarCalibracion(centroGlobal);
    setState(() {
      _clics++;
      if (_clics >= CalibracionScreen.clicsPorPunto) {
        _clics = 0;
        _punto++;
      }
    });
  }

  String get _instruccion {
    if (_terminada) return 'Calibración terminada.';
    final faltan = CalibracionScreen.clicsPorPunto - _clics;
    return 'Punto ${_punto + 1} de ${CalibracionScreen.puntos.length}: '
        'mira el círculo y haz clic en él. '
        '${faltan == 1 ? 'Falta 1 clic' : 'Faltan $faltan clics'}.';
  }

  @override
  Widget build(BuildContext context) {
    const lado = 64.0;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.margen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  BotonAtras(
                    alternativa: Rutas.ajustes,
                    texto: _terminada ? 'Volver a Ajustes' : 'Cancelar',
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.separacion),
              const TituloPantalla('Calibración'),
              const SizedBox(height: AppSizes.separacion),
              RegionViva(
                mensaje: _instruccion,
                anunciarAlAparecer: false,
                child: Text(_instruccion),
              ),
              Expanded(
                child: _terminada
                    ? const SizedBox.shrink()
                    : LayoutBuilder(
                        builder: (context, zona) {
                          final (fx, fy) = CalibracionScreen.puntos[_punto];
                          final x = (zona.maxWidth - lado) * fx;
                          final y = (zona.maxHeight - lado) * fy;
                          return Stack(
                            children: [
                              Positioned(
                                left: x,
                                top: y,
                                width: lado,
                                height: lado,
                                child: Builder(
                                  builder: (context) => _Punto(
                                    clicsQueFaltan:
                                        CalibracionScreen.clicsPorPunto -
                                        _clics,
                                    alPulsar: () {
                                      final caja =
                                          context.findRenderObject()
                                              as RenderBox;
                                      _clic(
                                        caja.localToGlobal(
                                          caja.size.center(Offset.zero),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Círculo de calibración: botón de 64 px con los clics que faltan.
class _Punto extends StatelessWidget {
  const _Punto({required this.clicsQueFaltan, required this.alPulsar});

  final int clicsQueFaltan;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Punto de calibración, faltan $clicsQueFaltan clics',
      excludeSemantics: true,
      onTap: alPulsar,
      child: FilledButton(
        onPressed: alPulsar,
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Text('$clicsQueFaltan'),
      ),
    );
  }
}
