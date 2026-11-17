import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
class TituloPantalla extends StatelessWidget {
  const TituloPantalla(this.texto, {super.key, this.centrado = false});

  final String texto;
  final bool centrado;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      headingLevel: 1,
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
/// │ cuerpo (desplazable)         │
/// ├──────────────────────────────┤
/// │ barraInferior (opcional)     │  barra inferior (#F2F2F2)
/// └──────────────────────────────┘
///
/// El título va en su propia línea, debajo de los botones, para que con el
/// texto al 200 % no tenga que competir por el ancho con ellos. Ninguna barra
/// tiene altura fija: crecen con el texto.
class PantallaBase extends StatelessWidget {
  const PantallaBase({
    super.key,
    required this.titulo,
    required this.cuerpo,
    this.botonIzquierdo,
    this.botonDerecho,
    this.barraInferior,
    this.botonFlotante,
  });

  final String titulo;
  final Widget cuerpo;
  final Widget? botonIzquierdo;
  final Widget? botonDerecho;
  final Widget? barraInferior;
  final Widget? botonFlotante;

  @override
  Widget build(BuildContext context) {
    final hayBotones = botonIzquierdo != null || botonDerecho != null;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
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
                      // Flexible (ajuste suelto) deja que el botón encoja si
                      // el texto es muy grande; el hueco sobrante lo reparte
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
                          if (botonDerecho != null)
                            Flexible(child: botonDerecho!),
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
          ),
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
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.margen),
                  child: barraInferior,
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
    return OutlinedButton.icon(
      onPressed: () => volver(context, alternativa),
      icon: const Icon(Icons.arrow_back),
      label: Text(texto),
    );
  }
}
