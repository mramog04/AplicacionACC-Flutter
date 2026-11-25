// Modos con los ojos: detección de ojos cerrados, pausa manteniéndolos
// cerrados y doble parpadeo, con aperturas simuladas.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lista_compra/gaze/gaze_controller.dart';
import 'package:lista_compra/gaze/gaze_eyes.dart';
import 'package:lista_compra/gaze/gaze_settings.dart';
import 'package:lista_compra/gaze/gaze_source.dart';
import 'package:lista_compra/router.dart';

import 'helpers.dart';

const abierto = 0.30;
const abajo = 0.22; // mirando hacia abajo
const cerrado = 0.12;

class Registro {
  Registro({double? umbral}) {
    g.detector.umbral = umbral;
    pasar(abierto, 1000);
  }

  final eventos = <String>[];
  Duration t = Duration.zero;
  late final g = GestosOjos(
    alMantenerCerrados: () => eventos.add('mantener'),
    alEmpezarParpadeo: () {},
    alDobleParpadeo: () => eventos.add('doble'),
  );

  void pasar(double? apertura, int ms) {
    for (final fin = t + Duration(milliseconds: ms); t < fin;) {
      g.procesar(apertura, t);
      t += const Duration(milliseconds: 33);
    }
  }
}

class CamaraOjos implements GazeSource {
  final m = StreamController<Offset>.broadcast(sync: true);
  final o = StreamController<double?>.broadcast(sync: true);

  @override
  String get nombre => 'Cámara con ojos';
  @override
  Stream<Offset> get muestras => m.stream;
  @override
  Stream<double?> get aperturas => o.stream;
  @override
  double? get distanciaCm => null;
  @override
  Future<void> iniciar() async {}
  @override
  Future<void> detener() async {}
  @override
  void empezarCalibracion() {}
  @override
  void registrarCalibracion(Offset posicion) {}
}

void main() {
  test('Mantener los ojos cerrados salta una sola vez por cierre', () {
    final r = Registro()..pasar(cerrado, 700);
    expect(r.eventos, isEmpty, reason: 'aún no llega a 0,8 s');
    r.pasar(cerrado, 200);
    expect(r.eventos, ['mantener']);
    r.pasar(cerrado, 3000);
    expect(r.eventos, ['mantener']);
    r
      ..pasar(abierto, 600)
      ..pasar(cerrado, 900);
    expect(r.eventos, ['mantener', 'mantener']);
  });

  test('Un parpadeo normal no hace nada', () {
    final r = Registro();
    for (var i = 0; i < 4; i++) {
      r
        ..pasar(cerrado, 150)
        ..pasar(abierto, 2500);
    }
    expect(r.eventos, isEmpty);
  });

  test('Dos parpadeos rápidos seguidos son un doble parpadeo', () {
    final r = Registro()
      ..pasar(cerrado, 130)
      ..pasar(abierto, 250)
      ..pasar(cerrado, 130)
      ..pasar(abierto, 1000);
    expect(r.eventos, ['doble']);
    // Tres seguidos: el tercero no vuelve a pulsar.
    r
      ..pasar(cerrado, 130)
      ..pasar(abierto, 200)
      ..pasar(cerrado, 130)
      ..pasar(abierto, 200)
      ..pasar(cerrado, 130)
      ..pasar(abierto, 1000);
    expect(r.eventos, ['doble', 'doble']);
  });

  test('Dos parpadeos separados, o uno largo y otro corto, no lo son', () {
    final r = Registro()
      ..pasar(cerrado, 130)
      ..pasar(abierto, 900)
      ..pasar(cerrado, 130)
      ..pasar(abierto, 2000)
      ..pasar(cerrado, 600)
      ..pasar(abierto, 200)
      ..pasar(cerrado, 130)
      ..pasar(abierto, 1000);
    expect(r.eventos, isEmpty);
  });

  test('Mirar hacia abajo no se confunde con cerrar los ojos', () {
    final umbral = DetectorOjos.umbralDe(abiertos: abajo, cerrados: cerrado);
    expect(umbral, closeTo(0.17, 0.001));
    final r = Registro(umbral: umbral)..pasar(abajo, 5000);
    expect(r.g.cerrados, isFalse);
    expect(r.eventos, isEmpty);
    r.pasar(cerrado, 900);
    expect(r.eventos, ['mantener']);
  });

  test('Si no se distinguen, no hay umbral personal', () {
    expect(DetectorOjos.umbralDe(abiertos: 0.2, cerrados: 0.18), isNull);
  });

  test('Perder la cara no cuenta como ojos cerrados', () {
    final r = Registro()
      ..pasar(cerrado, 300)
      ..pasar(null, 3000)
      ..pasar(abierto, 500);
    expect(r.eventos, isEmpty);
  });

  test('Con los ojos cerrados o recién abiertos la mirada no vale', () {
    final r = Registro();
    expect(r.g.miradaFiable(r.t), isTrue);
    r.pasar(cerrado, 100);
    expect(r.g.miradaFiable(r.t), isFalse);
    r.pasar(abierto, 100);
    expect(r.g.miradaFiable(r.t), isFalse);
    r.pasar(abierto, 300);
    expect(r.g.miradaFiable(r.t), isTrue);
  });

  group('En los ajustes', () {
    late CamaraOjos camara;
    late GazeSettings a;
    late int pulsado;

    setUp(() async {
      camara = CamaraOjos();
      a = GazeSettings(disponible: true, camara: camara)
        ..pantalla = const Size(500, 800);
      pulsado = 0;
      a.controlador.registrar(
        'b',
        ObjetivoMirada(
          rect: () => const Rect.fromLTWH(100, 100, 200, 100),
          activar: () => pulsado++,
        ),
      );
      await a.activar(true);
      await a.usarFuente(FuenteMirada.camara);
    });
    tearDown(() => a.activar(false));

    var t = Duration.zero;
    void mirar(int ms) {
      for (final fin = t + Duration(milliseconds: ms); t < fin;) {
        t += const Duration(milliseconds: 33);
        a.controlador.procesar(const Offset(200, 150), t);
      }
    }

    test('modo mirar: cerrar los ojos no pausa', () {
      a.gestos.alMantenerCerrados();
      expect(a.enPausa, isFalse);
      mirar(2200);
      expect(pulsado, 1);
    });

    test('modo con pausa: pausar, no pulsa; reanudar, pulsa', () {
      a.modo = ModoMirada.pausaOjos;
      a.gestos.alMantenerCerrados();
      expect(a.enPausa, isTrue);
      mirar(4000);
      expect(pulsado, 0);
      expect(a.controlador.punto.value, isNotNull, reason: 'el puntero sigue');
      a.gestos.alMantenerCerrados();
      expect(a.enPausa, isFalse);
      mirar(2200);
      expect(pulsado, 1);
    });

    test('doble parpadeo: mirar no pulsa, parpadear sí', () {
      a.modo = ModoMirada.dobleParpadeo;
      mirar(5000);
      expect(a.controlador.bloqueado, 'b');
      expect(pulsado, 0);
      a.gestos.alEmpezarParpadeo();
      a.gestos.alDobleParpadeo();
      expect(pulsado, 1);
    });

    test('doble parpadeo sin mirar ningún botón no hace nada', () {
      a.modo = ModoMirada.dobleParpadeo;
      a.gestos.alEmpezarParpadeo();
      a.gestos.alDobleParpadeo();
      expect(pulsado, 0);
    });

    test('con el ratón se usa «mirar» y la pausa se quita', () async {
      a.modo = ModoMirada.pausaOjos;
      a.gestos.alMantenerCerrados();
      await a.usarFuente(FuenteMirada.raton);
      expect(a.enPausa, isFalse);
      expect(a.modoEfectivo, ModoMirada.mirar);
      expect(a.controlador.pausado, isFalse);
    });

    test('la cámara entrega la apertura de los ojos', () {
      camara.o.add(abierto);
      camara.o.add(cerrado);
      expect(a.ojosCerrados.value, isTrue);
    });
  });

  testWidgets('Los tres modos están en Ajustes, con su explicación', (
    tester,
  ) async {
    mirada.disponible = true;
    addTearDown(() => mirada.disponible = false);
    await arrancar(tester, ruta: Rutas.ajustes);
    await mirada.activar(true);
    await mirada.raton.detener();
    await asentar(tester);
    await tocar(tester, RegExp(r'^Doble parpadeo'));
    expect(mirada.modo, ModoMirada.dobleParpadeo);
    await nodo(tester, RegExp('Este modo necesita la cámara'));
    await tocar(tester, RegExp(r'^Mirar, con pausa'));
    expect(mirada.modo, ModoMirada.pausaOjos);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    mirada.modo = ModoMirada.mirar;
    await mirada.activar(false);
  });
}
