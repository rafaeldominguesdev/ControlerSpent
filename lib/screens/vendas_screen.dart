import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'lancar.dart';

enum _Parte { vender, historico }

/// O preço que vai na venda (o mesmo que o registro rápido usa).
int _preco(Store store, Produto p) =>
    p.precoVendaCentavos ?? store.calcular(p).precoSugerido.round();

/// Vendas: quanto entrou hoje e, separados, "Vender" (os produtos em grade, um
/// toque registra a venda) e "Histórico" (o caderno por dia).
class VendasScreen extends StatefulWidget {
  final Store store;
  const VendasScreen({super.key, required this.store});

  @override
  State<VendasScreen> createState() => _VendasScreenState();
}

class _VendasScreenState extends State<VendasScreen> {
  _Parte _parte = _Parte.vender;

  Store get store => widget.store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.cores;
        final t = context.tipos;
        final hoje = DateTime.now();
        final vendas = store.lancamentos.where((l) => l.tipo == TipoLancamento.venda);
        final deHoje = vendas.where((l) => mesmoDia(l.data, hoje));
        final vendidoHoje = deHoje.fold(0.0, (s, l) => s + l.faturamento);
        final lucroHoje = deHoje.fold(0.0, (s, l) => s + l.lucro);

        return Scaffold(
          appBar: AppBar(title: const Text('Vendas')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(Espaco.borda, Espaco.xs, Espaco.borda, Espaco.secao),
            children: [
              EntradaSuave(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Rotulo('Hoje, ${formatoDiaCurto.format(hoje)}'),
                  const SizedBox(height: Espaco.xs),
                  ValorAnimado(vendidoHoje, style: t.display(size: 46, color: c.positivo)),
                  const SizedBox(height: Espaco.s),
                  vendidoHoje == 0
                      ? Text('Nenhuma venda hoje ainda.', style: t.apoio())
                      : Pilula('+${reais(lucroHoje)} de lucro',
                          cor: c.positivo, icone: Icons.trending_up),
                ]),
              ),
              const SizedBox(height: Espaco.xl),
              EntradaSuave(
                ordem: 1,
                child: SeletorOpcoes<_Parte>(
                  opcoes: const [(_Parte.vender, 'Vender'), (_Parte.historico, 'Histórico')],
                  valor: _parte,
                  onChanged: (p) => setState(() => _parte = p),
                ),
              ),
              const SizedBox(height: Espaco.l),
              AnimatedSwitcher(
                duration: Movimento.medio,
                switchInCurve: Movimento.entrada,
                switchOutCurve: Movimento.saida,
                layoutBuilder: (atual, anteriores) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...anteriores, if (atual != null) atual],
                ),
                child: _parte == _Parte.vender
                    ? _Vender(key: const ValueKey('vender'), store: store)
                    : _Historico(key: const ValueKey('historico'), store: store, vendas: vendas),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Os produtos para vender, em grade.
class _Vender extends StatelessWidget {
  final Store store;
  const _Vender({super.key, required this.store});

  void _vender(BuildContext context, Produto p) =>
      registrarRapido(context, store, TipoLancamento.venda, produto: p);

  @override
  Widget build(BuildContext context) {
    final t = context.tipos;
    if (store.produtos.isEmpty) {
      return Column(children: [
        const Vazio(
          icone: Icons.cake_outlined,
          titulo: 'Nenhum produto ainda',
          texto: 'Cadastre seus produtos na aba Produtos. Depois é só tocar neles aqui para vender.',
        ),
        BotaoPrincipal(
          texto: 'Registrar venda',
          icone: Icons.add,
          onPressed: () => registrarRapido(context, store, TipoLancamento.venda),
        ),
      ]);
    }

    // Os mais vendidos nos últimos 30 dias aparecem primeiro.
    final desde = DateTime.now().subtract(const Duration(days: 30));
    final vendidos = <int, int>{};
    for (final l in store.lancamentos) {
      if (l.tipo == TipoLancamento.venda && l.data.isAfter(desde)) {
        vendidos[l.produtoId] = (vendidos[l.produtoId] ?? 0) + l.vendidos;
      }
    }
    final produtos = [...store.produtos]
      ..sort((a, b) => (vendidos[b.id] ?? 0).compareTo(vendidos[a.id] ?? 0));

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Toque no produto para vender', style: t.apoio()),
      const SizedBox(height: Espaco.m),
      LayoutBuilder(builder: (context, caixa) {
        // Altura fixa por cartão (foto quadrada + duas linhas de nome + preço),
        // para os preços ficarem alinhados mesmo com nomes de tamanhos diferentes.
        const colunas = 3;
        final largura = (caixa.maxWidth - Espaco.s * (colunas - 1)) / colunas;
        final escala = MediaQuery.textScalerOf(context);
        final textos = escala.scale(13) * 1.15 * 2 + escala.scale(12) * 1.3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: colunas,
            mainAxisSpacing: Espaco.s,
            crossAxisSpacing: Espaco.s,
            mainAxisExtent: largura + Espaco.xs + Espaco.s + 4 + textos,
          ),
          itemCount: produtos.length,
          itemBuilder: (context, i) => _CartaoVenda(
              store: store, p: produtos[i], onVender: () => _vender(context, produtos[i])),
        );
      }),
    ]);
  }
}

class _CartaoVenda extends StatelessWidget {
  final Store store;
  final Produto p;
  final VoidCallback onVender;
  const _CartaoVenda({required this.store, required this.p, required this.onVender});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final estoque = store.estoque(p.id);
    return Pressionavel(
      child: Material(
        color: c.superficie,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Raio.medio),
          side: BorderSide(color: c.linha),
        ),
        child: InkWell(
          onTap: onVender,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(fit: StackFit.expand, children: [
                LayoutBuilder(
                  builder: (_, caixa) => FotoProduto(p.fotoBase64, tamanho: caixa.maxWidth, raio: 0),
                ),
                if (estoque > 0)
                  Positioned(
                    left: Espaco.xs,
                    bottom: Espaco.xs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.superficie,
                        borderRadius: BorderRadius.circular(Raio.pequeno),
                      ),
                      child: Text('$estoque prontos',
                          style: t.valor(size: 11, color: c.positivo, peso: FontWeight.w700)),
                    ),
                  ),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Espaco.s, Espaco.xs, Espaco.s, Espaco.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.corpo(peso: FontWeight.w600).copyWith(fontSize: 13, height: 1.15)),
                    Text(reais(_preco(store, p)),
                        style: t.valor(size: 12, color: c.tintaSuave, peso: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// O caderno de vendas, separado por dia.
class _Historico extends StatelessWidget {
  final Store store;
  final Iterable<Lancamento> vendas;
  const _Historico({super.key, required this.store, required this.vendas});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final dias = agruparPorDia(vendas);
    if (dias.isEmpty) {
      return const Vazio(
        icone: Icons.receipt_long_outlined,
        titulo: 'Nenhuma venda ainda',
        texto: 'Cada venda que você registrar aparece aqui, separada por dia.',
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final dia in dias)
        GrupoDia(
          store: store,
          dia: dia.$1,
          itens: dia.$2,
          resumo: Text(reais(dia.$2.fold(0.0, (s, l) => s + l.faturamento)),
              style: t.valor(size: 12, color: c.positivo)),
        ),
    ]);
  }
}
