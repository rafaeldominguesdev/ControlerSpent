import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ajustes_screen.dart';

final _mesNome = DateFormat('MMMM', 'pt_BR');
final _mesCurto = DateFormat('MMM', 'pt_BR');
final _diaMes = DateFormat("d MMM", 'pt_BR');
final _semCentavos = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);

String _listaNomes(List<String> nomes) => switch (nomes.length) {
      0 => '',
      1 => nomes.first,
      _ => '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}',
    };

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
String _curto(DateTime d) => _mesCurto.format(d).replaceAll('.', '');
String _dia(DateTime d) => _diaMes.format(d).replaceAll('.', '');

/// "R$ 1.528", sem centavos (para caber na tabela e no topo).
String _reais0(double centavos) => centavos <= -50
    ? '−${_semCentavos.format(-centavos / 100)}'
    : _semCentavos.format(math.max(0.0, centavos) / 100);

DateTime _hoje() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

enum _Tipo { semana, mes, ano, outro }

/// Um intervalo [ini, fim) de dias inteiros.
typedef _Faixa = ({DateTime ini, DateTime fim});

bool _dentro(DateTime d, _Faixa f) => !d.isBefore(f.ini) && d.isBefore(f.fim);
int _dias(_Faixa f) => DateTime.utc(f.fim.year, f.fim.month, f.fim.day)
    .difference(DateTime.utc(f.ini.year, f.ini.month, f.ini.day))
    .inDays;

typedef _Numeros = ({double vendas, int pedidos, double lucro});

/// Vendas, pedidos e lucro de um mês; com [ate], só até aquele dia.
_Numeros _numeros(Store store, DateTime mes, {int? ate}) {
  var vendas = 0.0, lucro = 0.0;
  var pedidos = 0;
  for (final l in store.lancamentos) {
    if (l.data.year != mes.year || l.data.month != mes.month) continue;
    if (ate != null && l.data.day > ate) continue;
    if (l.tipo == TipoLancamento.producao) continue; // produção não entra no lucro
    vendas += l.faturamento;
    lucro += l.lucro;
    if (l.tipo == TipoLancamento.venda) pedidos++;
  }
  return (vendas: vendas, pedidos: pedidos, lucro: lucro);
}

/// O relatório do mês, no jeito de um painel de loja: vendas, pedidos e lucro
/// em destaque, comparados com o mês passado, e a tabela por produto, com as
/// contas do mês no fim.
class RelatorioScreen extends StatefulWidget {
  final Store store;
  const RelatorioScreen({super.key, required this.store});

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> with TickerProviderStateMixin {
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);
  List<DateTime> _meses = const [];
  TabController? _abas;

  @override
  void dispose() {
    _abas?.dispose();
    super.dispose();
  }

  /// Do primeiro mês com anotação (mostrando pelo menos 6 meses) até o mês atual.
  List<DateTime> _mesesDasAbas() {
    final hoje = DateTime.now();
    final atual = DateTime(hoje.year, hoje.month);
    var inicio = DateTime(hoje.year, hoje.month - 5);
    for (final l in widget.store.lancamentos) {
      final m = DateTime(l.data.year, l.data.month);
      if (m.isBefore(inicio)) inicio = m;
    }
    return [for (var m = inicio; !m.isAfter(atual); m = DateTime(m.year, m.month + 1)) m];
  }

  /// Recria as abas só quando a lista de meses muda (virou o mês ou apareceu
  /// uma anotação mais antiga).
  void _atualizarAbas() {
    final meses = _mesesDasAbas();
    if (_abas != null && meses.length == _meses.length && meses.first == _meses.first) return;
    if (!meses.contains(_mes)) _mes = meses.last;
    final antigas = _abas;
    _meses = meses;
    _abas = TabController(length: meses.length, vsync: this, initialIndex: meses.indexOf(_mes));
    // A barra de abas ainda usa as antigas até o fim deste quadro.
    if (antigas != null) WidgetsBinding.instance.addPostFrameCallback((_) => antigas.dispose());
  }

  void _abrirAjustes() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => ContasScreen(store: widget.store)));

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        _atualizarAbas();
        final t = context.tipos;
        final mes = _mes;
        final r = store.resumo(mes.year, mes.month);
        final anterior = DateTime(mes.year, mes.month - 1);
        final diasAnterior = DateUtils.getDaysInMonth(anterior.year, anterior.month);
        // No mês em andamento, compara com o mês passado até o mesmo dia.
        final ateDia = _emAndamento(mes) ? DateTime.now().day : null;

        Widget titulo(String s) => Padding(
              padding: const EdgeInsets.only(top: Espaco.xxl, bottom: Espaco.m),
              child: Text(s, style: t.secao()),
            );
        final blocos = <Widget>[
          _Topo(
            atual: _numeros(store, mes),
            antes: _numeros(store, anterior,
                ate: ateDia == null ? null : math.min(ateDia, diasAnterior)),
            mesAnterior: anterior,
            ateDia: ateDia,
          ),
          titulo('Por produto'),
          _Tabela(
            r: r,
            mes: mes,
            fotos: {for (final p in store.produtos) p.id: p.fotoBase64},
            emAndamento: ateDia != null,
            onAjustes: _abrirAjustes,
          ),
        ];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Relatório'),
            bottom: TabBar(
              controller: _abas,
              isScrollable: true,
              onTap: (i) => setState(() => _mes = _meses[i]),
              tabs: [for (final m in _meses) Tab(text: _rotuloAba(m))],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(Espaco.borda, Espaco.l, Espaco.borda, Espaco.secao),
            children: [
              for (final (i, b) in blocos.indexed) EntradaSuave(ordem: i, child: b),
            ],
          ),
        );
      },
    );
  }
}

/// Vendas, pedidos e lucro em destaque: grandes, um embaixo do outro, cada um
/// com a setinha que compara com o mês passado.
class _Topo extends StatelessWidget {
  final _Numeros atual, antes;
  final DateTime mesAnterior;
  final int? ateDia;
  const _Topo({
    required this.atual,
    required this.antes,
    required this.mesAnterior,
    required this.ateDia,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final curto = _mesCurto.format(mesAnterior).replaceAll('.', '');
    final apoio = t.apoio().copyWith(fontSize: 13);
    final grande = t.display(size: 38);

    Widget comparacao(double agora, double antes, {required String semBase}) {
      if (antes <= 0) return Text(agora > 0 ? semBase : '—', style: apoio);
      final pct = ((agora - antes) / antes * 100).round();
      if (pct == 0) return Text('igual a $curto', style: apoio);
      final sobe = pct > 0;
      final cor = sobe ? c.positivo : c.negativo;
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(sobe ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 16, color: cor),
        const SizedBox(width: 2),
        Text('${pct.abs()}%', style: t.valor(size: 14, color: cor, peso: FontWeight.w700)),
        Text(' que $curto', style: apoio),
      ]);
    }

    Widget linha(IconData icone, Color cor, String rotulo, Widget numero, Widget comparar) =>
        Padding(
          padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.l, Espaco.l, Espaco.l),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Raio.pequeno),
              ),
              child: Icon(icone, color: cor, size: 22),
            ),
            const SizedBox(width: Espaco.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(rotulo, style: t.corpo(color: c.tintaSuave))),
                  comparar,
                ]),
                const SizedBox(height: 2),
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: numero),
              ]),
            ),
          ]),
        );

    // Os fios começam depois do ícone, como numa lista.
    const divisoria = Divider(indent: Espaco.l + 42 + Espaco.m, endIndent: Espaco.l);
    final nome = _mesNome.format(mesAnterior);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Card(
        child: Column(children: [
          linha(
            Icons.payments_outlined,
            c.acao,
            'Vendas',
            ValorAnimado(atual.vendas, doZero: true, style: grande),
            comparacao(atual.vendas, antes.vendas, semBase: 'sem vendas em $curto'),
          ),
          divisoria,
          linha(
            Icons.receipt_long_outlined,
            c.destaque,
            'Pedidos',
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: atual.pedidos.toDouble()),
              duration: const Duration(milliseconds: 600),
              curve: Movimento.entrada,
              builder: (_, v, __) => Text('${v.round()}', style: grande),
            ),
            comparacao(atual.pedidos.toDouble(), antes.pedidos.toDouble(),
                semBase: 'sem pedidos em $curto'),
          ),
          divisoria,
          linha(
            Icons.trending_up_rounded,
            c.positivo,
            'Lucro',
            ValorAnimado(atual.lucro,
                doZero: true,
                style: grande.copyWith(color: atual.lucro < 0 ? c.negativo : c.positivo)),
            comparacao(atual.lucro, antes.lucro, semBase: 'sem lucro em $curto'),
          ),
        ]),
      ),
      const SizedBox(height: Espaco.s),
      Text(ateDia == null ? 'Comparado a $nome.' : 'Comparado a $nome até o dia $ateDia.',
          style: t.apoio().copyWith(fontSize: 12)),
    ]);
  }
}

/// A tabela por produto (quantidade, vendas e lucro), como na planilha, com o
/// total e as contas do mês no fim.
class _Tabela extends StatelessWidget {
  final ResumoMes r;
  final DateTime mes;
  final Map<int, String?> fotos;
  final bool emAndamento;
  final VoidCallback onAjustes;
  const _Tabela({
    required this.r,
    required this.mes,
    required this.fotos,
    required this.emAndamento,
    required this.onAjustes,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final escala = MediaQuery.textScalerOf(context);
    final colunaQtd = escala.scale(34);
    final colunaValor = escala.scale(76);
    final cabeca = t.apoio().copyWith(fontSize: 12, fontWeight: FontWeight.w600);
    final numero = t.valor(size: 14, peso: FontWeight.w500);
    final forte = t.valor(size: 15, peso: FontWeight.w700);
    const respiro = EdgeInsets.symmetric(horizontal: Espaco.l, vertical: Espaco.m);

    Widget fileira(Widget nome, Widget qtd, Widget vendas, Widget lucro,
            {EdgeInsets padding = respiro}) =>
        Padding(
          padding: padding,
          child: Row(children: [
            Expanded(child: nome),
            SizedBox(width: colunaQtd, child: Align(alignment: Alignment.centerRight, child: qtd)),
            SizedBox(
                width: colunaValor, child: Align(alignment: Alignment.centerRight, child: vendas)),
            SizedBox(
                width: colunaValor, child: Align(alignment: Alignment.centerRight, child: lucro)),
          ]),
        );

    final produtos = r.porProduto()
      ..sort((a, b) => b.vendidos != a.vendidos
          ? b.vendidos.compareTo(a.vendidos)
          : b.faturamento.compareTo(a.faturamento));

    final linhas = <Widget>[
      ColoredBox(
        color: c.realce,
        child: fileira(Text('Produto', style: cabeca), Text('Qtd', style: cabeca),
            Text('Vendas', style: cabeca), Text('Lucro', style: cabeca),
            padding: const EdgeInsets.symmetric(horizontal: Espaco.l, vertical: Espaco.s)),
      ),
      if (produtos.isEmpty)
        Padding(
          padding: respiro,
          child: Text('Nada vendido em ${_mesNome.format(mes)}.', style: t.apoio()),
        ),
      for (final (i, p) in produtos.indexed) ...[
        if (i > 0) const Divider(indent: Espaco.l + 30 + Espaco.s, endIndent: Espaco.l),
        fileira(
          Row(children: [
            FotoProduto(fotos[p.id], tamanho: 30),
            const SizedBox(width: Espaco.s),
            Expanded(
              child: Text(p.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.corpo().copyWith(fontSize: 14, height: 1.2)),
            ),
          ]),
          Text('${p.vendidos}', style: numero),
          Text(_reais0(p.faturamento), style: numero),
          Text(_reais0(p.lucro), style: p.lucro < 0 ? numero.copyWith(color: c.negativo) : numero),
        ),
      ],
      // Total com o traço de cima mais forte, como numa conta feita no papel.
      DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.tinta, width: 1.2))),
        child: fileira(
          Text('Total', style: t.corpo(peso: FontWeight.w700).copyWith(fontSize: 15)),
          Text('${r.vendidos}', style: forte),
          Text(_reais0(r.faturamento), style: forte),
          Text(_reais0(r.lucroBolso),
              style: forte.copyWith(color: r.lucroBolso < 0 ? c.negativo : c.positivo)),
        ),
      ),
      _Contas(r: r, emAndamento: emAndamento, onAjustes: onAjustes),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Card(
        clipBehavior: Clip.antiAlias,
        child: AnimatedSize(
          duration: Movimento.medio,
          curve: Movimento.entrada,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: Movimento.medio,
            child: Column(key: ValueKey(mes), children: linhas),
          ),
        ),
      ),
      const SizedBox(height: Espaco.s),
      Text('Lucro: o que sobra das vendas depois de ingredientes, embalagens, taxas e perdas.',
          style: t.apoio().copyWith(fontSize: 12)),
    ]);
  }
}

/// As contas fixas e o salário, embaixo do total: quanto são e quanto sobra ou
/// falta. No mês em andamento, o que falta não é prejuízo: ainda dá tempo de vender.
class _Contas extends StatelessWidget {
  final ResumoMes r;
  final bool emAndamento;
  final VoidCallback onAjustes;
  const _Contas({required this.r, required this.emAndamento, required this.onAjustes});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final a = r.ajustes;
    final contas = (a.totalFixos + a.salarioCentavos).toDouble();
    const respiro = EdgeInsets.symmetric(horizontal: Espaco.l, vertical: Espaco.m);

    if (contas == 0) {
      return Container(
        color: c.papel,
        padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.xs, Espaco.xs, Espaco.xs),
        child: Row(children: [
          Expanded(child: Text('Contas do mês (gás, luz, salário)', style: t.apoio())),
          TextButton(onPressed: onAjustes, child: const Text('Incluir')),
        ]),
      );
    }

    final nomes = [
      for (final f in a.fixos)
        if (f.valorCentavos > 0) f.nome.toLowerCase(),
      if (a.salarioCentavos > 0) 'seu salário',
    ];
    final sobra = r.lucroReal;
    final (rotulo, cor) = switch ((sobra >= 0, emAndamento)) {
      (true, true) => ('Sobra no mês', c.positivo),
      (true, false) => ('Sobrou no mês', c.positivo),
      (false, true) => ('Falta para cobrir', c.atencao),
      (false, false) => ('Faltou para cobrir', c.negativo),
    };
    return Container(
      color: c.papel,
      child: Column(children: [
        Padding(
          padding: respiro,
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Contas do mês', style: t.corpo().copyWith(fontSize: 14)),
                Text(_listaNomes(nomes), style: t.apoio().copyWith(fontSize: 11)),
              ]),
            ),
            Text('− ${_reais0(contas)}',
                style: t.valor(size: 14, color: c.tintaSuave, peso: FontWeight.w500)),
          ]),
        ),
        const Divider(indent: Espaco.l, endIndent: Espaco.l),
        Padding(
          padding: respiro,
          child: Row(children: [
            Expanded(
                child: Text(rotulo, style: t.corpo(peso: FontWeight.w700).copyWith(fontSize: 15))),
            Text(_reais0(sobra.abs()), style: t.valor(size: 15, color: cor, peso: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }
}
