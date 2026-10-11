import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ajustes_screen.dart';

class InsumosScreen extends StatelessWidget {
  final Store store;
  const InsumosScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) => _tela(context),
      );

  Widget _tela(BuildContext context) {
    final ingredientes = store.insumos.where((i) => !i.ehEmbalagem).toList();
    final embalagens = store.insumos.where((i) => i.ehEmbalagem).toList();
    return Scaffold(
      appBar:
          AppBar(title: const Text('Ingredientes'), actions: [BotaoConfiguracoes(store: store)]),
      floatingActionButton: store.insumos.isEmpty
          ? null
          : SizedBox(
              width: 190,
              child: BotaoPrincipal(
                  texto: 'Adicionar',
                  icone: Icons.add,
                  onPressed: () => editarInsumo(context, store)),
            ),
      body: store.insumos.isEmpty
          ? Center(
              child: Vazio(
                icone: Icons.shopping_basket_outlined,
                titulo: 'O que você compra',
                texto: 'Cadastre como vem na embalagem, por exemplo: leite condensado, '
                    '395 g, R\$ 7,90. O app calcula o custo de cada grama.',
                acao: 'Cadastrar ingrediente',
                onAcao: () => editarInsumo(context, store),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(Espaco.borda, 0, Espaco.borda, Espaco.secao),
              children: [
                if (ingredientes.isNotEmpty)
                  EntradaSuave(child: _Secao('Ingredientes', ingredientes, store)),
                if (embalagens.isNotEmpty)
                  EntradaSuave(ordem: 1, child: _Secao('Embalagens', embalagens, store)),
              ],
            ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String titulo;
  final List<Insumo> itens;
  final Store store;
  const _Secao(this.titulo, this.itens, this.store);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Espaco.l),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Espaco.xs, 0, Espaco.xs, Espaco.s),
            child: Rotulo(titulo),
          ),
          GrupoLista(children: [
            for (final ins in itens) _LinhaInsumo(ins: ins, store: store),
          ]),
        ]),
      );
}

class _LinhaInsumo extends StatelessWidget {
  final Insumo ins;
  final Store store;
  const _LinhaInsumo({required this.ins, required this.store});

  @override
  Widget build(BuildContext context) {
    // Grama sozinha dá centavos quebrados; a cada 100 g é mais fácil de comparar.
    final porUnidade = ins.unidade == Unidade.un;
    final custo = porUnidade ? ins.custoPorUnidade : ins.custoPorUnidade * 100;
    final legenda = porUnidade ? 'cada' : 'a cada 100 ${ins.unidade.label}';
    return InkWell(
      onTap: () => editarInsumo(context, store, ins),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Espaco.l, vertical: Espaco.m),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ins.nome, style: context.tipos.corpo(peso: FontWeight.w600)),
              Text(
                  '${fmtQtd(ins.qtdEmbalagem)} ${ins.unidade.label} por ${reais(ins.precoCentavos)}',
                  style: context.tipos.apoio().copyWith(fontSize: 12)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(reais(custo), style: context.tipos.valor()),
            Text(legenda, style: context.tipos.apoio().copyWith(fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}

/// Abre o formulário de cadastro/edição. Devolve o insumo salvo, se houver.
Future<Insumo?> editarInsumo(BuildContext context, Store store, [Insumo? atual]) {
  return showModalBottomSheet<Insumo>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _InsumoForm(store: store, atual: atual),
  );
}

class _InsumoForm extends StatefulWidget {
  final Store store;
  final Insumo? atual;
  const _InsumoForm({required this.store, this.atual});

  @override
  State<_InsumoForm> createState() => _InsumoFormState();
}

class _InsumoFormState extends State<_InsumoForm> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.atual?.nome);
  late final _qtd =
      TextEditingController(text: widget.atual == null ? '' : fmtNum(widget.atual!.qtdEmbalagem));
  late final _preco = TextEditingController(
      text: widget.atual == null
          ? ''
          : (widget.atual!.precoCentavos / 100).toStringAsFixed(2).replaceAll('.', ','));
  late Unidade _unidade = widget.atual?.unidade ?? Unidade.g;
  late bool _embalagem = widget.atual?.ehEmbalagem ?? false;

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    final ins = Insumo(
      id: widget.atual?.id,
      nome: _nome.text.trim(),
      unidade: _unidade,
      qtdEmbalagem: parseNum(_qtd.text)!,
      precoCentavos: parseCentavos(_preco.text)!,
      ehEmbalagem: _embalagem,
    );
    await widget.store.salvarInsumo(ins);
    if (mounted) Navigator.pop(context, ins);
  }

  Future<void> _remover() async {
    final ins = widget.atual!;
    if (widget.store.insumoEmUso(ins)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esse item está em uma receita. Tire da receita antes.')));
      return;
    }
    await widget.store.removerInsumo(ins);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const teclado = TextInputType.numberWithOptions(decimal: true);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.atual == null ? 'Novo item' : 'Editar item',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nome,
                  autofocus: widget.atual == null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration:
                      const InputDecoration(labelText: 'Nome', hintText: 'Leite condensado'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Coloque um nome' : null,
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Ingrediente')),
                    ButtonSegment(value: true, label: Text('Embalagem')),
                  ],
                  selected: {_embalagem},
                  onSelectionChanged: (s) => setState(() {
                    _embalagem = s.first;
                    if (_embalagem) _unidade = Unidade.un;
                  }),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtd,
                      keyboardType: teclado,
                      decoration:
                          const InputDecoration(labelText: 'Qtd do pacote', hintText: '395'),
                      validator: (v) =>
                          (parseNum(v ?? '') ?? 0) > 0 ? null : 'Informe a quantidade',
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<Unidade>(
                    value: _unidade,
                    items: Unidade.values
                        .map((u) => DropdownMenuItem(value: u, child: Text(u.label)))
                        .toList(),
                    onChanged: (u) => setState(() => _unidade = u!),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _preco,
                  keyboardType: teclado,
                  decoration: const InputDecoration(
                      labelText: 'Preço que pagou', prefixText: 'R\$ ', hintText: '7,50'),
                  validator: (v) => parseCentavos(v ?? '') == null ? 'Informe o preço' : null,
                ),
                const SizedBox(height: 20),
                BotaoPrincipal(texto: 'Salvar', onPressed: _salvar),
                if (widget.atual != null)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: context.cores.negativo),
                    onPressed: _remover,
                    child: const Text('Apagar item'),
                  ),
              ],
            )),
      ),
    );
  }
}
