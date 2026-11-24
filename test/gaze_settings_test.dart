// Estado del modo mirada con una cámara simulada (sin navegador): espera del
// permiso, permiso tardío tras cambiar de idea, y fallo con motivo.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:lista_compra/gaze/gaze_settings.dart';
import 'package:lista_compra/gaze/gaze_source.dart';

/// Cámara cuyo arranque termina cuando la prueba quiere (como el permiso
/// del navegador, que espera a que el usuario conteste).
class CamaraSimulada implements GazeSource {
  Completer<void> permiso = Completer<void>();
  bool encendida = false;
  int arranques = 0;

  @override
  String get nombre => 'Cámara simulada';

  @override
  Stream<Offset> get muestras => const Stream.empty();

  @override
  Future<void> iniciar() async {
    arranques++;
    await permiso.future;
    encendida = true;
  }

  @override
  Future<void> detener() async => encendida = false;

  @override
  double? distanciaCm;
  @override
  void empezarCalibracion() {}

  @override
  void registrarCalibracion(Offset posicion) {}
}

void main() {
  late CamaraSimulada camara;
  late GazeSettings ajustes;

  setUp(() {
    camara = CamaraSimulada();
    ajustes = GazeSettings(disponible: true, camara: camara);
  });

  tearDown(() => ajustes.activar(false));

  test('Desactivado por defecto', () {
    expect(GazeSettings().activo, isFalse);
  });

  test('Mientras se espera el permiso se usa el ratón y se indica', () async {
    await ajustes.activar(true);
    final pedida = ajustes.usarFuente(FuenteMirada.camara);
    await Future<void>.delayed(Duration.zero);
    expect(ajustes.esperandoCamara, isTrue);
    expect(ajustes.fuente, FuenteMirada.raton);

    camara.permiso.complete();
    await pedida;
    expect(ajustes.esperandoCamara, isFalse);
    expect(ajustes.fuente, FuenteMirada.camara);
    expect(camara.encendida, isTrue);
  });

  test('Si se vuelve al ratón antes del permiso, la cámara se apaga', () async {
    await ajustes.activar(true);
    final pedida = ajustes.usarFuente(FuenteMirada.camara);
    await Future<void>.delayed(Duration.zero);
    await ajustes.usarFuente(FuenteMirada.raton);
    expect(ajustes.esperandoCamara, isFalse);

    camara.permiso.complete(); // el usuario concede el permiso tarde
    await pedida;
    expect(camara.encendida, isFalse);
    expect(ajustes.fuente, FuenteMirada.raton);
  });

  test('Si la cámara falla, se queda el ratón y se guarda el motivo', () async {
    await ajustes.activar(true);
    final pedida = ajustes.usarFuente(FuenteMirada.camara);
    camara.permiso.completeError(FuenteNoDisponible('Permiso denegado.'));
    await pedida;
    expect(ajustes.fuente, FuenteMirada.raton);
    expect(ajustes.motivoSinCamara, 'Permiso denegado.');
    expect(ajustes.esperandoCamara, isFalse);
  });

  test('Al desactivar el modo se apaga la cámara', () async {
    camara.permiso.complete();
    await ajustes.activar(true);
    await ajustes.usarFuente(FuenteMirada.camara);
    expect(camara.encendida, isTrue);
    await ajustes.activar(false);
    expect(camara.encendida, isFalse);
  });

  test('Pedir la cámara dos veces solo la arranca una', () async {
    await ajustes.activar(true);
    final una = ajustes.usarFuente(FuenteMirada.camara);
    await Future<void>.delayed(Duration.zero);
    final otra = ajustes.usarFuente(FuenteMirada.camara);
    camara.permiso.complete();
    await Future.wait([una, otra]);
    expect(camara.arranques, 1);
    expect(ajustes.fuente, FuenteMirada.camara);
  });
}
