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

  String _saude(List<Calculo> calculos) {
    final n = calculos.length;
    final bons = calculos.where((c) => c.status == StatusPreco.lucrativo).length;
    final ruins = calculos
        .where((c) => c.status == StatusPreco.atencao || c.status == StatusPreco.prejuizo)
        .length;
    final total = n == 1 ? '1 produto' : '$n produtos';
    if (ruins == 0 && bons == n) return '$total, todos com boa margem.';
    final partes = [
      if (bons > 0) bons == 1 ? '1 com boa margem' : '$bons com boa margem',
      if (ruins > 0) ruins == 1 ? '1 pedindo atenção' : '$ruins pedindo atenção',
    ];
    return partes.isEmpty ? '$total.' : '$total: ${partes.join(' e ')}.';
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
          : Pressionavel(
              child: FloatingActionButton.extended(
                onPressed: () => _abrir(context),
                icon: const Icon(Icons.add),
                label: const Text('Novo produto'),
              ),
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
            padding: const EdgeInsets.fromLTRB(Espaco.borda, 0, Espaco.borda, 120),
            children: [
              EntradaSuave(
                child: Text(_saude(calculos),
                    style: context.tipos.corpo(color: context.cores.tintaSuave)),
              ),
              const SizedBox(height: Espaco.l),
              EntradaSuave(ordem: 1, child: _AtalhoProntas(onTap: () => _abrirProntas(context))),
              const SizedBox(height: Espaco.m),
              EntradaSuave(
                ordem: 2,
                child: GrupoLista(recuoDivisoria: 72, children: [
                  for (final (i, p) in store.produtos.indexed)
                    _LinhaProduto(p: p, c: calculos[i], onTap: () => _abrir(context, p)),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LinhaProduto extends StatelessWidget {
  final Produto p;
  final Calculo c;
  final VoidCallback onTap;
  const _LinhaProduto({required this.p, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cor = corStatus(context, c.status);
    final margem = c.margemReal == null ? null : '${(c.margemReal! * 100).toStringAsFixed(0)}%';
    // Só escreve o status quando pede atenção; margem boa já fala por si.
    final legenda = switch (c.status) {
      StatusPreco.lucrativo => '$margem de margem',
      StatusPreco.semPreco => 'sem preço',
      _ => '${textoStatus(c.status)}, $margem',
    };
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Espaco.l, vertical: Espaco.m),
        child: Row(children: [
          Hero(
            tag: 'foto-${p.id}',
            child: FotoProduto(p.fotoBase64, tamanho: 44),
          ),
          const SizedBox(width: Espaco.m),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.tipos.corpo(peso: FontWeight.w600)),
              Text('Custa ${reais(c.custoUnitario)}',
                  style: context.tipos.apoio().copyWith(fontSize: 12)),
            ]),
          ),
          const SizedBox(width: Espaco.s),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(reais(c.precoVenda ?? c.precoSugerido),
                style: context.tipos.valor(
                    color: c.precoVenda == null ? context.cores.tintaSuave : context.cores.tinta)),
            Text(legenda, style: context.tipos.apoio(color: cor).copyWith(fontSize: 12)),
          ]),
        ]),
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
