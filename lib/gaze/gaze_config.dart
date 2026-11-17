/// Parámetros del control por mirada (experimental). Todos en un sitio para
/// poder ajustarlos sin tocar la lógica.
abstract final class GazeConfig {
  /// Suavizado: media móvil de las últimas N muestras.
  static const int muestrasSuavizado = 12;

  /// Distancia máxima (px lógicos) de la mirada al rectángulo de un control
  /// para bloquearlo.
  static const double radioEntrada = 100;

  /// Una vez bloqueado, el control solo se suelta si la mirada se aleja más
  /// de esto…
  static const double radioSalida = 200;

  /// …durante más de este tiempo (histéresis). Mientras tanto el progreso
  /// del dwell se congela (no avanza mirando a otro sitio).
  static const Duration tiempoGracia = Duration(milliseconds: 400);

  /// Tiempo mirando un control bloqueado para activarlo.
  static const Duration dwell = Duration(milliseconds: 1500);

  /// Mirada estable (añadido a la especificación). Sin esto, al saltar con
  /// la vista de un control a otro, la media móvil «barre» los controles
  /// intermedios y bloquea uno de ellos, que luego no se suelta por la
  /// histéresis. Con esto:
  /// - una muestra suelta a más de [radioSalida] de la media se descarta
  ///   (valor atípico); tres seguidas son un salto de la vista y el
  ///   suavizado vuelve a empezar con ellas;
  /// - solo se bloquea un objetivo NUEVO con el buffer lleno y la media de su
  ///   mitad antigua a menos de [radioEntrada] de la de su mitad reciente.
  static const bool bloquearSoloConMiradaEstable = true;

  /// Tras activar un control, no se vuelve a activar hasta soltarlo (mirar
  /// a otro sitio). Evita repeticiones involuntarias.
  static const bool repetirSinSoltar = false;

  // Tras una activación tampoco se bloquea un control NUEVO hasta que la
  // mirada se aleja más de [radioEntrada] del punto de activación (si no,
  // tras navegar se activaría solo lo que quede bajo la vista en la pantalla
  // nueva). Detectado al probar en el navegador; ver gaze_controller.dart.

  /// Temblor simulado por defecto de la fuente de ratón (radio en px).
  static const double ruidoRatonPorDefecto = 30;

  /// Frecuencia de muestreo de la fuente de ratón.
  static const Duration periodoRaton = Duration(milliseconds: 33);

  /// Con el modo mirada activo: lado de los botones −/+ y hueco entre
  /// ellos y el valor. Con 64 px de hueco, el centro de «+» queda a más de
  /// [radioSalida] del borde de «−» (64 + 48 + 64 + 36 = 212 px), de modo que
  /// se puede pasar de uno a otro.
  static const double ladoBotonMirada = 72;
  static const double separacionMirada = 64;

  /// Hueco entre botones apilados (barra inferior, diálogos) en modo mirada.
  static const double separacionBotonesMirada = 32;
}
