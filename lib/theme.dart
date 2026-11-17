import 'package:flutter/material.dart';

/// Paleta de la aplicación. Todos los colores de la interfaz salen de aquí.
abstract final class AppColors {
  static const textoPrincipal = Color(0xFF111111);
  static const textoSecundario = Color(0xFF444444);
  static const fondo = Color(0xFFFFFFFF);
  static const fondoBarras = Color(0xFFF2F2F2);
  static const bordeControles = Color(0xFF222222);
  static const bordeSuave = Color(0xFF343434);
  static const acento = Color(0xFF0B4F9C);
  static const exito = Color(0xFF0B4F9C);
  static const error = Color(0xFFB00020);
  static const deshabilitado = Color(0xFF595959);
  static const blanco = Color(0xFFFFFFFF);
}

/// Medidas comunes (en píxeles lógicos).
abstract final class AppSizes {
  static const double textoBase = 16;
  static const double textoTitulo = textoBase * 1.25; // 20
  static const double textoSecundario = textoBase * 0.9; // 14,4
  static const double minControl = 48;
  static const double separacion = 8;
  static const double radio = 8;
  static const double bordeControl = 2;
  static const double bordeFoco = 3;
  static const double margen = 16;
}

/// Borde redondeado que, cuando el control tiene el foco, dibuja además un
/// contorno exterior de 3 px en el color de acento (separado 2 px del control
/// para que se vea también sobre botones con fondo de acento).
class BordeConFoco extends RoundedRectangleBorder {
  const BordeConFoco({super.side, super.borderRadius, this.anillo});

  /// Color del contorno de foco, o `null` si el control no tiene el foco.
  final Color? anillo;

  static const double _hueco = 2;

  @override
  BordeConFoco copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) {
    return BordeConFoco(
      side: side ?? this.side,
      borderRadius: borderRadius ?? this.borderRadius,
      anillo: anillo,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is BordeConFoco) {
      return BordeConFoco(
        side: BorderSide.lerp(a.side, side, t),
        borderRadius: BorderRadiusGeometry.lerp(
          a.borderRadius,
          borderRadius,
          t,
        )!,
        anillo: t < 0.5 ? a.anillo : anillo,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is BordeConFoco) return b.lerpFrom(this, t);
    return super.lerpTo(b, t);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    super.paint(canvas, rect, textDirection: textDirection);
    final color = anillo;
    if (color == null) return;
    final contorno = borderRadius
        .resolve(textDirection)
        .toRRect(rect)
        .inflate(_hueco + AppSizes.bordeFoco / 2);
    canvas.drawRRect(
      contorno,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSizes.bordeFoco
        ..color = color,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BordeConFoco && super == other && other.anillo == anillo;

  @override
  int get hashCode => Object.hash(super.hashCode, anillo);
}

WidgetStateProperty<OutlinedBorder> _formaBoton() {
  return WidgetStateProperty.resolveWith(
    (estados) => BordeConFoco(
      borderRadius: BorderRadius.circular(AppSizes.radio),
      anillo: estados.contains(WidgetState.focused) ? AppColors.acento : null,
    ),
  );
}

ButtonStyle _estiloBase(TextStyle etiqueta) {
  return ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(
      Size(AppSizes.minControl, AppSizes.minControl),
    ),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
    textStyle: WidgetStatePropertyAll(etiqueta),
    shape: _formaBoton(),
    elevation: const WidgetStatePropertyAll(0),
    tapTargetSize: MaterialTapTargetSize.padded,
  );
}

/// Botón principal: fondo de acento y texto blanco.
ButtonStyle _estiloPrimario(TextStyle etiqueta) {
  return _estiloBase(etiqueta).copyWith(
    backgroundColor: WidgetStateProperty.resolveWith(
      (e) => e.contains(WidgetState.disabled)
          ? AppColors.fondoBarras
          : AppColors.acento,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (e) => e.contains(WidgetState.disabled)
          ? AppColors.deshabilitado
          : AppColors.blanco,
    ),
    iconColor: WidgetStateProperty.resolveWith(
      (e) => e.contains(WidgetState.disabled)
          ? AppColors.deshabilitado
          : AppColors.blanco,
    ),
    side: WidgetStateProperty.resolveWith(
      (e) => BorderSide(
        color: e.contains(WidgetState.disabled)
            ? AppColors.deshabilitado
            : AppColors.acento,
        width: AppSizes.bordeControl,
      ),
    ),
  );
}

/// Botón secundario: fondo blanco y borde oscuro.
ButtonStyle _estiloSecundario(TextStyle etiqueta) {
  final colorTexto = WidgetStateProperty.resolveWith(
    (e) => e.contains(WidgetState.disabled)
        ? AppColors.deshabilitado
        : AppColors.textoPrincipal,
  );
  return _estiloBase(etiqueta).copyWith(
    backgroundColor: const WidgetStatePropertyAll(AppColors.fondo),
    foregroundColor: colorTexto,
    iconColor: colorTexto,
    side: WidgetStateProperty.resolveWith(
      (e) => BorderSide(
        color: e.contains(WidgetState.disabled)
            ? AppColors.deshabilitado
            : AppColors.bordeControles,
        width: AppSizes.bordeControl,
      ),
    ),
  );
}

OutlineInputBorder _bordeCampo(Color color, double ancho) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSizes.radio),
    borderSide: BorderSide(color: color, width: ancho),
  );
}

/// Tema global de la aplicación.
///
/// No se toca `MediaQuery.textScaler`: el tamaño de texto del sistema se
/// respeta sin límites (hasta 200 % o más), por eso ningún control tiene
/// altura fija, solo altura mínima.
ThemeData buildAppTheme() {
  TextStyle estilo(
    double tam, {
    FontWeight peso = FontWeight.w400,
    Color color = AppColors.textoPrincipal,
  }) {
    return TextStyle(
      fontSize: tam,
      fontWeight: peso,
      color: color,
      height: 1.4,
    );
  }

  final textos = TextTheme(
    headlineSmall: estilo(AppSizes.textoTitulo, peso: FontWeight.w700),
    titleLarge: estilo(AppSizes.textoTitulo, peso: FontWeight.w700),
    titleMedium: estilo(AppSizes.textoBase, peso: FontWeight.w700),
    titleSmall: estilo(AppSizes.textoBase, peso: FontWeight.w700),
    bodyLarge: estilo(AppSizes.textoBase),
    bodyMedium: estilo(AppSizes.textoBase),
    bodySmall: estilo(
      AppSizes.textoSecundario,
      color: AppColors.textoSecundario,
    ),
    labelLarge: estilo(AppSizes.textoBase, peso: FontWeight.w700),
    labelMedium: estilo(AppSizes.textoBase, peso: FontWeight.w700),
    labelSmall: estilo(AppSizes.textoSecundario),
  );

  const esquema = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.acento,
    onPrimary: AppColors.blanco,
    secondary: AppColors.acento,
    onSecondary: AppColors.blanco,
    tertiary: AppColors.exito,
    onTertiary: AppColors.blanco,
    error: AppColors.error,
    onError: AppColors.blanco,
    surface: AppColors.fondo,
    onSurface: AppColors.textoPrincipal,
    onSurfaceVariant: AppColors.textoSecundario,
    surfaceContainerLowest: AppColors.fondo,
    surfaceContainerLow: AppColors.fondoBarras,
    surfaceContainer: AppColors.fondoBarras,
    surfaceContainerHigh: AppColors.fondoBarras,
    surfaceContainerHighest: AppColors.fondoBarras,
    outline: AppColors.bordeControles,
    outlineVariant: AppColors.bordeSuave,
  );

  final etiquetaBoton = textos.labelLarge!;
  final primario = _estiloPrimario(etiquetaBoton);
  final secundario = _estiloSecundario(etiquetaBoton);

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: AppColors.fondo,
    fontFamily: 'Arial',
    fontFamilyFallback: const ['Helvetica', 'Arimo', 'Liberation Sans'],
    textTheme: textos,
    disabledColor: AppColors.deshabilitado,
    focusColor: AppColors.acento.withValues(alpha: 0.12),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    dividerTheme: const DividerThemeData(
      color: AppColors.bordeSuave,
      thickness: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(style: primario),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primario),
    outlinedButtonTheme: OutlinedButtonThemeData(style: secundario),
    textButtonTheme: TextButtonThemeData(style: secundario),
    iconButtonTheme: IconButtonThemeData(
      style: secundario.copyWith(
        padding: const WidgetStatePropertyAll(EdgeInsets.all(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.fondo,
      constraints: const BoxConstraints(minHeight: AppSizes.minControl),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      // La etiqueta se pinta fuera del campo (ver CampoTexto), siempre visible.
      floatingLabelBehavior: FloatingLabelBehavior.never,
      hintStyle: textos.bodyLarge!.copyWith(color: AppColors.textoSecundario),
      errorStyle: textos.bodySmall!.copyWith(color: AppColors.error),
      errorMaxLines: 3,
      border: _bordeCampo(AppColors.bordeControles, AppSizes.bordeControl),
      enabledBorder: _bordeCampo(
        AppColors.bordeControles,
        AppSizes.bordeControl,
      ),
      disabledBorder: _bordeCampo(
        AppColors.deshabilitado,
        AppSizes.bordeControl,
      ),
      focusedBorder: _bordeCampo(AppColors.acento, AppSizes.bordeFoco),
      errorBorder: _bordeCampo(AppColors.error, AppSizes.bordeControl),
      focusedErrorBorder: _bordeCampo(AppColors.acento, AppSizes.bordeFoco),
      prefixIconColor: AppColors.textoPrincipal,
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (e) => e.contains(WidgetState.disabled)
            ? AppColors.deshabilitado
            : e.contains(WidgetState.selected)
            ? AppColors.acento
            : AppColors.bordeControles,
      ),
    ),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: 12,
      minTileHeight: AppSizes.minControl,
      textColor: AppColors.textoPrincipal,
      iconColor: AppColors.textoPrincipal,
      selectedColor: AppColors.acento,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.acento,
      circularTrackColor: AppColors.fondoBarras,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.exito,
      contentTextStyle: textos.bodyLarge!.copyWith(color: AppColors.blanco),
      behavior: SnackBarBehavior.floating,
    ),
    tooltipTheme: TooltipThemeData(
      textStyle: textos.bodySmall!.copyWith(color: AppColors.blanco),
      decoration: BoxDecoration(
        color: AppColors.textoPrincipal,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}
