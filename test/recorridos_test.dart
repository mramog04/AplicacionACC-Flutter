// Los 3 recorridos críticos, completados solo con find.bySemanticsLabel (lo
// que «oye» un usuario de lector de pantalla), con el texto al 100 %, 200 % y
// 300 %. Cualquier desbordamiento (overflow) hace fallar la prueba.
//
// En el entorno de test la plataforma admite anuncios (supportsAnnounce), así
// que los avisos se comprueban con takeAnnouncements(). La variante sin
// anuncios (regiones vivas, como en Android 16) está en semantica_test.dart.

import 'package:flutter_test/flutter_test.dart';

import 'package:lista_compra/router.dart';

import 'helpers.dart';

void main() {
  for (final escala in [1.0, 2.0, 3.0]) {
    final sufijo = '(texto ×$escala)';

    testWidgets('Recorrido 1: crear lista $sufijo', (tester) async {
      await arrancar(tester, ruta: Rutas.carga, escala: escala);
      await tocar(tester, 'Continuar a Mis listas');
      expect(
        await nodo(tester, 'Mis listas'),
        isSemantics(isHeader: true, namesRoute: true),
      );

      await tocar(tester, 'Añadir lista');
      expect(await nodo(tester, 'Nueva lista'), isSemantics(isHeader: true));

      // Crear sin nombre: error visible y anunciado (región viva).
      await tocar(tester, 'Crear lista');
      await nodo(tester, 'Escribe un nombre para la lista.');
      expectAnuncio(tester, 'Error: Escribe un nombre para la lista.');

      await escribir(tester, RegExp(r'^Nombre de la lista'), 'Fiesta');
      await tocar(tester, 'Crear lista');
      // El aviso dura unos segundos: se comprueba antes de hacer scroll.
      expect(find.bySemanticsLabel('Hecho: Lista «Fiesta» creada.'), findsOne);
      expect(
        await nodo(tester, 'Fiesta'),
        isSemantics(isHeader: true, namesRoute: true),
      );
      await nodo(tester, RegExp('La lista está vacía'));

      // La lista nueva aparece en Mis listas.
      await tocar(tester, 'Atrás');
      await nodo(tester, RegExp(r'^Fiesta\n0 productos'));
    });

    testWidgets('Recorrido 2: añadir producto $sufijo', (tester) async {
      await arrancar(tester, ruta: Rutas.lista('1'), escala: escala);
      await nodo(tester, 'Total\n14,65 €');

      await tocar(tester, '+ Añadir producto');
      expect(
        await nodo(tester, 'Buscar producto'),
        isSemantics(isHeader: true),
      );
      await escribir(tester, RegExp('Nombre o marca'), 'queso');
      await nodo(tester, '1 resultado');
      expectAnuncio(tester, '1 resultado');

      await tocar(tester, RegExp(r'^Queso curado\n'));
      expect(await nodo(tester, 'Queso curado'), isSemantics(isHeader: true));
      expect(await nodoUnidades(tester), isSemantics(value: '1'));
      expect(
        await nodo(tester, 'Disminuir unidades'),
        isSemantics(isButton: true, isEnabled: false),
      );

      await tocar(tester, 'Aumentar unidades');
      await tocar(tester, 'Aumentar unidades');
      expect(await nodoUnidades(tester), isSemantics(value: '3'));
      expect(
        await nodo(tester, 'Disminuir unidades'),
        isSemantics(isButton: true, isEnabled: true),
      );
      await nodo(tester, '3 unidades. Subtotal: 12,30 €');
      expectAnuncio(tester, '3 unidades. Subtotal: 12,30 €');

      await tocar(tester, 'Añadir a la lista');
      expect(
        find.bySemanticsLabel(
          'Hecho: Añadido a la lista: 3 unidades de Queso curado.',
        ),
        findsOne,
      );
      expect(await nodo(tester, 'Compra semanal'), isSemantics(isHeader: true));
      await nodo(tester, RegExp(r'^Queso curado, 3 unidades'));
      await nodo(tester, 'Total\n26,95 €');
    });

    testWidgets('Recorrido 3: hacer la compra $sufijo', (tester) async {
      await arrancar(tester, ruta: Rutas.lista('1'), escala: escala);
      await tocar(tester, 'Terminar lista');
      expect(await nodo(tester, 'Modo compra'), isSemantics(isHeader: true));
      expectAnuncio(
        tester,
        'Modo compra. Marca cada producto cuando lo cojas.',
      );

      const productos = [
        'Leche entera',
        'Pan de molde integral',
        'Huevos camperos',
        'Tomates en rama',
      ];
      for (final (i, p) in productos.indexed) {
        final casilla = RegExp('^$p\n');
        expect(
          await nodo(tester, casilla),
          isSemantics(hasCheckedState: true, isChecked: false),
        );
        // Aún no está todo marcado: no hay confirmación.
        expect(
          find.bySemanticsLabel(RegExp('Compra completada')),
          findsNothing,
        );
        await tocar(tester, casilla);
        expect(
          await nodo(tester, casilla),
          isSemantics(hasCheckedState: true, isChecked: true),
        );
        await nodo(tester, '${i + 1} de 4 marcados');
      }

      await nodo(tester, '¡Compra completada! Has marcado los 4 productos.');
      expectAnuncio(tester, '¡Compra completada! Has marcado los 4 productos.');
      await tocar(tester, 'Volver a Mis listas');
      expect(await nodo(tester, 'Mis listas'), isSemantics(isHeader: true));
    });
  }

  testWidgets('Producto repetido: aviso y ficha con sus unidades', (
    tester,
  ) async {
    await arrancar(tester, ruta: Rutas.buscar('1'));
    await escribir(tester, RegExp('Nombre o marca'), 'leche');
    await tocar(tester, RegExp(r'^Leche entera\n'));
    await nodo(
      tester,
      'Aviso: «Leche entera» ya está en la lista. '
      'Puedes cambiar sus unidades.',
    );
    expect(await nodoUnidades(tester), isSemantics(value: '6'));
    await tocar(tester, 'Disminuir unidades');
    await tocar(tester, 'Guardar unidades');
    await nodo(tester, RegExp(r'^Leche entera, 5 unidades'));
  });

  testWidgets('Borrar lista pide confirmación', (tester) async {
    await arrancar(tester, ruta: Rutas.lista('2'));
    await tocar(tester, 'Borrar lista');
    await nodo(tester, '¿Borrar «Cena del sábado»?');
    await tocar(tester, 'Cancelar');
    expect(await nodo(tester, 'Cena del sábado'), isSemantics(isHeader: true));

    await tocar(tester, 'Borrar lista');
    await tocar(tester, 'Sí, borrar');
    expect(await nodo(tester, 'Mis listas'), isSemantics(isHeader: true));
    expect(find.bySemanticsLabel(RegExp(r'^Cena del sábado\n')), findsNothing);
    await nodo(tester, 'Hecho: Lista «Cena del sábado» borrada.');
  });

  testWidgets('Lista vacía: «Terminar lista» deshabilitado y explicado', (
    tester,
  ) async {
    await arrancar(tester, ruta: Rutas.nuevaLista);
    await escribir(tester, RegExp(r'^Nombre de la lista'), 'Vacía');
    await tocar(tester, 'Crear lista');
    expect(
      await nodo(tester, 'Terminar lista'),
      isSemantics(isButton: true, isEnabled: false),
    );
    await nodo(tester, 'Añade productos para poder terminar la lista.');
  });
}
