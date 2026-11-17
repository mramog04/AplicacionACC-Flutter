import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lista_compra/data/almacen.dart';
import 'package:lista_compra/main.dart';
import 'package:lista_compra/router.dart';

/// Desplaza hasta [f] (si hace falta) y lo toca.
Future<void> tocarVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
}

/// Recorre las 7 pantallas siguiendo los caminos de navegación previstos.
Future<void> recorrerPantallas(WidgetTester tester) async {
  await tester.pumpWidget(const ListaCompraApp());
  await tester.pump();

  // 1. Carga → Mis listas (tocar la pantalla).
  expect(find.text('Toca la pantalla para continuar'), findsOneWidget);
  await tester.tapAt(const Offset(10, 10));
  await tester.pumpAndSettle();

  // 2. Mis listas
  expect(find.text('Mis listas'), findsOneWidget);
  expect(find.text('Compra semanal'), findsOneWidget);
  expect(find.text('Cena del sábado'), findsOneWidget);
  // «Ajustes» arriba a la derecha y «Añadir lista» abajo a la derecha.
  final ancho = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  expect(tester.getRect(find.text('Ajustes')).right, greaterThan(ancho * 0.8));
  expect(
    tester.getRect(find.text('Añadir lista')).right,
    greaterThan(ancho * 0.8),
  );

  // → Ajustes y atrás
  await tocarVisible(tester, find.text('Ajustes'));
  await tester.pumpAndSettle();
  expect(find.text('Tamaño de texto'), findsOneWidget);
  await tocarVisible(tester, find.text('Atrás'));
  await tester.pumpAndSettle();

  // → Nueva lista, cancelar
  await tocarVisible(tester, find.text('Añadir lista'));
  await tester.pumpAndSettle();
  expect(find.text('Nombre de la lista'), findsOneWidget);
  await tocarVisible(tester, find.text('Cancelar'));
  await tester.pumpAndSettle();
  expect(find.text('Mis listas'), findsOneWidget);

  // → Nueva lista, crear → Lista
  await tocarVisible(tester, find.text('Añadir lista'));
  await tester.pumpAndSettle();
  await tocarVisible(tester, find.text('Crear lista'));
  await tester.pump();
  expect(find.text('Escribe un nombre para la lista.'), findsOneWidget);
  await tester.enterText(find.byType(TextField), 'Fiesta');
  await tocarVisible(tester, find.text('Crear lista'));
  await tester.pumpAndSettle();
  expect(find.text('Fiesta'), findsOneWidget);
  await tocarVisible(tester, find.text('Atrás'));
  await tester.pumpAndSettle();

  // → Lista
  await tocarVisible(tester, find.text('Compra semanal'));
  await tester.pumpAndSettle();
  expect(find.text('Total'), findsOneWidget);

  // Lista → Detalle (producto ya en la lista) → atrás
  await tocarVisible(tester, find.text('Leche entera'));
  await tester.pumpAndSettle();
  expect(find.text('Guardar unidades'), findsOneWidget);
  await tocarVisible(tester, find.text('Atrás'));
  await tester.pumpAndSettle();

  // Lista → Buscar → Detalle → Lista (al añadir)
  await tocarVisible(tester, find.text('+ Añadir producto'));
  await tester.pumpAndSettle();
  expect(find.text('8 resultados'), findsOneWidget);
  await tester.enterText(find.byType(TextField), 'queso');
  await tester.pump();
  expect(find.text('1 resultado'), findsOneWidget);
  await tocarVisible(tester, find.text('Queso curado'));
  await tester.pumpAndSettle();
  // El ListView construye sus hijos al desplazarse: se baja hasta el botón.
  await tester.scrollUntilVisible(
    find.byTooltip('Aumentar unidades'),
    100,
    scrollable: find
        .ancestor(of: find.text('Marca'), matching: find.byType(Scrollable))
        .first,
  );
  await tocarVisible(tester, find.byTooltip('Aumentar unidades'));
  await tester.pump();
  await tocarVisible(tester, find.text('Añadir a la lista'));
  await tester.pumpAndSettle();
  // De vuelta en la lista. (Con texto ≥200 % el título se desplaza con el
  // contenido y la lista conserva su scroll, así que puede no estar a la
  // vista: se comprueba la ruta.)
  expect(
    appRouter.routerDelegate.currentConfiguration.uri.toString(),
    Rutas.lista('1'),
  );
  expect(
    find.text('Añadido a la lista: 2 unidades de Queso curado.'),
    findsOneWidget,
  );
}

void main() {
  setUp(() {
    almacen.reiniciar();
    appRouter.go(Rutas.carga);
  });

  testWidgets('Navegación por las 7 pantallas', recorrerPantallas);

  testWidgets('Navegación con texto al 200 % sin desbordes', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await recorrerPantallas(tester);
  });

  testWidgets('Un solo h1 por pantalla y controles de al menos 48×48', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await tester.pumpWidget(const ListaCompraApp());
    for (final ruta in [
      Rutas.carga,
      Rutas.misListas,
      Rutas.nuevaLista,
      Rutas.lista('1'),
      Rutas.buscar('1'),
      Rutas.producto('1', 'p1'),
      Rutas.ajustes,
    ]) {
      appRouter.go(ruta);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final h1 = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.headingLevel == 1,
      );
      expect(h1, findsOneWidget, reason: ruta);
      final controles = find.byWidgetPredicate(
        (w) =>
            w is ButtonStyleButton ||
            w is IconButton ||
            w is TextField ||
            w is RadioListTile,
      );
      for (final e in controles.evaluate()) {
        final tam = tester.getSize(find.byWidget(e.widget));
        expect(
          tam.width >= 48 && tam.height >= 48,
          isTrue,
          reason: '$ruta: ${e.widget.runtimeType} mide $tam',
        );
      }
    }
    semantica.dispose();
  });
}
