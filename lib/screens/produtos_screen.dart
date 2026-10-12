import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../receitas_prontas.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'produto_form.dart';
import 'receitas_prontas_screen.dart';

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

/// Filtro "Outros": produtos sem categoria.
const _semCategoria = '';

/// O cardápio: os produtos com preço, custo e lucro de cada unidade, filtrados
/// por categoria, em grade ou em lista (o app lembra a escolha).
class ProdutosScreen extends StatefulWidget {
  final Store store;
  const ProdutosScreen({super.key, required this.store});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  /// Categoria escolhida no filtro; `null` mostra todas.
  String? _categoria;

  Store get store => widget.store;

  void _abrirProntas() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => ReceitasProntasScreen(store: store)));

  void _abrir([Produto? p]) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => ProdutoForm(store: store, atual: p)));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) => _tela(context),
      );

  Widget _tela(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final categorias = store.categorias;
    final semCategoria = store.produtos.where((p) => p.categoria.trim().isEmpty).length;
    // A categoria escolhida pode ter sumido (produto apagado ou trocado de categoria).
    if (_categoria != null &&
        !(categorias.contains(_categoria) || (_categoria == _semCategoria && semCategoria > 0))) {
      _categoria = null;
    }
    final produtos = [
      for (final p in store.produtos)
        if (_categoria == null || p.categoria.trim() == _categoria) p
    ];
    final emLista = store.produtosEmLista;

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
          store.mudarModoProdutos(lista: lista);
        },
        icon: Icon(icone),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Produtos')),
      floatingActionButton: store.produtos.isEmpty
          ? null
          : SizedBox(
              width: 190,
              child: BotaoPrincipal(texto: 'Novo produto', icone: Icons.add, onPressed: _abrir),
            ),
      body: store.produtos.isEmpty
          ? Center(
              child: Vazio(
                icone: Icons.cake_outlined,
                titulo: 'Seu cardápio começa aqui',
                texto: 'Cadastre um produto com a receita. O app calcula quanto custa '
                    'cada unidade e sugere o preço.',
                acao: 'Usar uma receita pronta',
                onAcao: _abrirProntas,
                acaoSecundaria: 'Cadastrar do zero',
                onAcaoSecundaria: _abrir,
              ),
            )
          : ListView(
              // Espaço no fim para o botão "Novo produto" não cobrir o último.
              padding: const EdgeInsets.fromLTRB(Espaco.borda, 0, Espaco.borda, 96),
              children: [
                EntradaSuave(
                  child: _Destaque(calculos: [for (final p in store.produtos) store.calcular(p)]),
                ),
                const SizedBox(height: Espaco.xl),
                EntradaSuave(ordem: 1, child: _AtalhoProntas(onTap: _abrirProntas)),
                if (categorias.isNotEmpty) ...[
                  const SizedBox(height: Espaco.l),
                  EntradaSuave(
                    ordem: 2,
                    child: _FiltroCategorias(
                      opcoes: [
                        (null, 'Todos', store.produtos.length),
                        for (final cat in categorias)
                          (
                            cat,
                            cat,
                            store.produtos.where((p) => p.categoria.trim() == cat).length,
                          ),
                        if (semCategoria > 0) (_semCategoria, 'Outros', semCategoria),
                      ],
                      escolhida: _categoria,
                      onChanged: (cat) => setState(() => _categoria = cat),
                    ),
                  ),
                ],
                const SizedBox(height: Espaco.s),
                EntradaSuave(
                  ordem: 2,
                  child: Row(children: [
                    Expanded(child: Text('Toque no produto para editar', style: t.apoio())),
                    alternar(Icons.grid_view_rounded, 'Ver em grade', false),
                    alternar(Icons.view_list_rounded, 'Ver em lista', true),
                  ]),
                ),
                const SizedBox(height: Espaco.s),
                EntradaSuave(
                  ordem: 3,
                  child: AnimatedSwitcher(
                    duration: Movimento.medio,
                    // A foto da que está saindo não pode disputar a animação de
                    // abrir o produto com a que está entrando.
                    transitionBuilder: (filho, anim) => FadeTransition(
                      opacity: anim,
                      child: HeroMode(
                        enabled: filho.key == ValueKey('$emLista $_categoria'),
                        child: filho,
                      ),
                    ),
                    child: emLista
                        ? GrupoLista(
                            key: ValueKey('$emLista $_categoria'),
                            recuoDivisoria: 82,
                            children: [
                              for (final p in produtos)
                                _LinhaProduto(p: p, c: store.calcular(p), onTap: () => _abrir(p)),
                            ],
                          )
                        : GridView.count(
                            key: ValueKey('$emLista $_categoria'),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            crossAxisCount: 2,
                            mainAxisSpacing: Espaco.m,
                            crossAxisSpacing: Espaco.m,
                            childAspectRatio: 0.68,
                            children: [
                              for (final p in produtos)
                                _CartaoProduto(p: p, c: store.calcular(p), onTap: () => _abrir(p)),
                            ],
                          ),
                  ),
                ),
              ],
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

/// Botões para filtrar por categoria, com quantos produtos tem em cada uma.
class _FiltroCategorias extends StatelessWidget {
  final List<(String?, String, int)> opcoes;
  final String? escolhida;
  final ValueChanged<String?> onChanged;
  const _FiltroCategorias({required this.opcoes, required this.escolhida, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: opcoes.length,
        separatorBuilder: (_, __) => const SizedBox(width: Espaco.s),
        itemBuilder: (context, i) {
          final (valor, nome, quantos) = opcoes[i];
          final ativo = valor == escolhida;
          return Material(
            key: ValueKey('categoria $nome'),
            color: ativo ? c.acao : c.superficie,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Raio.pequeno),
              side: BorderSide(color: ativo ? c.acao : c.linha),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(Raio.pequeno),
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(valor);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Espaco.m),
                child: Center(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: nome),
                      TextSpan(
                        text: '  $quantos',
                        style: TextStyle(
                            color: ativo ? c.sobreAcao.withValues(alpha: 0.75) : c.tintaSuave),
                      ),
                    ]),
                    style: t
                        .corpo(peso: FontWeight.w600, color: ativo ? c.sobreAcao : c.tinta)
                        .copyWith(fontSize: 14),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Preço, lucro e custo de uma unidade. Sem preço definido, mostra o sugerido.
({String preco, String? lucro, String custo, Color corLucro, bool sugerido}) _valores(
    BuildContext context, Calculo c) {
  final sugerido = c.precoVenda == null;
  return (
    preco: reais(c.precoVenda ?? c.precoSugerido),
    lucro: c.lucroUnitario == null ? null : reais(c.lucroUnitario!),
    custo: reais(c.custoUnitario),
    corLucro: corStatus(context, c.status),
    sugerido: sugerido,
  );
}

/// Produto em cartão: foto grande, nome, preço e, embaixo, lucro e custo de
/// cada unidade.
class _CartaoProduto extends StatelessWidget {
  final Produto p;
  final Calculo c;
  final VoidCallback onTap;
  const _CartaoProduto({required this.p, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final t = context.tipos;
    final v = _valores(context, c);
    final pequeno = t.apoio().copyWith(fontSize: 12);
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
              child: Hero(
                tag: 'foto-${p.id}',
                child: LayoutBuilder(
                  builder: (_, caixa) =>
                      FotoProduto(p.fotoBase64, tamanho: caixa.maxWidth, raio: 0),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Espaco.m, Espaco.s, Espaco.m, Espaco.m),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.corpo(peso: FontWeight.w600).copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(v.preco,
                    style: t.valor(
                        size: 16,
                        peso: FontWeight.w700,
                        color: v.sugerido ? cores.tintaSuave : cores.tinta)),
                const SizedBox(height: 2),
                Text(v.lucro == null ? 'preço sugerido' : 'lucro ${v.lucro}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: pequeno.copyWith(
                        color: v.lucro == null ? null : v.corLucro, fontWeight: FontWeight.w600)),
                Text('custo ${v.custo}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: pequeno),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Produto em linha: foto, nome e categoria; à direita, preço, lucro e custo.
class _LinhaProduto extends StatelessWidget {
  final Produto p;
  final Calculo c;
  final VoidCallback onTap;
  const _LinhaProduto({required this.p, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final t = context.tipos;
    final v = _valores(context, c);
    final pequeno = t.apoio().copyWith(fontSize: 12);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Espaco.l, vertical: Espaco.m),
        child: Row(children: [
          Hero(tag: 'foto-${p.id}', child: FotoProduto(p.fotoBase64, tamanho: 56)),
          const SizedBox(width: Espaco.m),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.corpo(peso: FontWeight.w600)),
              Text(p.categoria.trim().isEmpty ? 'Sem categoria' : p.categoria.trim(),
                  style: pequeno),
            ]),
          ),
          const SizedBox(width: Espaco.s),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(v.preco,
                style: t.valor(
                    size: 16,
                    peso: FontWeight.w700,
                    color: v.sugerido ? cores.tintaSuave : cores.tinta)),
            Text(v.lucro == null ? 'preço sugerido' : 'lucro ${v.lucro}',
                style: pequeno.copyWith(
                    color: v.lucro == null ? null : v.corLucro, fontWeight: FontWeight.w600)),
            Text('custo ${v.custo}', style: pequeno),
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
