# Evidencias de accesibilidad: Grupo Q, lista de la compra

| Apartado | Archivo |
|---|---|
| (a) Widget estándar cuya semántica ya es suficiente | [a_semantica_estandar_suficiente.md](a_semantica_estandar_suficiente.md) |
| (b) Casos donde hubo que añadir o corregir `Semantics` | [b_semantics_anadida_o_corregida.md](b_semantics_anadida_o_corregida.md) |
| (c) Orden de lectura esperado de pantallas relevantes | [c_orden_de_lectura.md](c_orden_de_lectura.md) |
| (d) Mensaje de error y cómo se anuncia | [d_mensaje_de_error.md](d_mensaje_de_error.md) |
| (e) Control por mirada (experimental): parámetros, limitaciones y cómo probarlo | [e_control_por_mirada.md](e_control_por_mirada.md) |
| Resultado de la última ejecución de `flutter test` | [resultados_tests.txt](resultados_tests.txt) |

## Qué cubren las pruebas automáticas

| Archivo | Qué comprueba |
|---|---|
| `test/recorridos_test.dart` | Los 3 recorridos completos usando solo `find.bySemanticsLabel`, con el texto al 100 %, 200 % y 300 %. También: producto repetido, borrar lista con confirmación y «Terminar lista» deshabilitado en una lista vacía. |
| `test/guias_test.dart` | `androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline` y una separación de al menos 8 px entre controles, en 12 pantallas o estados y a dos escalas (1,0 y 2,0). |
| `test/escalado_test.dart` | 7 pantallas con `textScaler` lineal 2,0 y 3,0 en un móvil de 412 × 915: sin desbordes, con todo el contenido alcanzable y sin controles tapados. |
| `test/semantica_test.dart` | Regiones vivas cuando la plataforma no admite anuncios, que el foco no se mueve, un único h1 que nombra la ruta, el selector de unidades ajustable, el orden de lectura y que los iconos decorativos no generan nodos. |
| `test/widget_test.dart` | El recorrido original por las 7 pantallas, al 100 % y 200 %, y el tamaño mínimo de 48 × 48. |
| `test/gaze_*_test.dart` | El control por mirada con muestras simuladas, sin cámara (ver (e)). |

## Lo que NO está verificado aquí

El comportamiento real de **TalkBack** (cómo pronuncia cada nodo, el orden con gestos y si anuncia las regiones vivas) depende del dispositivo y de la versión de Android. Las pruebas comprueban el árbol semántico que Flutter entrega al sistema, no lo que el lector hace después. Esto queda pendiente de probar en un móvil o un emulador.
