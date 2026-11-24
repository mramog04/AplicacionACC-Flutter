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
  external void stopVideo();
  external JSPromise<JSAny?> clearData();
  external _WebGazer removeMouseEventListeners();
  external _Parametros get params;
  external _WebGazer showVideoPreview(bool v);
  external _WebGazer showPredictionPoints(bool v);
  external _WebGazer showFaceOverlay(bool v);
  external _WebGazer showFaceFeedbackBox(bool v);
  external _WebGazer saveDataAcrossSessions(bool v);
  external _WebGazer applyKalmanFilter(bool v);
  external void recordScreenPosition(double x, double y, String tipo);
}

extension type _Parametros._(JSObject _) implements JSObject {
  external set faceMeshSolutionPath(String ruta);
}

extension type _Prediccion._(JSObject _) implements JSObject {
  external double get x;
  external double get y;
}

/// Modelo facial (MediaPipe) que usa WebGazer. Por defecto lo busca en
/// «./mediapipe/face_mesh» de nuestra web, donde no está: se carga de la
/// misma versión del paquete que web/index.html.
const _rutaModelo =
    'https://cdn.jsdelivr.net/npm/webgazer@3.5.3/dist/mediapipe/face_mesh';

/// Mirada estimada con la cámara web mediante WebGazer.js, que procesa el
/// vídeo en el navegador.
class WebGazerGazeSource implements GazeSource {
  final _controlador = StreamController<Offset>.broadcast();
  bool _iniciada = false;

  @override
  String get nombre => 'Cámara (WebGazer)';

  @override
  Stream<Offset> get muestras => _controlador.stream;

  Future<void>? _arranque;

  /// Dos arranques a la vez rompen MediaPipe («abort(undefined)») hasta
  /// recargar: si ya hay uno en marcha, se espera a ese.
  @override
  Future<void> iniciar() async {
    if (_iniciada) return;
    await (_arranque ??= _arrancar().whenComplete(() => _arranque = null));
  }

  Future<void> _arrancar() async {
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
    wg.params.faceMeshSolutionPath = _rutaModelo;
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
      // WebGazer aprende de cualquier clic o movimiento del ratón como si se
      // mirara ahí. Solo se quiere aprender de la calibración.
      wg.removeMouseEventListeners();
      _iniciada = true;
    } catch (e) {
      // Puede fallar con la cámara ya encendida (p. ej. sin modelo facial).
      _apagar(wg);
      throw FuenteNoDisponible(_motivo('$e'));
    }
  }

  static String _motivo(String error) {
    if (error.contains('NotAllowedError')) {
      return 'Permiso de cámara denegado.';
    }
    if (error.contains('NotFoundError') ||
        error.contains('OverconstrainedError')) {
      return 'No se ha encontrado una cámara compatible.';
    }
    if (error.contains('NotReadableError')) {
      return 'La cámara está ocupada por otra aplicación.';
    }
    if (error.contains('abort')) {
      return 'El modelo facial ha fallado. Recarga la página para reintentarlo.';
    }
    final corto = error.split('\n').first;
    return 'WebGazer no ha podido arrancar '
        '(${corto.length > 100 ? corto.substring(0, 100) : corto}).';
  }

  /// Apaga la cámara. `end()` por sí solo no la apaga: para el bucle y quita
  /// los elementos de la página, pero deja el vídeo en marcha.
  void _apagar(_WebGazer wg) {
    wg.clearGazeListener();
    try {
      wg.stopVideo();
    } catch (_) {
      // No había vídeo (p. ej. permiso denegado).
    }
    try {
      wg.removeMouseEventListeners();
      wg.end();
    } catch (_) {
      // No había elementos que quitar.
    }
  }

  @override
  Future<void> detener() async {
    final wg = _webgazer;
    if (wg != null && _iniciada) _apagar(wg);
    _iniciada = false;
  }

  @override
  void empezarCalibracion() {
    if (_iniciada) _webgazer?.clearData();
  }

  /// Punto de calibración: el usuario mira y hace clic en [posicion].
  @override
  void registrarCalibracion(Offset posicion) {
    if (_iniciada) {
      _webgazer?.recordScreenPosition(posicion.dx, posicion.dy, 'click');
    }
  }
}
