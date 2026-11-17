import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    final hayBotones = botonIzquierdo != null || botonDerecho != null;
    final altoMaxBarra = MediaQuery.sizeOf(context).height * fraccionMaxBarra;
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
                      const SizedBox(width: AppSizes.separacion),
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
            i == 0 ? AppSizes.margen : separacion,
            AppSizes.margen,
            i == contenido.length - 1 ? margenInferior : 0,
          ),
          child: hijo,
        ),
    ];
    final cuerpo = ListView(
      // Sin SafeArea arriba si la barra va dentro: ya la aplica ella.
      padding: EdgeInsets.zero,
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
