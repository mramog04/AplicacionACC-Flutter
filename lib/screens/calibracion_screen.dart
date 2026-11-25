import 'dart:async';

import 'package:flutter/material.dart';

import '../gaze/gaze_correction.dart';
import '../gaze/gaze_eyes.dart';
import '../gaze/gaze_settings.dart';
import '../gaze/sonido_stub.dart'
    if (dart.library.js_interop) '../gaze/sonido_web.dart';
import '../router.dart';
import '../theme.dart';
import '../widgets/avisos.dart';
import '../widgets/indicador_distancia.dart';
import '../widgets/pantalla_base.dart';

/// Calibración de la cámara para el modo mirada, a pantalla completa:
///
/// 0. Colocarse: distancia a la cámara y «Empezar».
/// 1. 9 puntos que llegan hasta los bordes y las esquinas: mirar cada uno y
///    hacer 5 clics. Cada clic le dice a WebGazer «ahora miro aquí».
/// 2. Ajuste de bordes: mirar 5 puntos sin hacer clic. Se compara lo
///    estimado con el punto real y se corrige (ver [CorreccionMirada]).
/// 3. Cerrar los ojos hasta oír un pitido, para distinguirlos de abiertos
///    (también mirando abajo, que es cuando más se entornan).
///
/// Mientras tanto la activación por mirada está en pausa.
class CalibracionScreen extends StatefulWidget {
  const CalibracionScreen({super.key});

  static const clicsPorPunto = 5;

  /// Posiciones relativas (x, y) de los 9 puntos: 0 y 1 son los bordes.
  static const puntos = [
    (0.0, 0.0), (0.5, 0.0), (1.0, 0.0), //
    (0.0, 0.5), (0.5, 0.5), (1.0, 0.5), //
    (0.0, 1.0), (0.5, 1.0), (1.0, 1.0),
  ];

  /// Puntos del ajuste de bordes: el centro y las cuatro esquinas.
  static const puntosAjuste = [
    (0.5, 0.5),
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ];

  /// Tiempo para llevar la vista al punto, y tiempo midiendo.
  static const esperaAjuste = Duration(milliseconds: 1000);
  static const medidaAjuste = Duration(milliseconds: 1500);
  static const minimoMuestras = 5;

  @override
  State<CalibracionScreen> createState() => _CalibracionScreenState();
}

class _CalibracionScreenState extends State<CalibracionScreen> {
  static const _lado = 64.0;
  static const _borde = 8.0;

  bool _empezada = false;
  int _punto = 0;
  int _clics = 0;
  int _ajuste = 0;
  bool _midiendo = false;
  Timer? _timer;
  StreamSubscription<Offset>? _sub;
  final _muestras = <Offset>[];
  final _pares = <(Offset, Offset)>[];
  StreamSubscription<double?>? _subOjos;
  final _aperturas = <double>[];
  final _abiertos = <double>[];
  bool _ojosMedidos = false;

  bool get _enClics => _punto < CalibracionScreen.puntos.length;
  bool get _enAjuste =>
      !_enClics && _ajuste < CalibracionScreen.puntosAjuste.length;
  bool get _terminada => !_enClics && !_enAjuste && _ojosMedidos;

  @override
  void initState() {
    super.initState();
    mirada.camara.empezarCalibracion();
    mirada.correccion = CorreccionMirada.identidad;
    mirada.gestos.detector.umbral = null;
    // Tras el primer fotograma: notifica a la raíz de la app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) mirada.calibrando = true;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    _subOjos?.cancel();
    // Aplazado: durante dispose no se puede notificar.
    scheduleMicrotask(() => mirada.calibrando = false);
    super.dispose();
  }

  Offset _centro((double, double) f) {
    final t = MediaQuery.sizeOf(context);
    const m = _borde + _lado / 2;
    return Offset(m + (t.width - 2 * m) * f.$1, m + (t.height - 2 * m) * f.$2);
  }

  void _clic() {
    mirada.camara.registrarCalibracion(
      _centro(CalibracionScreen.puntos[_punto]),
    );
    setState(() {
      _clics++;
      if (_clics >= CalibracionScreen.clicsPorPunto) {
        _clics = 0;
        _punto++;
      }
    });
    if (!_enClics) _empezarPuntoAjuste();
  }

  void _medirOjos() {
    _aperturas.clear();
    _subOjos = mirada.camara.aperturas.listen((a) {
      if (a != null) _aperturas.add(a);
    });
  }

  /// Mediana de lo medido, o null si hay muy pocas medidas.
  double? _acabarOjos() {
    _subOjos?.cancel();
    if (_aperturas.length < CalibracionScreen.minimoMuestras) return null;
    _aperturas.sort();
    return _aperturas[_aperturas.length ~/ 2];
  }

  void _empezarOjosCerrados() {
    _timer = Timer(CalibracionScreen.esperaAjuste, () {
      _medirOjos();
      _timer = Timer(CalibracionScreen.medidaAjuste, () {
        final cerrados = _acabarOjos();
        if (cerrados != null && _abiertos.isNotEmpty) {
          mirada.gestos.detector.umbral = DetectorOjos.umbralDe(
            abiertos: _abiertos.reduce((a, b) => a < b ? a : b),
            cerrados: cerrados,
          );
        }
        pitido(880);
        setState(() => _ojosMedidos = true);
      });
    });
  }

  void _empezarPuntoAjuste() {
    _muestras.clear();
    _midiendo = false;
    _timer = Timer(CalibracionScreen.esperaAjuste, () {
      setState(() => _midiendo = true);
      _sub = mirada.camara.muestras.listen(_muestras.add);
      _medirOjos();
      _timer = Timer(CalibracionScreen.medidaAjuste, _acabarPuntoAjuste);
    });
  }

  void _acabarPuntoAjuste() {
    _sub?.cancel();
    if (_muestras.length >= CalibracionScreen.minimoMuestras) {
      _pares.add((
        _centro(CalibracionScreen.puntosAjuste[_ajuste]),
        CorreccionMirada.mediana(_muestras),
      ));
    }
    if (_acabarOjos() case final abiertos?) _abiertos.add(abiertos);
    setState(() => _ajuste++);
    if (!_enAjuste) {
      mirada.correccion = CorreccionMirada.ajustar(_pares);
      _empezarOjosCerrados();
    } else {
      _empezarPuntoAjuste();
    }
  }

  void _empezar() {
    mirada.distanciaCalibrada = mirada.camara.distanciaCm;
    setState(() => _empezada = true);
  }

  String get _instruccion {
    if (!_empezada) {
      return 'Siéntate de frente, con luz delante, y mantén la misma postura '
          'durante toda la calibración y después.';
    }
    if (_terminada) {
      return _pares.length < 3
          ? 'Calibración terminada, pero no se ha detectado bien tu mirada. '
                'Comprueba la luz y que se te vea la cara, y repítela.'
          : mirada.gestos.detector.umbral == null
          ? 'Calibración terminada. No se distinguen bien tus ojos cerrados: '
                'los modos que los usan pueden fallar.'
          : 'Calibración terminada.';
    }
    if (!_enClics && !_enAjuste) {
      return 'Cierra los ojos y no los abras hasta oír el pitido.';
    }
    if (!_enClics) {
      return 'Ajuste de bordes, ${_ajuste + 1} de '
          '${CalibracionScreen.puntosAjuste.length}: mira el círculo sin '
          'hacer clic ni mover la cabeza.';
    }
    final faltan = CalibracionScreen.clicsPorPunto - _clics;
    return 'Punto ${_punto + 1} de ${CalibracionScreen.puntos.length}: '
        'mira el círculo y haz clic en él. '
        '${faltan == 1 ? 'Falta 1 clic' : 'Faltan $faltan clics'}.';
  }

  @override
  Widget build(BuildContext context) {
    final actual = !_empezada || (!_enClics && !_enAjuste)
        ? null
        : _enClics
        ? CalibracionScreen.puntos[_punto]
        : CalibracionScreen.puntosAjuste[_ajuste];
    final centro = actual == null ? null : _centro(actual);
    return Scaffold(
      body: Stack(
        children: [
          // El texto va en la mitad de la pantalla donde no está el punto.
          Align(
            alignment: Alignment(0, (actual?.$2 ?? 1) >= 0.5 ? -0.45 : 0.45),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: _lado + 2 * AppSizes.margen,
                vertical: AppSizes.margen,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TituloPantalla('Calibración', centrado: true),
                  const SizedBox(height: AppSizes.separacion),
                  RegionViva(
                    mensaje: _instruccion,
                    anunciarAlAparecer: false,
                    child: Text(_instruccion, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: AppSizes.margen),
                  if (!_empezada) ...[
                    const IndicadorDistancia(),
                    const SizedBox(height: AppSizes.margen),
                    FilledButton(
                      onPressed: _empezar,
                      child: const Text('Empezar'),
                    ),
                    const SizedBox(height: AppSizes.margen),
                  ],
                  BotonAtras(
                    alternativa: Rutas.ajustes,
                    texto: _terminada ? 'Volver a Ajustes' : 'Cancelar',
                  ),
                ],
              ),
            ),
          ),
          if (centro != null)
            Positioned(
              left: centro.dx - _lado / 2,
              top: centro.dy - _lado / 2,
              width: _lado,
              height: _lado,
              child: _enClics
                  ? _Punto(
                      clicsQueFaltan: CalibracionScreen.clicsPorPunto - _clics,
                      alPulsar: _clic,
                    )
                  : _PuntoMirar(midiendo: _midiendo),
            ),
        ],
      ),
    );
  }
}

/// Círculo de calibración: botón de 64 px con los clics que faltan.
class _Punto extends StatelessWidget {
  const _Punto({required this.clicsQueFaltan, required this.alPulsar});

  final int clicsQueFaltan;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Punto de calibración, faltan $clicsQueFaltan clics',
      excludeSemantics: true,
      onTap: alPulsar,
      child: FilledButton(
        onPressed: alPulsar,
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Text('$clicsQueFaltan'),
      ),
    );
  }
}

/// Círculo que solo hay que mirar; mientras mide se rellena y lleva un ojo.
class _PuntoMirar extends StatelessWidget {
  const _PuntoMirar({required this.midiendo});

  final bool midiendo;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: midiendo ? AppColors.acento : AppColors.fondo,
          border: Border.all(color: AppColors.acento, width: 5),
        ),
        child: Icon(
          midiendo ? Icons.visibility : Icons.circle,
          size: midiendo ? 32 : 12,
          color: midiendo ? AppColors.blanco : AppColors.acento,
        ),
      ),
    );
  }
}
