import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lista_compra/data/almacen.dart';
import 'package:lista_compra/main.dart';
import 'package:lista_compra/router.dart';

/// Tamaño de un móvil típico (412 × 915 lógicos).
const tamanoMovil = Size(412, 915);

/// Arranca la app en [ruta] con datos de ejemplo limpios, tamaño de móvil y
/// el escalado de texto indicado (lineal). La semántica ya la activa
/// `testWidgets` (semanticsEnabled es true por defecto).
Future<void> arrancar(
  WidgetTester tester, {
  String ruta = Rutas.misListas,
  double escala = 1,
}) async {
  tester.view.physicalSize = tamanoMovil;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  almacen.reiniciar();
  appRouter.go(ruta);
  await tester.pumpWidget(const ListaCompraApp());
  await asentar(tester);
}

/// Como pumpAndSettle, pero también sirve en la pantalla de carga (cuyo
/// círculo gira sin fin).
Future<void> asentar(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Cuerpo desplazable de la pantalla visible: el Scrollable vertical más
/// alto (las barras superior e inferior también son desplazables, pero más
/// bajas).
Finder cuerpoDesplazable(WidgetTester tester) {
  final candidatos = find.byType(Scrollable).evaluate().where((e) {
    final s = (e as StatefulElement).state as ScrollableState;
    return s.position.axis == Axis.vertical;
  }).toList();
  candidatos.sort((a, b) => b.size!.height.compareTo(a.size!.height));
  return find.byElementPredicate((e) => e == candidatos.first);
}

/// Hace visible [f] como lo haría un usuario: si no está construido (el
/// ListView crea sus hijos al desplazarse), arrastra el cuerpo hasta arriba
/// y luego hacia abajo poco a poco hasta encontrarlo. Con arrastres reales
/// (no saltos de posición) también funciona con la barra superior
/// desplazable (NestedScrollView, texto ≥ 200 %).
Future<Finder> mostrar(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) {
    final centro = tester.getCenter(cuerpoDesplazable(tester));
    for (var i = 0; i < 15 && f.evaluate().isEmpty; i++) {
      await tester.dragFrom(centro, const Offset(0, 400));
      await asentar(tester);
    }
    for (var i = 0; i < 60 && f.evaluate().isEmpty; i++) {
      await tester.dragFrom(centro, const Offset(0, -150));
      await asentar(tester);
    }
  }
  if (f.evaluate().isNotEmpty) {
    await tester.ensureVisible(f.first);
    await asentar(tester);
  }
  return f;
}

/// Comprueba que hay exactamente un nodo con esa etiqueta (haciendo scroll
/// si hace falta) y lo devuelve.
Future<SemanticsNode> nodo(WidgetTester tester, Pattern etiqueta) async {
  final f = await mostrar(tester, find.bySemanticsLabel(etiqueta));
  expect(f, findsOne, reason: 'Etiqueta: $etiqueta');
  return tester.getSemantics(f);
}

/// Toca el nodo semántico con esa etiqueta (exacta o RegExp) y espera.
Future<void> tocar(WidgetTester tester, Pattern etiqueta) async {
  final f = await mostrar(tester, find.bySemanticsLabel(etiqueta));
  await tester.tap(f);
  await asentar(tester);
}

/// Etiquetas (y valores) de los nodos en el orden en que los recorre el
/// lector de pantalla, sin nodos ocultos ni contenedores sin texto.
List<String> ordenLectura(WidgetTester tester) {
  final raiz = tester
      .renderObject(find.byType(ListaCompraApp))
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  final salida = <String>[];
  void visitar(SemanticsNode n) {
    final d = n.getSemanticsData();
    if (d.flagsCollection.isHidden) return;
    final texto = [
      if (d.label.isNotEmpty) d.label,
      if (d.value.isNotEmpty) d.value,
      if (d.tooltip.isNotEmpty) d.tooltip,
    ].join(' | ');
    if (texto.isNotEmpty) salida.add(texto.replaceAll('\n', ' / '));
    for (final c in n.debugListChildrenInOrder(
      DebugSemanticsDumpOrder.traversalOrder,
    )) {
      visitar(c);
    }
  }

  visitar(raiz);
  return salida;
}

/// Escribe [texto] en el campo cuyo nodo semántico tiene esa etiqueta.
Future<void> escribir(
  WidgetTester tester,
  Pattern etiqueta,
  String texto,
) async {
  await mostrar(tester, find.bySemanticsLabel(etiqueta));
  final campo = find.descendant(
    of: find.bySemanticsLabel(etiqueta),
    matching: find.byType(EditableText),
  );
  await tester.enterText(campo, texto);
  await asentar(tester);
}

/// Nodo «Unidades» del selector (el que tiene valor; no el subtítulo h2).
Future<SemanticsNode> nodoUnidades(WidgetTester tester) async {
  final f = await mostrar(
    tester,
    find.byWidgetPredicate(
      (w) =>
          w is Semantics &&
          w.properties.label == 'Unidades' &&
          w.properties.value != null,
    ),
  );
  return tester.getSemantics(f);
}

/// Rectángulo de [n] en coordenadas de pantalla.
Rect rectGlobal(SemanticsNode n) {
  var r = n.rect;
  for (SemanticsNode? m = n; m != null; m = m.parent) {
    if (m.transform != null) r = MatrixUtils.transformRect(m.transform!, r);
  }
  return r;
}

/// Nodos visibles con acción de tocar (los «targets» de la pantalla).
List<SemanticsNode> nodosTocables(WidgetTester tester) {
  final raiz = tester
      .renderObject(find.byType(ListaCompraApp))
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  final salida = <SemanticsNode>[];
  void visitar(SemanticsNode n) {
    final d = n.getSemanticsData();
    if (d.flagsCollection.isHidden) return;
    if (d.hasAction(SemanticsAction.tap)) salida.add(n);
    n.visitChildren((c) {
      visitar(c);
      return true;
    });
  }

  visitar(raiz);
  return salida;
}

/// Comprueba que entre cada par de controles tocables que no se solapan hay
/// al menos [minimo] píxeles lógicos de separación.
void comprobarSeparacion(WidgetTester tester, {double minimo = 8}) {
  final pantalla = Offset.zero & tamanoMovil;
  final rects = [
    for (final n in nodosTocables(tester))
      if (rectGlobal(n).overlaps(pantalla))
        (n.getSemanticsData().label.split('\n').first, rectGlobal(n)),
  ];
  for (var i = 0; i < rects.length; i++) {
    for (var j = i + 1; j < rects.length; j++) {
      final (ea, a) = rects[i];
      final (eb, b) = rects[j];
      // Si se solapan, uno contiene al otro (p. ej. la pantalla de carga
      // entera es un botón): no es un caso de «controles próximos».
      if (a.overlaps(b)) continue;
      final dx = [
        b.left - a.right,
        a.left - b.right,
      ].reduce((x, y) => x > y ? x : y);
      final dy = [
        b.top - a.bottom,
        a.top - b.bottom,
      ].reduce((x, y) => x > y ? x : y);
      final hueco = dx > dy ? dx : dy;
      expect(
        hueco,
        greaterThanOrEqualTo(minimo - 0.01),
        reason: '«$ea» y «$eb» están a ${hueco.toStringAsFixed(1)} px',
      );
    }
  }
}

/// Comprueba que desde la última llamada se ha anunciado [mensaje].
void expectAnuncio(WidgetTester tester, String mensaje) {
  expect(tester.takeAnnouncements().map((a) => a.message), contains(mensaje));
}
