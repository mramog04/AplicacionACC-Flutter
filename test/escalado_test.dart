// Cada pantalla clave con textScaler lineal 2.0 y 3.0 en un móvil de
// 412 × 915: no hay desbordamientos (un overflow hace fallar la prueba) y
// todo el contenido esperado se puede alcanzar desplazándose (nada se pierde
// ni queda tapado).

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lista_compra/router.dart';

import 'helpers.dart';

/// Pantalla → etiquetas que tienen que poder alcanzarse.
final pantallas = <String, (String, List<Pattern>)>{
  'Carga': (
    Rutas.carga,
    ['Continuar a Mis listas', 'Lista de la compra', 'Cargando'],
  ),
  'Mis listas': (
    Rutas.misListas,
    [
      'Ajustes',
      'Mis listas',
      RegExp(r'^Compra semanal\n'),
      RegExp(r'^Cena del sábado\n'),
      'Añadir lista',
    ],
  ),
  'Nueva lista': (
    Rutas.nuevaLista,
    ['Cancelar', 'Nueva lista', RegExp(r'^Nombre de la lista'), 'Crear lista'],
  ),
  'Lista': (
    Rutas.lista('1'),
    [
      'Atrás',
      'Borrar lista',
      'Compra semanal',
      'Total\n14,65 €',
      RegExp(r'^Leche entera,'),
      RegExp(r'^Tomates en rama,'),
      '+ Añadir producto',
      'Terminar lista',
    ],
  ),
  'Buscar producto': (
    Rutas.buscar('1'),
    [
      'Atrás',
      'Buscar producto',
      RegExp('Nombre o marca'),
      '8 resultados',
      RegExp(r'^Leche entera\n'),
      RegExp(r'^Vino tinto\n'),
    ],
  ),
  'Detalle de producto': (
    Rutas.producto('1', 'p5'),
    [
      'Atrás',
      'Aceite de oliva virgen extra',
      RegExp(r'^Descripción\n'),
      'Disminuir unidades',
      'Aumentar unidades',
      'Mínimo: 1 unidad.',
      '1 unidad. Subtotal: 8,90 €',
      'Añadir a la lista',
    ],
  ),
  'Ajustes': (
    Rutas.ajustes,
    ['Atrás', 'Ajustes', 'Español', 'Muy grande (200 %)'],
  ),
};

void main() {
  for (final escala in [2.0, 3.0]) {
    for (final MapEntry(key: nombre, value: (ruta, etiquetas))
        in pantallas.entries) {
      testWidgets('$nombre sin desbordes y completa (texto ×$escala)', (
        tester,
      ) async {
        await arrancar(tester, ruta: ruta, escala: escala);
        for (final e in etiquetas) {
          final f = await mostrar(tester, find.bySemanticsLabel(e));
          expect(f, findsOne, reason: '«$e» no se encuentra');
          // Los controles no quedan tapados por otra cosa (p. ej. el botón
          // flotante o un aviso). Excepción: el botón de pantalla completa de
          // la carga, cuyo centro cubre el contenido, que al tocarlo hace lo
          // mismo (y TalkBack lo activa por su acción, no por coordenadas).
          final tocable = tester
              .getSemantics(f)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap);
          if (tocable && e != 'Continuar a Mis listas') {
            expect(f.hitTestable(), findsOne, reason: '«$e» queda tapado');
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
