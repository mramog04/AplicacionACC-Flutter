import 'package:flutter/foundation.dart';

import 'gaze_config.dart';
import 'gaze_controller.dart';
import 'gaze_source.dart';
import 'webgazer_source_stub.dart'
    if (dart.library.js_interop) 'webgazer_source_web.dart';

enum FuenteMirada { raton, camara }

/// Estado del modo «Control por mirada (experimental)». Desactivado por
/// defecto; solo disponible en web.
class GazeSettings extends ChangeNotifier {
  GazeSettings({bool? disponible, GazeSource? camara})
    : disponible = disponible ?? kIsWeb,
      camara = camara ?? WebGazerGazeSource();

  /// Solo en Flutter web (los tests lo activan a mano).
  bool disponible;

  bool _activo = false;
  bool get activo => _activo;

  FuenteMirada _fuente = FuenteMirada.raton;

  /// Fuente en uso. Mientras se espera el permiso de la cámara sigue siendo
  /// el ratón.
  FuenteMirada get fuente => _fuente;

  /// Se ha pedido la cámara y el navegador aún no ha respondido (el usuario
  /// no ha contestado al permiso). Se muestra en Ajustes.
  bool esperandoCamara = false;

  /// El usuario ha leído y aceptado el aviso de privacidad de la cámara.
  bool privacidadAceptada = false;

  /// Por qué no se está usando la cámara (se muestra en Ajustes), o null.
  String? motivoSinCamara;

  final raton = MouseGazeSource();
  final GazeSource camara;
  final controlador = GazeController();

  /// Cada petición de fuente invalida las anteriores que sigan pendientes.
  int _generacion = 0;

  double get ruidoRaton => raton.ruido;
  set ruidoRaton(double v) {
    raton.ruido = v;
    notifyListeners();
  }

  /// Hueco entre botones apilados: mayor con el modo mirada.
  double get separacionBotones =>
      _activo ? GazeConfig.separacionBotonesMirada : 8;

  Future<void> activar(bool valor) async {
    if (valor == _activo || (valor && !disponible)) return;
    _activo = valor;
    _generacion++;
    if (valor) {
      // Se empieza siempre con el ratón; si se había elegido la cámara, se
      // pide a continuación.
      final elegida = _fuente;
      _fuente = FuenteMirada.raton;
      await raton.iniciar();
      controlador.escuchar(raton);
      notifyListeners();
      if (elegida == FuenteMirada.camara) await usarFuente(elegida);
    } else {
      esperandoCamara = false;
      await raton.detener();
      await camara.detener();
      controlador.dejarDeEscuchar();
      notifyListeners();
    }
  }

  /// Cambia de fuente. Si la cámara no está disponible, se queda con el
  /// ratón y guarda el motivo en [motivoSinCamara].
  Future<void> usarFuente(FuenteMirada nueva) async {
    final generacion = ++_generacion;
    motivoSinCamara = null;
    if (nueva == FuenteMirada.raton) {
      esperandoCamara = false;
      await camara.detener();
      _fuente = FuenteMirada.raton;
      if (_activo) {
        await raton.iniciar();
        controlador.escuchar(raton);
      }
      notifyListeners();
      return;
    }
    if (!_activo) {
      _fuente = FuenteMirada.camara; // se pedirá al activar el modo
      notifyListeners();
      return;
    }
    esperandoCamara = true;
    notifyListeners();
    try {
      await camara.iniciar();
    } on FuenteNoDisponible catch (e) {
      if (generacion == _generacion) {
        esperandoCamara = false;
        motivoSinCamara = e.motivo;
        notifyListeners();
      }
      return;
    }
    // Mientras se esperaba, el usuario eligió otra cosa o apagó el modo.
    if (generacion != _generacion || !_activo) {
      await camara.detener();
      return;
    }
    await raton.detener();
    _fuente = FuenteMirada.camara;
    esperandoCamara = false;
    controlador.escuchar(camara);
    notifyListeners();
  }
}

/// Única instancia, compartida por la app.
final mirada = GazeSettings();
