import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

final _diaSemana = DateFormat("EEE, d 'de' MMM", 'pt_BR');
final _hora = DateFormat('HH:mm', 'pt_BR');

DateTime _soDia(DateTime d) => DateTime(d.year, d.month, d.day);

/// "Hoje", "Amanhã" ou "sex, 18 de out".
String _quando(DateTime d) {
  final dias = _soDia(d).difference(_soDia(DateTime.now())).inDays;
  final hora = d.hour == 0 && d.minute == 0 ? '' : ' · ${_hora.format(d)}';
  final dia = switch (dias) {
    0 => 'Hoje',
    1 => 'Amanhã',
    -1 => 'Ontem',
    _ => _diaSemana.format(d).replaceAll('.', ''),
  };
  return '$dia$hora';
}

String _resumoItens(Encomenda e) =>
    e.itens.map((i) => '${i.qtd} ${i.produtoNome.toLowerCase()}').join(', ');

/// As encomendas em aberto, por data de entrega (atrasadas primeiro), e as
/// últimas entregues. Fica dentro da aba Vendas.
class ListaEncomendas extends StatelessWidget {
  final Store store;
  const ListaEncomendas({super.key, required this.store});

  void _nova(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => EncomendaForm(store: store)));

  @override
  Widget build(BuildContext context) {
    final t = context.tipos;
    final c = context.cores;
    final hoje = _soDia(DateTime.now());
    final abertas = store.encomendas.where((e) => e.status == StatusEncomenda.aberta).toList()
      ..sort((a, b) => a.entrega.compareTo(b.entrega));
    final entregues = store.encomendas.where((e) => e.status == StatusEncomenda.entregue).toList()
      ..sort((a, b) => b.entrega.compareTo(a.entrega));

    final grupos = <String, List<Encomenda>>{};
    for (final e in abertas) {
      final dias = _soDia(e.entrega).difference(hoje).inDays;
      final nome = dias < 0
          ? 'Atrasadas'
          : dias == 0
              ? 'Hoje'
              : dias == 1
                  ? 'Amanhã'
                  : dias < 7
                      ? 'Nos próximos dias'
                      : 'Mais para frente';
      (grupos[nome] ??= []).add(e);
    }

    final aReceber = abertas.fold(0, (s, e) => s + e.faltaCentavos);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      BotaoPrincipal(texto: 'Nova encomenda', icone: Icons.add, onPressed: () => _nova(context)),
      if (abertas.isEmpty)
        const Vazio(
          icone: Icons.event_note_outlined,
          titulo: 'Nenhuma encomenda',
          texto: 'Anote aqui os pedidos com data marcada: bolo de aniversário, '
              'cento de docinhos… Quando entregar, vira venda.',
        )
      else ...[
        const SizedBox(height: Espaco.l),
        Text(
          '${abertas.length} ${abertas.length == 1 ? 'encomenda' : 'encomendas'} · '
          '${reais(aReceber)} a receber',
          style: t.apoio(),
        ),
        for (final g in grupos.entries) ...[
          const SizedBox(height: Espaco.l),
          Rotulo(g.key, cor: g.key == 'Atrasadas' ? c.negativo : null),
          const SizedBox(height: Espaco.s),
          for (final e in g.value) ...[
            _CartaoEncomenda(store: store, e: e, atrasada: g.key == 'Atrasadas'),
            const SizedBox(height: Espaco.s),
          ],
        ],
      ],
      if (entregues.isNotEmpty) ...[
        const SizedBox(height: Espaco.xl),
        const Rotulo('Entregues'),
        const SizedBox(height: Espaco.s),
        for (final e in entregues.take(5)) ...[
          _CartaoEncomenda(store: store, e: e, atrasada: false),
          const SizedBox(height: Espaco.s),
        ],
      ],
    ]);
  }
}

class _CartaoEncomenda extends StatelessWidget {
  final Store store;
  final Encomenda e;
  final bool atrasada;
  const _CartaoEncomenda({required this.store, required this.e, required this.atrasada});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final entregue = e.status == StatusEncomenda.entregue;
    return Pressionavel(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _abrirDetalhes(context, store, e),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                width: 4,
                color: entregue ? c.positivo : (atrasada ? c.negativo : c.acao),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Espaco.l),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(e.cliente.isEmpty ? 'Sem nome' : e.cliente,
                            style: t.corpo(peso: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(reais(e.totalCentavos), style: t.valor(peso: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 2),
                    Text(_resumoItens(e),
                        style: t.apoio(), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: Espaco.s),
                    Row(children: [
                      Icon(entregue ? Icons.check_circle_outline : Icons.schedule,
                          size: 15, color: atrasada ? c.negativo : c.tintaSuave),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entregue ? 'Entregue' : _quando(e.entrega),
                          style: t
                              .apoio(color: atrasada ? c.negativo : null)
                              .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (!entregue && e.sinalCentavos > 0)
                        Text('falta ${reais(e.faltaCentavos)}',
                            style: t.apoio(color: c.atencao).copyWith(fontSize: 12)),
                    ]),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

Future<void> _abrirDetalhes(BuildContext context, Store store, Encomenda e) async {
  final c = context.cores;
  final t = context.tipos;
  final aberta = e.status == StatusEncomenda.aberta;
  final escolha = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Espaco.borda, 0, Espaco.borda, Espaco.l),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(e.cliente.isEmpty ? 'Encomenda' : e.cliente, style: t.secao()),
              Text(
                [_quando(e.entrega), if (e.telefone != null) e.telefone!].join(' · '),
                style: t.apoio(),
              ),
              const SizedBox(height: Espaco.l),
              for (final i in e.itens)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Expanded(child: Text('${i.qtd}× ${i.produtoNome}', style: t.corpo())),
                    Text(reais(i.totalCentavos), style: t.valor()),
                  ]),
                ),
              const Divider(height: Espaco.xl),
              LinhaConta('Total', e.totalCentavos.toDouble(), forte: true),
              if (e.sinalCentavos > 0) ...[
                LinhaConta('Sinal pago', e.sinalCentavos.toDouble(), menos: true),
                LinhaConta('Falta receber', e.faltaCentavos.toDouble(), forte: true),
              ],
              if (e.obs != null) ...[
                const SizedBox(height: Espaco.m),
                Text(e.obs!, style: t.apoio()),
              ],
              const SizedBox(height: Espaco.xl),
              if (aberta) ...[
                BotaoPrincipal(
                  texto: 'Marcar como entregue',
                  icone: Icons.check,
                  onPressed: () => Navigator.pop(ctx, 'entregar'),
                ),
                const SizedBox(height: Espaco.s),
                OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, 'editar'), child: const Text('Editar')),
              ],
              TextButton(
                style: TextButton.styleFrom(foregroundColor: c.negativo),
                onPressed: () => Navigator.pop(ctx, 'apagar'),
                child: Text(aberta ? 'Cancelar encomenda' : 'Apagar do histórico'),
              ),
            ]),
      ),
    ),
  );
  if (!context.mounted || escolha == null) return;
  switch (escolha) {
    case 'editar':
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => EncomendaForm(store: store, original: e)));
    case 'entregar':
      final pagamento = await _escolherPagamento(context, store, e);
      if (pagamento == null) return;
      await store.entregarEncomenda(e, pagamento);
      HapticFeedback.mediumImpact();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Entregue! ${reais(e.totalCentavos)} entrou nas vendas de hoje.')));
      }
    case 'apagar':
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(aberta ? 'Cancelar a encomenda?' : 'Apagar do histórico?'),
          content: Text(aberta
              ? 'Ela sai da lista. Se já recebeu sinal, lembre de devolver ou combinar.'
              : 'As vendas que ela gerou continuam no relatório.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: ctx.cores.negativo),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(aberta ? 'Cancelar encomenda' : 'Apagar'),
            ),
          ],
        ),
      );
      if (ok == true) await store.removerEncomenda(e);
  }
}

/// Como recebeu o restante: a taxa da maquininha entra no lucro.
Future<Pagamento?> _escolherPagamento(BuildContext context, Store store, Encomenda e) =>
    showModalBottomSheet<Pagamento>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Espaco.borda, 0, Espaco.borda, Espaco.s),
            child: Text('Como ${e.cliente.isEmpty ? 'a pessoa' : e.cliente} pagou?',
                style: ctx.tipos.secao()),
          ),
          for (final p in Pagamento.values)
            ListTile(
              title: Text(p.label),
              trailing: store.ajustes.taxa(p) > 0
                  ? Text('taxa ${fmtNum(store.ajustes.taxa(p) * 100)}%', style: ctx.tipos.apoio())
                  : null,
              onTap: () => Navigator.pop(ctx, p),
            ),
        ]),
      ),
    );

/// Criar ou editar uma encomenda.
class EncomendaForm extends StatefulWidget {
  final Store store;
  final Encomenda? original;
  const EncomendaForm({super.key, required this.store, this.original});

  @override
  State<EncomendaForm> createState() => _EncomendaFormState();
}

class _EncomendaFormState extends State<EncomendaForm> {
  late final _cliente = TextEditingController(text: widget.original?.cliente ?? '');
  late final _telefone = TextEditingController(text: widget.original?.telefone ?? '');
  late final _obs = TextEditingController(text: widget.original?.obs ?? '');
  late final _sinal = TextEditingController(
      text: (widget.original?.sinalCentavos ?? 0) == 0
          ? ''
          : (widget.original!.sinalCentavos / 100).toStringAsFixed(2).replaceAll('.', ','));
  late DateTime _dia = widget.original == null
      ? _soDia(DateTime.now().add(const Duration(days: 1)))
      : _soDia(widget.original!.entrega);
  late TimeOfDay? _horario = widget.original == null ||
          (widget.original!.entrega.hour == 0 && widget.original!.entrega.minute == 0)
      ? null
      : TimeOfDay.fromDateTime(widget.original!.entrega);
  late final List<ItemEncomenda> _itens = [
    for (final i in widget.original?.itens ?? const <ItemEncomenda>[])
      ItemEncomenda(
          produtoId: i.produtoId,
          produtoNome: i.produtoNome,
          qtd: i.qtd,
          precoUnitCentavos: i.precoUnitCentavos),
  ];

  Store get store => widget.store;

  @override
  void dispose() {
    _cliente.dispose();
    _telefone.dispose();
    _obs.dispose();
    _sinal.dispose();
    super.dispose();
  }

  int get _total => _itens.fold(0, (s, i) => s + i.totalCentavos);

  Future<void> _adicionarProduto() async {
    if (store.produtos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastre os produtos na aba Produtos primeiro.')));
      return;
    }
    final p = await showModalBottomSheet<Produto>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, rolagem) => ListView(controller: rolagem, children: [
          for (final p in store.produtos)
            ListTile(
              leading: FotoProduto(p.fotoBase64, tamanho: 40),
              title: Text(p.nome),
              trailing: Text(reais(_precoDe(p)), style: ctx.tipos.valor()),
              onTap: () => Navigator.pop(ctx, p),
            ),
        ]),
      ),
    );
    if (p == null) return;
    setState(() {
      final ja = _itens.where((i) => i.produtoId == p.id).firstOrNull;
      if (ja != null) {
        ja.qtd++;
      } else {
        _itens.add(ItemEncomenda(
            produtoId: p.id, produtoNome: p.nome, qtd: 1, precoUnitCentavos: _precoDe(p)));
      }
    });
  }

  int _precoDe(Produto p) => p.precoVendaCentavos ?? store.calcular(p).precoSugerido.round();

  Future<void> _escolherDia() async {
    final hoje = _soDia(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _dia.isBefore(hoje) ? hoje : _dia,
      firstDate: hoje.subtract(const Duration(days: 30)),
      lastDate: hoje.add(const Duration(days: 365 * 2)),
      helpText: 'Dia da entrega',
    );
    if (d != null) setState(() => _dia = d);
  }

  Future<void> _escolherHora() async {
    final h = await showTimePicker(
      context: context,
      initialTime: _horario ?? const TimeOfDay(hour: 14, minute: 0),
      helpText: 'Horário da entrega',
    );
    if (h != null) setState(() => _horario = h);
  }

  Future<void> _salvar() async {
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Adicione pelo menos um produto.')));
      return;
    }
    final entrega =
        DateTime(_dia.year, _dia.month, _dia.day, _horario?.hour ?? 0, _horario?.minute ?? 0);
    final telefone = _telefone.text.trim();
    final obs = _obs.text.trim();
    await store.salvarEncomenda(Encomenda(
      id: widget.original?.id,
      cliente: _cliente.text.trim(),
      telefone: telefone.isEmpty ? null : telefone,
      entrega: entrega,
      itens: _itens,
      sinalCentavos: (parseCentavos(_sinal.text) ?? 0).clamp(0, _total),
      obs: obs.isEmpty ? null : obs,
    ));
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final clientes = store.clientesRecentes();

    Widget campoData(IconData icone, String texto, VoidCallback onTap) => Expanded(
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icone, size: 18),
            label: Text(texto, maxLines: 1, overflow: TextOverflow.ellipsis),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(widget.original == null ? 'Nova encomenda' : 'Editar encomenda')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Espaco.borda, Espaco.s, Espaco.borda, Espaco.secao),
        children: [
          TextField(
            controller: _cliente,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Cliente'),
          ),
          if (clientes.isNotEmpty && widget.original == null) ...[
            const SizedBox(height: Espaco.s),
            Wrap(spacing: Espaco.s, runSpacing: Espaco.xs, children: [
              for (final n in clientes)
                ActionChip(label: Text(n), onPressed: () => setState(() => _cliente.text = n)),
            ]),
          ],
          const SizedBox(height: Espaco.m),
          TextField(
            controller: _telefone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Telefone (opcional)'),
          ),
          const SizedBox(height: Espaco.xl),
          const Rotulo('Entrega'),
          const SizedBox(height: Espaco.s),
          Row(children: [
            campoData(Icons.event_outlined, _quando(_dia), _escolherDia),
            const SizedBox(width: Espaco.s),
            campoData(Icons.schedule, _horario == null ? 'Horário' : _horario!.format(context),
                _escolherHora),
          ]),
          const SizedBox(height: Espaco.xl),
          Row(children: [
            const Expanded(child: Rotulo('Produtos')),
            TextButton.icon(
              onPressed: _adicionarProduto,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar'),
            ),
          ]),
          if (_itens.isEmpty)
            Card(
              child: InkWell(
                onTap: _adicionarProduto,
                child: Padding(
                  padding: const EdgeInsets.all(Espaco.xl),
                  child: Text('Toque para escolher o que foi encomendado.',
                      textAlign: TextAlign.center, style: t.apoio()),
                ),
              ),
            )
          else
            GrupoLista(children: [
              for (final i in _itens)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.m, Espaco.s, Espaco.m),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(i.produtoNome, style: t.corpo(peso: FontWeight.w600)),
                        Text('${reais(i.precoUnitCentavos)} cada · ${reais(i.totalCentavos)}',
                            style: t.apoio().copyWith(fontSize: 12)),
                      ]),
                    ),
                    IconButton(
                      tooltip: 'Menos',
                      onPressed: () => setState(() {
                        if (i.qtd > 1) {
                          i.qtd--;
                        } else {
                          _itens.remove(i);
                        }
                      }),
                      icon: Icon(i.qtd > 1 ? Icons.remove : Icons.delete_outline,
                          color: i.qtd > 1 ? null : c.negativo),
                    ),
                    SizedBox(
                      width: 32,
                      child:
                          Text('${i.qtd}', textAlign: TextAlign.center, style: t.valor(size: 17)),
                    ),
                    IconButton(
                      tooltip: 'Mais',
                      onPressed: () => setState(() => i.qtd++),
                      icon: const Icon(Icons.add),
                    ),
                  ]),
                ),
            ]),
          const SizedBox(height: Espaco.m),
          Row(children: [
            Expanded(child: Text('Total', style: t.corpo(peso: FontWeight.w700))),
            Text(reais(_total), style: t.valor(size: 18, peso: FontWeight.w700)),
          ]),
          const SizedBox(height: Espaco.xl),
          TextField(
            controller: _sinal,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(labelText: 'Sinal já pago (opcional)', prefixText: 'R\$ '),
            onChanged: (_) => setState(() {}),
          ),
          if ((parseCentavos(_sinal.text) ?? 0) > 0 && _total > 0) ...[
            const SizedBox(height: Espaco.xs),
            Text(
                'Falta receber ${reais((_total - (parseCentavos(_sinal.text) ?? 0)).clamp(0, _total))}',
                style: t.apoio(color: c.atencao)),
          ],
          const SizedBox(height: Espaco.m),
          TextField(
            controller: _obs,
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Observações (opcional)', hintText: 'Sabor, tema, endereço…'),
          ),
          const SizedBox(height: Espaco.xl),
          BotaoPrincipal(texto: 'Salvar encomenda', icone: Icons.check, onPressed: _salvar),
        ],
      ),
    );
  }
}
