import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de cor, nas cores da logo (azul), em versão clara e escura.
/// Texto sempre acima de 4.5:1 sobre o fundo; cores de gráfico acima de 3:1.
/// Dinheiro entrando continua verde. Use pelo contexto: `context.cores.tinta`.
@immutable
class Cores extends ThemeExtension<Cores> {
  final Color papel; // fundo das telas
  final Color superficie; // listas, folhas, campos
  final Color realce; // seleção, trilhos, áreas de destaque
  final Color linha; // divisórias finas
  final Color tinta; // texto principal
  final Color tintaSuave; // texto secundário
  final Color acao; // botões e item ativo
  final Color sobreAcao; // texto em cima da ação
  final Color destaque; // segunda cor dos gráficos
  final Color positivo; // dinheiro entrando, lucro (texto)
  final Color dinheiro; // dinheiro em gráficos (preenchimento)
  final Color dinheiroSuave; // fundo verde bem leve
  final Color atencao;
  final Color negativo;
  final List<Color> grafico; // sequência para fatias e séries

  const Cores({
    required this.papel,
    required this.superficie,
    required this.realce,
    required this.linha,
    required this.tinta,
    required this.tintaSuave,
    required this.acao,
    required this.sobreAcao,
    required this.destaque,
    required this.positivo,
    required this.dinheiro,
    required this.dinheiroSuave,
    required this.atencao,
    required this.negativo,
    required this.grafico,
  });

  static const claro = Cores(
    papel: Color(0xFFF6F8FC),
    superficie: Color(0xFFFCFDFF),
    realce: Color(0xFFE8EEFA),
    linha: Color(0xFFDDE4F0),
    tinta: Color(0xFF0E1A3A),
    tintaSuave: Color(0xFF56627E),
    acao: Color(0xFF2F63F0), // azul da logo, um pouco mais escuro para o texto branco ler bem
    sobreAcao: Color(0xFFFCFDFF),
    destaque: Color(0xFF0E95A3),
    positivo: Color(0xFF16804A),
    dinheiro: Color(0xFF22A35A),
    dinheiroSuave: Color(0xFFE2F4E9),
    atencao: Color(0xFFA15C00),
    negativo: Color(0xFFC0352B),
    grafico: [
      Color(0xFF366FFD),
      Color(0xFF0E95A3),
      Color(0xFFD0476A),
      Color(0xFF3228D6),
      Color(0xFFC77700),
      Color(0xFF0A1F5B),
    ],
  );

  /// Escuro: azul-marinho quase preto, uma cor de ação e o verde do dinheiro.
  static const escuro = Cores(
    papel: Color(0xFF070B18),
    superficie: Color(0xFF0F1729),
    realce: Color(0xFF18233D),
    linha: Color(0xFF1E2B48),
    tinta: Color(0xFFEEF2FF),
    tintaSuave: Color(0xFF8D9AB9),
    acao: Color(0xFF6A8CFF),
    sobreAcao: Color(0xFF070B18),
    destaque: Color(0xFF3DD6E6),
    positivo: Color(0xFF5BD68A),
    dinheiro: Color(0xFF3FC57A),
    dinheiroSuave: Color(0xFF0F2A1E),
    atencao: Color(0xFFF5B84A),
    negativo: Color(0xFFFF8A80),
    grafico: [
      Color(0xFF6A8CFF),
      Color(0xFF3DD6E6),
      Color(0xFFFF8FA3),
      Color(0xFF8F86FF),
      Color(0xFFF5B84A),
      Color(0xFF6EE7A0),
    ],
  );

  @override
  Cores copyWith({Color? papel, Color? superficie, Color? tinta}) => Cores(
        papel: papel ?? this.papel,
        superficie: superficie ?? this.superficie,
        realce: realce,
        linha: linha,
        tinta: tinta ?? this.tinta,
        tintaSuave: tintaSuave,
        acao: acao,
        sobreAcao: sobreAcao,
        destaque: destaque,
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
      realce: l(realce, outra.realce),
      linha: l(linha, outra.linha),
      tinta: l(tinta, outra.tinta),
      tintaSuave: l(tintaSuave, outra.tintaSuave),
      acao: l(acao, outra.acao),
      sobreAcao: l(sobreAcao, outra.sobreAcao),
      destaque: l(destaque, outra.destaque),
      positivo: l(positivo, outra.positivo),
      dinheiro: l(dinheiro, outra.dinheiro),
      dinheiroSuave: l(dinheiroSuave, outra.dinheiroSuave),
      atencao: l(atencao, outra.atencao),
      negativo: l(negativo, outra.negativo),
      grafico: [for (var i = 0; i < grafico.length; i++) l(grafico[i], outra.grafico[i])],
    );
  }
}

/// Cores da logo (iguais no claro e no escuro).
abstract class Marca {
  static const marinho = Color(0xFF0A1F5B); // barras da logo
  static const inicio = Color(0xFF3555FE); // fundo liso de onde o degradê da abertura nasce
}

abstract class Espaco {
  static const xs = 4.0, s = 8.0, m = 10.0, l = 14.0, xl = 20.0, xxl = 28.0, secao = 32.0;
  static const borda = 16.0; // margem lateral das telas
}

/// Cantos discretos: arredondado só o bastante para não ficar duro.
abstract class Raio {
  static const pequeno = 6.0, medio = 10.0, grande = 14.0;
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

  /// Rótulo pequeno acima de um bloco.
  TextStyle rotulo({Color? color}) => GoogleFonts.figtree(
        fontSize: 13,
        fontWeight: FontWeight.w500,
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
      seedColor: p.acao,
      brightness: brilho,
      primary: p.acao,
      onPrimary: p.sobreAcao,
      secondary: p.destaque,
      surface: p.papel,
      onSurface: p.tinta,
      onSurfaceVariant: p.tintaSuave,
      outline: p.linha,
      outlineVariant: p.linha,
      secondaryContainer: p.realce,
      onSecondaryContainer: p.acao,
      surfaceContainerLowest: p.superficie,
      surfaceContainerLow: p.superficie,
      surfaceContainer: p.superficie,
      surfaceContainerHigh: p.superficie,
      surfaceContainerHighest: p.realce,
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
      floatingLabelStyle: t.apoio(color: p.acao),
      hintStyle: t.apoio(color: p.tintaSuave.withValues(alpha: 0.7)),
      helperStyle: t.apoio().copyWith(fontSize: 12),
      prefixStyle: t.corpo(color: p.tintaSuave),
      suffixStyle: t.corpo(color: p.tintaSuave),
      contentPadding: const EdgeInsets.symmetric(horizontal: Espaco.l, vertical: 13),
      border: campoBorda,
      enabledBorder: campoBorda,
      focusedBorder: campoBorda.copyWith(borderSide: BorderSide(color: p.acao, width: 1.6)),
      errorBorder: campoBorda.copyWith(borderSide: BorderSide(color: p.negativo)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.acao,
        foregroundColor: p.sobreAcao,
        minimumSize: const Size.fromHeight(50),
        textStyle: t.corpo(peso: FontWeight.w600).copyWith(fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.medio)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.acao,
        backgroundColor: p.superficie,
        minimumSize: const Size.fromHeight(46),
        side: BorderSide(color: p.linha),
        textStyle: t.corpo(peso: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.medio)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.acao,
        minimumSize: const Size(48, 48),
        textStyle: t.corpo(peso: FontWeight.w600).copyWith(fontSize: 14),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.acao,
      foregroundColor: p.sobreAcao,
      elevation: 2,
      highlightElevation: 0,
      extendedTextStyle: t.corpo(peso: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.medio)),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.pequeno)),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: p.tinta,
      unselectedLabelColor: p.tintaSuave,
      labelStyle: t.corpo(peso: FontWeight.w700).copyWith(fontSize: 15),
      unselectedLabelStyle: t.corpo(peso: FontWeight.w500).copyWith(fontSize: 15),
      indicator: UnderlineTabIndicator(borderSide: BorderSide(width: 3, color: p.acao)),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: p.linha,
      dividerHeight: 1,
      tabAlignment: TabAlignment.start,
      overlayColor: WidgetStatePropertyAll(p.realce),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: p.superficie,
        selectedBackgroundColor: p.acao,
        selectedForegroundColor: p.sobreAcao,
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
      actionTextColor: p.realce,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.medio)),
    ),
    dividerTheme: DividerThemeData(color: p.linha, thickness: 1, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.acao),
  );
}

/// Temas prontos (criados uma vez só).
final temaClaro = temaApp(Cores.claro, Brightness.light);
final temaEscuro = temaApp(Cores.escuro, Brightness.dark);
