
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

/// Linha tracejada, como no fim de uma nota.
class Tracejado extends StatelessWidget {
  const Tracejado({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 11,
        child: CustomPaint(
            painter: _TracejadoPainter(context.cores.linha), size: const Size(double.infinity, 11)),
      );
}

class _TracejadoPainter extends CustomPainter {
  final Color cor;
  _TracejadoPainter(this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = cor
      ..strokeWidth = 1.2;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, y), Offset((x + 3.5).clamp(0, size.width), y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _TracejadoPainter antigo) => antigo.cor != cor;
}

/// Escolha entre poucas opções (ex.: forma de pagamento), em uma faixa só.
class SeletorOpcoes<T> extends StatelessWidget {
  final List<(T, String)> opcoes;
  final T valor;
  final ValueChanged<T> onChanged;
  const SeletorOpcoes(
      {super.key, required this.opcoes, required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Espaco.xs),
      decoration: BoxDecoration(
        color: context.cores.superficie,
        borderRadius: BorderRadius.circular(Raio.medio),
        border: Border.all(color: context.cores.linha),
      ),
      child: Row(children: [
        for (final (v, texto) in opcoes)
          Expanded(
            child: Semantics(
              button: true,
              selected: v == valor,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(v);
                },
                child: AnimatedContainer(
                  duration: Movimento.medio,
                  curve: Movimento.entrada,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: v == valor ? context.cores.cacau : Colors.transparent,
                    borderRadius: BorderRadius.circular(Raio.pequeno),
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: Movimento.medio,
                    style: context.tipos
                        .corpo(
                          peso: FontWeight.w600,
                          color: v == valor ? context.cores.sobreCacau : context.cores.tinta,
                        )
                        .copyWith(fontSize: 14),
                    child: Text(texto),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Botões de menos e mais, grandes, com o número no meio.
class Contador extends StatelessWidget {
  final int valor;
  final ValueChanged<int> onChanged;
  final int minimo;
  const Contador({super.key, required this.valor, required this.onChanged, this.minimo = 1});

  @override
  Widget build(BuildContext context) {
    Widget botao(IconData i, int delta, String dica) {
      final ativo = valor + delta >= minimo;
      return Pressionavel(
        escala: 0.92,
        child: Material(
          color: context.cores.superficie,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Raio.medio),
            side: BorderSide(color: context.cores.linha),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(Raio.medio),
            onTap: ativo
                ? () {
                    HapticFeedback.selectionClick();
                    onChanged(valor + delta);
                  }
                : null,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(i,
                  semanticLabel: dica,
                  color: ativo ? context.cores.cacau : context.cores.linha,
                  size: 24),
            ),
          ),
        ),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      botao(Icons.remove, -1, 'Diminuir'),
      SizedBox(
        width: 104,
        child: AnimatedSwitcher(
          duration: Movimento.rapido,
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(a), child: c),
          ),
          child: Text('$valor',
              key: ValueKey(valor),
              textAlign: TextAlign.center,
              style: context.tipos.display(size: 44)),
        ),
      ),
      botao(Icons.add, 1, 'Aumentar'),
    ]);
  }
}

/// Tela vazia com uma explicação curta e, se fizer sentido, um botão.
class Vazio extends StatelessWidget {
  final IconData icone;
  final String titulo, texto;
  final String? acao, acaoSecundaria;
  final VoidCallback? onAcao, onAcaoSecundaria;
  const Vazio({
    super.key,
    required this.icone,
    required this.titulo,
    required this.texto,
    this.acao,
    this.onAcao,
    this.acaoSecundaria,
    this.onAcaoSecundaria,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Espaco.xxl, vertical: Espaco.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: context.cores.bege, shape: BoxShape.circle),
            child: Icon(icone, color: context.cores.cacau, size: 24),
          ),
          const SizedBox(height: Espaco.l),
          Text(titulo, textAlign: TextAlign.center, style: context.tipos.secao()),
          const SizedBox(height: Espaco.s),
          Text(texto, textAlign: TextAlign.center, style: context.tipos.apoio()),
          if (acao != null) ...[
            const SizedBox(height: Espaco.xl),
            OutlinedButton(onPressed: onAcao, child: Text(acao!)),
          ],
          if (acaoSecundaria != null)
            TextButton(onPressed: onAcaoSecundaria, child: Text(acaoSecundaria!)),
        ]),
      );
}

class ItemNav {
  final IconData icone, iconeAtivo;
  final String texto;
  const ItemNav(this.icone, this.iconeAtivo, this.texto);
}

class _BotaoNav extends StatelessWidget {
  final ItemNav item;
  final double ativo; // 0 a 1
  const _BotaoNav({required this.item, required this.ativo});

  @override
  Widget build(BuildContext context) {
    final cor = Color.lerp(context.cores.tintaSuave, context.cores.cacau, ativo)!;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(ativo > 0.5 ? item.iconeAtivo : item.icone, color: cor, size: 22),
      const SizedBox(height: 3),
      Text(
        item.texto,
        style: context.tipos.apoio(color: cor).copyWith(
              fontSize: 11,
              fontWeight: ativo > 0.5 ? FontWeight.w700 : FontWeight.w500,
            ),
      ),
    ]);
  }
}
