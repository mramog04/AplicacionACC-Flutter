// Semántica detallada: anuncios en plataformas sin «announce» (regiones
// vivas), foco, títulos, selector de unidades y orden de lectura.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lista_compra/router.dart';

import 'helpers.dart';

/// Simula una plataforma sin anuncios (p. ej. Android 16, que los retiró):
/// los mensajes tienen que llegar al lector como regiones vivas.
void sinAnuncios(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(supportsAnnounce: false);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

void main() {
  group('Sin anuncios de plataforma: regiones vivas', () {
    testWidgets('error de nombre vacío', (tester) async {
      sinAnuncios(tester);
      await arrancar(tester, ruta: Rutas.nuevaLista);
      await tocar(tester, 'Crear lista');
      expect(
        await nodo(tester, 'Escribe un nombre para la lista.'),
        isSemantics(isLiveRegion: true),
      );
      // No se envía además un anuncio: se leería dos veces.
      expect(tester.takeAnnouncements(), isEmpty);
    });

    testWidgets('número de resultados y subtotal', (tester) async {
      sinAnuncios(tester);
      await arrancar(tester, ruta: Rutas.buscar('1'));
      await escribir(tester, RegExp('Nombre o marca'), 'pan');
      expect(
        await nodo(tester, '1 resultado'),
        isSemantics(isLiveRegion: true),
      );
      await tocar(tester, RegExp(r'^Pan de molde integral\n'));
      await tocar(tester, 'Aumentar unidades');
      expect(
        await nodo(tester, '2 unidades. Subtotal: 3,30 €'),
        isSemantics(isLiveRegion: true),
      );
      expect(tester.takeAnnouncements(), isEmpty);
    });

    testWidgets('modo compra y compra completada', (tester) async {
      sinAnuncios(tester);
      await arrancar(tester, ruta: Rutas.lista('2'));
      await tocar(tester, 'Terminar lista');
      expect(
        await nodo(tester, 'Modo compra. Marca cada producto cuando lo cojas.'),
        isSemantics(isLiveRegion: true),
      );
      for (final p in ['Pasta espagueti', 'Queso curado', 'Vino tinto']) {
        await tocar(tester, RegExp('^$p\n'));
      }
      expect(
        await nodo(tester, '¡Compra completada! Has marcado los 3 productos.'),
        isSemantics(isLiveRegion: true),
      );
      expect(tester.takeAnnouncements(), isEmpty);
    });
  });

  testWidgets('El error no mueve el foco', (tester) async {
    await arrancar(tester, ruta: Rutas.nuevaLista);
    final antes = FocusManager.instance.primaryFocus;
    // Lo tiene el campo «Nombre de la lista» (autofocus).
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode,
      same(antes),
    );
    await tocar(tester, 'Crear lista');
    expect(FocusManager.instance.primaryFocus, same(antes));
  });

  testWidgets('Cada pantalla tiene un único título h1 que nombra la ruta', (
    tester,
  ) async {
    final titulos = {
      Rutas.carga: 'Lista de la compra',
      Rutas.misListas: 'Mis listas',
      Rutas.nuevaLista: 'Nueva lista',
      Rutas.lista('1'): 'Compra semanal',
      Rutas.buscar('1'): 'Buscar producto',
      Rutas.producto('1', 'p1'): 'Leche entera',
      Rutas.ajustes: 'Ajustes',
    };
    for (final MapEntry(key: ruta, value: titulo) in titulos.entries) {
      await arrancar(tester, ruta: ruta);
      final h1 = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.headingLevel == 1,
      );
      expect(h1, findsOne, reason: ruta);
      expect(
        tester.getSemantics(h1),
        isSemantics(label: titulo, isHeader: true, namesRoute: true),
        reason: ruta,
      );
    }
  });

  testWidgets('El valor «Unidades» se ajusta con deslizar arriba/abajo', (
    tester,
  ) async {
    await arrancar(tester, ruta: Rutas.producto('1', 'p5'));
    var unidades = await nodoUnidades(tester);
    expect(
      unidades,
      isSemantics(
        label: 'Unidades',
        value: '1',
        increasedValue: '2',
        hasIncreaseAction: true,
        // En el mínimo no se puede bajar: no se ofrece la acción.
        hasDecreaseAction: false,
      ),
    );
    final valor = find.semantics.byPredicate(
      (n) => n.label == 'Unidades' && n.value.isNotEmpty,
    );
    tester.semantics.increase(valor);
    await asentar(tester);
    unidades = await nodoUnidades(tester);
    expect(
      unidades,
      isSemantics(value: '2', hasIncreaseAction: true, hasDecreaseAction: true),
    );
    tester.semantics.decrease(valor);
    await asentar(tester);
    expect(await nodoUnidades(tester), isSemantics(value: '1'));
  });

  testWidgets('Orden de lectura: detalle de producto', (tester) async {
    await arrancar(tester, ruta: Rutas.producto('1', 'p5'));
    expect(ordenLectura(tester), [
      'Atrás',
      'Aceite de oliva virgen extra',
      'Marca / Olivar del Sur',
      'Formato / Botella de 1 litro',
      'Precio / 8,90 €',
      'Descripción / Aceite de oliva virgen extra de primera prensada en frío.',
      'Unidades',
      'Disminuir unidades',
      'Unidades | 1',
      'Aumentar unidades',
      'Mínimo: 1 unidad.',
      '1 unidad. Subtotal: 8,90 €',
      'Añadir a la lista',
    ]);
  });

  testWidgets('Orden de lectura: lista en modo compra', (tester) async {
    await arrancar(tester, ruta: Rutas.lista('2'));
    await tocar(tester, 'Terminar lista');
    await tocar(tester, RegExp(r'^Pasta espagueti\n'));
    expect(ordenLectura(tester), [
      'Atrás',
      'Cena del sábado',
      'Modo compra',
      'Modo compra. Marca cada producto cuando lo cojas.',
      '1 de 3 marcados',
      'Pasta espagueti / 2 unidades, Paquete de 500 g',
      'Queso curado / 1 unidad, Cuña de 250 g',
      'Vino tinto / 1 unidad, Botella de 75 cl',
      'Salir del modo compra',
    ]);
    // El estado de cada casilla va en el nodo (no en el texto).
    expect(
      await nodo(tester, RegExp(r'^Pasta espagueti\n')),
      isSemantics(hasCheckedState: true, isChecked: true),
    );
  });

  testWidgets('Los iconos decorativos no generan nodos', (tester) async {
    await arrancar(tester);
    // Ni las flechas «›» de cada fila ni el icono «+» del botón aparecen
    // como elementos sueltos: cada botón se lee con su texto.
    expect(ordenLectura(tester), [
      'Ajustes',
      'Mis listas',
      'Compra semanal / 4 productos / 14,65 €',
      'Cena del sábado / 3 productos / 12,30 €',
      'Añadir lista',
    ]);
  });
}
