// Datos de ejemplo fijos. No se guarda nada: es solo para poder navegar.

class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.marca,
    required this.formato,
    required this.precio,
    required this.descripcion,
  });

  final String id;
  final String nombre;
  final String marca;
  final String formato;
  final double precio;
  final String descripcion;
}

class LineaLista {
  const LineaLista(this.producto, this.unidades);

  final Producto producto;
  final int unidades;

  double get subtotal => producto.precio * unidades;
}

class ListaCompra {
  const ListaCompra({
    required this.id,
    required this.nombre,
    required this.lineas,
  });

  final String id;
  final String nombre;
  final List<LineaLista> lineas;

  double get total => lineas.fold(0, (suma, l) => suma + l.subtotal);
}

const productosEjemplo = <Producto>[
  Producto(
    id: 'p1',
    nombre: 'Leche entera',
    marca: 'Granja del Valle',
    formato: 'Brik de 1 litro',
    precio: 0.95,
    descripcion: 'Leche entera de vaca, UHT.',
  ),
  Producto(
    id: 'p2',
    nombre: 'Pan de molde integral',
    marca: 'Horno Real',
    formato: 'Paquete de 460 g',
    precio: 1.65,
    descripcion: 'Pan de molde de harina integral, sin corteza.',
  ),
  Producto(
    id: 'p3',
    nombre: 'Huevos camperos',
    marca: 'Corral Norte',
    formato: 'Docena',
    precio: 2.80,
    descripcion: 'Huevos de gallinas criadas en libertad, talla L.',
  ),
  Producto(
    id: 'p4',
    nombre: 'Tomates en rama',
    marca: 'Huerta Local',
    formato: 'Bandeja de 1 kg',
    precio: 2.25,
    descripcion: 'Tomates maduros en rama.',
  ),
  Producto(
    id: 'p5',
    nombre: 'Aceite de oliva virgen extra',
    marca: 'Olivar del Sur',
    formato: 'Botella de 1 litro',
    precio: 8.90,
    descripcion: 'Aceite de oliva virgen extra de primera prensada en frío.',
  ),
  Producto(
    id: 'p6',
    nombre: 'Pasta espagueti',
    marca: 'Molino Alto',
    formato: 'Paquete de 500 g',
    precio: 0.85,
    descripcion: 'Pasta de sémola de trigo duro.',
  ),
  Producto(
    id: 'p7',
    nombre: 'Queso curado',
    marca: 'Quesería Montaña',
    formato: 'Cuña de 250 g',
    precio: 4.10,
    descripcion: 'Queso de oveja curado durante 6 meses.',
  ),
  Producto(
    id: 'p8',
    nombre: 'Vino tinto',
    marca: 'Bodega Ribera',
    formato: 'Botella de 75 cl',
    precio: 6.50,
    descripcion: 'Vino tinto crianza.',
  ),
];

final listasEjemplo = <ListaCompra>[
  ListaCompra(
    id: '1',
    nombre: 'Compra semanal',
    lineas: [
      LineaLista(productosEjemplo[0], 6),
      LineaLista(productosEjemplo[1], 1),
      LineaLista(productosEjemplo[2], 1),
      LineaLista(productosEjemplo[3], 2),
    ],
  ),
  ListaCompra(
    id: '2',
    nombre: 'Cena del sábado',
    lineas: [
      LineaLista(productosEjemplo[5], 2),
      LineaLista(productosEjemplo[6], 1),
      LineaLista(productosEjemplo[7], 1),
    ],
  ),
];

ListaCompra? buscarLista(String id) {
  for (final l in listasEjemplo) {
    if (l.id == id) return l;
  }
  return null;
}

Producto? buscarProducto(String id) {
  for (final p in productosEjemplo) {
    if (p.id == id) return p;
  }
  return null;
}

/// Formatea un precio al estilo español: «12,35 €».
String formatearPrecio(double precio) =>
    '${precio.toStringAsFixed(2).replaceAll('.', ',')} €';

/// «1 producto» / «3 productos».
String contarProductos(int n) => n == 1 ? '1 producto' : '$n productos';
