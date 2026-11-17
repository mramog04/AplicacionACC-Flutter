import 'dart:async';
import 'dart:math';

import 'package:flutter/painting.dart';

import 'gaze_config.dart';

/// Fuente de muestras de mirada en coordenadas de pantalla (px lógicos).
abstract class GazeSource {
  /// Nombre para mostrar en Ajustes.
  String get nombre;

  Stream<Offset> get muestras;

  /// Arranca la fuente. Lanza [FuenteNoDisponible] si no puede.
  Future<void> iniciar();

  Future<void> detener();

  /// Calibración: el usuario mira y hace clic en [posicion]. Solo la usa la
  /// cámara; las demás fuentes no hacen nada.
  void registrarCalibracion(Offset posicion);
}

/// La fuente no se puede usar; [motivo] se muestra al usuario.
class FuenteNoDisponible implements Exception {
  FuenteNoDisponible(this.motivo);
  final String motivo;

  @override
  String toString() => motivo;
}

/// Simula la mirada con la posición del puntero más un temblor aleatorio,
/// para probar el modo sin cámara. Emite muestras periódicas aunque el ratón
/// esté quieto (como haría una cámara).
class MouseGazeSource implements GazeSource {
  MouseGazeSource({
    this.ruido = GazeConfig.ruidoRatonPorDefecto,
    Random? aleatorio,
  }) : _aleatorio = aleatorio ?? Random();

  /// Radio máximo del temblor simulado, en px.
  double ruido;

  final Random _aleatorio;
  final _controlador = StreamController<Offset>.broadcast();
  Timer? _timer;
  Offset? _puntero;

  @override
  String get nombre => 'Ratón con temblor simulado';

  @override
  Stream<Offset> get muestras => _controlador.stream;

  /// Lo llama la capa de mirada en cada movimiento del puntero.
  void actualizarPuntero(Offset posicion) => _puntero = posicion;

  /// Punto uniforme dentro de un círculo de radio [ruido] alrededor de [p].
  Offset conRuido(Offset p) {
    if (ruido <= 0) return p;
    final r = ruido * sqrt(_aleatorio.nextDouble());
    final a = 2 * pi * _aleatorio.nextDouble();
    return p + Offset(r * cos(a), r * sin(a));
  }

  @override
  Future<void> iniciar() async {
    _timer?.cancel();
    _timer = Timer.periodic(GazeConfig.periodoRaton, (_) {
      final p = _puntero;
      if (p != null) _controlador.add(conRuido(p));
    });
  }

  @override
  Future<void> detener() async {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void registrarCalibracion(Offset posicion) {}
}
