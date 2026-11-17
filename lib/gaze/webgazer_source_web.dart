import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/painting.dart';

import 'gaze_source.dart';

// Enlaces con WebGazer.js (cargado desde web/index.html) mediante
// dart:js_interop. Solo se compila en web.

@JS('webgazer')
external _WebGazer? get _webgazer;

@JS('isSecureContext')
external bool get _contextoSeguro;

extension type _WebGazer._(JSObject _) implements JSObject {
  external _WebGazer setGazeListener(JSFunction escuchador);
  external _WebGazer clearGazeListener();
  external JSPromise<JSAny?> begin();
  external void end();
  external _WebGazer showVideoPreview(bool v);
  external _WebGazer showPredictionPoints(bool v);
  external _WebGazer showFaceOverlay(bool v);
  external _WebGazer showFaceFeedbackBox(bool v);
  external _WebGazer saveDataAcrossSessions(bool v);
  external _WebGazer applyKalmanFilter(bool v);
  external void recordScreenPosition(double x, double y, String tipo);
}

extension type _Prediccion._(JSObject _) implements JSObject {
  external double get x;
  external double get y;
}

/// Mirada estimada con la cámara web mediante WebGazer.js. El vídeo se
/// procesa en el navegador: no se envía a ningún servidor.
class WebGazerGazeSource implements GazeSource {
  final _controlador = StreamController<Offset>.broadcast();
  bool _iniciada = false;

  @override
  String get nombre => 'Cámara (WebGazer)';

  @override
  Stream<Offset> get muestras => _controlador.stream;

  @override
  Future<void> iniciar() async {
    if (!_contextoSeguro) {
      throw FuenteNoDisponible(
        'La cámara solo se puede usar desde https o localhost.',
      );
    }
    final wg = _webgazer;
    if (wg == null) {
      throw FuenteNoDisponible(
        'No se ha podido cargar WebGazer.js (¿sin conexión o bloqueado?).',
      );
    }
    wg
        .saveDataAcrossSessions(false) // no guarda datos en el navegador
        .showVideoPreview(false)
        .showPredictionPoints(false) // no se dibuja un punto de mirada
        .showFaceOverlay(false)
        .showFaceFeedbackBox(false)
        .applyKalmanFilter(true)
        .setGazeListener(
          ((_Prediccion? p, JSNumber _) {
            if (p != null) _controlador.add(Offset(p.x, p.y));
          }).toJS,
        );
    try {
      await wg.begin().toDart;
      _iniciada = true;
    } catch (e) {
      throw FuenteNoDisponible(
        'No se ha podido acceder a la cámara (permiso denegado o sin '
        'cámara).',
      );
    }
  }

  @override
  Future<void> detener() async {
    final wg = _webgazer;
    if (wg != null && _iniciada) {
      wg.clearGazeListener();
      wg.end(); // apaga la cámara
    }
    _iniciada = false;
  }

  /// Punto de calibración: el usuario mira y hace clic en [posicion].
  @override
  void registrarCalibracion(Offset posicion) {
    if (_iniciada) {
      _webgazer?.recordScreenPosition(posicion.dx, posicion.dy, 'click');
    }
  }
}
