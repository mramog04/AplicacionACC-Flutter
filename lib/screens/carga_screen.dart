import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../theme.dart';
import '../widgets/controles.dart';
import '../widgets/pantalla_base.dart';

/// 1. Carga: círculo de carga alrededor del logotipo. Al tocar en cualquier
/// parte (o pulsar Intro/Espacio con el teclado) se va a Mis listas.
class CargaScreen extends StatelessWidget {
  const CargaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Si el sistema pide reducir animaciones, el círculo se muestra quieto.
    final sinAnimaciones = MediaQuery.of(context).disableAnimations;
    void continuar() => context.go(Rutas.misListas);

    return Scaffold(
      body: Stack(
        children: [
          // Toda la pantalla es un único botón.
          Positioned.fill(
            child: Semantics(
              button: true,
              label: 'Continuar a Mis listas',
              excludeSemantics: true,
              // Sin relleno de foco: con teclado se ve el contorno de 3 px.
              child: AnilloFoco(
                child: InkWell(
                  focusColor: Colors.transparent,
                  onTap: continuar,
                ),
              ),
            ),
          ),
          // El contenido se puede desplazar (con el texto muy grande o en
          // horizontal puede no caber) y tocarlo también continúa. El
          // GestureDetector se excluye de la semántica: el botón ya es el de
          // debajo y no debe aparecer dos veces.
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.margen),
                child: GestureDetector(
                  onTap: continuar,
                  excludeFromSemantics: true,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const TituloPantalla(
                        'Lista de la compra',
                        centrado: true,
                      ),
                      const SizedBox(height: 32),
                      SizedBox.square(
                        dimension: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: sinAnimaciones ? 1 : null,
                                strokeWidth: 6,
                                semanticsLabel: 'Cargando',
                              ),
                            ),
                            const Icon(
                              Icons.shopping_basket,
                              size: 80,
                              color: AppColors.acento,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Toca la pantalla para continuar',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
