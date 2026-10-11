import 'package:flutter/material.dart';

import '../models.dart';
import '../receitas_prontas.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'produto_form.dart';
import 'receitas_prontas_screen.dart';
import 'ajustes_screen.dart';

Color corStatus(BuildContext context, StatusPreco s) => switch (s) {
      StatusPreco.lucrativo => context.cores.positivo,
      StatusPreco.atencao => context.cores.atencao,
      StatusPreco.prejuizo => context.cores.negativo,
      StatusPreco.semPreco => context.cores.tintaSuave,
    };

String textoStatus(StatusPreco s) => switch (s) {
      StatusPreco.lucrativo => 'Lucrativo',
      StatusPreco.atencao => 'Atenção',
      StatusPreco.prejuizo => 'Prejuízo',
      StatusPreco.semPreco => 'Sem preço',
    };

class ProdutosScreen extends StatelessWidget {
  final Store store;
  const ProdutosScreen({super.key, required this.store});

  void _abrirProntas(BuildContext context) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => ReceitasProntasScreen(store: store)));

  void _abrir(BuildContext context, [Produto? p]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProdutoForm(store: store, atual: p)),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) => _tela(context),
      );

  Widget _tela(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos'), actions: [BotaoConfiguracoes(store: store)]),
      floatingActionButton: store.produtos.isEmpty
          ? null
          : SizedBox(
              width: 190,
              child: BotaoPrincipal(
                  texto: 'Novo produto', icone: Icons.add, onPressed: () => _abrir(context)),
            ),
      body: Builder(
        builder: (context) {
          if (store.produtos.isEmpty) {
            return Center(
              child: Vazio(
                icone: Icons.cake_outlined,
                titulo: 'Seu cardápio começa aqui',
                texto: 'Cadastre um produto com a receita. O app calcula quanto custa '
                    'cada unidade e sugere o preço.',
                acao: 'Usar uma receita pronta',
                onAcao: () => _abrirProntas(context),
                acaoSecundaria: 'Cadastrar do zero',
                onAcaoSecundaria: () => _abrir(context),
              ),
            );
          }
          final calculos = [for (final p in store.produtos) store.calcular(p)];
          return ListView(
            padding: const EdgeInsets.fromLTRB(Espaco.borda, 0, Espaco.borda, Espaco.secao),
            children: [
              EntradaSuave(child: _Destaque(calculos: calculos)),
              const SizedBox(height: Espaco.xl),
              EntradaSuave(ordem: 1, child: _AtalhoProntas(onTap: () => _abrirProntas(context))),
              const SizedBox(height: Espaco.l),
              EntradaSuave(
                ordem: 2,
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  crossAxisCount: 2,
                  mainAxisSpacing: Espaco.m,
                  crossAxisSpacing: Espaco.m,
                  childAspectRatio: 0.8,
                  children: [
                    for (final (i, p) in store.produtos.indexed)
                      _CartaoProduto(p: p, c: calculos[i], onTap: () => _abrir(context, p)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Topo da aba: quantos produtos e a margem média do cardápio.
class _Destaque extends StatelessWidget {
  final List<Calculo> calculos;
  const _Destaque({required this.calculos});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final margens = [
      for (final x in calculos)
        if (x.margemReal != null) x.margemReal!
    ];
    final media = margens.isEmpty ? null : margens.reduce((a, b) => a + b) / margens.length * 100;
    final atencao = calculos
        .where((x) => x.status == StatusPreco.atencao || x.status == StatusPreco.prejuizo)
        .length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Rotulo('Cardápio'),
      const SizedBox(height: Espaco.xs),
      Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('${calculos.length}', style: t.display(size: 46)),
            const SizedBox(width: Espaco.s),
            Text(calculos.length == 1 ? 'produto' : 'produtos', style: t.apoio()),
          ]),
      const SizedBox(height: Espaco.s),
      Wrap(spacing: Espaco.s, runSpacing: Espaco.s, children: [
        if (media != null)
          Pilula('margem média ${media.toStringAsFixed(0)}%',
              cor: media >= 30 ? c.positivo : c.atencao, icone: Icons.trending_up),
        if (atencao > 0)
          Pilula(atencao == 1 ? '1 pedindo atenção' : '$atencao pedindo atenção',
              cor: c.negativo, icone: Icons.error_outline),
      ]),
    ]);
  }
}

/// Produto em cartão: foto grande, margem por cima, nome e preço.
class _CartaoProduto extends StatelessWidget {
  final Produto p;
  final Calculo c;
  final VoidCallback onTap;
  const _CartaoProduto({required this.p, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final t = context.tipos;
    final cor = corStatus(context, c.status);
    final margem = c.margemReal == null ? null : '${(c.margemReal! * 100).toStringAsFixed(0)}%';
    return Pressionavel(
      child: Material(
        color: cores.superficie,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Raio.medio),
          side: BorderSide(color: cores.linha),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                Hero(
                  tag: 'foto-${p.id}',
                  child: LayoutBuilder(
                    builder: (_, caixa) =>
                        FotoProduto(p.fotoBase64, tamanho: caixa.maxWidth, raio: 0),
                  ),
                ),
                Positioned(
                  top: Espaco.s,
                  right: Espaco.s,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Espaco.s, vertical: 3),
                    decoration: BoxDecoration(
                      color: cores.papel.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(Raio.pequeno),
                    ),
                    child: Text(margem ?? textoStatus(c.status),
                        style: t.valor(size: 12, color: cor, peso: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Espaco.m, Espaco.s, Espaco.m, Espaco.m),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.corpo(peso: FontWeight.w600).copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(reais(c.precoVenda ?? c.precoSugerido),
                    style: t.valor(
                        size: 15, color: c.precoVenda == null ? cores.tintaSuave : cores.tinta)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Atalho para as receitas prontas, no topo da lista de produtos.
class _AtalhoProntas extends StatelessWidget {
  final VoidCallback onTap;
  const _AtalhoProntas({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final nomes = receitasProntas.take(3).map((m) => m.nome.toLowerCase()).join(', ');
    return Pressionavel(
      escala: 0.98,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Espaco.l, vertical: Espaco.m),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: c.dinheiroSuave, borderRadius: BorderRadius.circular(Raio.pequeno)),
                child: Icon(Icons.menu_book_outlined, color: c.positivo, size: 22),
              ),
              const SizedBox(width: Espaco.m),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Receitas prontas', style: t.corpo(peso: FontWeight.w600)),
                  Text('${nomes[0].toUpperCase()}${nomes.substring(1)} e mais',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.apoio().copyWith(fontSize: 12)),
                ]),
              ),
              Icon(Icons.chevron_right, color: c.tintaSuave),
            ]),
          ),
        ),
      ),
    );
  }
}
