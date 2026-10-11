
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'store.dart';
import 'theme.dart';

bool _semAnimacao(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// "+R$ 12,00" ou "−R$ 12,00".
String comSinal(double centavos) => centavos < 0 ? reais(centavos) : '+${reais(centavos)}';

/// Valor em reais que corre até o número novo quando muda.
class ValorAnimado extends StatelessWidget {
  final double centavos;
  final TextStyle? style;
  final bool sinal;
  const ValorAnimado(this.centavos, {super.key, this.style, this.sinal = false});

  String _texto(double v) => sinal ? comSinal(v) : reais(v);

  @override
  Widget build(BuildContext context) {
    if (_semAnimacao(context)) return Text(_texto(centavos), style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: centavos),
      duration: const Duration(milliseconds: 600),
      curve: Movimento.entrada,
      builder: (_, v, __) => Text(_texto(v), style: style),
    );
  }
}

/// Entra subindo um pouco, em sequência pela posição.
class EntradaSuave extends StatelessWidget {
  final int ordem;
  final Widget child;
  const EntradaSuave({super.key, this.ordem = 0, required this.child});

  @override
  Widget build(BuildContext context) {
    if (_semAnimacao(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + ordem.clamp(0, 8) * 50),
      curve: Movimento.entrada,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
      ),
      child: child,
    );
  }
}
