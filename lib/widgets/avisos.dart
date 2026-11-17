import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme.dart';

/// Pide al lector de pantalla que lea [mensaje] sin mover el foco.
///
/// Sigue el mismo criterio que Flutter usa en sus propios widgets
/// (InputDecorator, Form, CalendarDatePicker): si la plataforma admite
/// anuncios (`MediaQuery.supportsAnnounce`) se envía uno; si no (p. ej.
/// Android 16, que los ha retirado), no se hace nada aquí y el mensaje debe
/// estar visible dentro de una región viva ([RegionViva], el `errorText` de
/// un campo o un SnackBar), que es lo que el lector anuncia en ese caso.
void anunciar(BuildContext context, String mensaje) {
  if (!MediaQuery.supportsAnnounceOf(context)) return;
  SemanticsService.sendAnnouncement(
    View.of(context),
    mensaje,
    Directionality.of(context),
  );
}

/// Contenido visible que el lector de pantalla anuncia cuando aparece (si
/// [anunciarAlAparecer]) y cada vez que cambia [mensaje], sin mover el foco.
///
/// [mensaje] es lo que se lee; el [child] visual se excluye de la semántica
/// para que no se lea dos veces.
class RegionViva extends StatefulWidget {
  const RegionViva({
    super.key,
    required this.mensaje,
    required this.child,
    this.anunciarAlAparecer = true,
  });

  final String mensaje;
  final Widget child;
  final bool anunciarAlAparecer;

  @override
  State<RegionViva> createState() => _RegionVivaState();
}

class _RegionVivaState extends State<RegionViva> {
  @override
  void initState() {
    super.initState();
    if (widget.anunciarAlAparecer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) anunciar(context, widget.mensaje);
      });
    }
  }

  @override
  void didUpdateWidget(RegionViva old) {
    super.didUpdateWidget(old);
    if (old.mensaje != widget.mensaje) anunciar(context, widget.mensaje);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      // En Android la región viva solo se anuncia si cambia su etiqueta, por
      // eso el texto va en `label` y no en `value`.
      liveRegion: !MediaQuery.supportsAnnounceOf(context),
      label: widget.mensaje,
      child: ExcludeSemantics(child: widget.child),
    );
  }
}

/// Tipo de aviso: cambia el icono (forma) además del texto, para no
/// depender solo del color.
enum TipoAviso {
  exito(Icons.check_circle_outline, 'Hecho'),
  informacion(Icons.info_outline, 'Aviso');

  const TipoAviso(this.icono, this.prefijo);
  final IconData icono;
  final String prefijo;
}

/// Muestra un SnackBar con icono y texto. El SnackBar de Flutter ya es una
/// región viva (lo anuncia el lector) y no roba el foco.
void mostrarAviso(
  BuildContext context,
  String texto, {
  TipoAviso tipo = TipoAviso.exito,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(tipo.icono, color: AppColors.blanco),
          const SizedBox(width: AppSizes.separacion),
          Expanded(
            child: Text(texto, semanticsLabel: '${tipo.prefijo}: $texto'),
          ),
        ],
      ),
    ),
  );
}
