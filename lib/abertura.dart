import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Abertura do app: começa idêntica à tela nativa (azul liso com a logo no
/// centro), o degradê da logo se forma na diagonal, o nome aparece e o app entra
/// com um zoom na logo.
class Abertura extends StatefulWidget {
  final Widget child;
  const Abertura({super.key, required this.child});

  @override
  State<Abertura> createState() => _AberturaState();
}

class _AberturaState extends State<Abertura> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  );
  bool _terminou = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Com "reduzir movimento" ligado no celular: só um esmaecer rápido.
      if (MediaQuery.disableAnimationsOf(context)) {
        _anim.duration = const Duration(milliseconds: 300);
      }
      _anim.forward().whenComplete(() {
        if (mounted) setState(() => _terminou = true);
      });
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  /// Quanto já andou do trecho [inicio, fim] da animação (0 a 1).
  double _trecho(double inicio, double fim, [Curve curva = Curves.linear]) =>
      curva.transform(((_anim.value - inicio) / (fim - inicio)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    if (_terminou) return widget.child;
    final t = context.tipos;
    final reduzido = MediaQuery.disableAnimationsOf(context);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final degrade = reduzido ? 1.0 : _trecho(0.04, 0.46, Curves.easeInOutCubic);
        final nome = reduzido ? 1.0 : _trecho(0.46, 0.62, Curves.easeOutCubic);
        final respira = reduzido ? 0.0 : _trecho(0, 0.7, Curves.easeInOut);
        final zoom = reduzido ? 0.0 : _trecho(0.74, 1, Curves.easeInCubic);
        final nomeSai = reduzido ? 0.0 : _trecho(0.74, 0.82);
        final fundoSai = _trecho(reduzido ? 0 : 0.82, 1);
        final logoSai = _trecho(reduzido ? 0 : 0.85, 1);
        final app = _trecho(reduzido ? 0 : 0.78, 1, Curves.easeOutCubic);

        // A frente do degradê anda na diagonal, do canto de cima ao de baixo,
        // com a borda macia (20% da tela).
        final frente = degrade * 1.4 - 0.2;

        return Stack(fit: StackFit.expand, children: [
          // O app chega por trás, crescendo de leve.
          Opacity(
            opacity: app,
            child: Transform.scale(scale: 0.94 + 0.06 * app, child: widget.child),
          ),
          AbsorbPointer(
            // Sem uma superfície do Material, o texto ganha o sublinhado amarelo de emergência.
            child: Material(
              type: MaterialType.transparency,
              child: Opacity(
                opacity: 1 - fundoSai,
                child: Stack(fit: StackFit.expand, children: [
                  // O azul liso da tela nativa...
                  const ColoredBox(color: Marca.inicio),
                  // ...e o degradê da logo se espalhando por cima dele.
                  ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (r) => LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: const [Colors.white, Colors.white, Colors.transparent],
                      stops: [0, frente.clamp(0.0, 1.0), (frente + 0.2).clamp(0.0, 1.0)],
                    ).createShader(r),
                    child: Transform.scale(
                      scale: 1.06 - 0.06 * degrade,
                      child: Image.asset('assets/logo/abertura_fundo.png', fit: BoxFit.fill),
                    ),
                  ),
                  Center(
                    // 256 x 256: o mesmo quadro da imagem da tela nativa.
                    child: SizedBox(
                      width: 256,
                      height: 256,
                      child: Stack(clipBehavior: Clip.none, children: [
                        Opacity(
                          opacity: 1 - logoSai,
                          child: Transform.scale(
                            scale: 1 + 0.03 * respira + 6 * zoom,
                            child: Image.asset('assets/logo/abertura.png', width: 256, height: 256),
                          ),
                        ),
                        Positioned(
                          left: -140,
                          right: -140,
                          top: 228,
                          child: Opacity(
                            opacity: nome * (1 - nomeSai),
                            child: Transform.translate(
                              offset: Offset(0, 14 * (1 - nome)),
                              child: _Desfoque(
                                quanto: 6 * (1 - nome),
                                child: Text('Doce Controle',
                                    textAlign: TextAlign.center,
                                    style: t.display(size: 32, color: Marca.marinho)),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

/// Desfoque que some aos poucos (o nome "entra em foco").
class _Desfoque extends StatelessWidget {
  final double quanto;
  final Widget child;
  const _Desfoque({required this.quanto, required this.child});

  @override
  Widget build(BuildContext context) => quanto <= 0
      ? child
      : ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: quanto, sigmaY: quanto), child: child);
}
