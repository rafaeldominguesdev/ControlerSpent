import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

/// Aparência, nome do negócio, custos fixos e salário (usados no "lucro real").
class AjustesScreen extends StatefulWidget {
  final Store store;
  const AjustesScreen({super.key, required this.store});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  late final _a = Ajustes.fromJson(widget.store.ajustes.toJson());
  late final _nome = TextEditingController(text: _a.nomeNegocio);
  late final _salario = TextEditingController(text: _fmt(_a.salarioCentavos));
  late final List<(TextEditingController, TextEditingController)> _fixos = [
    for (final f in _a.fixos)
      (TextEditingController(text: f.nome), TextEditingController(text: _fmt(f.valorCentavos))),
  ];

  late final Map<Pagamento, TextEditingController> _taxas = {
    for (final p in Pagamento.values)
      if (p != Pagamento.dinheiro)
        p: TextEditingController(text: _a.taxa(p) == 0 ? '' : fmtNum(_a.taxa(p) * 100)),
  };

  static String _fmt(int c) => c == 0 ? '' : (c / 100).toStringAsFixed(2).replaceAll('.', ',');

  int get _totalFixos => _fixos.fold(0, (s, f) => s + (parseCentavos(f.$2.text) ?? 0));

  Future<void> _salvar() async {
    await widget.store.salvarAjustes(Ajustes(
      nomeNegocio: _nome.text.trim().isEmpty ? 'Minha Confeitaria' : _nome.text.trim(),
      salarioCentavos: parseCentavos(_salario.text) ?? 0,
      fixos: [
        for (final f in _fixos)
          if (f.$1.text.trim().isNotEmpty)
            CustoFixo(nome: f.$1.text.trim(), valorCentavos: parseCentavos(f.$2.text) ?? 0),
      ],
      taxas: {
        for (final p in Pagamento.values) p: (parseNum(_taxas[p]?.text ?? '') ?? 0) / 100,
      },
      tema: widget.store.ajustes.tema, // o tema já é salvo na hora em que muda
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const teclado = TextInputType.numberWithOptions(decimal: true);
    final titulo = Theme.of(context).textTheme.titleLarge;
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      // Botão no corpo, para subir junto com o teclado.
      body: Column(children: [
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(Espaco.borda, Espaco.s, Espaco.borda, Espaco.secao),
            children: [
              Text('Aparência', style: titulo),
              const SizedBox(height: Espaco.s),
              ValueListenableBuilder(
                valueListenable: widget.store.tema,
                builder: (context, tema, _) => SeletorOpcoes<TemaApp>(
                  opcoes: [for (final t in TemaApp.values) (t, t.label)],
                  valor: tema,
                  onChanged: widget.store.mudarTema,
                ),
              ),
              const SizedBox(height: Espaco.s),
              Text('Automático segue o modo claro ou escuro do celular.',
                  style: context.tipos.apoio()),
              const SizedBox(height: Espaco.secao),
              TextField(
                controller: _nome,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome da confeitaria'),
              ),
              const SizedBox(height: Espaco.secao),
              Text('Seu salário', style: titulo),
              const SizedBox(height: 4),
              Text('Quanto você quer tirar por mês pelo seu trabalho.',
                  style: context.tipos.apoio()),
              const SizedBox(height: 10),
              TextField(
                controller: _salario,
                keyboardType: teclado,
                decoration: const InputDecoration(labelText: 'Salário por mês', prefixText: 'R\$ '),
              ),
              const SizedBox(height: Espaco.secao),
              Text('Custos fixos do mês', style: titulo),
              const SizedBox(height: 4),
              Text('Contas que você paga mesmo sem produzir: gás, luz, água e internet.',
                  style: context.tipos.apoio()),
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
              Text('Total: ${reais(_totalFixos)} por mês',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: Espaco.secao),
              Text('Taxas da maquininha', style: titulo),
              const SizedBox(height: 4),
              Text(
                  'Quanto a maquininha ou o banco desconta em cada venda. '
                  'O app tira isso do lucro sozinho.',
                  style: context.tipos.apoio()),
              const SizedBox(height: 10),
              Row(children: [
                for (final (i, e) in _taxas.entries.indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: e.value,
                      keyboardType: teclado,
                      decoration:
                          InputDecoration(labelText: e.key.label, suffixText: '%', hintText: '0'),
                    ),
                  ),
                ],
              ]),
            ],
          ),
        ),
        BarraInferior(
          texto: 'Salvar ajustes',
          onPressed: _salvar,
          tecladoAberto: MediaQuery.viewInsetsOf(context).bottom > 0,
        ),
      ]),
    );
  }
}
