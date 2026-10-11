import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ajustes_screen.dart';

final _mesAno = DateFormat("MMMM 'de' yyyy", 'pt_BR');
final _mesNome = DateFormat('MMMM', 'pt_BR');
final _mesCurto = DateFormat('MMM', 'pt_BR');
final _realCurto = NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);

String _listaNomes(List<String> nomes) => switch (nomes.length) {
      0 => '',
      1 => nomes.first,
      _ => '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}',
    };

bool _emAndamento(DateTime mes) {
  final hoje = DateTime.now();
  return mes.year == hoje.year && mes.month == hoje.month;
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Rótulo curto para cima das barras: "474", "1,8 mil".
String _curto(double reais) {
  final v = reais.abs();
  final txt =
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1).replaceAll('.', ',')} mil' : '${v.round()}';
  return reais < 0 ? '\u2212$txt' : txt;
}

/// Vendas de um mês; com [ateDia], só até aquele dia (para comparar períodos iguais).
double _vendasDoMes(Store store, DateTime mes, {int? ateDia}) => store.lancamentos
    .where((l) =>
        l.data.year == mes.year &&
        l.data.month == mes.month &&
        (ateDia == null || l.data.day <= ateDia))
    .fold(0.0, (s, l) => s + l.faturamento);

class RelatorioScreen extends StatefulWidget {
  final Store store;
  const RelatorioScreen({super.key, required this.store});

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);
  bool _voltando = false;

  void _mudarMes(int delta) => setState(() {
        _voltando = delta < 0;
        _mes = DateTime(_mes.year, _mes.month + delta);
      });

  void _abrirAjustes() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => AjustesScreen(store: widget.store)));

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final r = store.resumo(_mes.year, _mes.month);
        return Scaffold(
          appBar: AppBar(
            title: Text(store.ajustes.nomeNegocio),
            actions: [BotaoConfiguracoes(store: store)],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(Espaco.borda, 0, Espaco.borda, Espaco.secao),
            children: [
              _SeletorMes(
                texto: _mesAno.format(_mes),
                onAnterior: () => _mudarMes(-1),
                onProximo: () => _mudarMes(1),
              ),
              // O conteúdo do mês desliza para o lado da seta tocada.
              AnimatedSwitcher(
                duration: Movimento.medio,
                switchInCurve: Movimento.entrada,
                switchOutCurve: Movimento.saida,
                transitionBuilder: (child, anim) {
                  final entrando = child.key == ValueKey(_mes);
                  final dx = (entrando ? 1 : -1) * (_voltando ? -0.06 : 0.06);
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  );
                },
                layoutBuilder: (atual, anteriores) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...anteriores, if (atual != null) atual],
                ),
                child: _ConteudoMes(
                  key: ValueKey(_mes),
                  store: store,
                  r: r,
                  mes: _mes,
                  onAjustes: _abrirAjustes,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConteudoMes extends StatelessWidget {
  final Store store;
  final ResumoMes r;
  final DateTime mes;
  final VoidCallback onAjustes;
  const _ConteudoMes(
      {super.key,
      required this.store,
      required this.r,
      required this.mes,
      required this.onAjustes});

  @override
  Widget build(BuildContext context) {
    final t = context.tipos;
    final produtos = r.porProduto();
    Widget titulo(String s) => Text(s, style: t.secao());
    final blocos = <Widget>[
      _Destaque(store: store, r: r, mes: mes),
      const SizedBox(height: Espaco.xl),
      _FaixaNumeros(r: r),
      if (r.itens.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: Espaco.l),
          child: Vazio(
            icone: Icons.receipt_long_outlined,
            titulo: 'Nada vendido em ${_mesNome.format(mes)}',
            texto: 'Quando você registrar vendas na aba Vendas, os gráficos aparecem aqui.',
          ),
        )
      else ...[
        const SizedBox(height: Espaco.secao),
        titulo('Para onde foi o dinheiro'),
        const SizedBox(height: Espaco.m),
        _ParaOndeFoi(r: r),
        const SizedBox(height: Espaco.secao),
        titulo('Mais vendidos'),
        const SizedBox(height: Espaco.m),
        _Ranking(store: store, produtos: produtos),
        const SizedBox(height: Espaco.secao),
        titulo('Vendas por produto'),
        const SizedBox(height: Espaco.m),
        _Rosca(produtos: produtos, total: r.faturamento),
      ],
      const SizedBox(height: Espaco.secao),
      titulo('Contas do mês'),
      const SizedBox(height: Espaco.m),
      _ContasDoMes(r: r, onAjustes: onAjustes),
      const SizedBox(height: Espaco.secao),
      titulo('Últimos 6 meses'),
      const SizedBox(height: Espaco.m),
      _Meses(store: store, ate: mes),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, b) in blocos.indexed) EntradaSuave(ordem: i ~/ 3, child: b),
      ],
    );
  }
}

class _SeletorMes extends StatelessWidget {
  final String texto;
  final VoidCallback onAnterior, onProximo;
  const _SeletorMes({required this.texto, required this.onAnterior, required this.onProximo});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Espaco.s),
        child: Row(children: [
          Expanded(child: Rotulo(texto)),
          IconButton(
            tooltip: 'Mês anterior',
            onPressed: onAnterior,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Próximo mês',
            onPressed: onProximo,
            icon: const Icon(Icons.chevron_right),
          ),
        ]),
      );
}

/// Vendas do mês em verde, a comparação com o mês anterior e o gráfico por dia.
class _Destaque extends StatelessWidget {
  final Store store;
  final ResumoMes r;
  final DateTime mes;
  const _Destaque({required this.store, required this.r, required this.mes});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final anterior = DateTime(mes.year, mes.month - 1);
    final ateDia = _emAndamento(mes) ? DateTime.now().day : null;
    final vendasAntes = _vendasDoMes(store, anterior, ateDia: ateDia);
    final variacao = vendasAntes > 0 ? (r.faturamento - vendasAntes) / vendasAntes : null;

    Widget comparacao() {
      if (variacao == null) {
        return Text(
          r.faturamento == 0 ? 'Nenhuma venda registrada ainda.' : 'Sem vendas no mês anterior.',
          style: t.apoio(),
        );
      }
      final pct = (variacao.abs() * 100).round();
      final subiu = variacao >= 0;
      final cor = subiu ? c.positivo : c.negativo;
      final periodo = ateDia == null ? '' : ' no mesmo período';
      return Row(children: [
        Icon(subiu ? Icons.trending_up : Icons.trending_down, size: 18, color: cor),
        const SizedBox(width: Espaco.xs),
        Flexible(
          child: Text(
            pct == 0
                ? 'Igual a ${_mesNome.format(anterior)}$periodo'
                : '$pct% ${subiu ? 'acima' : 'abaixo'} de ${_mesNome.format(anterior)}$periodo',
            style: t.apoio(color: cor).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Vendas do mês', style: t.apoio()),
      const SizedBox(height: 2),
      ValorAnimado(r.faturamento, style: t.display(size: 40, color: c.positivo)),
      const SizedBox(height: Espaco.xs),
      comparacao(),
      if (r.itens.isNotEmpty) ...[
        const SizedBox(height: Espaco.l),
        _VendasPorDia(r: r, mes: mes),
      ],
    ]);
  }
}

/// Uma barra por dia do mês, sobre um trilho verde-claro (até hoje).
class _VendasPorDia extends StatelessWidget {
  final ResumoMes r;
  final DateTime mes;
  const _VendasPorDia({required this.r, required this.mes});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final dias = DateUtils.getDaysInMonth(mes.year, mes.month);
    final porDia = List<double>.filled(dias, 0);
    for (final l in r.itens) {
      porDia[l.data.day - 1] += l.faturamento / 100;
    }
    final maior = porDia.fold(0.0, (a, b) => b > a ? b : a);
    final teto = maior <= 0 ? 1.0 : maior * 1.08;
    final hoje = _emAndamento(mes) ? DateTime.now().day : dias;

    return LayoutBuilder(builder: (context, caixa) {
      final largura = ((caixa.maxWidth / dias) * 0.55).clamp(3.0, 10.0);
      return SizedBox(
        height: 104,
        child: BarChart(
          BarChartData(
            maxY: teto,
            minY: 0,
            alignment: BarChartAlignment.spaceBetween,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => c.tinta,
                tooltipBorderRadius: BorderRadius.circular(Raio.pequeno),
                getTooltipItem: (grupo, _, rod, __) => BarTooltipItem(
                  '${grupo.x + 1} de ${_mesCurto.format(mes).replaceAll('.', '')}\n'
                  '${reais(rod.toY * 100)}',
                  t.valor(size: 12, color: c.papel),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 20,
                  getTitlesWidget: (v, meta) {
                    final d = v.toInt() + 1;
                    final mostrar = d == 1 || d == dias || (d % 10 == 0 && dias - d > 3);
                    return mostrar
                        ? Padding(
                            padding: const EdgeInsets.only(top: Espaco.xs),
                            child: Text('$d', style: t.apoio().copyWith(fontSize: 11)),
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < dias; i++)
                BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: porDia[i],
                    width: largura,
                    color: i + 1 == hoje && _emAndamento(mes) ? c.positivo : c.dinheiro,
                    borderRadius: BorderRadius.circular(largura / 2),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: i + 1 <= hoje,
                      toY: teto,
                      color: c.dinheiroSuave,
                    ),
                  ),
                ]),
            ],
          ),
          duration: Movimento.lento,
          curve: Movimento.entrada,
        ),
      );
    });
  }
}

/// Lucro, margem e quantidade lado a lado.
class _FaixaNumeros extends StatelessWidget {
  final ResumoMes r;
  const _FaixaNumeros({required this.r});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final margem = r.faturamento == 0 ? 0.0 : r.lucroBolso / r.faturamento * 100;
    final corMargem = margem >= 30 ? c.positivo : (margem >= 0 ? c.atencao : c.negativo);
    Widget item(String rotulo, Widget valor) => Expanded(
          child: Column(children: [
            Text(rotulo, style: t.apoio().copyWith(fontSize: 12)),
            const SizedBox(height: 2),
            valor,
          ]),
        );
    final separador = Container(width: 1, height: 34, color: c.linha);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Espaco.m),
        child: Row(children: [
          item(
            'Lucro',
            ValorAnimado(r.lucroBolso,
                style: t.valor(size: 17, color: r.lucroBolso < 0 ? c.negativo : c.positivo)),
          ),
          separador,
          item('Margem',
              Text('${margem.toStringAsFixed(0)}%', style: t.valor(size: 17, color: corMargem))),
          separador,
          item('Vendidos', Text('${r.vendidos}', style: t.valor(size: 17))),
        ]),
      ),
    );
  }
}

/// Uma barra única dividida entre lucro, ingredientes e taxas.
class _ParaOndeFoi extends StatelessWidget {
  final ResumoMes r;
  const _ParaOndeFoi({required this.r});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final partes = [
      if (r.lucroBolso > 0) ('Lucro', r.lucroBolso, c.dinheiro),
      ('Ingredientes e embalagens', r.custo, c.destaque),
      if (r.taxas > 0) ('Taxas da maquininha', r.taxas, c.grafico[2]),
    ];
    final total = partes.fold(0.0, (s, p) => s + p.$2);
    if (total <= 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Espaco.l),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // A barra cresce da esquerda para a direita ao aparecer.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Movimento.entrada,
            builder: (_, f, child) => ClipRect(
              child: Align(alignment: Alignment.centerLeft, widthFactor: f, child: child),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                height: 14,
                // stretch: sem isso os pedaços (ColoredBox sem filho) ficam com altura zero.
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (final (i, p) in partes.indexed)
                    Expanded(
                      flex: (p.$2 / total * 1000).round().clamp(1, 1000),
                      child: Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
                        child: ColoredBox(color: p.$3),
                      ),
                    ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: Espaco.m),
          for (final p in partes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: p.$3, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: Espaco.s),
                Expanded(child: Text(p.$1, style: t.apoio(color: c.tinta))),
                Text(reais(p.$2), style: t.valor(size: 14)),
                SizedBox(
                  width: 44,
                  child: Text('${(p.$2 / total * 100).round()}%',
                      textAlign: TextAlign.right, style: t.apoio()),
                ),
              ]),
            ),
          if (r.lucroBolso < 0)
            Padding(
              padding: const EdgeInsets.only(top: Espaco.s),
              child: Text('Os custos passaram as vendas em ${reais(-r.lucroBolso)}.',
                  style: t.apoio(color: c.negativo)),
            ),
          if (r.perdas > 0)
            Padding(
              padding: const EdgeInsets.only(top: Espaco.xs),
              child: Text('Os ingredientes incluem ${reais(r.perdas)} de sobras e perdas.',
                  style: t.apoio().copyWith(fontSize: 12)),
            ),
        ]),
      ),
    );
  }
}

class _Ranking extends StatelessWidget {
  final Store store;
  final List<PorProduto> produtos;
  const _Ranking({required this.store, required this.produtos});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final fotos = {for (final p in store.produtos) p.id: p.fotoBase64};
    return GrupoLista(
      recuoDivisoria: 92,
      children: [
        for (final (i, p) in produtos.take(3).indexed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Espaco.l, vertical: Espaco.m),
            child: Row(children: [
              SizedBox(
                width: 22,
                child: Text('${i + 1}',
                    style: t.display(size: 22, color: i == 0 ? c.destaque : c.tintaSuave)),
              ),
              const SizedBox(width: Espaco.s),
              FotoProduto(fotos[p.id], tamanho: 36),
              const SizedBox(width: Espaco.m),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.corpo(peso: FontWeight.w600)),
                  Text('${p.vendidos} vendidos', style: t.apoio().copyWith(fontSize: 12)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(reais(p.faturamento), style: t.valor(color: c.positivo)),
                Text('lucro ${reais(p.lucro)}', style: t.apoio().copyWith(fontSize: 12)),
              ]),
            ]),
          ),
      ],
    );
  }
}

class _Rosca extends StatelessWidget {
  final List<PorProduto> produtos;
  final double total;
  const _Rosca({required this.produtos, required this.total});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final lista = [...produtos]..sort((a, b) => b.faturamento.compareTo(a.faturamento));
    // Mais de 5 fatias vira ruído: o resto entra em "Outros".
    final principais = lista.take(4).toList();
    final outros = lista.skip(4).fold(0.0, (s, p) => s + p.faturamento);
    final fatias = [
      for (final p in principais) (p.nome, p.faturamento),
      if (outros > 0) ('Outros', outros),
    ];
    Color cor(int i) => c.grafico[i % c.grafico.length];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Espaco.l),
        child: Row(children: [
          SizedBox(
            width: 116,
            height: 116,
            child: Stack(alignment: Alignment.center, children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  centerSpaceRadius: 36,
                  sectionsSpace: 3,
                  sections: [
                    for (final (i, f) in fatias.indexed)
                      PieChartSectionData(value: f.$2, color: cor(i), radius: 20, showTitle: false),
                  ],
                ),
                duration: Movimento.lento,
                curve: Movimento.entrada,
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('vendas', style: t.apoio().copyWith(fontSize: 11)),
                Text(_realCurto.format(total / 100), style: t.valor(size: 13)),
              ]),
            ]),
          ),
          const SizedBox(width: Espaco.l),
          Expanded(
            child: Column(children: [
              for (final (i, f) in fatias.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration:
                          BoxDecoration(color: cor(i), borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: Espaco.s),
                    Expanded(
                      child: Text(f.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.apoio(color: c.tinta)),
                    ),
                    Text(total == 0 ? '' : '${(f.$2 / total * 100).round()}%',
                        style: t.valor(size: 13)),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// O lucro depois de pagar as contas fixas e o salário dela.
class _ContasDoMes extends StatelessWidget {
  final ResumoMes r;
  final VoidCallback onAjustes;
  const _ContasDoMes({required this.r, required this.onAjustes});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final a = r.ajustes;
    final semContas = a.totalFixos == 0 && a.salarioCentavos == 0;
    final nomesFixos = [
      for (final f in a.fixos)
        if (f.valorCentavos > 0) f.nome
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.s, Espaco.l, Espaco.s),
        child: Column(children: [
          LinhaConta('Lucro do mês', r.lucroBolso, cor: r.lucroBolso < 0 ? c.negativo : c.positivo),
          if (semContas)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: onAjustes,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Incluir gás, luz e seu salário'),
              ),
            )
          else ...[
            LinhaConta(
              'Contas fixas e salário',
              (a.totalFixos + a.salarioCentavos).toDouble(),
              menos: true,
              detalhe: _listaNomes([...nomesFixos, if (a.salarioCentavos > 0) 'seu salário']),
            ),
            const Tracejado(),
            LinhaConta('Sobra no fim do mês', r.lucroReal,
                forte: true, cor: r.lucroReal < 0 ? c.negativo : c.positivo),
          ],
        ]),
      ),
    );
  }
}

/// Lucro mês a mês, com o valor em cima de cada barra.
class _Meses extends StatelessWidget {
  final Store store;
  final DateTime ate;
  const _Meses({required this.store, required this.ate});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final meses = [for (var i = 5; i >= 0; i--) DateTime(ate.year, ate.month - i)];
    final lucros = [for (final m in meses) store.resumo(m.year, m.month).lucroBolso / 100];
    final maior = lucros.fold(0.0, (a, b) => b > a ? b : a);
    final menor = lucros.fold(0.0, (a, b) => b < a ? b : a);
    final melhor = lucros.indexOf(maior);
    final temDados = lucros.any((v) => v != 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.xl, Espaco.l, Espaco.m),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: maior <= 0 ? 100 : maior * 1.3,
                minY: menor < 0 ? menor * 1.3 : 0,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(
                  show: true,
                  border: Border(bottom: BorderSide(color: c.linha)),
                ),
                barTouchData: BarTouchData(
                  enabled: false,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent,
                    tooltipPadding: EdgeInsets.zero,
                    tooltipMargin: 4,
                    getTooltipItem: (grupo, _, rod, __) => BarTooltipItem(
                      _curto(rod.toY),
                      t.valor(
                        size: 11,
                        color: grupo.x == meses.length - 1 ? c.positivo : c.tintaSuave,
                        peso: grupo.x == meses.length - 1 ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        final atual = i == meses.length - 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: Espaco.s),
                          child: Text(
                            _mesCurto.format(meses[i]).replaceAll('.', ''),
                            style: t.apoio(color: atual ? c.tinta : c.tintaSuave).copyWith(
                                fontSize: 12,
                                fontWeight: atual ? FontWeight.w700 : FontWeight.w400),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < lucros.length; i++)
                    BarChartGroupData(
                      x: i,
                      showingTooltipIndicators: lucros[i] == 0 ? const [] : const [0],
                      barRods: [
                        BarChartRodData(
                          toY: lucros[i],
                          width: 22,
                          color: lucros[i] < 0
                              ? c.negativo
                              : (i == lucros.length - 1 ? c.positivo : c.dinheiro),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(lucros[i] >= 0 ? 6 : 0),
                            bottom: Radius.circular(lucros[i] < 0 ? 6 : 0),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              duration: Movimento.lento,
              curve: Movimento.entrada,
            ),
          ),
          const SizedBox(height: Espaco.m),
          Text(
            [
              temDados && maior > 0
                  ? 'Melhor mês: ${_mesNome.format(meses[melhor])} (${reais(maior * 100)}).'
                  : 'Ainda não há vendas nesses meses.',
              if (_emAndamento(ate)) '${_cap(_mesNome.format(ate))} está em andamento.',
            ].join(' '),
            style: t.apoio(),
          ),
        ]),
      ),
    );
  }
}
