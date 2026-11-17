import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router.dart';
import 'theme.dart';

void main() {
  runApp(const ListaCompraApp());
}

class ListaCompraApp extends StatelessWidget {
  const ListaCompraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // No se envuelve en MediaQuery ni se toca textScaler: se respeta el
    // tamaño de texto del sistema sin límite.
    return MaterialApp.router(
      title: 'Lista de la compra',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
