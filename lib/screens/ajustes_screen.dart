import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

String _fmt(int c) => c == 0 ? '' : (c / 100).toStringAsFixed(2).replaceAll('.', ',');

/// Nome e logo da loja em uso.
class LojaScreen extends StatefulWidget {
  final Store store;
  const LojaScreen({super.key, required this.store});

  @override
  State<LojaScreen> createState() => _LojaScreenState();
}

class _LojaScreenState extends State<LojaScreen> {
  late final _nome = TextEditingController(text: widget.store.lojaAtual.nome);
  late String? _foto = widget.store.lojaAtual.fotoBase64;

  Future<void> _trocarFoto() async {
    final foto = await pedirFoto(context, temFoto: _foto != null);
    if (foto == null || !mounted) return;
    setState(() => _foto = foto.isEmpty ? null : foto);
  }

  Future<void> _salvar() async {
    final nome = _nome.text.trim();
    await widget.store.editarLoja(nome: nome.isEmpty ? 'Minha Confeitaria' : nome, foto: _foto);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final foto = _foto;
    return Scaffold(
      appBar: AppBar(title: const Text('Loja')),
      body: Column(children: [
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(Espaco.borda, Espaco.l, Espaco.borda, Espaco.secao),
            children: [
              Center(
                child: Pressionavel(
                  child: GestureDetector(
                    onTap: _trocarFoto,
                    child: Column(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Raio.grande),
                        child: SizedBox(
                          width: 112,
                          height: 112,
                          child: foto == null
                              ? ColoredBox(
                                  color: c.realce,
                                  child: Icon(Icons.add_a_photo_outlined, color: c.acao, size: 32),
                                )
                              : Image.memory(FotoProduto.bytes(foto), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: Espaco.s),
                      Text(foto == null ? 'Pôr logo ou foto' : 'Trocar logo',
                          style: t.corpo(peso: FontWeight.w600, color: c.acao)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: Espaco.xl),
              TextField(
                controller: _nome,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome da loja'),
              ),
              const SizedBox(height: Espaco.s),
              Text('O nome e a logo aparecem na aba Mais e nas abas de lojas, no topo do app.',
                  style: t.apoio()),
            ],
          ),
        ),
        BarraInferior(
          texto: 'Salvar',
          onPressed: _salvar,
          tecladoAberto: MediaQuery.viewInsetsOf(context).bottom > 0,
        ),
      ]),
    );
  }
}

/// Salário e contas fixas do mês (gás, luz...), descontados no relatório.
class ContasScreen extends StatefulWidget {
  final Store store;
  const ContasScreen({super.key, required this.store});

  @override
  State<ContasScreen> createState() => _ContasScreenState();
}

class _ContasScreenState extends State<ContasScreen> {
  late final _a = Ajustes.fromJson(widget.store.ajustes.toJson());
  late final _salario = TextEditingController(text: _fmt(_a.salarioCentavos));
  late final List<(TextEditingController, TextEditingController)> _fixos = [
    for (final f in _a.fixos)
      (TextEditingController(text: f.nome), TextEditingController(text: _fmt(f.valorCentavos))),
  ];

  int get _totalFixos => _fixos.fold(0, (s, f) => s + (parseCentavos(f.$2.text) ?? 0));

  Future<void> _salvar() async {
    _a
      ..salarioCentavos = parseCentavos(_salario.text) ?? 0
      ..fixos = [
        for (final f in _fixos)
          if (f.$1.text.trim().isNotEmpty)
            CustoFixo(nome: f.$1.text.trim(), valorCentavos: parseCentavos(f.$2.text) ?? 0),
      ];
    await widget.store.salvarAjustes(_a);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const teclado = TextInputType.numberWithOptions(decimal: true);
    final t = context.tipos;
    return Scaffold(
      appBar: AppBar(title: const Text('Contas do mês')),
      // Botão no corpo, para subir junto com o teclado.
      body: Column(children: [
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(Espaco.borda, Espaco.s, Espaco.borda, Espaco.secao),
            children: [
              Text('Seu salário', style: t.secao()),
              const SizedBox(height: 4),
              Text('Quanto você quer tirar por mês pelo seu trabalho.', style: t.apoio()),
              const SizedBox(height: 10),
              TextField(
                controller: _salario,
                keyboardType: teclado,
                decoration: const InputDecoration(labelText: 'Salário por mês', prefixText: 'R\$ '),
              ),
              const SizedBox(height: Espaco.secao),
              Text('Contas fixas', style: t.secao()),
              const SizedBox(height: 4),
              Text('Contas que você paga mesmo sem produzir: gás, luz, água e internet.',
                  style: t.apoio()),
              const SizedBox(height: 10),
              for (final (i, f) in _fixos.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: f.$1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(labelText: 'Conta'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: f.$2,
                        keyboardType: teclado,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ '),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tirar esta conta',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _fixos.removeAt(i)),
                    ),
                  ]),
                ),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _fixos.add((TextEditingController(), TextEditingController()))),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar conta'),
              ),
              const SizedBox(height: 8),
              Text('Total: ${reais(_totalFixos)} por mês', style: t.corpo(peso: FontWeight.w600)),
            ],
          ),
        ),
        BarraInferior(
          texto: 'Salvar contas',
          onPressed: _salvar,
          tecladoAberto: MediaQuery.viewInsetsOf(context).bottom > 0,
        ),
      ]),
    );
  }
}

/// Quanto a maquininha ou o banco desconta em cada forma de pagamento.
class TaxasScreen extends StatefulWidget {
  final Store store;
  const TaxasScreen({super.key, required this.store});

  @override
  State<TaxasScreen> createState() => _TaxasScreenState();
}

class _TaxasScreenState extends State<TaxasScreen> {
  late final _a = Ajustes.fromJson(widget.store.ajustes.toJson());
  late final Map<Pagamento, TextEditingController> _taxas = {
    for (final p in Pagamento.values)
      if (p != Pagamento.dinheiro)
        p: TextEditingController(text: _a.taxa(p) == 0 ? '' : fmtNum(_a.taxa(p) * 100)),
  };

  Future<void> _salvar() async {
    _a.taxas = {
      for (final p in Pagamento.values) p: (parseNum(_taxas[p]?.text ?? '') ?? 0) / 100,
    };
    await widget.store.salvarAjustes(_a);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tipos;
    return Scaffold(
      appBar: AppBar(title: const Text('Taxas da maquininha')),
      body: Column(children: [
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(Espaco.borda, Espaco.s, Espaco.borda, Espaco.secao),
            children: [
              Text(
                  'Quanto a maquininha ou o banco desconta em cada venda. '
                  'O app tira isso do lucro sozinho. Dinheiro não tem taxa.',
                  style: t.apoio()),
              const SizedBox(height: Espaco.l),
              for (final e in _taxas.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: Espaco.m),
                  child: TextField(
                    controller: e.value,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        InputDecoration(labelText: e.key.label, suffixText: '%', hintText: '0'),
                  ),
                ),
            ],
          ),
        ),
        BarraInferior(
          texto: 'Salvar taxas',
          onPressed: _salvar,
          tecladoAberto: MediaQuery.viewInsetsOf(context).bottom > 0,
        ),
      ]),
    );
  }
}
