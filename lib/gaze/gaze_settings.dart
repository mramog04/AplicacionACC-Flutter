import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'gaze_config.dart';
import 'gaze_controller.dart';
import 'gaze_correction.dart';
import 'gaze_eyes.dart';
import 'gaze_source.dart';
import 'sonido_stub.dart' if (dart.library.js_interop) 'sonido_web.dart';
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

  /// Tamaño de la pantalla (lo pone CapaMirada).
  Size pantalla = Size.infinite;

  /// Corrección de la cámara, medida al final de la calibración.
  CorreccionMirada correccion = CorreccionMirada.identidad;

  /// Distancia a la que se calibró, o null si no se ha medido.
  double? distanciaCalibrada;

  /// Dibujar un puntero rojo donde se estima la mirada (Ajustes).
  bool _mostrarPuntero = false;
  bool get mostrarPuntero => _mostrarPuntero;
  set mostrarPuntero(bool v) {
    _mostrarPuntero = v;
    notifyListeners();
  }

  ModoMirada _modo = ModoMirada.mirar;
  ModoMirada get modo => _modo;
  set modo(ModoMirada v) {
    _modo = v;
    _enPausa = false;
    _aplicarModo();
  }

  /// Los modos con los ojos necesitan la cámara; con el ratón se usa «Mirar».
  ModoMirada get modoEfectivo =>
      _fuente == FuenteMirada.camara ? _modo : ModoMirada.mirar;

  /// Pulsaciones desactivadas cerrando los ojos.
  bool _enPausa = false;
  bool get enPausa => _enPausa;

  /// Para enseñar en Ajustes si la cámara detecta los ojos cerrados.
  final ojosCerrados = ValueNotifier<bool>(false);

  Object? _objetivoParpadeo;
  StreamSubscription<double?>? _subOjos;
  final _relojOjos = Stopwatch();
  late final gestos = GestosOjos(
    alMantenerCerrados: () {
      if (_calibrando || modoEfectivo != ModoMirada.pausaOjos) return;
      _enPausa = !_enPausa;
      pitido(_enPausa ? 440 : 880);
      _aplicarModo();
    },
    // Se recuerda el control mirado al empezar: al parpadear la mirada baila.
    alEmpezarParpadeo: () => _objetivoParpadeo = controlador.bloqueado,
    alDobleParpadeo: () {
      final objetivo = _objetivoParpadeo;
      if (_calibrando ||
          modoEfectivo != ModoMirada.dobleParpadeo ||
          objetivo == null) {
        return;
      }
      pitido(660);
      controlador.activar(objetivo);
    },
  );

  void _aplicarModo() {
    controlador
      ..reiniciar()
      ..dwellActivo = modoEfectivo != ModoMirada.dobleParpadeo
      ..pausado = _calibrando || _enPausa;
    notifyListeners();
  }

  void _escucharOjos() {
    gestos.reiniciar();
    _crudas.clear();
    _relojOjos
      ..reset()
      ..start();
    _subOjos = camara.aperturas.listen((a) {
      gestos.procesar(a, _relojOjos.elapsed);
      ojosCerrados.value = gestos.cerrados;
    });
  }

  void _dejarDeEscucharOjos() {
    _subOjos?.cancel();
    _subOjos = null;
    gestos.reiniciar();
    ojosCerrados.value = false;
    _enPausa = false;
  }

  /// Últimas estimaciones sin corregir, para el reajuste rápido.
  final _crudas = <(Duration, Offset)>[];

  Offset _corregir(Offset m) {
    _crudas.add((_relojOjos.elapsed, m));
    if (_crudas.length > GazeConfig.muestrasSuavizado) _crudas.removeAt(0);
    return _dentro(correccion.aplicar(m));
  }

  /// Ctrl + clic reajusta la mirada (solo con la cámara en marcha).
  bool get reajustable =>
      _activo && !_calibrando && _fuente == FuenteMirada.camara;

  /// Reajuste rápido cuando se descalibra: el usuario mira [real] (el puntero
  /// del ratón) y se desplaza la corrección lo que falte. Devuelve false si
  /// no hay mirada reciente con la que comparar.
  bool reajustar(Offset real) {
    if (!reajustable) return false;
    final desde = _relojOjos.elapsed - GazeConfig.ventanaReajuste;
    final recientes = [
      for (final (t, m) in _crudas)
        if (t >= desde) m,
    ];
    if (recientes.length < GazeConfig.minimoReajuste) return false;
    final estimada = correccion.aplicar(CorreccionMirada.mediana(recientes));
    correccion = correccion.desplazada(real - estimada);
    // El suavizado guarda posiciones con la corrección anterior.
    controlador.reiniciar();
    controlador.punto.value = _dentro(real);
    return true;
  }

  bool _calibrando = false;
  bool get calibrando => _calibrando;

  /// Durante la calibración no se activa nada y la app ocupa toda la
  /// pantalla, para calibrar también los bordes.
  set calibrando(bool v) {
    if (v == _calibrando) return;
    _calibrando = v;
    _aplicarModo();
  }

  /// Margen que aparta la app del borde con el modo activo.
  EdgeInsets get margen {
    if (!_activo ||
        _calibrando ||
        !pantalla.isFinite ||
        pantalla.width < GazeConfig.anchoMinimoConMargen) {
      return EdgeInsets.zero;
    }
    return EdgeInsets.symmetric(
      horizontal: pantalla.width * GazeConfig.margenHorizontalMirada,
      vertical: pantalla.height * GazeConfig.margenVerticalMirada,
    );
  }

  /// Si la estimación se sale de la pantalla, se toma el punto del borde más
  /// cercano: mirar una esquina suele dar valores de fuera.
  Offset _dentro(Offset p) {
    final m = margen;
    return Offset(
      p.dx.clamp(m.left, pantalla.width - m.right),
      p.dy.clamp(m.top, pantalla.height - m.bottom),
    );
  }

  /// Cada petición de fuente invalida las anteriores que sigan pendientes.
  int _generacion = 0;

  double get ruidoRaton => raton.ruido;
  set ruidoRaton(double v) {
    raton.ruido = v;
    notifyListeners();
  }

  /// Hueco entre botones apilados: mayor con el modo mirada.
  double get separacionBotones => _activo ? GazeConfig.separacionMirada : 8;

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
      controlador.escuchar(raton, ajustar: _dentro);
      _aplicarModo();
      if (elegida == FuenteMirada.camara) await usarFuente(elegida);
    } else {
      esperandoCamara = false;
      await raton.detener();
      await camara.detener();
      controlador.dejarDeEscuchar();
      _dejarDeEscucharOjos();
      _aplicarModo();
    }
  }

  /// Cambia de fuente. Si la cámara no está disponible, se queda con el
  /// ratón y guarda el motivo en [motivoSinCamara].
  Future<void> usarFuente(FuenteMirada nueva) async {
    // Ya se está pidiendo: no se vuelve a pedir.
    if (nueva == FuenteMirada.camara && esperandoCamara) return;
    final generacion = ++_generacion;
    motivoSinCamara = null;
    if (nueva == FuenteMirada.raton) {
      esperandoCamara = false;
      await camara.detener();
      _fuente = FuenteMirada.raton;
      _dejarDeEscucharOjos();
      if (_activo) {
        await raton.iniciar();
        controlador.escuchar(raton, ajustar: _dentro);
      }
      _aplicarModo();
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
      // (Si se ha vuelto a pedir la cámara, la usa esa petición.)
      if (!esperandoCamara) await camara.detener();
      return;
    }
    await raton.detener();
    _fuente = FuenteMirada.camara;
    esperandoCamara = false;
    controlador.escuchar(
      camara,
      ajustar: _corregir,
      aceptar: () => gestos.miradaFiable(_relojOjos.elapsed),
    );
    _escucharOjos();
    _aplicarModo();
  }
}

/// Única instancia, compartida por la app. (Las pruebas la sustituyen para
/// usar una cámara simulada.)
GazeSettings mirada = GazeSettings();
