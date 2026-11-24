// Modo mirada dentro de la app, con muestras simuladas (sin cámara).

import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lista_compra/gaze/gaze_settings.dart';
import 'package:lista_compra/gaze/gaze_source.dart';
import 'package:lista_compra/router.dart';

import 'helpers.dart';

/// Activa el modo con la fuente de ratón parada: las muestras las manda la
/// prueba con [mirarA].
Future<void> activarMirada(WidgetTester tester) async {
  addTearDown(desactivarMirada);
  mirada.disponible = true;
  await mirada.activar(true);
  await mirada.raton.detener();
  mirada.controlador.reiniciar();
  await asentar(tester);
}

Future<void> desactivarMirada() async {
  await mirada.activar(false);
  mirada
    ..disponible = false
    ..privacidadAceptada = false
    ..motivoSinCamara = null;
}

var _t = Duration.zero;

/// Mira el centro del control con esa etiqueta durante [ms] milisegundos.
Future<void> mirarA(WidgetTester tester, Pattern etiqueta, int ms) async {
  // El modo mirada no desplaza la pantalla: si el control no se ve, la
  // prueba hace scroll antes (como haría el usuario con otro medio).
  final centro = tester.getCenter(
    await mostrar(tester, find.bySemanticsLabel(etiqueta)),
  );
  for (final fin = _t + Duration(milliseconds: ms); _t < fin;) {
    _t += const Duration(milliseconds: 33);
    mirada.controlador.procesar(centro, _t);
  }
  await asentar(tester);
}

/// Mira a un sitio sin controles para soltar el objetivo.
Future<void> apartarVista(WidgetTester tester, Offset donde) async {
  for (final fin = _t + const Duration(milliseconds: 700); _t < fin;) {
    _t += const Duration(milliseconds: 33);
    mirada.controlador.procesar(donde, _t);
  }
  await asentar(tester);
}

void main() {
  testWidgets('Se activa desde Ajustes; sin cámara se queda con el ratón', (
    tester,
  ) async {
    mirada.disponible = true;
    await arrancar(tester, ruta: Rutas.ajustes);
    final interruptor = RegExp(r'^Control por mirada \(experimental\)');
    expect(
      await nodo(tester, interruptor),
      isSemantics(hasToggledState: true, isToggled: false),
    );
    await tocar(tester, interruptor);
    expect(mirada.activo, isTrue);

    // Elegir la cámara muestra antes el aviso de privacidad.
    await tocar(tester, 'Cámara (WebGazer)');
    await nodo(tester, 'Uso de la cámara');
    await nodo(tester, RegExp('no sale del dispositivo'));
    await tocar(tester, 'Aceptar y usar la cámara');
    // Fuera de la web no hay cámara: se usa el ratón y se dice por qué.
    expect(mirada.fuente, FuenteMirada.raton);
    await nodo(
      tester,
      'No se puede usar la cámara: La cámara solo funciona en la versión '
      'web. Se usa el ratón.',
    );

    await tocar(tester, interruptor);
    expect(mirada.activo, isFalse);
    await desactivarMirada();
  });

  testWidgets('Mirar «Aumentar unidades» 1,5 s hace lo mismo que tocarlo', (
    tester,
  ) async {
    await arrancar(tester, ruta: Rutas.producto('1', 'p5'));
    await activarMirada(tester);
    expect(await nodoUnidades(tester), isSemantics(value: '1'));

    // ~400 ms hasta tener la mirada estable (12 muestras) + 1500 ms de dwell.
    await mirarA(tester, 'Aumentar unidades', 1500);
    expect(await nodoUnidades(tester), isSemantics(value: '1'));
    await mirarA(tester, 'Aumentar unidades', 600);
    expect(await nodoUnidades(tester), isSemantics(value: '2'));
    expectAnuncio(tester, 'Activado con la mirada: Aumentar unidades');

    // No se repite mientras se sigue mirando.
    await mirarA(tester, 'Aumentar unidades', 2000);
    expect(await nodoUnidades(tester), isSemantics(value: '2'));
    await desactivarMirada();
  });

  testWidgets('Recorrido 2 completo con la mirada', (tester) async {
    await arrancar(tester, ruta: Rutas.lista('1'));
    await activarMirada(tester);
    await mirarA(tester, '+ Añadir producto', 2000);
    await nodo(tester, 'Buscar producto');
    await mirarA(tester, RegExp(r'^Aceite de oliva'), 2000);
    await nodo(tester, 'Aceite de oliva virgen extra');
    await mirarA(tester, 'Añadir a la lista', 2000);
    await nodo(tester, RegExp(r'^Aceite de oliva virgen extra, 1 unidad'));
    await desactivarMirada();
  });

  testWidgets('«Borrar lista» por mirada necesita un segundo paso', (
    tester,
  ) async {
    await arrancar(tester, ruta: Rutas.lista('2'));
    await activarMirada(tester);
    await mirarA(tester, 'Borrar lista', 2000);
    await nodo(tester, '¿Borrar «Cena del sábado»?');

    // Primera activación: no borra, pide confirmar.
    await mirarA(tester, 'Sí, borrar', 2000);
    await nodo(tester, 'Confirmar borrado');
    expectAnuncio(
      tester,
      'Segundo paso: aparta la vista y mira otra vez «Confirmar borrado» '
      'para borrar la lista.',
    );
    // Seguir mirando no basta: hay que apartar la vista y volver.
    await mirarA(tester, 'Confirmar borrado', 2000);
    await nodo(tester, '¿Borrar «Cena del sábado»?');

    await apartarVista(tester, const Offset(206, 20));
    await mirarA(tester, 'Confirmar borrado', 2000);
    await nodo(tester, 'Mis listas');
    expect(find.bySemanticsLabel(RegExp(r'^Cena del sábado\n')), findsNothing);
    await desactivarMirada();
  });

  testWidgets('Con el modo mirada, −/+ más grandes y separados; guías OK', (
    tester,
  ) async {
    await arrancar(tester, ruta: Rutas.producto('1', 'p5'));
    await activarMirada(tester);
    final menos = tester.getRect(find.bySemanticsLabel('Disminuir unidades'));
    final mas = tester.getRect(find.bySemanticsLabel('Aumentar unidades'));
    expect(menos.width, greaterThanOrEqualTo(88));
    expect(mas.left - menos.right, greaterThanOrEqualTo(72));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    comprobarSeparacion(tester);
    await desactivarMirada();
  });

  testWidgets('El modo agranda los botones sin cambiarles el ancho', (
    tester,
  ) async {
    await arrancar(tester, ruta: Rutas.lista('1'));
    Rect r(String e) => tester.getRect(find.bySemanticsLabel(e));
    const etiquetas = ['+ Añadir producto', 'Terminar lista'];
    final antes = [for (final e in etiquetas) r(e)];
    await activarMirada(tester);
    for (final (i, e) in etiquetas.indexed) {
      expect(r(e).width, antes[i].width);
      expect(r(e).height, greaterThanOrEqualTo(88));
    }
    await desactivarMirada();
    await asentar(tester);
    expect([for (final e in etiquetas) r(e)], antes, reason: 'vuelve igual');
  });

  for (final (nombre, ancho, alto) in [
    ('móvil', 412.0, 915.0),
    ('escritorio', 1280.0, 720.0),
  ]) {
    for (final (pantalla, ruta, compra) in [
      ('Mis listas', Rutas.misListas, false),
      ('Nueva lista', Rutas.nuevaLista, false),
      ('Lista', Rutas.lista('1'), false),
      ('Modo compra', Rutas.lista('1'), true),
      ('Buscar', Rutas.buscar('1'), false),
      ('Detalle', Rutas.producto('1', 'p5'), false),
    ]) {
      testWidgets('$pantalla ($nombre): controles de mirada separados', (
        tester,
      ) async {
        await arrancar(tester, ruta: ruta);
        tester.view.physicalSize = Size(ancho, alto);
        await asentar(tester);
        if (compra) await tocar(tester, 'Terminar lista');
        await activarMirada(tester);
        // ignore: invalid_use_of_visible_for_testing_member
        final rects = mirada.controlador.rectsObjetivos
            .whereType<Rect>()
            .toList();
        expect(rects.length, greaterThanOrEqualTo(2));
        for (final (i, a) in rects.indexed) {
          for (final b in rects.skip(i + 1)) {
            final dx = a.left > b.left ? a.left - b.right : b.left - a.right;
            final dy = a.top > b.top ? a.top - b.bottom : b.top - a.bottom;
            expect(
              dx > dy ? dx : dy,
              greaterThanOrEqualTo(40),
              reason: '$a y $b',
            );
          }
        }
        expect(tester.takeException(), isNull);
        await desactivarMirada();
      });
    }
  }

  testWidgets('Recorrido 3 con temblor, de casilla en casilla sin apartar la '
      'vista', (tester) async {
    await arrancar(tester, ruta: Rutas.lista('2'));
    tester.view.physicalSize = const Size(1280, 900);
    await asentar(tester);
    await activarMirada(tester);
    final temblor = MouseGazeSource(ruido: 60, aleatorio: Random(7));
    Future<void> mirarTemblando(Pattern etiqueta) async {
      final centro = tester.getCenter(find.bySemanticsLabel(etiqueta));
      for (final fin = _t + const Duration(milliseconds: 3000); _t < fin;) {
        _t += const Duration(milliseconds: 33);
        mirada.controlador.procesar(temblor.conRuido(centro), _t);
      }
      await asentar(tester);
    }

    await mirarTemblando('Terminar lista');
    for (final p in ['Pasta espagueti', 'Queso curado', 'Vino tinto']) {
      final casilla = RegExp('^$p\n');
      final f = find.bySemanticsLabel(casilla);
      for (var i = 0; i < 3 && f.hitTestable().evaluate().isEmpty; i++) {
        await mirarTemblando('Bajar');
      }
      await mirarTemblando(casilla);
    }
    await nodo(tester, '¡Compra completada! Has marcado los 3 productos.');
    expectAnuncio(tester, '¡Compra completada! Has marcado los 3 productos.');
    await desactivarMirada();
  });

  testWidgets('Lo que no cabe se alcanza con «Bajar» y «Subir» por mirada', (
    tester,
  ) async {
    await arrancar(tester, ruta: Rutas.buscar('1'));
    expect(find.bySemanticsLabel('Bajar'), findsNothing);
    await activarMirada(tester);
    final vino = find.bySemanticsLabel(RegExp(r'^Vino tinto\n'));
    expect(vino.hitTestable(), findsNothing);
    for (var i = 0; i < 10 && vino.hitTestable().evaluate().isEmpty; i++) {
      await mirarA(tester, 'Bajar', 2200);
      // Para repetir hay que apartar la vista del botón.
      await apartarVista(tester, const Offset(5, 5));
    }
    expect(vino.hitTestable(), findsOne);
    await desactivarMirada();
    await asentar(tester);
    expect(find.bySemanticsLabel('Bajar'), findsNothing);
  });

  for (final (pantalla, ruta, filas) in [
    ('Mis listas', Rutas.misListas, [r'^Compra semanal', r'^Cena del sábado']),
    ('Lista', Rutas.lista('1'), [r'^Leche entera', r'^Pan de molde']),
    ('Buscar', Rutas.buscar('1'), [r'^Leche entera', r'^Pan de molde']),
  ]) {
    testWidgets('$pantalla: unos 250 px entre filas vecinas', (tester) async {
      await arrancar(tester, ruta: ruta);
      tester.view.physicalSize = const Size(1280, 900);
      await asentar(tester);
      await activarMirada(tester);
      double y(String e) =>
          tester.getCenter(find.bySemanticsLabel(RegExp(e))).dy;
      expect(y(filas[1]) - y(filas[0]), greaterThanOrEqualTo(250));
      await desactivarMirada();
    });
  }

  for (final (ancho, separacionMinima) in [(1280.0, 400.0), (412.0, 150.0)]) {
    testWidgets('− y + centrados y separados (ancho $ancho)', (tester) async {
      await arrancar(tester, ruta: Rutas.producto('1', 'p1'));
      tester.view.physicalSize = Size(ancho, 900);
      await asentar(tester);
      final antes = tester.getRect(find.bySemanticsLabel('Disminuir unidades'));
      expect(antes.left, 16, reason: 'sin el modo, a la izquierda');
      await activarMirada(tester);
      final menos = tester.getRect(
        await mostrar(tester, find.bySemanticsLabel('Disminuir unidades')),
      );
      final mas = tester.getRect(find.bySemanticsLabel('Aumentar unidades'));
      expect(mas.left - menos.right, greaterThanOrEqualTo(separacionMinima));
      expect((menos.center.dx + mas.center.dx) / 2, closeTo(ancho / 2, 90));
      await mirarA(tester, 'Aumentar unidades', 2200);
      expect(await nodoUnidades(tester), isSemantics(value: '7'));
      await mirarA(tester, 'Disminuir unidades', 2600);
      expect(await nodoUnidades(tester), isSemantics(value: '6'));
      await desactivarMirada();
      await asentar(tester);
      expect(
        tester.getRect(find.bySemanticsLabel('Disminuir unidades')),
        antes,
        reason: 'con el modo apagado queda como estaba',
      );
    });
  }
}
