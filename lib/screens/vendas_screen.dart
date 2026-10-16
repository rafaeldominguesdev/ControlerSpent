import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'backup_screen.dart';
import 'encomendas_screen.dart';
import 'lancar.dart';

enum _Parte { vender, encomendas, historico }

/// O preço que vai na venda (o mesmo que o registro rápido usa).
int _preco(Store store, Produto p) =>
    p.precoVendaCentavos ?? store.calcular(p).precoSugerido.round();

/// Vendas: quanto entrou hoje e, separados, "Vender" (os produtos em grade ou
/// lista, um toque registra a venda) e "Histórico" (o caderno por dia).
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
        final abertas = store.encomendas.where((e) => e.status == StatusEncomenda.aberta).length;

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
              if (store.precisaCopia) ...[
                const SizedBox(height: Espaco.l),
                _LembreteCopia(store: store),
              ],
              const SizedBox(height: Espaco.xl),
              EntradaSuave(
                ordem: 1,
                child: SeletorOpcoes<_Parte>(
                  opcoes: [
                    (_Parte.vender, 'Vender'),
                    (
                      _Parte.encomendas,
                      abertas == 0 ? 'Encomendas' : 'Encomendas ($abertas)',
                    ),
                    (_Parte.historico, 'Histórico'),
                  ],
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
                child: switch (_parte) {
                  _Parte.vender => _Vender(key: const ValueKey('vender'), store: store),
                  _Parte.encomendas =>
                    ListaEncomendas(key: const ValueKey('encomendas'), store: store),
                  _Parte.historico =>
                    _Historico(key: const ValueKey('historico'), store: store, vendas: vendas),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Os produtos para vender, em grade ou em lista (o app lembra a escolha).
class _Vender extends StatelessWidget {
  final Store store;
  const _Vender({super.key, required this.store});

  void _vender(BuildContext context, Produto p) =>
      registrarRapido(context, store, TipoLancamento.venda, produto: p);

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    if (store.produtos.isEmpty) {
      return Column(children: [
        const Vazio(
          icone: Icons.cake_outlined,
          titulo: 'Nenhum produto ainda',
          texto:
              'Cadastre seus produtos na aba Produtos. Depois é só tocar neles aqui para vender.',
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
    final emLista = store.vendasEmLista;

    Widget alternar(IconData icone, String dica, bool lista) {
      final ativo = emLista == lista;
      return IconButton(
        tooltip: dica,
        isSelected: ativo,
        style: IconButton.styleFrom(
          backgroundColor: ativo ? c.realce : Colors.transparent,
          foregroundColor: ativo ? c.acao : c.tintaSuave,
        ),
        onPressed: () {
          HapticFeedback.selectionClick();
          store.mudarModoVendas(lista: lista);
        },
        icon: Icon(icone),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text('Toque no produto para vender', style: t.apoio())),
        alternar(Icons.grid_view_rounded, 'Ver em grade', false),
        alternar(Icons.view_list_rounded, 'Ver em lista', true),
      ]),
      const SizedBox(height: Espaco.s),
      AnimatedSwitcher(
        duration: Movimento.medio,
        child: emLista
            ? GrupoLista(
                key: const ValueKey('lista'),
                recuoDivisoria: 72,
                children: [
                  for (final p in produtos)
                    _LinhaVenda(store: store, p: p, onVender: () => _vender(context, p)),
                ],
              )
            : LayoutBuilder(
                key: const ValueKey('grade'),
                builder: (context, caixa) {
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
                        store: store,
                        p: produtos[i],
                        onVender: () => _vender(context, produtos[i])),
                  );
                },
              ),
      ),
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
                  builder: (_, caixa) =>
                      FotoProduto(p.fotoBase64, tamanho: caixa.maxWidth, raio: 0),
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

class _LinhaVenda extends StatelessWidget {
  final Store store;
  final Produto p;
  final VoidCallback onVender;
  const _LinhaVenda({required this.store, required this.p, required this.onVender});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final estoque = store.estoque(p.id);
    return InkWell(
      onTap: onVender,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.s, Espaco.s, Espaco.s),
        child: Row(children: [
          FotoProduto(p.fotoBase64, tamanho: 44),
          const SizedBox(width: Espaco.m),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.corpo(peso: FontWeight.w600)),
              Text(
                [
                  reais(_preco(store, p)),
                  if (estoque > 0) '$estoque prontos',
                ].join(' · '),
                style: t.apoio().copyWith(fontSize: 12),
              ),
            ]),
          ),
          IconButton.filledTonal(
            tooltip: 'Vender ${p.nome}',
            style: IconButton.styleFrom(backgroundColor: c.realce, foregroundColor: c.acao),
            onPressed: onVender,
            icon: const Icon(Icons.add),
          ),
        ]),
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

/// Um lembrete discreto quando faz uma semana (ou nunca) que a cópia não sai
/// do celular. Some sozinho depois de salvar uma.
class _LembreteCopia extends StatelessWidget {
  final Store store;
  const _LembreteCopia({required this.store});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    return Material(
      color: c.atencao.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(Raio.medio),
      child: InkWell(
        borderRadius: BorderRadius.circular(Raio.medio),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => BackupScreen(store: store))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Espaco.l, vertical: Espaco.m),
          child: Row(children: [
            Icon(Icons.cloud_upload_outlined, color: c.atencao, size: 20),
            const SizedBox(width: Espaco.m),
            Expanded(
              child: Text('Salve uma cópia dos seus dados fora do celular',
                  style: t.corpo(color: c.atencao).copyWith(fontSize: 14)),
            ),
            Icon(Icons.chevron_right, color: c.atencao),
          ]),
        ),
      ),
    );
  }
}
