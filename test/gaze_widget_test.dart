// Modo mirada dentro de la app, con muestras simuladas (sin cámara).

import 'package:flutter_test/flutter_test.dart';

import 'package:lista_compra/gaze/gaze_settings.dart';
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
    expect(menos.width, greaterThanOrEqualTo(72));
    // El centro de «+» queda a más del radio de salida del borde de «−».
    expect(mas.center.dx - menos.right, greaterThan(200));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    comprobarSeparacion(tester);
    await desactivarMirada();
  });

  testWidgets('Activar el modo no cambia el tamaño de los botones', (
    tester,
  ) async {
    await arrancar(tester, ruta: Rutas.lista('1'));
    final antes = [
      for (final e in ['+ Añadir producto', 'Terminar lista', 'Borrar lista'])
        tester.getRect(find.bySemanticsLabel(e)),
    ];
    await activarMirada(tester);
    final despues = [
      for (final e in ['+ Añadir producto', 'Terminar lista', 'Borrar lista'])
        tester.getRect(find.bySemanticsLabel(e)),
    ];
    expect(despues[0].size, antes[0].size);
    expect(despues[1].size, antes[1].size);
    expect(despues[2].size, antes[2].size);
  });
}
