import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

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
