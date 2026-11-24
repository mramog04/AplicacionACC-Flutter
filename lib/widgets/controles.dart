import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../gaze/gaze_config.dart';
import '../gaze/gaze_target.dart';
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
              // El error se marca también con un icono, no solo con el rojo.
              suffixIcon: widget.error == null
                  ? null
                  : const Icon(Icons.error_outline, color: AppColors.error),
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
///
/// El OutlinedButton ya junta todos los textos en un único nodo con rol de
/// botón; [etiquetaSemantica] solo hace falta cuando lo visible se leería
/// mal (p. ej. «6 × 0,95 €»).
class BotonFila extends StatelessWidget implements ControlDeMirada {
  const BotonFila({
    super.key,
    required this.titulo,
    required this.alPulsar,
    this.subtitulo,
    this.extra,
    this.etiquetaSemantica,
  });

  final String titulo;
  final String? subtitulo;
  final String? extra;
  final String? etiquetaSemantica;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    // Con el texto muy grande el precio baja a su propia línea para que el
    // título no se quede en una columna estrecha.
    final textoGrande = MediaQuery.textScalerOf(context).scale(1) >= 2;
    final textosFila = [
      Text(titulo, style: textos.titleMedium),
      if (subtitulo != null) Text(subtitulo!, style: textos.bodySmall),
      if (extra != null && textoGrande) Text(extra!, style: textos.titleMedium),
    ];
    Widget contenido = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: textosFila,
          ),
        ),
        if (extra != null && !textoGrande) ...[
          const SizedBox(width: AppSizes.separacion),
          Text(extra!, style: textos.titleMedium),
        ],
        const SizedBox(width: AppSizes.separacion),
        // Decorativo: sin etiqueta, no genera nodo semántico.
        const Icon(Icons.chevron_right, color: AppColors.textoPrincipal),
      ],
    );
    if (etiquetaSemantica != null) {
      contenido = Semantics(
        label: etiquetaSemantica,
        child: ExcludeSemantics(child: contenido),
      );
    }
    return GazeTarget(
      etiqueta: titulo,
      alActivar: alPulsar,
      altoMinimo: GazeConfig.altoFilaMirada,
      child: OutlinedButton(
        onPressed: alPulsar,
        style: OutlinedButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsets.all(AppSizes.margen),
        ),
        child: contenido,
      ),
    );
  }
}

/// Selector de unidades: «−», valor y «+».
///
/// Semántica: dos botones con nombre propio («Disminuir unidades» /
/// «Aumentar unidades») y, entre ellos, un nodo «Unidades» con el valor
/// actual que además se puede ajustar deslizando arriba/abajo (TalkBack) como
/// un control deslizante.
class SelectorUnidades extends StatelessWidget {
  const SelectorUnidades({
    super.key,
    required this.valor,
    required this.alCambiar,
    this.minimo = 1,
    this.separacion = AppSizes.separacion,
    this.tamanoBoton = AppSizes.minControl,
    this.centrado = false,
  });

  final int valor;
  final int minimo;
  final ValueChanged<int> alCambiar;

  /// Hueco entre «−», valor y «+» (mayor en el modo mirada).
  final double separacion;

  /// Centrado a lo ancho (modo mirada).
  final bool centrado;

  /// Lado mínimo de los botones «−» y «+».
  final double tamanoBoton;

  @override
  Widget build(BuildContext context) {
    final puedeBajar = valor > minimo;
    void bajar() => alCambiar(valor - 1);
    void subir() => alCambiar(valor + 1);
    final estiloBoton = IconButton.styleFrom(
      minimumSize: Size.square(tamanoBoton),
    );
    // Sin claves de orden, Flutter ordena por geometría y leía el valor antes
    // que «−». Se fuerza el orden visual: «−», valor, «+».
    Widget enOrden(double orden, Widget hijo) =>
        Semantics(sortKey: OrdinalSortKey(orden), child: hijo);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Wrap(
        spacing: separacion,
        runSpacing: separacion,
        alignment: centrado ? WrapAlignment.center : WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          enOrden(
            0,
            _BotonIcono(
              etiqueta: 'Disminuir unidades',
              icono: Icons.remove,
              alPulsar: puedeBajar ? bajar : null,
              estilo: estiloBoton,
            ),
          ),
          enOrden(
            1,
            Semantics(
              label: 'Unidades',
              value: '$valor',
              increasedValue: '${valor + 1}',
              decreasedValue: puedeBajar ? '${valor - 1}' : null,
              onIncrease: subir,
              onDecrease: puedeBajar ? bajar : null,
              child: ExcludeSemantics(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: AppSizes.minControl,
                    minHeight: AppSizes.minControl,
                  ),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Text(
                      '$valor',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
            ),
          ),
          enOrden(
            2,
            _BotonIcono(
              etiqueta: 'Aumentar unidades',
              icono: Icons.add,
              alPulsar: subir,
              estilo: estiloBoton,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón de solo icono con nombre accesible.
///
/// El nombre va en la etiqueta del icono (`semanticLabel`), que es lo que lee
/// el lector. El tooltip (visible al mantener pulsado) se excluye de la
/// semántica: si no, el nombre se leería dos veces.
class _BotonIcono extends StatelessWidget {
  const _BotonIcono({
    required this.etiqueta,
    required this.icono,
    required this.alPulsar,
    required this.estilo,
  });

  final String etiqueta;
  final IconData icono;
  final VoidCallback? alPulsar;
  final ButtonStyle estilo;

  @override
  Widget build(BuildContext context) {
    return GazeTarget(
      etiqueta: etiqueta,
      alActivar: alPulsar,
      child: Tooltip(
        message: etiqueta,
        excludeFromSemantics: true,
        child: IconButton(
          onPressed: alPulsar,
          style: estilo,
          icon: Icon(icono, semanticLabel: etiqueta),
        ),
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
