// Guías de accesibilidad de flutter_test en cada pantalla y en los estados
// relevantes (error, modo compra, compra completa, diálogo de borrado), con
// el texto al 100 % y al 200 %:
// - androidTapTargetGuideline: targets de al menos 48×48.
// - labeledTapTargetGuideline: todo lo tocable tiene nombre.
// - textContrastGuideline: contraste de texto suficiente.
// Además, comprobarSeparacion: al menos 8 px entre controles próximos.

import 'package:flutter_test/flutter_test.dart';

import 'package:lista_compra/router.dart';

import 'helpers.dart';

typedef Preparar = Future<void> Function(WidgetTester tester);

Future<void> nada(WidgetTester tester) async {}

final casos = <String, (String, Preparar)>{
  'Carga': (Rutas.carga, nada),
  'Mis listas': (Rutas.misListas, nada),
  'Nueva lista': (Rutas.nuevaLista, nada),
  'Nueva lista con error': (Rutas.nuevaLista, (t) => tocar(t, 'Crear lista')),
  'Lista': (Rutas.lista('1'), nada),
  'Lista: diálogo de borrar': (
    Rutas.lista('1'),
    (t) => tocar(t, 'Borrar lista'),
  ),
  'Lista: modo compra': (Rutas.lista('2'), (t) => tocar(t, 'Terminar lista')),
  'Lista: compra completada': (
    Rutas.lista('2'),
    (t) async {
      await tocar(t, 'Terminar lista');
      for (final p in ['Pasta espagueti', 'Queso curado', 'Vino tinto']) {
        await tocar(t, RegExp('^$p\n'));
      }
    },
  ),
  'Buscar producto': (Rutas.buscar('1'), nada),
  'Detalle (producto nuevo)': (Rutas.producto('1', 'p5'), nada),
  'Detalle (producto en la lista)': (Rutas.producto('1', 'p1'), nada),
  'Ajustes': (Rutas.ajustes, nada),
};

void main() {
  for (final escala in [1.0, 2.0]) {
    for (final MapEntry(key: nombre, value: (ruta, preparar))
        in casos.entries) {
      testWidgets('$nombre cumple las guías (texto ×$escala)', (tester) async {
        await arrancar(tester, ruta: ruta, escala: escala);
        await preparar(tester);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        comprobarSeparacion(tester);
      });
    }
  }
}
