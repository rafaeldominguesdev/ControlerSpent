import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'models.dart';
import 'store.dart';
import 'theme.dart';

bool _semAnimacao(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// "+R$ 12,00" ou "−R$ 12,00".
String comSinal(double centavos) => centavos < 0 ? reais(centavos) : '+${reais(centavos)}';

/// Valor em reais que corre até o número novo quando muda. Com [doZero], na
/// primeira vez ele também sobe a partir de zero (para os números de destaque).
class ValorAnimado extends StatelessWidget {
  final double centavos;
  final TextStyle? style;
  final bool sinal;
  final bool doZero;
  const ValorAnimado(this.centavos,
      {super.key, this.style, this.sinal = false, this.doZero = false});

  String _texto(double v) => sinal ? comSinal(v) : reais(v);

  @override
  Widget build(BuildContext context) {
    if (_semAnimacao(context)) return Text(_texto(centavos), style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: doZero ? 0 : null, end: centavos),
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

/// Rótulo pequeno acima de um bloco ("Hoje", "Conta do mês").
class Rotulo extends StatelessWidget {
  final String texto;
  final Color? cor;
  const Rotulo(this.texto, {super.key, this.cor});

  @override
  Widget build(BuildContext context) => Text(texto, style: context.tipos.rotulo(color: cor));
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
                    color: v == valor ? context.cores.acao : Colors.transparent,
                    borderRadius: BorderRadius.circular(Raio.pequeno),
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: Movimento.medio,
                    style: context.tipos
                        .corpo(
                          peso: FontWeight.w600,
                          color: v == valor ? context.cores.sobreAcao : context.cores.tinta,
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

/// Botões de menos e mais, grandes, com o número no meio. Tocar no número abre
/// o teclado para digitar (50 brigadeiros não são 49 toques no "+"), e os
/// atalhos somam de 5 em 5 ou de 10 em 10.
class Contador extends StatelessWidget {
  final int valor;
  final ValueChanged<int> onChanged;
  final int minimo;
  final List<int> atalhos;
  const Contador({
    super.key,
    required this.valor,
    required this.onChanged,
    this.minimo = 1,
    this.atalhos = const [5, 10],
  });

  Future<void> _digitar(BuildContext context) async {
    final campo = TextEditingController(text: '$valor')
      ..selection = TextSelection(baseOffset: 0, extentOffset: '$valor'.length);
    final novo = await showDialog<int>(
      context: context,
      builder: (ctx) {
        void confirmar() => Navigator.pop(ctx, int.tryParse(campo.text));
        return AlertDialog(
          title: const Text('Quantidade'),
          content: TextField(
            controller: campo,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: ctx.tipos.display(size: 36),
            onSubmitted: (_) => confirmar(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
              onPressed: confirmar,
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (novo != null && novo >= minimo) onChanged(novo);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    Widget botao(IconData i, int delta, String dica) {
      final ativo = valor + delta >= minimo;
      return Pressionavel(
        escala: 0.92,
        child: Material(
          color: c.superficie,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Raio.medio),
            side: BorderSide(color: c.linha),
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
              child: Icon(i, semanticLabel: dica, color: ativo ? c.acao : c.linha, size: 24),
            ),
          ),
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        botao(Icons.remove, -1, 'Diminuir'),
        const SizedBox(width: Espaco.m),
        // O número fica numa "caixinha" para parecer tocável.
        Semantics(
          button: true,
          label: 'Quantidade $valor. Toque para digitar.',
          child: Material(
            color: c.realce,
            borderRadius: BorderRadius.circular(Raio.medio),
            child: InkWell(
              borderRadius: BorderRadius.circular(Raio.medio),
              onTap: () => _digitar(context),
              child: SizedBox(
                width: 104,
                height: 60,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: Movimento.rapido,
                    transitionBuilder: (w, a) => FadeTransition(
                      opacity: a,
                      child:
                          ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(a), child: w),
                    ),
                    child: Text('$valor',
                        key: ValueKey(valor),
                        textAlign: TextAlign.center,
                        style: context.tipos.display(size: 40)),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: Espaco.m),
        botao(Icons.add, 1, 'Aumentar'),
      ]),
      if (atalhos.isNotEmpty) ...[
        const SizedBox(height: Espaco.s),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final (i, n) in atalhos.indexed) ...[
            if (i > 0) const SizedBox(width: Espaco.s),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 36),
                padding: const EdgeInsets.symmetric(horizontal: Espaco.m),
                textStyle: context.tipos.valor(size: 14),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                onChanged(valor + n);
              },
              child: Text('+$n'),
            ),
          ],
        ]),
      ],
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
            decoration: BoxDecoration(
                color: context.cores.realce, borderRadius: BorderRadius.circular(Raio.medio)),
            child: Icon(icone, color: context.cores.acao, size: 24),
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

/// Barra de abas: fio fino em cima e um traço que acompanha a página,
/// inclusive enquanto o dedo arrasta entre as abas.
class NavAnimada extends StatelessWidget {
  final PageController controller;
  final int atual;
  final List<ItemNav> itens;
  final ValueChanged<int> onTap;
  const NavAnimada({
    super.key,
    required this.controller,
    required this.atual,
    required this.itens,
    required this.onTap,
  });

  double _posicao() {
    if (!controller.hasClients || !controller.position.haveDimensions) {
      return atual.toDouble();
    }
    return controller.page ?? atual.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final n = itens.length;
    final c = context.cores;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.superficie,
        border: Border(top: BorderSide(color: c.linha)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final pos = _posicao().clamp(0.0, (n - 1).toDouble());
              return Stack(children: [
                Align(
                  alignment: Alignment(n == 1 ? 0 : -1 + 2 * pos / (n - 1), -1),
                  child: FractionallySizedBox(
                    widthFactor: 1 / n,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 24,
                        height: 3,
                        decoration: BoxDecoration(
                          color: c.acao,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(children: [
                  for (final (i, it) in itens.indexed)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == atual,
                        label: it.texto,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (i != atual) HapticFeedback.selectionClick();
                            onTap(i);
                          },
                          child: ExcludeSemantics(
                            // 1 quando a página está inteira na tela, 0 quando está longe.
                            child:
                                _BotaoNav(item: it, ativo: (1 - (pos - i).abs()).clamp(0.0, 1.0)),
                          ),
                        ),
                      ),
                    ),
                ]),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class _BotaoNav extends StatelessWidget {
  final ItemNav item;
  final double ativo; // 0 a 1
  const _BotaoNav({required this.item, required this.ativo});

  @override
  Widget build(BuildContext context) {
    final cor = Color.lerp(context.cores.tintaSuave, context.cores.acao, ativo)!;
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

/// Mantém a aba montada quando sai da tela: não recarrega nem repete a animação
/// de entrada toda vez que ela volta.
class ManterViva extends StatefulWidget {
  final Widget child;
  const ManterViva({super.key, required this.child});

  @override
  State<ManterViva> createState() => _ManterVivaState();
}

class _ManterVivaState extends State<ManterViva> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Rodapé com o botão principal. Fica dentro do corpo da tela, então sobe junto
/// com o teclado; com o teclado aberto, ganha um botão para fechá-lo (o teclado
/// numérico do iPhone não tem tecla de fechar).
class BarraInferior extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;

  /// Dentro do corpo de um Scaffold o MediaQuery já vem sem o teclado, então a
  /// tela precisa informar (lendo o MediaQuery acima do Scaffold).
  final bool? tecladoAberto;
  const BarraInferior(
      {super.key, required this.texto, required this.onPressed, this.tecladoAberto});

  @override
  Widget build(BuildContext context) {
    final teclado = tecladoAberto ?? MediaQuery.viewInsetsOf(context).bottom > 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cores.papel,
        border: Border(top: BorderSide(color: context.cores.linha)),
      ),
      child: SafeArea(
        top: false,
        bottom: !teclado,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Espaco.borda, Espaco.s, Espaco.borda, Espaco.s),
          child: Row(children: [
            AnimatedSize(
              duration: Movimento.medio,
              curve: Movimento.entrada,
              child: teclado
                  ? Padding(
                      padding: const EdgeInsets.only(right: Espaco.s),
                      child: IconButton.outlined(
                        tooltip: 'Fechar teclado',
                        style: IconButton.styleFrom(
                          minimumSize: const Size(50, 50),
                          side: BorderSide(color: context.cores.linha),
                          backgroundColor: context.cores.superficie,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Raio.medio)),
                        ),
                        onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
                        icon: Icon(Icons.keyboard_hide_outlined, color: context.cores.acao),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: BotaoPrincipal(texto: texto, onPressed: onPressed),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Foto do produto (ou do ingrediente); sem foto, um desenho no lugar.
class FotoProduto extends StatelessWidget {
  final String? base64;
  final double tamanho;
  final double raio;
  final IconData icone;
  const FotoProduto(this.base64,
      {super.key, this.tamanho = 48, this.raio = Raio.pequeno, this.icone = Icons.cake_outlined});

  /// Desenho de quando o ingrediente ou a embalagem não tem foto.
  static IconData iconeInsumo(Insumo i) =>
      i.ehEmbalagem ? Icons.inventory_2_outlined : Icons.egg_outlined;

  static final _cache = <String, Uint8List>{};

  static Uint8List bytes(String b64) => _cache.putIfAbsent(b64, () => base64Decode(b64));

  @override
  Widget build(BuildContext context) {
    final b = base64;
    return ClipRRect(
      borderRadius: BorderRadius.circular(raio),
      child: SizedBox(
        width: tamanho,
        height: tamanho,
        child: b == null
            ? ColoredBox(
                color: context.cores.realce,
                child: Icon(icone, size: tamanho * 0.42, color: context.cores.tintaSuave),
              )
            : Image.memory(bytes(b), fit: BoxFit.cover, gaplessPlayback: true),
      ),
    );
  }
}

/// Botão principal: cor de ação sólida, sem enfeite.
class BotaoPrincipal extends StatelessWidget {
  final String texto;
  final IconData? icone;
  final VoidCallback? onPressed;
  const BotaoPrincipal({super.key, required this.texto, this.icone, this.onPressed});

  @override
  Widget build(BuildContext context) => Pressionavel(
        child: icone == null
            ? FilledButton(onPressed: onPressed, child: Text(texto))
            : FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(icone, size: 22),
                label: Text(texto),
              ),
      );
}

/// Etiqueta curta e colorida (ex.: "+R$ 118 de lucro").
class Pilula extends StatelessWidget {
  final String texto;
  final Color cor;
  final IconData? icone;
  const Pilula(this.texto, {super.key, required this.cor, this.icone});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: Espaco.m, vertical: 6),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(Raio.pequeno),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icone != null) ...[
            Icon(icone, size: 16, color: cor),
            const SizedBox(width: Espaco.xs),
          ],
          Text(texto, style: context.tipos.valor(size: 13, color: cor)),
        ]),
      );
}

/// Pergunta de onde vem a foto (câmera ou galeria) e devolve a imagem já reduzida,
/// em base64. Devolve `null` se ela desistir e `''` se pediu para tirar a foto.
Future<String?> pedirFoto(BuildContext context, {required bool temFoto}) async {
  // Fechar a folha é desistir; "Tirar a foto" volta como 'remover'.
  final escolha = await showModalBottomSheet<Object>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: const Text('Tirar foto'),
          onTap: () => Navigator.pop(ctx, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Escolher da galeria'),
          onTap: () => Navigator.pop(ctx, ImageSource.gallery),
        ),
        if (temFoto)
          ListTile(
            leading: Icon(Icons.delete_outline, color: ctx.cores.negativo),
            title: const Text('Tirar a foto'),
            onTap: () => Navigator.pop(ctx, 'remover'),
          ),
      ]),
    ),
  );
  if (escolha == 'remover') return '';
  if (escolha is! ImageSource) return null;
  final origem = escolha;
  try {
    // Reduz a foto para não pesar no aparelho.
    final img = await ImagePicker()
        .pickImage(source: origem, maxWidth: 700, maxHeight: 700, imageQuality: 75);
    if (img == null) return null;
    return base64Encode(await img.readAsBytes());
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Não deu para abrir a câmera/galeria. Verifique a permissão nos Ajustes do celular.')));
    }
    return null;
  }
}

/// Logo da loja: a foto que ela escolheu ou, sem foto, o ícone do app.
class AvatarLoja extends StatelessWidget {
  final Loja loja;
  final double tamanho;
  const AvatarLoja(this.loja, {super.key, this.tamanho = 56});

  @override
  Widget build(BuildContext context) {
    final foto = loja.fotoBase64;
    return ClipRRect(
      borderRadius: BorderRadius.circular(tamanho >= 40 ? Raio.medio : Raio.pequeno),
      child: foto == null
          ? Image.asset('assets/logo/icone.png', width: tamanho, height: tamanho)
          : Image.memory(FotoProduto.bytes(foto),
              width: tamanho, height: tamanho, fit: BoxFit.cover, gaplessPlayback: true),
    );
  }
}

/// Logo da loja com um botãozinho de câmera: um toque já abre a câmera ou a
/// galeria para pôr (ou trocar) a foto daquela loja.
class AvatarLojaEditavel extends StatelessWidget {
  final Store store;
  final Loja loja;
  final double tamanho;
  const AvatarLojaEditavel({super.key, required this.store, required this.loja, this.tamanho = 56});

  Future<void> _trocar(BuildContext context) async {
    final foto = await pedirFoto(context, temFoto: loja.fotoBase64 != null);
    if (foto == null) return;
    await store.mudarFotoLoja(loja.id, foto.isEmpty ? null : foto);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final selo = (tamanho * 0.45).clamp(18.0, 26.0);
    return Semantics(
      button: true,
      label: loja.fotoBase64 == null
          ? 'Pôr foto da loja ${loja.nome}'
          : 'Trocar foto da loja ${loja.nome}',
      child: Pressionavel(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _trocar(context),
          child: Stack(clipBehavior: Clip.none, children: [
            AvatarLoja(loja, tamanho: tamanho),
            Positioned(
              right: -selo / 4,
              bottom: -selo / 4,
              child: Container(
                width: selo,
                height: selo,
                decoration: BoxDecoration(
                  color: c.acao,
                  borderRadius: BorderRadius.circular(Raio.pequeno),
                  border: Border.all(color: c.papel, width: 2),
                ),
                child: Icon(Icons.photo_camera, size: selo * 0.55, color: c.sobreAcao),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
