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
