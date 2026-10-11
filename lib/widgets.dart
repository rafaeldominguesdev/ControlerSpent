
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

/// Afunda de leve enquanto o dedo está em cima. Solta se o dedo arrastar
/// (para não ficar "apertado" durante a rolagem).
class Pressionavel extends StatefulWidget {
  final Widget child;
  final double escala;
  const Pressionavel({super.key, required this.child, this.escala = 0.97});

  @override
  State<Pressionavel> createState() => _PressionavelState();
}

class _PressionavelState extends State<Pressionavel> {
  bool _apertado = false;
  Offset? _inicio;

  void _set(bool v) {
    if (v == _apertado) return;
    setState(() => _apertado = v);
  }

  @override
  Widget build(BuildContext context) {
    if (_semAnimacao(context)) return widget.child;
    return Listener(
      onPointerDown: (e) {
        _inicio = e.position;
        _set(true);
      },
      onPointerMove: (e) {
        if (_inicio != null && (e.position - _inicio!).distance > kTouchSlop) _set(false);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _apertado ? widget.escala : 1,
        duration: _apertado ? Movimento.rapido : Movimento.medio,
        curve: Movimento.entrada,
        child: widget.child,
      ),
    );
  }
}

/// Rótulo pequeno em caixa alta ("HOJE", "CONTA DO MÊS").
class Rotulo extends StatelessWidget {
  final String texto;
  final Color? cor;
  const Rotulo(this.texto, {super.key, this.cor});

  @override
  Widget build(BuildContext context) =>
      Text(texto.toUpperCase(), style: context.tipos.rotulo(color: cor));
}

/// Várias linhas dentro de uma única superfície, separadas por fios.
class GrupoLista extends StatelessWidget {
  final List<Widget> children;
  final double recuoDivisoria;
  const GrupoLista({super.key, required this.children, this.recuoDivisoria = 16});

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) Divider(indent: recuoDivisoria),
            c,
          ],
        ]),
      );
}

/// Linha de "nota fiscal": descrição à esquerda, valor à direita.
class LinhaConta extends StatelessWidget {
  final String rotulo;
  final String? detalhe;
  final double valor;
  final bool menos, forte;
  final Color? cor;

  /// Mostra este texto no lugar do valor em reais (ex.: "40 unidades").
  final String? texto;
  const LinhaConta(this.rotulo, this.valor,
      {super.key, this.detalhe, this.menos = false, this.forte = false, this.cor, this.texto});

  @override
  Widget build(BuildContext context) {
    final texto = this.texto ?? (menos ? '− ${reais(valor.abs())}' : reais(valor));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rotulo,
                style: forte
                    ? context.tipos.corpo(peso: FontWeight.w600)
                    : context.tipos.corpo(color: context.cores.tinta)),
            if (detalhe != null)
              Text(detalhe!, style: context.tipos.apoio().copyWith(fontSize: 12)),
          ]),
        ),
        const SizedBox(width: Espaco.m),
        Text(texto,
            style: context.tipos.valor(
                size: forte ? 16 : 15,
                peso: forte ? FontWeight.w700 : FontWeight.w500,
                color: cor ?? (menos ? context.cores.tintaSuave : context.cores.tinta))),
      ]),
    );
  }
}
