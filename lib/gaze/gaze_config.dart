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

  /// Decidir entre controles vecinos (cambia la especificación inicial, en
  /// la que un control a menos de [radioSalida] no se podía alcanzar sin
  /// apartar antes la vista):
  /// - un control gana a otro si está más cerca por al menos este margen; si
  ///   la mirada cae entre dos sin ganador, no se bloquea ninguno;
  /// - mientras un vecino gana al bloqueado, el dwell se congela;
  /// - si además la mirada está sobre el vecino (a [radioCambio] o menos)
  ///   durante [tiempoCambio], pasa a ser el bloqueado y el dwell empieza.
  static const double margenDecision = 24;
  static const double radioCambio = 30;
  static const Duration tiempoCambio = Duration(milliseconds: 400);

  /// Con el modo activo: tamaño mínimo de cada control y hueco entre
  /// controles vecinos (filas, casillas, −/+, barra inferior, diálogos).
  static const double ladoMinimoMirada = 88;
  static const double separacionMirada = 72;

  /// Filas de las listas (listas, productos, resultados y casillas): más
  /// altas y más separadas. Una cámara web con WebGazer se equivoca unos
  /// 100–150 px, así que entre los centros de dos filas debe haber unos 250.
  static const double altoFilaMirada = 96;
  static const double separacionFilasMirada = 160;

  /// Selector de unidades: lado de «−» y «+» si hay ancho, y hueco máximo
  /// entre cada uno y el valor (se reduce si no cabe).
  static const double ladoUnidadesMirada = 112;
  static const double separacionUnidadesMirada = 200;

  /// Ojos cerrados este tiempo: pausa o reanuda las pulsaciones (modo
  /// «Mirar, con pausa»). Un parpadeo normal es bastante más corto.
  static const Duration tiempoPausaOjos = Duration(milliseconds: 800);

  /// Doble parpadeo: duración máxima de cada uno y tiempo máximo entre ellos.
  static const Duration parpadeoMaximo = Duration(milliseconds: 450);
  static const Duration huecoEntreParpadeos = Duration(milliseconds: 600);

  /// Tras abrir los ojos se ignora la mirada este tiempo: la estimación
  /// tarda en asentarse.
  static const Duration esperaTrasAbrir = Duration(milliseconds: 250);

  /// Sin calibrar los ojos: se consideran cerrados por debajo de esta
  /// fracción de su apertura habitual.
  static const double fraccionCerrados = 0.6;

  /// Distancia a la cámara recomendada (la habitual en los estudios con
  /// cámara web) y datos para estimarla: distancia media entre las comisuras
  /// externas de los ojos y ángulo de visión horizontal típico de una cámara.
  /// Es aproximada: depende de la cámara y de la persona.
  static const double distanciaMinCm = 50;
  static const double distanciaMaxCm = 70;
  static const double anchoOjosCm = 9;
  static const double anguloCamaraGrados = 65;

  /// Diámetro del puntero opcional que marca dónde se estima la mirada.
  static const double ladoPuntero = 32;

  /// Con el modo activo en pantallas de al menos [anchoMinimoConMargen], la
  /// app se aparta del borde esta fracción del ancho y del alto: en los bordes
  /// y esquinas la estimación de la mirada es peor.
  static const double anchoMinimoConMargen = 600;
  static const double margenHorizontalMirada = 0.06;
  static const double margenVerticalMirada = 0.03;

  /// Ancho del carril con los botones «Subir» y «Bajar» (la mirada no puede
  /// arrastrar la pantalla) y parte visible que desplaza cada activación.
  static const double anchoCarrilMirada = 96;
  static const double fraccionDesplazamiento = 0.7;
}
