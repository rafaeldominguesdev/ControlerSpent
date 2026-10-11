import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de cor do "caderno de confeitaria", em versão clara e escura.
/// Texto sempre acima de 4.5:1 sobre o fundo; cores de gráfico acima de 3:1.
/// Use pelo contexto: `context.cores.tinta`.
@immutable
class Cores extends ThemeExtension<Cores> {
  final Color papel; // fundo das telas
  final Color superficie; // listas, folhas, campos
  final Color bege; // seleção, trilhos, áreas de destaque
  final Color linha; // divisórias finas
  final Color tinta; // texto principal
  final Color tintaSuave; // texto secundário
  final Color cacau; // ação principal
  final Color sobreCacau; // texto em cima da ação principal
  final Color caramelo; // detalhe, só em gráficos
  final Color positivo; // dinheiro entrando, lucro (texto)
  final Color dinheiro; // dinheiro em gráficos (preenchimento)
  final Color dinheiroSuave; // fundo verde bem leve
  final Color atencao;
  final Color negativo;
  final List<Color> grafico; // sequência para fatias e séries

  const Cores({
    required this.papel,
    required this.superficie,
    required this.bege,
    required this.linha,
    required this.tinta,
    required this.tintaSuave,
    required this.cacau,
    required this.sobreCacau,
    required this.caramelo,
    required this.positivo,
    required this.dinheiro,
    required this.dinheiroSuave,
    required this.atencao,
    required this.negativo,
    required this.grafico,
  });

  static const claro = Cores(
    papel: Color(0xFFF5EFE6),
    superficie: Color(0xFFFBF8F3),
    bege: Color(0xFFEADFD0),
    linha: Color(0xFFE3D8C9),
    tinta: Color(0xFF2B1F18),
    tintaSuave: Color(0xFF76614F),
    cacau: Color(0xFF6B4632),
    sobreCacau: Color(0xFFFBF8F3),
    caramelo: Color(0xFFB5793D),
    positivo: Color(0xFF2E7438),
    dinheiro: Color(0xFF3E8E45),
    dinheiroSuave: Color(0xFFE4EFDD),
    atencao: Color(0xFF8F6440),
    negativo: Color(0xFFA13D33),
    grafico: [
      Color(0xFF3E8E45),
      Color(0xFFB5793D),
      Color(0xFFB4505A),
      Color(0xFF3C7D86),
      Color(0xFF6B4632),
      Color(0xFF8C7A2B),
    ],
  );

  static const escuro = Cores(
    papel: Color(0xFF16110E),
    superficie: Color(0xFF211A16),
    bege: Color(0xFF33291F),
    linha: Color(0xFF3B3029),
    tinta: Color(0xFFF2EAE0),
    tintaSuave: Color(0xFFB8A595),
    cacau: Color(0xFFE0AE82),
    sobreCacau: Color(0xFF1E1510),
    caramelo: Color(0xFFE0A267),
    positivo: Color(0xFF7CCB7E),
    dinheiro: Color(0xFF5DBB63),
    dinheiroSuave: Color(0xFF1F2D1E),
    atencao: Color(0xFFE7B866),
    negativo: Color(0xFFF0897C),
    grafico: [
      Color(0xFF5DBB63),
      Color(0xFFE0A267),
      Color(0xFFDB7680),
      Color(0xFF63AEB7),
      Color(0xFFC49A7A),
      Color(0xFFE3C266),
    ],
  );

  @override
  Cores copyWith({Color? papel, Color? superficie, Color? tinta}) => Cores(
        papel: papel ?? this.papel,
        superficie: superficie ?? this.superficie,
        bege: bege,
        linha: linha,
        tinta: tinta ?? this.tinta,
        tintaSuave: tintaSuave,
        cacau: cacau,
        sobreCacau: sobreCacau,
        caramelo: caramelo,
        positivo: positivo,
        dinheiro: dinheiro,
        dinheiroSuave: dinheiroSuave,
        atencao: atencao,
        negativo: negativo,
        grafico: grafico,
      );

  /// Mistura as duas paletas: é o que deixa a troca claro/escuro suave.
  @override
  Cores lerp(Cores? outra, double t) {
    if (outra == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return Cores(
      papel: l(papel, outra.papel),
      superficie: l(superficie, outra.superficie),
      bege: l(bege, outra.bege),
      linha: l(linha, outra.linha),
      tinta: l(tinta, outra.tinta),
      tintaSuave: l(tintaSuave, outra.tintaSuave),
      cacau: l(cacau, outra.cacau),
      sobreCacau: l(sobreCacau, outra.sobreCacau),
      caramelo: l(caramelo, outra.caramelo),
      positivo: l(positivo, outra.positivo),
      dinheiro: l(dinheiro, outra.dinheiro),
      dinheiroSuave: l(dinheiroSuave, outra.dinheiroSuave),
      atencao: l(atencao, outra.atencao),
      negativo: l(negativo, outra.negativo),
      grafico: [for (var i = 0; i < grafico.length; i++) l(grafico[i], outra.grafico[i])],
    );
  }
}

abstract class Espaco {
  static const xs = 4.0, s = 8.0, m = 10.0, l = 14.0, xl = 20.0, xxl = 28.0, secao = 32.0;
  static const borda = 16.0; // margem lateral das telas
}

abstract class Raio {
  static const pequeno = 10.0, medio = 14.0, grande = 20.0;
}

abstract class Movimento {
  static const rapido = Duration(milliseconds: 140);
  static const medio = Duration(milliseconds: 260);
  static const lento = Duration(milliseconds: 380);
  static const pagina = Duration(milliseconds: 320); // troca de aba
  static const entrada = Curves.easeOutCubic;
  static const saida = Curves.easeInCubic;
}

/// Estilos de texto com intenção. A serifa (Newsreader) só aparece em títulos
/// de tela e nos números grandes; todo o resto é Figtree.
/// Use pelo contexto: `context.tipos.corpo()`.
class Tipos {
  final Cores c;
  const Tipos(this.c);

  static const _numeros = [FontFeature.tabularFigures()];

  TextStyle display({double size = 36, Color? color}) => GoogleFonts.newsreader(
        fontSize: size,
        height: 1.05,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.8,
        color: color ?? c.tinta,
        fontFeatures: _numeros,
      );

  TextStyle tituloTela() => GoogleFonts.newsreader(
        fontSize: 26,
        height: 1.1,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
        color: c.tinta,
      );

  TextStyle secao() => GoogleFonts.newsreader(
        fontSize: 19,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: c.tinta,
      );

  /// Rótulo pequeno em caixa alta, com espaçamento aberto.
  TextStyle rotulo({Color? color}) => GoogleFonts.figtree(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: color ?? c.tintaSuave,
      );

  TextStyle corpo({Color? color, FontWeight peso = FontWeight.w400}) =>
      GoogleFonts.figtree(fontSize: 15, height: 1.3, fontWeight: peso, color: color ?? c.tinta);

  TextStyle apoio({Color? color}) =>
      GoogleFonts.figtree(fontSize: 13, height: 1.3, color: color ?? c.tintaSuave);

  TextStyle valor({double size = 15, Color? color, FontWeight peso = FontWeight.w600}) =>
      GoogleFonts.figtree(
          fontSize: size, fontWeight: peso, color: color ?? c.tinta, fontFeatures: _numeros);
}

extension TemaDoContexto on BuildContext {
  Cores get cores => Theme.of(this).extension<Cores>()!;
  Tipos get tipos => Tipos(cores);
}

ThemeData temaApp(Cores p, Brightness brilho) {
  final t = Tipos(p);
  final base = ThemeData(
    useMaterial3: true,
    brightness: brilho,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.cacau,
      brightness: brilho,
      primary: p.cacau,
      onPrimary: p.sobreCacau,
      secondary: p.caramelo,
      surface: p.papel,
      onSurface: p.tinta,
      onSurfaceVariant: p.tintaSuave,
      outline: p.linha,
      outlineVariant: p.linha,
      secondaryContainer: p.bege,
      onSecondaryContainer: p.cacau,
      surfaceContainerLowest: p.superficie,
      surfaceContainerLow: p.superficie,
      surfaceContainer: p.superficie,
      surfaceContainerHigh: p.superficie,
      surfaceContainerHighest: p.bege,
      error: p.negativo,
    ),
    scaffoldBackgroundColor: p.papel,
    fontFamily: GoogleFonts.figtree().fontFamily,
    extensions: [p],
  );
  final texto = base.textTheme.apply(bodyColor: p.tinta, displayColor: p.tinta);

  final deslizar = SharedAxisPageTransitionsBuilder(
    transitionType: SharedAxisTransitionType.horizontal,
    fillColor: p.papel,
  );
  final campoBorda = OutlineInputBorder(
    borderRadius: BorderRadius.circular(Raio.medio),
    borderSide: BorderSide(color: p.linha),
  );

  return base.copyWith(
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      TargetPlatform.iOS: deslizar,
      TargetPlatform.android: deslizar,
      TargetPlatform.macOS: deslizar,
    }),
    textTheme: texto.copyWith(
      displaySmall: t.display(),
      titleLarge: t.secao(),
      titleMedium: t.corpo(peso: FontWeight.w600),
      bodyLarge: t.corpo(),
      bodyMedium: t.corpo().copyWith(fontSize: 14),
      labelLarge: t.corpo(peso: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.papel,
      foregroundColor: p.tinta,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: Espaco.borda,
      toolbarHeight: 56,
      titleTextStyle: t.tituloTela(),
    ),
    cardTheme: CardThemeData(
      color: p.superficie,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Raio.medio),
        side: BorderSide(color: p.linha),
      ),
    ),
    listTileTheme: ListTileThemeData(
      titleTextStyle: t.corpo(peso: FontWeight.w600),
      subtitleTextStyle: t.apoio(),
      iconColor: p.tintaSuave,
      contentPadding: const EdgeInsets.symmetric(horizontal: Espaco.l),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.superficie,
      labelStyle: t.apoio(),
      floatingLabelStyle: t.apoio(color: p.cacau),
      hintStyle: t.apoio(color: p.tintaSuave.withValues(alpha: 0.7)),
      helperStyle: t.apoio().copyWith(fontSize: 12),
      prefixStyle: t.corpo(color: p.tintaSuave),
      suffixStyle: t.corpo(color: p.tintaSuave),
      contentPadding: const EdgeInsets.symmetric(horizontal: Espaco.l, vertical: 13),
      border: campoBorda,
      enabledBorder: campoBorda,
      focusedBorder: campoBorda.copyWith(borderSide: BorderSide(color: p.cacau, width: 1.6)),
      errorBorder: campoBorda.copyWith(borderSide: BorderSide(color: p.negativo)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.cacau,
        foregroundColor: p.sobreCacau,
        minimumSize: const Size.fromHeight(50),
        textStyle: t.corpo(peso: FontWeight.w600).copyWith(fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.medio)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.cacau,
        backgroundColor: p.superficie,
        minimumSize: const Size.fromHeight(46),
        side: BorderSide(color: p.linha),
        textStyle: t.corpo(peso: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.medio)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.cacau,
        minimumSize: const Size(48, 48),
        textStyle: t.corpo(peso: FontWeight.w600).copyWith(fontSize: 14),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.cacau,
      foregroundColor: p.sobreCacau,
      elevation: 2,
      highlightElevation: 0,
      extendedTextStyle: t.corpo(peso: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.medio)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: p.superficie,
        selectedBackgroundColor: p.cacau,
        selectedForegroundColor: p.sobreCacau,
        foregroundColor: p.tinta,
        side: BorderSide(color: p.linha),
        textStyle: t.corpo(peso: FontWeight.w600).copyWith(fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.pequeno)),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.papel,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: p.linha,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Raio.grande))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.papel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.grande)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.tinta,
      contentTextStyle: t.corpo(color: p.papel).copyWith(fontSize: 14),
      actionTextColor: p.bege,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.medio)),
    ),
    dividerTheme: DividerThemeData(color: p.linha, thickness: 1, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.cacau),
  );
}

/// Temas prontos (criados uma vez só).
final temaClaro = temaApp(Cores.claro, Brightness.light);
final temaEscuro = temaApp(Cores.escuro, Brightness.dark);
