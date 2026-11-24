import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../gaze/gaze_config.dart';
import '../gaze/gaze_settings.dart';
import '../gaze/gaze_target.dart';
import '../theme.dart';

/// Vuelve a la pantalla anterior; si no la hay (p. ej. se entró por URL),
/// va a [alternativa].
void volver(BuildContext context, String alternativa) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(alternativa);
  }
}

/// Título único de la pantalla (h1).
///
/// `namesRoute` hace que el lector de pantalla lo lea al llegar a la
/// pantalla, igual que el título de un AppBar (aquí no se usa AppBar).
class TituloPantalla extends StatelessWidget {
  const TituloPantalla(this.texto, {super.key, this.centrado = false});

  final String texto;
  final bool centrado;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      headingLevel: 1,
      namesRoute: true,
      child: Text(
        texto,
        textAlign: centrado ? TextAlign.center : TextAlign.start,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}

/// Subtítulo de sección (h2) dentro de una pantalla.
class Subtitulo extends StatelessWidget {
  const Subtitulo(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      headingLevel: 2,
      child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// Esqueleto común de todas las pantallas (salvo la de carga):
///
/// ┌──────────────────────────────┐
/// │ [izquierdo]        [derecho] │  barra superior (#F2F2F2)
/// │ Título (h1)                  │
/// ├──────────────────────────────┤
/// │ contenido (desplazable)      │
/// ├──────────────────────────────┤
/// │ barraInferior (opcional)     │  barra inferior (#F2F2F2)
/// └──────────────────────────────┘
///
/// El título va en su propia línea, debajo de los botones, para que con el
/// texto al 200 % no tenga que competir por el ancho con ellos. Ninguna barra
/// tiene altura fija: crecen con el texto. Para que con el texto muy grande
/// no dejen sin sitio al contenido:
/// - la barra inferior ocupa como mucho [fraccionMaxBarra] de la altura (si
///   no le cabe, se desplaza dentro);
/// - desde [escalaBarraDesplazable] la barra superior deja de ser fija y pasa
///   a ser el primer elemento del desplazamiento, como un AppBar que se
///   recoge. Se usa un único ListView (y no NestedScrollView) para que
///   «mostrar en pantalla» (lo que hace TalkBack al mover el foco) funcione
///   bien: con NestedScrollView la cabecera volvía a desplegarse y sacaba de
///   la pantalla el elemento enfocado.
class PantallaBase extends StatelessWidget {
  const PantallaBase({
    super.key,
    required this.titulo,
    required this.contenido,
    this.separacion = AppSizes.separacion,
    this.margenInferior = AppSizes.margen,
    this.botonIzquierdo,
    this.botonDerecho,
    this.barraInferior,
    this.botonFlotante,
  });

  final String titulo;

  /// Elementos del cuerpo, de arriba abajo.
  final List<Widget> contenido;

  /// Hueco vertical entre elementos del contenido.
  final double separacion;

  /// Espacio al final del contenido (p. ej. para que un botón flotante no
  /// tape el último elemento).
  final double margenInferior;

  final Widget? botonIzquierdo;
  final Widget? botonDerecho;
  final Widget? barraInferior;
  final Widget? botonFlotante;

  static const double fraccionMaxBarra = 0.35;
  static const double escalaBarraDesplazable = 2;

  /// En modo mirada los botones son mayores: la barra puede ocupar más.
  static const double fraccionMaxBarraMirada = 0.5;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: mirada,
    builder: (context, _) => _construir(context),
  );

  /// Hueco encima del elemento [i] del contenido. En modo mirada, dos
  /// controles seguidos se separan más.
  double _huecoEncima(int i) {
    if (i == 0) return AppSizes.margen;
    final controlesSeguidos =
        contenido[i] is ControlDeMirada && contenido[i - 1] is ControlDeMirada;
    return mirada.activo && controlesSeguidos
        ? GazeConfig.separacionMirada
        : separacion;
  }

  Widget _construir(BuildContext context) {
    final hayBotones = botonIzquierdo != null || botonDerecho != null;
    final altoMaxBarra =
        MediaQuery.sizeOf(context).height *
        (mirada.activo ? fraccionMaxBarraMirada : fraccionMaxBarra);
    final barraDesplazable =
        MediaQuery.textScalerOf(context).scale(1) >= escalaBarraDesplazable;

    final barraSuperior = DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.fondoBarras,
        border: Border(bottom: BorderSide(color: AppColors.bordeSuave)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.margen,
            AppSizes.separacion,
            AppSizes.margen,
            AppSizes.margen,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hayBotones) ...[
                // Flexible (ajuste suelto) deja que el botón encoja si el
                // texto es muy grande; el hueco sobrante lo reparte
                // mainAxisAlignment, así el derecho queda a la derecha.
                Row(
                  mainAxisAlignment: botonIzquierdo == null
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.spaceBetween,
                  children: [
                    if (botonIzquierdo != null)
                      Flexible(child: botonIzquierdo!),
                    if (botonIzquierdo != null && botonDerecho != null)
                      SizedBox(width: mirada.separacionBotones),
                    if (botonDerecho != null) Flexible(child: botonDerecho!),
                  ],
                ),
                const SizedBox(height: AppSizes.separacion),
              ] else
                const SizedBox(height: AppSizes.separacion),
              TituloPantalla(titulo),
            ],
          ),
        ),
      ),
    );

    final elementos = [
      for (final (i, hijo) in contenido.indexed)
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSizes.margen,
            _huecoEncima(i),
            AppSizes.margen,
            i == contenido.length - 1 ? margenInferior : 0,
          ),
          child: hijo,
        ),
    ];
    final cuerpo = _CuerpoDesplazable(
      hayBarraInferior: barraInferior != null,
      hayBotonFlotante: botonFlotante != null,
      children: [if (barraDesplazable) barraSuperior, ...elementos],
    );

    return Scaffold(
      body: barraDesplazable
          ? cuerpo
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                barraSuperior,
                Expanded(child: cuerpo),
              ],
            ),
      bottomNavigationBar: barraInferior == null
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.fondoBarras,
                border: Border(top: BorderSide(color: AppColors.bordeSuave)),
              ),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: altoMaxBarra),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.margen),
                    child: barraInferior,
                  ),
                ),
              ),
            ),
      floatingActionButton: botonFlotante,
    );
  }
}

/// Contenido desplazable de la pantalla. En modo mirada, si no cabe, añade a
/// la derecha un carril con «Subir» y «Bajar» (con la vista no se puede
/// arrastrar) y deja un hueco antes de la barra inferior.
class _CuerpoDesplazable extends StatefulWidget {
  const _CuerpoDesplazable({
    required this.children,
    required this.hayBarraInferior,
    required this.hayBotonFlotante,
  });

  final List<Widget> children;
  final bool hayBarraInferior;
  final bool hayBotonFlotante;

  @override
  State<_CuerpoDesplazable> createState() => _CuerpoDesplazableState();
}

class _CuerpoDesplazableState extends State<_CuerpoDesplazable> {
  final _scroll = ScrollController();

  /// El carril no se quita una vez puesto: al estrechar el contenido podría
  /// hacer falta o no alternativamente, y la pantalla parpadearía.
  bool _noCabe = false;
  bool _puedeSubir = false;
  bool _puedeBajar = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _alCambiar(ScrollMetrics m) {
    if (m.axis != Axis.vertical) return false;
    final noCabe = _noCabe || m.maxScrollExtent > 0;
    final subir = m.pixels > 0.5;
    final bajar = m.pixels < m.maxScrollExtent - 0.5;
    if (noCabe != _noCabe || subir != _puedeSubir || bajar != _puedeBajar) {
      // La notificación puede llegar durante el layout.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _noCabe = noCabe;
          _puedeSubir = subir;
          _puedeBajar = bajar;
        });
      });
    }
    return false;
  }

  void _desplazar(int sentido) {
    final m = _scroll.position;
    final destino =
        (m.pixels +
                sentido *
                    m.viewportDimension *
                    GazeConfig.fraccionDesplazamiento)
            .clamp(m.minScrollExtent, m.maxScrollExtent);
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(destino);
    } else {
      _scroll.animateTo(
        destino,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => n.depth == 0 && _alCambiar(n.metrics),
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (n) => n.depth == 0 && _alCambiar(n.metrics),
        child: ListView(
          controller: _scroll,
          // Sin SafeArea arriba si la barra va dentro: ya la aplica ella.
          padding: EdgeInsets.zero,
          children: widget.children,
        ),
      ),
    );
    final activo = mirada.activo;
    return Padding(
      padding: EdgeInsets.only(
        bottom: activo && widget.hayBarraInferior
            ? GazeConfig.separacionMirada - AppSizes.margen
            : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            // El borde de las casillas se pinta en el Material más cercano:
            // sin este, se salía de la zona de la lista.
            child: Material(
              type: MaterialType.transparency,
              clipBehavior: Clip.hardEdge,
              child: lista,
            ),
          ),
          if (activo && _noCabe) _carril(context),
        ],
      ),
    );
  }

  Widget _carril(BuildContext context) {
    final textoGrande = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    Widget boton(String texto, IconData icono, bool puede, int sentido) {
      final accion = puede ? () => _desplazar(sentido) : null;
      return Flexible(
        child: GazeTarget(
          etiqueta: texto,
          alActivar: accion,
          child: OutlinedButton(
            onPressed: accion,
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(4)),
            child: textoGrande
                ? Icon(icono, size: 40, semanticLabel: texto)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(icono, size: 28), Text(texto)],
                  ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        GazeConfig.separacionMirada - AppSizes.margen,
        AppSizes.margen,
        AppSizes.margen,
        // Que el botón flotante no quede encima de «Bajar».
        widget.hayBotonFlotante
            ? 104 + AppSizes.margen + GazeConfig.separacionMirada
            : AppSizes.margen,
      ),
      child: SizedBox(
        width: GazeConfig.anchoCarrilMirada,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            boton('Subir', Icons.arrow_upward, _puedeSubir, -1),
            boton('Bajar', Icons.arrow_downward, _puedeBajar, 1),
          ],
        ),
      ),
    );
  }
}

/// Botón «Atrás» con icono y texto.
class BotonAtras extends StatelessWidget {
  const BotonAtras({
    super.key,
    required this.alternativa,
    this.texto = 'Atrás',
  });

  /// Ruta a la que ir si no hay pantalla anterior en la pila.
  final String alternativa;
  final String texto;

  @override
  Widget build(BuildContext context) {
    void accion() => volver(context, alternativa);
    return GazeTarget(
      etiqueta: texto,
      alActivar: accion,
      child: OutlinedButton.icon(
        onPressed: accion,
        icon: const Icon(Icons.arrow_back),
        label: Text(texto),
      ),
    );
  }
}
