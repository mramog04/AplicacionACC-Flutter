import 'package:flutter/foundation.dart';

import 'datos_ejemplo.dart';

/// Estado de la aplicación en memoria (sin backend ni base de datos: se
/// pierde al cerrar la app). Las pantallas lo escuchan con
/// `ListenableBuilder` y se redibujan cuando cambia.
class Almacen extends ChangeNotifier {
  Almacen() {
    reiniciar();
  }

  late List<ListaCompra> _listas;
  late int _siguienteId;

  List<ListaCompra> get listas => List.unmodifiable(_listas);

  /// Vuelve a las listas de ejemplo (lo usan los tests entre pruebas).
  void reiniciar() {
    _listas = crearListasEjemplo();
    _siguienteId = _listas.length + 1;
    notifyListeners();
  }

  ListaCompra? lista(String id) {
    for (final l in _listas) {
      if (l.id == id) return l;
    }
    return null;
  }

  LineaLista? linea(String idLista, String idProducto) {
    for (final l in lista(idLista)?.lineas ?? const <LineaLista>[]) {
      if (l.producto.id == idProducto) return l;
    }
    return null;
  }

  ListaCompra crearLista(String nombre) {
    final nueva = ListaCompra(
      id: '${_siguienteId++}',
      nombre: nombre,
      lineas: [],
    );
    _listas.add(nueva);
    notifyListeners();
    return nueva;
  }

  void borrarLista(String id) {
    _listas.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  /// Añade [producto] a la lista. Si ya estaba, suma las unidades (la
  /// interfaz evita este caso llevando a la ficha del producto existente).
  void anadirProducto(String idLista, Producto producto, int unidades) {
    final existente = linea(idLista, producto.id);
    if (existente != null) {
      existente.unidades += unidades;
    } else {
      lista(idLista)?.lineas.add(LineaLista(producto, unidades));
    }
    notifyListeners();
  }

  void fijarUnidades(String idLista, String idProducto, int unidades) {
    linea(idLista, idProducto)?.unidades = unidades;
    notifyListeners();
  }

  void marcar(String idLista, String idProducto, bool marcada) {
    linea(idLista, idProducto)?.marcada = marcada;
    notifyListeners();
  }
}

/// Única instancia, compartida por todas las pantallas.
final almacen = Almacen();
