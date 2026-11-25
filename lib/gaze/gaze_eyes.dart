import 'gaze_config.dart';

/// Cómo se pulsan los botones con la mirada.
enum ModoMirada {
  mirar('Mirar', 'Se pulsa el botón que miras durante 1,5 segundos.'),
  pausaOjos(
    'Mirar, con pausa',
    'Cierra los ojos casi un segundo, hasta oír el pitido, para poder mirar '
        'sin pulsar nada. Repítelo para volver a pulsar.',
  ),
  dobleParpadeo(
    'Doble parpadeo',
    'Se pulsa el botón que miras al parpadear dos veces seguidas, rápido.',
  );

  const ModoMirada(this.nombre, this.ayuda);
  final String nombre;
  final String ayuda;

  bool get usaOjos => this != mirar;
}

/// Decide si los ojos están abiertos o cerrados a partir de su apertura
/// (alto entre ancho del ojo, media de los dos), fotograma a fotograma.
class DetectorOjos {
  /// Apertura por debajo de la cual están cerrados, medida al calibrar. Sin
  /// calibrar se usa una fracción de la apertura habitual.
  double? umbral;

  double? _habitual;
  Duration? _sinCaraDesde;
  bool _cerrados = false;
  bool get cerrados => _cerrados;

  /// Umbral personal, o null si no se distinguen bien. [abiertos] es la
  /// apertura más pequeña con los ojos abiertos (mirando abajo se entornan).
  static double? umbralDe({
    required double abiertos,
    required double cerrados,
  }) => cerrados < abiertos * 0.8 ? (abiertos + cerrados) / 2 : null;

  void reiniciar() {
    _habitual = null;
    _sinCaraDesde = null;
    _cerrados = false;
  }

  /// Procesa una medida ([apertura] null = no se ve la cara). Devuelve true
  /// si la cara se ha perdido y lo que hubiera en curso no cuenta.
  bool procesar(double? apertura, Duration ahora) {
    if (apertura == null) {
      _sinCaraDesde ??= ahora;
      if (ahora - _sinCaraDesde! < const Duration(milliseconds: 500)) {
        return false;
      }
      _cerrados = false;
      return true;
    }
    _sinCaraDesde = null;
    final h = _habitual ?? apertura;
    // Sube deprisa y baja despacio: un parpadeo no la cambia.
    _habitual = _cerrados
        ? h
        : h + (apertura - h) * (apertura > h ? 0.2 : 0.02);
    final limite = umbral ?? _habitual! * GazeConfig.fraccionCerrados;
    // Para abrirse hace falta superar el límite con margen: no titubea.
    _cerrados = apertura < (_cerrados ? limite * 1.1 : limite);
    return false;
  }
}

/// Convierte abrir y cerrar los ojos en gestos: mantenerlos cerrados y el
/// doble parpadeo.
class GestosOjos {
  GestosOjos({
    required this.alMantenerCerrados,
    required this.alEmpezarParpadeo,
    required this.alDobleParpadeo,
  });

  /// Llevan cerrados [GazeConfig.tiempoPausaOjos] (una vez por cierre).
  final void Function() alMantenerCerrados;

  /// Primer cierre de un posible doble parpadeo.
  final void Function() alEmpezarParpadeo;
  final void Function() alDobleParpadeo;

  final detector = DetectorOjos();
  Duration? _cierre;
  Duration? _finPrimero;
  Duration? _apertura;
  bool _mantenido = false;
  bool _esSegundo = false;

  bool get cerrados => detector.cerrados;

  /// Con los ojos cerrados o recién abiertos la estimación no vale.
  bool miradaFiable(Duration ahora) =>
      !cerrados &&
      (_apertura == null || ahora - _apertura! >= GazeConfig.esperaTrasAbrir);

  void reiniciar() {
    detector.reiniciar();
    _cierre = _finPrimero = _apertura = null;
    _mantenido = _esSegundo = false;
  }

  void procesar(double? apertura, Duration ahora) {
    if (detector.procesar(apertura, ahora)) {
      _cierre = _finPrimero = null;
      return;
    }
    // Sin cara no se sabe: no avanza nada.
    if (apertura == null) return;
    if (cerrados) {
      if (_cierre == null) {
        _cierre = ahora;
        _mantenido = false;
        final fin = _finPrimero;
        _esSegundo =
            fin != null && ahora - fin <= GazeConfig.huecoEntreParpadeos;
        if (!_esSegundo) alEmpezarParpadeo();
      } else if (!_mantenido &&
          ahora - _cierre! >= GazeConfig.tiempoPausaOjos) {
        _mantenido = true;
        alMantenerCerrados();
      }
      return;
    }
    final cierre = _cierre;
    if (cierre == null) return;
    _cierre = null;
    _apertura = ahora;
    final corto = ahora - cierre <= GazeConfig.parpadeoMaximo;
    if (corto && _esSegundo) {
      _finPrimero = null;
      alDobleParpadeo();
    } else {
      _finPrimero = corto ? ahora : null;
    }
  }
}
