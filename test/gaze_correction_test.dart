// Bordes y esquinas: corrección de la mirada, límites de pantalla y
// calibración a pantalla completa.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lista_compra/gaze/gaze_correction.dart';
import 'package:lista_compra/gaze/gaze_distance.dart';
import 'package:lista_compra/gaze/gaze_settings.dart';
import 'package:lista_compra/gaze/gaze_source.dart';
import 'package:lista_compra/gaze/gaze_controller.dart';
import 'package:lista_compra/router.dart';

import 'helpers.dart';

class CamaraFija implements GazeSource {
  final c = StreamController<Offset>.broadcast(sync: true);

  @override
  String get nombre => 'Cámara fija';
  @override
  Stream<Offset> get muestras => c.stream;
  @override
  Future<void> iniciar() async {}
  @override
  Future<void> detener() async {}
  @override
  double? distanciaCm;
  @override
  void empezarCalibracion() {}
  @override
  void registrarCalibracion(Offset posicion) {}
}

void main() {
  const pantalla = Size(1280, 800);
  const centro = Offset(640, 400);
  final reales = [
    centro,
    const Offset(40, 40),
    const Offset(1240, 40),
    const Offset(1240, 760),
    const Offset(40, 760),
  ];

  test('La corrección deshace una mirada encogida y desplazada', () {
    Offset estimar(Offset p) =>
        centro + (p - centro) * 0.6 + const Offset(30, -20);
    final c = CorreccionMirada.ajustar([
      for (final p in reales) (p, estimar(p)),
    ]);
    for (final p in reales) {
      expect((c.aplicar(estimar(p)) - p).distance, lessThan(1));
    }
  });

  test('Sin datos fiables no corrige', () {
    expect(CorreccionMirada.ajustar([]).ax, 1);
    final quieta = CorreccionMirada.ajustar([
      for (final p in reales) (p, centro),
    ]);
    expect(quieta.aplicar(const Offset(5, 7)), const Offset(5, 7));
    final invertida = CorreccionMirada.ajustar([
      for (final p in reales) (p, Offset(1280 - p.dx, 800 - p.dy)),
    ]);
    expect(invertida.ax, 1);
  });

  test('La mediana ignora un valor atípico', () {
    expect(
      CorreccionMirada.mediana(const [
        Offset(10, 10),
        Offset(11, 11),
        Offset(5000, -900),
      ]),
      const Offset(11, 10),
    );
  });

  test('Una estimación fuera de la pantalla cuenta como el borde', () async {
    final camara = CamaraFija();
    final a = GazeSettings(disponible: true, camara: camara)
      ..pantalla = pantalla;
    a.controlador.registrar(
      'esquina',
      ObjetivoMirada(
        rect: () => const Rect.fromLTWH(93, 48, 104, 88),
        activar: () {},
      ),
    );
    await a.activar(true);
    await a.usarFuente(FuenteMirada.camara);
    for (var i = 0; i < 14; i++) {
      camara.c.add(const Offset(-260, -180));
    }
    expect(a.controlador.bloqueado, 'esquina');
    await a.activar(false);
  });

  test(
    'El margen solo se aplica con el modo activo, ancho y sin calibrar',
    () async {
      final a = GazeSettings(disponible: true, camara: CamaraFija())
        ..pantalla = pantalla;
      expect(a.margen, EdgeInsets.zero);
      await a.activar(true);
      expect(a.margen.left, greaterThan(60));
      expect(a.margen.top, 24);
      a.calibrando = true;
      expect(a.margen, EdgeInsets.zero);
      a.calibrando = false;
      a.pantalla = const Size(412, 915);
      expect(a.margen, EdgeInsets.zero);
      await a.activar(false);
    },
  );

  test('Distancia: el doble de separación entre los ojos, la mitad', () {
    final d = estimarDistanciaCm(separacionOjosPx: 75, anchoImagenPx: 640)!;
    expect(d, closeTo(60, 3));
    expect(
      estimarDistanciaCm(separacionOjosPx: 150, anchoImagenPx: 640),
      closeTo(d / 2, 0.01),
    );
    expect(estimarDistanciaCm(separacionOjosPx: 0, anchoImagenPx: 640), isNull);
    expect(EstadoDistancia.de(null), EstadoDistancia.sinCara);
    expect(EstadoDistancia.de(40), EstadoDistancia.cerca);
    expect(EstadoDistancia.de(60), EstadoDistancia.bien);
    expect(EstadoDistancia.de(90), EstadoDistancia.lejos);
  });

  testWidgets('El puntero solo aparece si se pide y sigue a la mirada', (
    tester,
  ) async {
    mirada.disponible = true;
    addTearDown(() => mirada.disponible = false);
    await arrancar(tester);
    await mirada.activar(true);
    await mirada.raton.detener();
    final puntero = find.byKey(const ValueKey('puntero-mirada'));
    Future<void> mirar(Offset p) async {
      for (var i = 0; i < 14; i++) {
        mirada.controlador.procesar(p, Duration(milliseconds: i));
      }
      await tester.pump();
    }

    await mirar(const Offset(200, 700));
    expect(puntero, findsNothing);
    mirada.mostrarPuntero = true;
    await tester.pump();
    expect(tester.getCenter(puntero), const Offset(200, 700));
    await mirar(const Offset(100, 650));
    expect(tester.getCenter(puntero), const Offset(100, 650));
    // No intercepta toques ni añade nodos semánticos.
    expect(puntero.hitTestable(), findsNothing);
    mirada.mostrarPuntero = false;
    await mirada.activar(false);
  });

  testWidgets('La calibración llega a las cuatro esquinas y termina', (
    tester,
  ) async {
    mirada.disponible = true;
    addTearDown(() => mirada.disponible = false);
    await arrancar(tester, ruta: Rutas.ajustes);
    tester.view.physicalSize = pantalla;
    await mirada.activar(true);
    await mirada.raton.detener();
    appRouter.go(Rutas.calibracion);
    await asentar(tester);
    expect(mirada.controlador.pausado, isTrue);
    expect(find.bySemanticsLabel(RegExp('No se ve tu cara')), findsOne);
    await tester.tap(find.bySemanticsLabel('Empezar'));
    await asentar(tester);

    final centros = <Offset>[];
    for (var p = 0; p < 9; p++) {
      for (var k = 0; k < 5; k++) {
        final f = find.bySemanticsLabel(RegExp('^Punto de calibración'));
        expect(f.hitTestable(), findsOne);
        if (k == 0) centros.add(tester.getCenter(f));
        await tester.tap(f);
        await tester.pump();
      }
    }
    for (final e in const [
      Offset(40, 40),
      Offset(1240, 40),
      Offset(40, 760),
      Offset(1240, 760),
    ]) {
      expect(centros, contains(e));
    }
    expect(
      find.bySemanticsLabel(RegExp('^Ajuste de bordes, 1 de 5')),
      findsOne,
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    // Sin cámara no hay muestras: termina y lo dice.
    expect(
      find.bySemanticsLabel(RegExp('no se ha detectado bien tu mirada')),
      findsOne,
    );
    await tester.tap(find.bySemanticsLabel('Volver a Ajustes'));
    await asentar(tester);
    expect(mirada.controlador.pausado, isFalse);
    expect(tester.takeException(), isNull);
    await mirada.activar(false);
  });
}
