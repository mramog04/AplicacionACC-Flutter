import 'package:go_router/go_router.dart';

import 'screens/ajustes_screen.dart';
import 'screens/buscar_producto_screen.dart';
import 'screens/carga_screen.dart';
import 'screens/detalle_producto_screen.dart';
import 'screens/lista_screen.dart';
import 'screens/mis_listas_screen.dart';
import 'screens/nueva_lista_screen.dart';

/// Rutas de la aplicación. Las pantallas usan estos métodos en lugar de
/// escribir las URL a mano.
abstract final class Rutas {
  static const carga = '/';
  static const misListas = '/listas';
  static const nuevaLista = '/listas/nueva';
  static const ajustes = '/ajustes';
  static String lista(String id) => '/listas/$id';
  static String buscar(String id) => '/listas/$id/buscar';
  static String producto(String id, String pid) => '/listas/$id/producto/$pid';
}

/// Las rutas están anidadas para que, al navegar con `context.go`, la pila
/// contenga las pantallas padre y el botón «Atrás» (y el del navegador)
/// vuelva a ellas:
///
///   /                              Carga
///   /listas                        Mis listas
///   /listas/nueva                  Nueva lista
///   /listas/:id                    Lista
///   /listas/:id/buscar             Buscar producto
///   /listas/:id/producto/:pid      Detalle de producto
///   /ajustes                       Ajustes
final appRouter = GoRouter(
  initialLocation: Rutas.carga,
  routes: [
    GoRoute(path: Rutas.carga, builder: (_, _) => const CargaScreen()),
    GoRoute(
      path: Rutas.misListas,
      builder: (_, _) => const MisListasScreen(),
      routes: [
        // «nueva» va antes que «:id» para que no se interprete como un id.
        GoRoute(path: 'nueva', builder: (_, _) => const NuevaListaScreen()),
        GoRoute(
          path: ':id',
          builder: (_, state) => ListaScreen(id: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'buscar',
              builder: (_, state) =>
                  BuscarProductoScreen(idLista: state.pathParameters['id']!),
            ),
            GoRoute(
              path: 'producto/:pid',
              builder: (_, state) => DetalleProductoScreen(
                idLista: state.pathParameters['id']!,
                idProducto: state.pathParameters['pid']!,
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: Rutas.ajustes, builder: (_, _) => const AjustesScreen()),
  ],
);
