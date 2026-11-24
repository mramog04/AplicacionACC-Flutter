import 'dart:async';

import 'package:flutter/material.dart';

import '../gaze/gaze_config.dart';
import '../gaze/gaze_distance.dart';
import '../gaze/gaze_settings.dart';
import '../theme.dart';
import 'avisos.dart';

/// Distancia aproximada a la cámara y si es la adecuada. Al lector solo se le
/// anuncia cuando cambia el estado (no cada centímetro).
class IndicadorDistancia extends StatefulWidget {
  const IndicadorDistancia({super.key});

  @override
  State<IndicadorDistancia> createState() => _IndicadorDistanciaState();
}

class _IndicadorDistanciaState extends State<IndicadorDistancia> {
  late final Timer _timer;
  final _medidas = <double>[];
  double? _cm;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) => _medir());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// Media de las últimas medidas, para que el número no baile.
  void _medir() {
    final d = mirada.camara.distanciaCm;
    if (d == null) {
      _medidas.clear();
    } else {
      _medidas.add(d);
      if (_medidas.length > 5) _medidas.removeAt(0);
    }
    final cm = _medidas.isEmpty
        ? null
        : _medidas.reduce((a, b) => a + b) / _medidas.length;
    if (cm?.round() != _cm?.round()) setState(() => _cm = cm);
  }

  @override
  Widget build(BuildContext context) {
    final estado = EstadoDistancia.de(_cm);
    final bien = estado == EstadoDistancia.bien;
    final calibrada = mirada.distanciaCalibrada;
    final recomendada =
        'Recomendado: entre ${GazeConfig.distanciaMinCm.round()} y '
        '${GazeConfig.distanciaMaxCm.round()} cm (más o menos un brazo).';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegionViva(
          mensaje: estado.texto,
          anunciarAlAparecer: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                bien ? Icons.check_circle_outline : Icons.info_outline,
                color: bien ? AppColors.acento : AppColors.error,
              ),
              const SizedBox(width: AppSizes.separacion),
              Flexible(
                child: Text(
                  _cm == null
                      ? estado.texto
                      : 'Unos ${_cm!.round()} cm. ${estado.texto}',
                ),
              ),
            ],
          ),
        ),
        Text(recomendada, style: Theme.of(context).textTheme.bodySmall),
        if (calibrada != null)
          Text(
            'Calibraste a unos ${calibrada.round()} cm: procura mantenerla.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
