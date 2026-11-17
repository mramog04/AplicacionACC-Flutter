import 'dart:async';

import 'package:flutter/painting.dart';

import 'gaze_source.dart';

/// Versión para plataformas que no son web: WebGazer no existe.
class WebGazerGazeSource implements GazeSource {
  @override
  String get nombre => 'Cámara (WebGazer)';

  @override
  Stream<Offset> get muestras => const Stream.empty();

  @override
  Future<void> iniciar() async =>
      throw FuenteNoDisponible('La cámara solo funciona en la versión web.');

  @override
  Future<void> detener() async {}

  @override
  void registrarCalibracion(Offset posicion) {}
}
