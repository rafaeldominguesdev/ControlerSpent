import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'insumos_screen.dart';
import 'produtos_screen.dart';

/// Cadastro do produto com a receita. O cálculo atualiza enquanto ela digita.
class ProdutoForm extends StatefulWidget {
  final Store store;
  final Produto? atual;
  const ProdutoForm({super.key, required this.store, this.atual});

  @override
  State<ProdutoForm> createState() => _ProdutoFormState();
}

class _ProdutoFormState extends State<ProdutoForm> {
  final _form = GlobalKey<FormState>();
  late final Produto _p = widget.atual == null
      ? Produto(nome: '')
      : Produto.fromJson(widget.atual!.toJson()); // cópia para editar
  late final _nome = TextEditingController(text: _p.nome);
  late final _categoria = TextEditingController(text: _p.categoria);
  late final _rend = TextEditingController(text: '${_p.rendimento}');
  late final _margem = TextEditingController(text: (_p.margem * 100).toStringAsFixed(0));
  late final _preco = TextEditingController(
      text: _p.precoVendaCentavos == null
          ? ''
          : (_p.precoVendaCentavos! / 100).toStringAsFixed(2).replaceAll('.', ','));

  Store get store => widget.store;

  void _sincronizar() {
    _p.nome = _nome.text.trim();
    _p.categoria = _categoria.text.trim();
    _p.rendimento = int.tryParse(_rend.text) ?? 1;
    _p.margem = (parseNum(_margem.text) ?? 0) / 100;
    _p.precoVendaCentavos = parseCentavos(_preco.text);
    setState(() {});
  }

  Future<void> _adicionarItem() async {
    final usados = _p.itens.map((e) => e.insumoId).toSet();
    final escolhido = await showModalBottomSheet<Insumo>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => _EscolherInsumo(store: store, excluir: usados),
    );
    if (escolhido == null || !mounted) return;
    final qtd = await _pedirQtd(escolhido);
    if (qtd == null) return;
    setState(() => _p.itens.add(ItemReceita(insumoId: escolhido.id, qtd: qtd)));
  }

  Future<double?> _pedirQtd(Insumo ins, [double? atual]) {
    final c = TextEditingController(text: atual == null ? '' : fmtNum(atual));
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ins.nome),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Quanto usa na receita',
            suffixText: ins.unidade.label,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final v = parseNum(c.text);
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _escolherFoto() async {
    final foto = await pedirFoto(context, temFoto: _p.fotoBase64 != null);
    if (foto == null || !mounted) return;
    setState(() => _p.fotoBase64 = foto.isEmpty ? null : foto);
  }

  Future<void> _salvar() async {
    _sincronizar();
    if (!_form.currentState!.validate()) return;
    await store.salvarProduto(_p);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _excluir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Apagar ${_p.nome}?'),
        content: const Text('As vendas que já foram anotadas continuam no relatório.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
              style: TextButton.styleFrom(foregroundColor: context.cores.negativo),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Apagar')),
        ],
      ),
    );
    if (ok != true) return;
    await store.removerProduto(_p);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final insumos = store.insumosPorId;
    final calc = Calculo.de(_p, insumos);
    const teclado = TextInputType.numberWithOptions(decimal: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.atual == null ? 'Novo produto' : 'Editar produto'),
        actions: [
          if (widget.atual != null)
            IconButton(
                tooltip: 'Apagar produto',
                onPressed: _excluir,
                icon: const Icon(Icons.delete_outline)),
          const SizedBox(width: Espaco.s),
        ],
      ),
      // O botão de salvar fica dentro do corpo (e não no rodapé fixo) para subir
      // junto com o teclado; antes ele ficava escondido atrás do teclado numérico.
      body: Form(
        key: _form,
        onChanged: _sincronizar,
        child: Column(children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding:
                  const EdgeInsets.fromLTRB(Espaco.borda, Espaco.s, Espaco.borda, Espaco.secao),
              children: [
                _FotoGrande(
                  id: _p.id,
                  base64: _p.fotoBase64,
                  onTap: _escolherFoto,
                ),
                const SizedBox(height: Espaco.xl),
                TextFormField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Nome do produto', hintText: 'Brigadeiro gourmet'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Coloque um nome' : null,
                ),
                const SizedBox(height: Espaco.m),
                _CampoCategoria(
                  controller: _categoria,
                  sugestoes:
                      {...store.categorias, 'Bolos', 'Docinhos', 'Doces', 'Salgados'}.toList(),
                  onChanged: _sincronizar,
                ),
                const SizedBox(height: Espaco.m),
                TextFormField(
                  controller: _rend,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'A receita rende quantas unidades?',
                    suffixText: 'unidades',
                  ),
                  validator: (v) =>
                      (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Informe quantas unidades',
                ),
                const SizedBox(height: Espaco.secao),
                Text('Receita', style: context.tipos.secao()),
                const SizedBox(height: Espaco.xs),
                Text('O que vai na receita inteira, incluindo embalagens.',
                    style: context.tipos.apoio()),
                const SizedBox(height: Espaco.m),
                GrupoLista(children: [
                  for (final it in _p.itens) _linhaItem(it, insumos[it.insumoId]),
                  ListTile(
                    leading: Icon(Icons.add, color: context.cores.acao),
                    title: Text('Adicionar ingrediente',
                        style:
                            context.tipos.corpo(peso: FontWeight.w600, color: context.cores.acao)),
                    onTap: _adicionarItem,
                  ),
                ]),
                const SizedBox(height: Espaco.secao),
                Text('Preço', style: context.tipos.secao()),
                const SizedBox(height: Espaco.m),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: TextFormField(
                      controller: _margem,
                      keyboardType: teclado,
                      decoration:
                          const InputDecoration(labelText: 'Lucro desejado', suffixText: '%'),
                    ),
                  ),
                  const SizedBox(width: Espaco.m),
                  Expanded(
                    child: TextFormField(
                      controller: _preco,
                      keyboardType: teclado,
                      decoration:
                          const InputDecoration(labelText: 'Preço que cobra', prefixText: 'R\$ '),
                    ),
                  ),
                ]),
                const SizedBox(height: Espaco.l),
                _Resumo(
                  calc: calc,
                  rendimento: _p.rendimento,
                  onUsarSugerido: () {
                    _preco.text =
                        (calc.precoSugerido / 100).toStringAsFixed(2).replaceAll('.', ',');
                    _sincronizar();
                  },
                ),
              ],
            ),
          ),
          BarraInferior(
            texto: 'Salvar produto',
            onPressed: _salvar,
            tecladoAberto: MediaQuery.viewInsetsOf(context).bottom > 0,
          ),
        ]),
      ),
    );
  }

  Widget _linhaItem(ItemReceita it, Insumo? ins) {
    if (ins == null) {
      return ListTile(
        title: const Text('Item apagado'),
        subtitle: const Text('Esse ingrediente não existe mais.'),
        trailing: IconButton(
          tooltip: 'Tirar da receita',
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => _p.itens.remove(it)),
        ),
      );
    }
    return InkWell(
      onTap: () async {
        final q = await _pedirQtd(ins, it.qtd);
        if (q != null) setState(() => it.qtd = q);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.s, Espaco.xs, Espaco.s),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ins.nome, style: context.tipos.corpo(peso: FontWeight.w600)),
              Text('${fmtQtd(it.qtd)} ${ins.unidade.label}', style: context.tipos.apoio()),
            ]),
          ),
          Text(reais(ins.custoPorUnidade * it.qtd),
              style: context.tipos.valor(peso: FontWeight.w500)),
          IconButton(
            tooltip: 'Tirar da receita',
            icon: Icon(Icons.close, size: 20, color: context.cores.tintaSuave),
            onPressed: () => setState(() => _p.itens.remove(it)),
          ),
        ]),
      ),
    );
  }
}

/// Foto larga no topo; sem foto, um espaço convidando a pôr uma.
class _FotoGrande extends StatelessWidget {
  final int id;
  final String? base64;
  final VoidCallback onTap;
  const _FotoGrande({required this.id, required this.base64, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressionavel(
      escala: 0.98,
      child: Semantics(
        button: true,
        label: base64 == null ? 'Pôr uma foto' : 'Trocar a foto',
        child: GestureDetector(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 16 / 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Raio.grande),
              child: Stack(fit: StackFit.expand, children: [
                Hero(
                  tag: 'foto-$id',
                  child: AnimatedSwitcher(
                    duration: Movimento.medio,
                    // Ocupa a área toda (o padrão do AnimatedSwitcher encolhe o filho).
                    layoutBuilder: (atual, anteriores) => Stack(
                      fit: StackFit.expand,
                      children: [...anteriores, if (atual != null) atual],
                    ),
                    child: base64 == null
                        ? ColoredBox(key: const ValueKey('sem'), color: context.cores.realce)
                        : Image.memory(FotoProduto.bytes(base64!),
                            key: ValueKey(base64!.length), fit: BoxFit.cover),
                  ),
                ),
                if (base64 == null)
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_a_photo_outlined, color: context.cores.acao, size: 30),
                    const SizedBox(height: Espaco.s),
                    Text('Pôr uma foto',
                        style:
                            context.tipos.corpo(peso: FontWeight.w600, color: context.cores.acao)),
                  ])
                else
                  Positioned(
                    right: Espaco.m,
                    bottom: Espaco.m,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.cores.tinta.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(Raio.pequeno),
                      ),
                      child: Text('Trocar foto',
                          style: context.tipos
                              .apoio(color: context.cores.sobreAcao)
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  final Calculo calc;
  final int rendimento;
  final VoidCallback onUsarSugerido;
  const _Resumo({required this.calc, required this.rendimento, required this.onUsarSugerido});

  @override
  Widget build(BuildContext context) {
    final cor = corStatus(context, calc.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.s, Espaco.l, Espaco.s),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LinhaConta('Custo da receita', calc.custoReceita,
              detalhe: rendimento == 1 ? 'Rende 1 unidade' : 'Rende $rendimento unidades'),
          LinhaConta('Custo de cada unidade', calc.custoUnitario, forte: true),
          const Tracejado(),
          Row(children: [
            Expanded(child: Text('Preço sugerido', style: context.tipos.corpo())),
            Text(reais(calc.precoSugerido),
                style: context.tipos.valor(size: 18, peso: FontWeight.w700)),
          ]),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
              onPressed: onUsarSugerido,
              child: const Text('Usar este preço'),
            ),
          ),
          if (calc.precoVenda != null) ...[
            const Divider(),
            const SizedBox(height: Espaco.xs),
            LinhaConta('Lucro em cada unidade', calc.lucroUnitario!, forte: true, cor: cor),
            Padding(
              padding: const EdgeInsets.only(bottom: Espaco.s),
              child: Text(
                'Margem de ${(calc.margemReal! * 100).toStringAsFixed(0)}%. ${textoStatus(calc.status)}.',
                style: context.tipos.apoio(color: cor),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _EscolherInsumo extends StatelessWidget {
  final Store store;
  final Set<int> excluir;
  const _EscolherInsumo({required this.store, required this.excluir});

  @override
  Widget build(BuildContext context) {
    final lista = store.insumos.where((i) => !excluir.contains(i.id)).toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(children: [
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: const Text('Cadastrar novo ingrediente'),
          onTap: () async {
            final novo = await editarInsumo(context, store);
            if (novo != null && context.mounted) Navigator.pop(context, novo);
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(children: [
            for (final i in lista)
              ListTile(
                title: Text(i.nome),
                subtitle: Text(
                    '${fmtQtd(i.qtdEmbalagem)} ${i.unidade.label} por ${reais(i.precoCentavos)}'),
                onTap: () => Navigator.pop(context, i),
              ),
          ]),
        ),
      ]),
    );
  }
}

/// Categoria do produto (bolos, docinhos...): digitada ou escolhida entre as que
/// já existem. Serve para filtrar a aba Produtos.
class _CampoCategoria extends StatelessWidget {
  final TextEditingController controller;
  final List<String> sugestoes;
  final VoidCallback onChanged;
  const _CampoCategoria(
      {required this.controller, required this.sugestoes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, valor, _) {
        final atual = valor.text.trim().toLowerCase();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextFormField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Categoria (opcional)', hintText: 'Bolos, docinhos, salgados…'),
          ),
          const SizedBox(height: Espaco.s),
          Wrap(spacing: Espaco.s, runSpacing: Espaco.s, children: [
            for (final s in sugestoes)
              Pressionavel(
                child: Material(
                  color: s.toLowerCase() == atual ? c.acao : c.superficie,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Raio.pequeno),
                    side: BorderSide(color: s.toLowerCase() == atual ? c.acao : c.linha),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Raio.pequeno),
                    onTap: () {
                      controller.text = s.toLowerCase() == atual ? '' : s;
                      onChanged();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Espaco.m, vertical: 7),
                      child: Text(s,
                          style: t
                              .corpo(
                                  peso: FontWeight.w500,
                                  color: s.toLowerCase() == atual ? c.sobreAcao : c.tinta)
                              .copyWith(fontSize: 14)),
                    ),
                  ),
                ),
              ),
          ]),
        ]);
      },
    );
  }
}
