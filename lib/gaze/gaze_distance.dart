import 'dart:math';

import 'gaze_config.dart';

/// Distancia aproximada a la cámara (cm) a partir de los píxeles que separan
/// las comisuras externas de los ojos en una imagen de [anchoImagenPx].
double? estimarDistanciaCm({
  required double separacionOjosPx,
  required double anchoImagenPx,
}) {
  if (separacionOjosPx <= 0 || anchoImagenPx <= 0) return null;
  final focal =
      anchoImagenPx / 2 / tan(GazeConfig.anguloCamaraGrados / 2 * pi / 180);
  return GazeConfig.anchoOjosCm * focal / separacionOjosPx;
}

enum EstadoDistancia {
  sinCara('No se ve tu cara. Ponte de frente a la cámara y con luz.'),
  cerca('Estás demasiado cerca: aléjate un poco.'),
  bien('Distancia correcta.'),
  lejos('Estás demasiado lejos: acércate un poco.');

  const EstadoDistancia(this.texto);
  final String texto;

  static EstadoDistancia de(double? cm) => switch (cm) {
    null => sinCara,
    < GazeConfig.distanciaMinCm => cerca,
    > GazeConfig.distanciaMaxCm => lejos,
    _ => bien,
  };
}
