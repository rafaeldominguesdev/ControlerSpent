import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

/// Partes comuns das abas Vendas e Produção: registrar rápido, editar,
/// e as linhas do histórico agrupadas por dia.

final formatoDia = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');
final formatoDiaCurto = DateFormat("d 'de' MMMM", 'pt_BR');

bool mesmoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

List<(DateTime, List<Lancamento>)> agruparPorDia(Iterable<Lancamento> ls) {
  final grupos = <(DateTime, List<Lancamento>)>[];
  for (final l in ls) {
    final d = DateTime(l.data.year, l.data.month, l.data.day);
    if (grupos.isNotEmpty && grupos.last.$1 == d) {
      grupos.last.$2.add(l);
    } else {
      grupos.add((d, [l]));
    }
  }
  return grupos;
}

String nomeDia(DateTime d) {
  final hoje = DateTime.now();
  if (mesmoDia(d, hoje)) return 'Hoje';
  if (mesmoDia(d, hoje.subtract(const Duration(days: 1)))) return 'Ontem';
  return formatoDia.format(d);
}

String _plural(int n, String um, String varios) => n == 1 ? '1 $um' : '$n $varios';

class _FluxoRapido extends StatefulWidget {
  final Store store;
  final TipoLancamento tipo;
  const _FluxoRapido({required this.store, required this.tipo});

  @override
  State<_FluxoRapido> createState() => _FluxoRapidoState();
}

class _FluxoRapidoState extends State<_FluxoRapido> {
  Produto? _produto;
  int _qtd = 1;
  Pagamento _pagamento = Pagamento.pix;
  final _preco = TextEditingController();
  final _cliente = TextEditingController();
  final _obs = TextEditingController();

  Store get store => widget.store;
  TipoLancamento get tipo => widget.tipo;

  void _escolher(Produto p) {
    final preco = p.precoVendaCentavos ?? store.calcular(p).precoSugerido.round();
    _preco.text = (preco / 100).toStringAsFixed(2).replaceAll('.', ',');
    setState(() {
      _produto = p;
      _qtd = tipo == TipoLancamento.producao ? p.rendimento : 1;
    });
  }

  Lancamento get _lancamento {
    final custo = store.calcular(_produto!).custoUnitario;
    return switch (tipo) {
      TipoLancamento.venda => Lancamento.venda(_produto!, custo,
          qtd: _qtd,
          preco: parseCentavos(_preco.text) ?? 0,
          pagamento: _pagamento,
          taxa: store.ajustes.taxa(_pagamento),
          cliente: _cliente.text,
          obs: _obs.text),
      TipoLancamento.perda => Lancamento.perda(_produto!, custo, _qtd),
      _ => Lancamento.producao(_produto!, custo, _qtd),
    };
  }

  Future<void> _confirmar() async {
    final l = _lancamento;
    await store.salvarLancamento(l);
    if (mounted) Navigator.pop(context, l);
  }

  @override
  Widget build(BuildContext context) {
    final voltar = _produto == null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AnimatedSize(
        duration: Movimento.medio,
        curve: Movimento.entrada,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: Movimento.medio,
          switchInCurve: Movimento.entrada,
          switchOutCurve: Movimento.saida,
          transitionBuilder: (c, a) {
            final entrando = c.key == ValueKey(voltar ? 'produto' : 'qtd');
            final dx = (entrando ? 1 : -1) * (voltar ? -0.08 : 0.08);
            return FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(a),
                child: c,
              ),
            );
          },
          child: _produto == null ? _passoProduto() : _passoQuantidade(),
        ),
      ),
    );
  }

  Widget _passoProduto() {
    final c = context.cores;
    final t = context.tipos;
    final pergunta = switch (tipo) {
      TipoLancamento.venda => 'O que você vendeu?',
      TipoLancamento.perda => 'O que se perdeu?',
      _ => 'O que você produziu?',
    };
    return Padding(
      key: const ValueKey('produto'),
      padding: const EdgeInsets.fromLTRB(Espaco.borda, 0, Espaco.borda, Espaco.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(pergunta, style: t.secao()),
          const SizedBox(height: Espaco.l),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: Espaco.m,
              crossAxisSpacing: Espaco.m,
              childAspectRatio: 0.86,
              children: [
                for (final p in store.produtos) _cartaoProduto(p, c, t),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartaoProduto(Produto p, Cores c, Tipos t) {
    final estoque = store.estoque(p.id);
    final detalhe = switch (tipo) {
      TipoLancamento.producao => 'Rende ${p.rendimento}',
      _ when estoque > 0 => _plural(estoque, 'pronto', 'prontos'),
      _ => null,
    };
    return Pressionavel(
      child: Material(
        color: c.superficie,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Raio.medio),
          side: BorderSide(color: c.linha),
        ),
        child: InkWell(
          onTap: () => _escolher(p),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: LayoutBuilder(
                builder: (_, caixa) => FotoProduto(p.fotoBase64, tamanho: caixa.maxWidth, raio: 0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Espaco.m, Espaco.s, Espaco.m, Espaco.m),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.corpo(peso: FontWeight.w600).copyWith(fontSize: 15)),
                Row(children: [
                  Text(reais(p.precoVendaCentavos ?? store.calcular(p).precoSugerido),
                      style: t.valor(size: 13, color: c.tintaSuave, peso: FontWeight.w500)),
                  if (detalhe != null) ...[
                    const Spacer(),
                    Text(detalhe,
                        style: t
                            .apoio(color: tipo == TipoLancamento.producao ? null : c.positivo)
                            .copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _passoQuantidade() {
    final c = context.cores;
    final t = context.tipos;
    final l = _lancamento;
    final p = _produto!;
    final pergunta = switch (tipo) {
      TipoLancamento.venda => 'Quantos vendeu?',
      TipoLancamento.perda => 'Quantos se perderam?',
      _ => 'Quantos ficaram prontos?',
    };
    final botao = switch (tipo) {
      TipoLancamento.venda => 'Anotar venda de ${reais(l.faturamento)}',
      TipoLancamento.perda => 'Anotar perda',
      _ => 'Anotar produção de $_qtd',
    };
    final clientes = store.clientesRecentes();

    return Padding(
      key: const ValueKey('qtd'),
      padding: const EdgeInsets.fromLTRB(Espaco.borda, 0, Espaco.borda, Espaco.xl),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              IconButton(
                tooltip: 'Escolher outro produto',
                onPressed: () => setState(() => _produto = null),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: Espaco.xs),
              FotoProduto(p.fotoBase64, tamanho: 40),
              const SizedBox(width: Espaco.m),
              Expanded(
                child: Text(p.nome, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.secao()),
              ),
            ]),
            const SizedBox(height: Espaco.l),
            Text(pergunta, textAlign: TextAlign.center, style: t.corpo(color: c.tintaSuave)),
            const SizedBox(height: Espaco.m),
            Contador(valor: _qtd, onChanged: (v) => setState(() => _qtd = v)),
            if (tipo == TipoLancamento.producao && p.rendimento > 1) ...[
              const SizedBox(height: Espaco.m),
              // Atalhos: a receita rende N, então 1, 2 ou 3 receitas.
              SeletorOpcoes<int>(
                opcoes: [
                  for (final n in [1, 2, 3])
                    (n * p.rendimento, '$n ${n == 1 ? 'receita' : 'receitas'}'),
                ],
                valor: _qtd,
                onChanged: (v) => setState(() => _qtd = v),
              ),
            ],
            if (tipo == TipoLancamento.venda) ...[
              const SizedBox(height: Espaco.xl),
              TextField(
                controller: _preco,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Preço de cada', prefixText: 'R\$ '),
              ),
              const SizedBox(height: Espaco.l),
              Text('Como pagou?', style: t.apoio()),
              const SizedBox(height: Espaco.s),
              SeletorOpcoes<Pagamento>(
                opcoes: [for (final p in Pagamento.values) (p, p.label)],
                valor: _pagamento,
                onChanged: (p) => setState(() => _pagamento = p),
              ),
              const SizedBox(height: Espaco.l),
              TextField(
                controller: _cliente,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Cliente (opcional)', prefixIcon: Icon(Icons.person_outline)),
              ),
              if (clientes.isNotEmpty) ...[
                const SizedBox(height: Espaco.s),
                Wrap(spacing: Espaco.s, runSpacing: Espaco.s, children: [
                  for (final nome in clientes)
                    _Sugestao(
                      texto: nome,
                      onTap: () => setState(() => _cliente.text = nome),
                    ),
                ]),
              ],
              const SizedBox(height: Espaco.m),
              TextField(
                controller: _obs,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Observação (opcional)', hintText: 'Ex.: entregar sábado'),
              ),
            ],
            const SizedBox(height: Espaco.l),
            ...switch (tipo) {
              TipoLancamento.venda => [
                  LinhaConta('Total', l.faturamento, cor: c.positivo),
                  LinhaConta('Seu lucro', l.lucro,
                      forte: true, cor: l.lucro < 0 ? c.negativo : c.positivo),
                ],
              TipoLancamento.perda => [
                  LinhaConta('Custo perdido', -l.lucro, forte: true, cor: c.negativo),
                ],
              _ => [
                  LinhaConta('Custo dos ingredientes', l.custo),
                  LinhaConta('Prontos depois disso', 0,
                      forte: true,
                      texto: _plural(store.estoque(p.id) + _qtd, 'unidade', 'unidades')),
                ],
            },
            const SizedBox(height: Espaco.l),
            Pressionavel(child: FilledButton(onPressed: _confirmar, child: Text(botao))),
          ],
        ),
      ),
    );
  }
}

/// Sugestão tocável (ex.: nome de cliente que já comprou).
class _Sugestao extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;
  const _Sugestao({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Material(
      color: c.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Raio.pequeno),
        side: BorderSide(color: c.linha),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Raio.pequeno),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Espaco.m, vertical: Espaco.s),
          child: Text(texto, style: context.tipos.apoio(color: c.tinta)),
        ),
      ),
    );
  }
}
