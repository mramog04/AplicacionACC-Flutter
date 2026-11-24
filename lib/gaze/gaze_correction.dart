import 'dart:ui';

/// Corrección lineal por eje de la mirada estimada: `real = a · medida + b`.
///
/// La estimación tiende a encogerse hacia el centro, así que al mirar un
/// borde se queda corta. Se ajusta (mínimos cuadrados) con lo medido al mirar
/// unos puntos conocidos tras la calibración.
class CorreccionMirada {
  const CorreccionMirada({this.ax = 1, this.bx = 0, this.ay = 1, this.by = 0});

  final double ax, bx, ay, by;

  static const identidad = CorreccionMirada();

  /// Límites de la escala: fuera de ellos la medida no es de fiar.
  static const _escalaMin = 0.5;
  static const _escalaMax = 3.0;

  Offset aplicar(Offset p) => Offset(ax * p.dx + bx, ay * p.dy + by);

  /// Ajusta con pares (punto real, mirada medida). Con menos de 3 pares, o en
  /// un eje sin variación suficiente, no corrige.
  static CorreccionMirada ajustar(List<(Offset, Offset)> pares) {
    if (pares.length < 3) return identidad;
    (double, double) eje(double Function(Offset) v) {
      var mReal = 0.0, mMedida = 0.0;
      for (final (real, medida) in pares) {
        mReal += v(real) / pares.length;
        mMedida += v(medida) / pares.length;
      }
      var cov = 0.0, varianza = 0.0;
      for (final (real, medida) in pares) {
        cov += (v(medida) - mMedida) * (v(real) - mReal);
        varianza += (v(medida) - mMedida) * (v(medida) - mMedida);
      }
      // Menos de 20 px de desviación media: ruido. O relación inversa.
      if (varianza / pares.length < 400 || cov <= 0) return (1, 0);
      final a = (cov / varianza).clamp(_escalaMin, _escalaMax);
      return (a, mReal - a * mMedida);
    }

    final (ax, bx) = eje((o) => o.dx);
    final (ay, by) = eje((o) => o.dy);
    return CorreccionMirada(ax: ax, bx: bx, ay: ay, by: by);
  }

  /// Mediana por eje (resiste valores atípicos).
  static Offset mediana(List<Offset> muestras) {
    double m(Iterable<double> vs) {
      final l = vs.toList()..sort();
      return l[l.length ~/ 2];
    }

    return Offset(m(muestras.map((o) => o.dx)), m(muestras.map((o) => o.dy)));
  }
}
