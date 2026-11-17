import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'gaze_config.dart';
import 'gaze_source.dart';

/// Un control que se puede activar con la mirada.
class ObjetivoMirada {
  ObjetivoMirada({required this.rect, required this.activar});

  /// Rectángulo visible en pantalla en este momento, o null si ahora no se
  /// puede mirar (fuera de pantalla, en una ruta tapada…).
  final Rect? Function() rect;

  /// Hace lo mismo que un toque.
  final VoidCallback activar;
}

/// Distancia de [p] al rectángulo [r] (0 si está dentro).
double distanciaARect(Offset p, Rect r) {
  final dx = [
    r.left - p.dx,
    0.0,
    p.dx - r.right,
  ].reduce((a, b) => a > b ? a : b);
  final dy = [
    r.top - p.dy,
    0.0,
    p.dy - r.bottom,
  ].reduce((a, b) => a > b ? a : b);
  return Offset(dx, dy).distance;
}

/// Lógica del control por mirada: suavizado, objetivo pegajoso con
/// histéresis y activación por permanencia (dwell).
///
/// Es independiente de la cámara: [procesar] recibe muestras y una marca de
/// tiempo, así que se prueba con muestras simuladas.
class GazeController extends ChangeNotifier {
  GazeController({
    this.muestrasSuavizado = GazeConfig.muestrasSuavizado,
    this.radioEntrada = GazeConfig.radioEntrada,
    this.radioSalida = GazeConfig.radioSalida,
    this.tiempoGracia = GazeConfig.tiempoGracia,
    this.dwell = GazeConfig.dwell,
    this.repetirSinSoltar = GazeConfig.repetirSinSoltar,
    this.bloquearSoloConMiradaEstable = GazeConfig.bloquearSoloConMiradaEstable,
  });

  final int muestrasSuavizado;
  final double radioEntrada;
  final double radioSalida;
  final Duration tiempoGracia;
  final Duration dwell;
  final bool repetirSinSoltar;
  final bool bloquearSoloConMiradaEstable;

  final _objetivos = <Object, ObjetivoMirada>{};
  final _ultimas = Queue<Offset>();
  final _lejanas = <Offset>[];

  /// Muestras seguidas lejos de la media que cuentan como salto de la vista.
  static const muestrasParaSalto = 3;

  Object? _bloqueado;
  Duration _acumulado = Duration.zero;
  Duration? _ultimaMarca;
  Duration? _fueraDesde;
  bool _yaActivado = false;

  /// Punto donde se activó el último control. Hasta que la mirada se aleje
  /// de él no se bloquea otro: si no, tras navegar, el control que quede
  /// bajo la vista en la pantalla nueva se activaría solo.
  Offset? _puntoActivacion;
  bool pausado = false;

  /// Control bloqueado ahora mismo (o null).
  Object? get bloqueado => _bloqueado;

  /// Progreso del dwell del control bloqueado, de 0 a 1.
  double get progreso => _bloqueado == null
      ? 0
      : (_acumulado.inMicroseconds / dwell.inMicroseconds).clamp(0, 1);

  /// Rectángulo del control bloqueado (para pruebas y depuración).
  @visibleForTesting
  Rect? get rectBloqueado => _objetivos[_bloqueado]?.rect();

  /// Rectángulos de todos los controles registrados (pruebas/depuración).
  @visibleForTesting
  List<Rect?> get rectsObjetivos => [
    for (final o in _objetivos.values) o.rect(),
  ];

  /// Última posición suavizada (para pruebas y depuración; no se dibuja).
  Offset? get posicion => _ultimas.isEmpty ? null : _media();

  void registrar(Object id, ObjetivoMirada objetivo) =>
      _objetivos[id] = objetivo;

  /// Se llama desde build/dispose de los widgets: no se notifica en el acto
  /// (el árbol de widgets está bloqueado) sino en una microtarea.
  void anularRegistro(Object id) {
    _objetivos.remove(id);
    if (_bloqueado == id) {
      _soltar(notificar: false);
      scheduleMicrotask(() {
        if (!_eliminado) notifyListeners();
      });
    }
  }

  bool _eliminado = false;

  /// Olvida el estado (al cambiar de fuente o desactivar el modo).
  void reiniciar() {
    _puntoActivacion = null;
    _ultimas.clear();
    _lejanas.clear();
    _soltar();
  }

  Offset _media() {
    var x = 0.0, y = 0.0;
    for (final m in _ultimas) {
      x += m.dx;
      y += m.dy;
    }
    return Offset(x / _ultimas.length, y / _ultimas.length);
  }

  /// La mirada está quieta: el buffer está lleno y la media de su mitad
  /// antigua y la de su mitad reciente están a menos de [radioEntrada]. Con
  /// un salto de la vista las dos mitades difieren mucho; con temblor, no.
  bool _estable() {
    // Sin suavizado (N = 1) no hay ventana que comparar.
    if (!bloquearSoloConMiradaEstable || muestrasSuavizado < 2) return true;
    if (_ultimas.length < muestrasSuavizado) return false;
    final lista = _ultimas.toList();
    final mitad = lista.length ~/ 2;
    Offset media(Iterable<Offset> ms) {
      var x = 0.0, y = 0.0;
      for (final m in ms) {
        x += m.dx;
        y += m.dy;
      }
      return Offset(x / ms.length, y / ms.length);
    }

    final antigua = media(lista.take(mitad));
    final reciente = media(lista.skip(mitad));
    return (antigua - reciente).distance <= radioEntrada;
  }

  /// Tiempo desde la muestra anterior.
  Duration _avanzarReloj(Duration ahora) {
    final dt = _ultimaMarca == null ? Duration.zero : ahora - _ultimaMarca!;
    _ultimaMarca = ahora;
    return dt;
  }

  void _soltar({bool notificar = true}) {
    final habia = _bloqueado != null;
    _bloqueado = null;
    _acumulado = Duration.zero;
    _fueraDesde = null;
    _yaActivado = false;
    if (habia && notificar) notifyListeners();
  }

  /// Control más cercano a [p] dentro de [radioEntrada], o null.
  Object? _masCercano(Offset p) {
    Object? mejor;
    var mejorDist = double.infinity;
    for (final MapEntry(key: id, value: o) in _objetivos.entries) {
      final r = o.rect();
      if (r == null || r.isEmpty) continue;
      final d = distanciaARect(p, r);
      if (d <= radioEntrada && d < mejorDist) {
        mejor = id;
        mejorDist = d;
      }
    }
    return mejor;
  }

  /// Procesa una muestra de mirada [muestra] tomada en el instante [ahora].
  void procesar(Offset muestra, Duration ahora) {
    // Si el control bloqueado ya no se ve (p. ej. lo tapa un diálogo o se ha
    // cambiado de pantalla), se suelta sin esperar la gracia.
    if (_bloqueado != null && _objetivos[_bloqueado]?.rect() == null) {
      _soltar();
    }
    // Muestras lejos de la media (> radioSalida): una suelta es un valor
    // atípico y se descarta; varias seguidas son un salto de la vista y el
    // suavizado vuelve a empezar con ellas (así no se arrastra la posición
    // antigua, que «barrería» los controles intermedios).
    if (bloquearSoloConMiradaEstable &&
        muestrasSuavizado >= 2 &&
        _ultimas.isNotEmpty &&
        (muestra - _media()).distance > radioSalida) {
      _lejanas.add(muestra);
      if (_lejanas.length < muestrasParaSalto) {
        _avanzarReloj(ahora);
        return;
      }
      _ultimas
        ..clear()
        ..addAll(_lejanas);
      _lejanas.clear();
    } else {
      _lejanas.clear();
      _ultimas.addLast(muestra);
    }
    while (_ultimas.length > muestrasSuavizado) {
      _ultimas.removeFirst();
    }
    final p = _media();
    final dt = _avanzarReloj(ahora);
    if (pausado) return;

    // 1. Mantener o soltar el objetivo bloqueado (histéresis).
    if (_bloqueado != null) {
      final r = _objetivos[_bloqueado]!.rect()!;
      final d = distanciaARect(p, r);
      if (d <= radioSalida) {
        _fueraDesde = null;
      } else {
        _fueraDesde ??= ahora;
        if (ahora - _fueraDesde! > tiempoGracia) _soltar();
      }
    }

    // 2. Sin objetivo: bloquear el más cercano dentro del radio de entrada
    //    (solo con la mirada estable, ver GazeConfig).
    if (_bloqueado == null) {
      // Rearme tras una activación (ver _puntoActivacion).
      if (_puntoActivacion != null) {
        if ((p - _puntoActivacion!).distance <= radioEntrada) return;
        _puntoActivacion = null;
      }
      final nuevo = _estable() ? _masCercano(p) : null;
      if (nuevo != null) {
        _bloqueado = nuevo;
        _acumulado = Duration.zero;
        notifyListeners();
      }
      return;
    }

    // 3. Dwell: avanza solo mientras la mirada está dentro del radio de
    //    salida (durante la gracia se congela).
    if (_fueraDesde != null || _yaActivado) return;
    _acumulado += dt;
    if (_acumulado >= dwell) {
      final objetivo = _objetivos[_bloqueado];
      if (repetirSinSoltar) {
        _acumulado = Duration.zero;
      } else {
        _yaActivado = true;
        _acumulado = dwell;
      }
      _puntoActivacion = p;
      notifyListeners();
      objetivo?.activar();
    } else {
      notifyListeners();
    }
  }

  // --- Conexión con una fuente real ---------------------------------------

  StreamSubscription<Offset>? _sub;
  final _reloj = Stopwatch();

  /// Empieza a escuchar [fuente]. Las marcas de tiempo salen de un reloj
  /// propio.
  void escuchar(GazeSource fuente) {
    _sub?.cancel();
    reiniciar();
    _reloj
      ..reset()
      ..start();
    _sub = fuente.muestras.listen((m) => procesar(m, _reloj.elapsed));
  }

  void dejarDeEscuchar() {
    _sub?.cancel();
    _sub = null;
    _reloj.stop();
    reiniciar();
  }

  @override
  void dispose() {
    _eliminado = true;
    _sub?.cancel();
    super.dispose();
  }
}
