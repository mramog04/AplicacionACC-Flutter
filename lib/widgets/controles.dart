import 'package:flutter/material.dart';

import '../theme.dart';

/// Campo de texto con la etiqueta siempre visible encima.
///
/// La etiqueta visible se excluye de la semántica y se asigna al propio campo
/// para que el lector de pantalla la lea una sola vez, asociada al campo.
/// Tocar la etiqueta también enfoca el campo.
class CampoTexto extends StatefulWidget {
  const CampoTexto({
    super.key,
    required this.etiqueta,
    this.controller,
    this.pista,
    this.error,
    this.iconoPrefijo,
    this.autofocus = false,
    this.accionTeclado,
    this.alCambiar,
    this.alEnviar,
  });

  final String etiqueta;
  final TextEditingController? controller;
  final String? pista;
  final String? error;
  final IconData? iconoPrefijo;
  final bool autofocus;
  final TextInputAction? accionTeclado;
  final ValueChanged<String>? alCambiar;
  final ValueChanged<String>? alEnviar;

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  final _foco = FocusNode();

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: GestureDetector(
            onTap: _foco.requestFocus,
            child: Text(
              widget.etiqueta,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Semantics(
          label: widget.etiqueta,
          child: TextField(
            focusNode: _foco,
            controller: widget.controller,
            autofocus: widget.autofocus,
            textInputAction: widget.accionTeclado,
            onChanged: widget.alCambiar,
            onSubmitted: widget.alEnviar,
            decoration: InputDecoration(
              hintText: widget.pista,
              errorText: widget.error,
              prefixIcon: widget.iconoPrefijo == null
                  ? null
                  : Icon(widget.iconoPrefijo),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fila pulsable de una lista (lista de la compra, producto, resultado…).
/// Es un botón secundario a lo ancho, con título, subtítulo opcional y
/// un texto a la derecha opcional (precio).
class BotonFila extends StatelessWidget {
  const BotonFila({
    super.key,
    required this.titulo,
    required this.alPulsar,
    this.subtitulo,
    this.extra,
  });

  final String titulo;
  final String? subtitulo;
  final String? extra;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return OutlinedButton(
      onPressed: alPulsar,
      style: OutlinedButton.styleFrom(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.all(AppSizes.margen),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: textos.titleMedium),
                if (subtitulo != null)
                  Text(subtitulo!, style: textos.bodySmall),
              ],
            ),
          ),
          if (extra != null) ...[
            const SizedBox(width: AppSizes.separacion),
            Text(extra!, style: textos.titleMedium),
          ],
          const SizedBox(width: AppSizes.separacion),
          const Icon(Icons.chevron_right, color: AppColors.textoPrincipal),
        ],
      ),
    );
  }
}

/// Dibuja el contorno de foco de 3 px alrededor de [child] cuando él o
/// cualquiera de sus descendientes tiene el foco. Para controles que no son
/// botones (p. ej. RadioListTile) y no usan [BordeConFoco].
class AnilloFoco extends StatefulWidget {
  const AnilloFoco({super.key, required this.child});

  final Widget child;

  @override
  State<AnilloFoco> createState() => _AnilloFocoState();
}

class _AnilloFocoState extends State<AnilloFoco> {
  bool _conFoco = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (v) => setState(() => _conFoco = v),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radio),
          border: _conFoco
              ? Border.all(color: AppColors.acento, width: AppSizes.bordeFoco)
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Lista vertical con 8 px de separación entre elementos y margen de 16 px.
class ListaSeparada extends StatelessWidget {
  const ListaSeparada({super.key, required this.children, this.margenInferior});

  final List<Widget> children;

  /// Espacio extra al final (p. ej. para que un botón flotante no tape nada).
  final double? margenInferior;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSizes.margen,
        AppSizes.margen,
        AppSizes.margen,
        margenInferior ?? AppSizes.margen,
      ),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSizes.separacion),
      itemBuilder: (_, i) => children[i],
    );
  }
}
