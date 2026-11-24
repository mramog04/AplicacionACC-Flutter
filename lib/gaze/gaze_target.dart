import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/avisos.dart';
import 'gaze_config.dart';
import 'gaze_controller.dart';
import 'gaze_settings.dart';

/// Marca los widgets que son un control de mirada dentro del contenido de
/// una pantalla (filas, casillas): con el modo activo, [PantallaBase] los
/// separa más entre sí.
abstract interface class ControlDeMirada {}

/// Envuelve un control para que se pueda activar con la mirada.
///
/// - Con el modo desactivado no añade nada visible ni semántico.
/// - Con el modo activo agranda el control hasta el tamaño mínimo de mirada,
///   registra su rectángulo en el [GazeController] y,
///   cuando está bloqueado, dibuja un borde grueso de acento y una barra con
///   el progreso del dwell (no se dibuja ningún punto de mirada).
/// - Al activarse ejecuta [alActivar] (la misma acción que un toque) y lo
///   anuncia al lector de pantalla.
class GazeTarget extends StatefulWidget {
  const GazeTarget({
    super.key,
    required this.etiqueta,
    required this.alActivar,
    required this.child,
  });

  /// Nombre del control para el anuncio («Activado con la mirada: …»).
  final String etiqueta;

  /// null = control deshabilitado: no se puede bloquear.
  final VoidCallback? alActivar;

  final Widget child;

  @override
  State<GazeTarget> createState() => _GazeTargetState();
}

class _GazeTargetState extends State<GazeTarget> {
  final _id = Object();
  final _clave = GlobalKey();
  ModalRoute<Object?>? _ruta;
  ScrollableState? _scroll;
  Size _pantalla = Size.zero;

  GazeController get _ctrl => mirada.controlador;

  @override
  void dispose() {
    _ctrl.anularRegistro(_id);
    super.dispose();
  }

  /// Rectángulo visible ahora (recortado por su zona desplazable y por la
  /// pantalla), o null si no está en la ruta visible o no se ve.
  Rect? _rect() {
    if (!mounted || widget.alActivar == null) return null;
    if (_ruta != null && !_ruta!.isCurrent) return null;
    final caja = _clave.currentContext?.findRenderObject() as RenderBox?;
    if (caja == null || !caja.attached || !caja.hasSize) return null;
    var r = caja.localToGlobal(Offset.zero) & caja.size;
    final cajaScroll = _scroll?.context.findRenderObject() as RenderBox?;
    if (cajaScroll != null && cajaScroll.attached && cajaScroll.hasSize) {
      r = r.intersect(cajaScroll.localToGlobal(Offset.zero) & cajaScroll.size);
    }
    r = r.intersect(Offset.zero & _pantalla);
    // Un control que asoma por el borde no cuenta: quedaría pegado al de la
    // barra de al lado. Hay que desplazar hasta verlo bien.
    final altoNecesario = math.min(
      caja.size.height * 0.6,
      GazeConfig.ladoMinimoMirada,
    );
    return r.width > 0 && r.height > 0 && r.height >= altoNecesario ? r : null;
  }

  void _activar() {
    final accion = widget.alActivar;
    if (!mounted || accion == null) return;
    // Se anuncia antes: la acción puede cerrar la pantalla.
    anunciar(context, 'Activado con la mirada: ${widget.etiqueta}');
    accion();
  }

  @override
  Widget build(BuildContext context) {
    _ruta = ModalRoute.of(context);
    _scroll = Scrollable.maybeOf(context);
    _pantalla = MediaQuery.sizeOf(context);
    final hijo = KeyedSubtree(key: _clave, child: widget.child);
    return ListenableBuilder(
      listenable: mirada,
      builder: (context, _) {
        if (!mirada.activo) {
          _ctrl.anularRegistro(_id);
          return hijo;
        }
        _ctrl.registrar(_id, ObjetivoMirada(rect: _rect, activar: _activar));
        return Stack(
          // passthrough: el control conserva las restricciones de su padre
          // (p. ej. un botón estirado a lo ancho sigue estirado).
          fit: StackFit.passthrough,
          clipBehavior: Clip.none,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: GazeConfig.ladoMinimoMirada,
                minHeight: GazeConfig.ladoMinimoMirada,
              ),
              child: hijo,
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: ListenableBuilder(
                    listenable: _ctrl,
                    builder: (context, _) => _ctrl.bloqueado == _id
                        ? _Seleccion(progreso: _ctrl.progreso)
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Indicador del control bloqueado: borde grueso + barra de progreso. Forma
/// y movimiento, no solo color.
class _Seleccion extends StatelessWidget {
  const _Seleccion({required this.progreso});

  final double progreso;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -6,
          top: -6,
          right: -6,
          bottom: -6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.acento, width: 5),
              borderRadius: BorderRadius.circular(AppSizes.radio + 4),
            ),
          ),
        ),
        Positioned(
          left: 6,
          right: 6,
          bottom: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 6,
              color: AppColors.acento,
              backgroundColor: AppColors.fondoBarras,
            ),
          ),
        ),
      ],
    );
  }
}

/// Capa en la raíz de la app que pasa la posición del puntero a la fuente
/// de ratón. Siempre está en el árbol (para no reconstruir la navegación al
/// activar el modo) y no hace nada si el modo está desactivado.
class CapaMirada extends StatelessWidget {
  const CapaMirada({super.key, required this.child});

  final Widget child;

  void _puntero(PointerEvent e) {
    if (mirada.activo) mirada.raton.actualizarPuntero(e.position);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerHover: _puntero,
      onPointerMove: _puntero,
      onPointerDown: _puntero,
      child: child,
    );
  }
}
