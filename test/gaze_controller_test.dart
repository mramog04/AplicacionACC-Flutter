// Pruebas unitarias del GazeController con muestras simuladas (sin cámara):
// objetivo pegajoso con histéresis, tiempo de gracia, suavizado y dwell.

import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:lista_compra/gaze/gaze_config.dart';
import 'package:lista_compra/gaze/gaze_controller.dart';
import 'package:lista_compra/gaze/gaze_source.dart';

/// Dos controles separados 250 px en horizontal: el centro de B queda a
/// 300 px del borde de A, por encima del radio de salida (200). Con menos
/// separación A no se soltaría nunca al mirar a B (ver «Un control a menos
/// del radio de salida no se puede alcanzar directamente»).
const rectA = Rect.fromLTWH(100, 100, 100, 50);
const rectB = Rect.fromLTWH(450, 100, 100, 50);

/// Paso entre muestras (~30 Hz).
const paso = Duration(milliseconds: 33);

class Escenario {
  Escenario({int suavizado = 1}) {
    c = GazeController(muestrasSuavizado: suavizado);
    c.registrar(
      'A',
      ObjetivoMirada(rect: () => rectA, activar: () => activados.add('A')),
    );
    c.registrar(
      'B',
      ObjetivoMirada(rect: () => rectB, activar: () => activados.add('B')),
    );
  }

  late final GazeController c;
  final activados = <String>[];
  Duration t = Duration.zero;

  /// Envía muestras durante [duracion]; cada una la da [posicion].
  void mirar(Duration duracion, Offset Function() posicion) {
    final fin = t + duracion;
    while (t < fin) {
      c.procesar(posicion(), t);
      t += paso;
    }
  }
}

void main() {
  test('Bloquea el control más cercano dentro del radio de entrada', () {
    final e = Escenario();
    e.mirar(paso, () => const Offset(150, 220)); // a 95 px de A
    expect(e.c.bloqueado, 'A');

    final lejos = Escenario();
    lejos.mirar(paso, () => const Offset(150, 300)); // a 175 px: nada
    expect(lejos.c.bloqueado, isNull);
  });

  test('El ruido dentro del radio de salida no cambia el objetivo', () {
    final e = Escenario(suavizado: GazeConfig.muestrasSuavizado);
    e.mirar(const Duration(milliseconds: 500), () => rectA.center);
    expect(e.c.bloqueado, 'A');

    // Temblor fuerte (hasta 150 px) alrededor de un punto a la derecha de A,
    // más cerca de B que de A pero a menos de 200 px de A.
    final azar = Random(42);
    final ruido = MouseGazeSource(ruido: 150, aleatorio: azar);
    const centro = Offset(350, 125); // a 150 px de A, a 100 px de B
    final bloqueados = <Object?>{};
    e.mirar(const Duration(seconds: 3), () {
      final m = ruido.conRuido(centro);
      bloqueados.add(e.c.bloqueado);
      return m;
    });
    expect(bloqueados, {'A'}, reason: 'nunca salta a B por el ruido');
  });

  test('Se suelta solo tras el tiempo de gracia fuera del radio de salida', () {
    final e = Escenario();
    e.mirar(const Duration(milliseconds: 300), () => rectA.center);
    expect(e.c.bloqueado, 'A');

    const fuera = Offset(150, 500); // a 350 px de A, lejos de todo
    // Menos que la gracia: sigue bloqueado.
    e.mirar(const Duration(milliseconds: 330), () => fuera);
    expect(e.c.bloqueado, 'A');
    // Pasada la gracia (400 ms): se suelta.
    e.mirar(const Duration(milliseconds: 200), () => fuera);
    expect(e.c.bloqueado, isNull);
    expect(e.c.progreso, 0);
  });

  test('Una salida breve (parpadeo) no suelta el objetivo', () {
    final e = Escenario();
    e.mirar(const Duration(milliseconds: 300), () => rectA.center);
    e.mirar(const Duration(milliseconds: 200), () => const Offset(150, 600));
    e.mirar(const Duration(milliseconds: 100), () => rectA.center);
    e.mirar(const Duration(milliseconds: 300), () => const Offset(150, 600));
    expect(e.c.bloqueado, 'A');
  });

  test('El dwell activa el control una sola vez hasta soltarlo', () {
    final e = Escenario();
    e.mirar(const Duration(milliseconds: 1400), () => rectA.center);
    expect(e.activados, isEmpty);
    expect(e.c.progreso, greaterThan(0.85));
    e.mirar(const Duration(milliseconds: 200), () => rectA.center);
    expect(e.activados, ['A']);
    // Seguir mirando no lo repite.
    e.mirar(const Duration(seconds: 3), () => rectA.center);
    expect(e.activados, ['A']);
  });

  test('El dwell se reinicia al cambiar de objetivo', () {
    final e = Escenario();
    e.mirar(const Duration(milliseconds: 1000), () => rectA.center);
    expect(e.c.progreso, closeTo(1000 / 1500, 0.05));

    // Se mira a B (a más de 200 px de A): tras la gracia se suelta A y se
    // bloquea B empezando de cero.
    e.mirar(const Duration(milliseconds: 500), () => rectB.center);
    expect(e.c.bloqueado, 'B');
    expect(e.c.progreso, lessThan(0.1));
    expect(e.activados, isEmpty, reason: 'A no llegó a activarse');

    e.mirar(const Duration(milliseconds: 1600), () => rectB.center);
    expect(e.activados, ['B']);
  });

  test('Durante la gracia el dwell no avanza', () {
    final e = Escenario();
    e.mirar(const Duration(milliseconds: 1000), () => rectA.center);
    final antes = e.c.progreso;
    e.mirar(const Duration(milliseconds: 300), () => const Offset(150, 600));
    expect(e.c.bloqueado, 'A');
    expect(e.c.progreso, antes);
  });

  test('El suavizado (media de 12) filtra una muestra aislada lejana', () {
    final e = Escenario(suavizado: 12);
    e.mirar(const Duration(milliseconds: 400), () => rectA.center);
    // Una sola muestra a 1000 px es un valor atípico: se descarta.
    e.c.procesar(const Offset(150, 1125), e.t);
    expect(
      distanciaARect(e.c.posicion!, rectA),
      lessThan(GazeConfig.radioSalida),
    );
  });

  test('En pausa (calibración) no bloquea ni activa', () {
    final e = Escenario()..c.pausado = true;
    e.mirar(const Duration(seconds: 2), () => rectA.center);
    expect(e.c.bloqueado, isNull);
    expect(e.activados, isEmpty);
  });

  test('Un control que deja de verse (rect null) no se bloquea', () {
    final c = GazeController(muestrasSuavizado: 1);
    c.registrar('oculto', ObjetivoMirada(rect: () => null, activar: () {}));
    c.procesar(const Offset(10, 10), Duration.zero);
    expect(c.bloqueado, isNull);
  });

  test('Un control a menos del radio de salida no se puede alcanzar '
      'directamente (limitación del diseño pegajoso)', () {
    const cerca = Rect.fromLTWH(250, 100, 100, 50); // a 50 px de A
    final c = GazeController(muestrasSuavizado: 1);
    c.registrar('A', ObjetivoMirada(rect: () => rectA, activar: () {}));
    c.registrar('C', ObjetivoMirada(rect: () => cerca, activar: () {}));
    var t = Duration.zero;
    void mirar(Offset p, int ms) {
      for (final fin = t + Duration(milliseconds: ms); t < fin; t += paso) {
        c.procesar(p, t);
      }
    }

    mirar(rectA.center, 300);
    mirar(cerca.center, 2000);
    expect(c.bloqueado, 'A', reason: 'C está dentro del radio de salida de A');
    // Hay que apartar la vista (más de 200 px, más de 400 ms) y volver.
    mirar(const Offset(300, 600), 600);
    mirar(cerca.center, 100);
    expect(c.bloqueado, 'C');
  });

  test('Si el control bloqueado deja de verse, se suelta sin gracia', () {
    var visible = true;
    final c = GazeController(muestrasSuavizado: 1);
    c.registrar(
      'A',
      ObjetivoMirada(rect: () => visible ? rectA : null, activar: () {}),
    );
    c.registrar('B', ObjetivoMirada(rect: () => rectB, activar: () {}));
    c.procesar(rectA.center, Duration.zero);
    expect(c.bloqueado, 'A');
    visible = false; // p. ej. se abre un diálogo encima
    c.procesar(rectB.center, paso);
    expect(c.bloqueado, 'B');
  });

  test('Un salto de la vista no bloquea los controles intermedios', () {
    // Filas apiladas como en «Buscar producto».
    const filas = {
      'aceite': Rect.fromLTRB(16, 353, 396, 511),
      'pasta': Rect.fromLTRB(16, 519, 396, 655),
      'queso': Rect.fromLTRB(16, 663, 396, 777),
    };
    final activados = <String>[];
    final c = GazeController(); // suavizado de 12, como en la app
    filas.forEach(
      (k, r) => c.registrar(
        k,
        ObjetivoMirada(rect: () => r, activar: () => activados.add(k)),
      ),
    );
    var t = Duration.zero;
    final bloqueados = <Object?>{};
    void mirar(Offset p, int ms) {
      for (final fin = t + Duration(milliseconds: ms); t < fin; t += paso) {
        c.procesar(p, t);
        bloqueados.add(c.bloqueado);
      }
    }

    mirar(const Offset(206, 900), 600); // abajo, a más de 100 px de todo
    mirar(const Offset(206, 432), 2200); // salto a «aceite»
    expect(bloqueados.whereType<String>().toSet(), {'aceite'});
    expect(activados, ['aceite']);
  });

  test('Tras activar, no se activa solo lo que quede bajo la vista', () {
    // Al activar A «se navega»: A desaparece y aparece C en el mismo sitio.
    var pantalla = 1;
    final activados = <String>[];
    final c = GazeController(muestrasSuavizado: 1);
    c.registrar(
      'A',
      ObjetivoMirada(
        rect: () => pantalla == 1 ? rectA : null,
        activar: () {
          activados.add('A');
          pantalla = 2;
        },
      ),
    );
    c.registrar(
      'C',
      ObjetivoMirada(
        rect: () => pantalla == 2 ? rectA : null,
        activar: () => activados.add('C'),
      ),
    );
    var t = Duration.zero;
    void mirar(Offset p, int ms) {
      for (final fin = t + Duration(milliseconds: ms); t < fin; t += paso) {
        c.procesar(p, t);
      }
    }

    mirar(rectA.center, 1600);
    expect(activados, ['A']);
    mirar(rectA.center, 3000); // la vista sigue en el mismo sitio
    expect(activados, ['A'], reason: 'C no se activa solo');
    expect(c.bloqueado, isNull);
    // Apartar la vista y volver: ahora sí.
    mirar(const Offset(150, 600), 100);
    mirar(rectA.center, 1600);
    expect(activados, ['A', 'C']);
  });
}
