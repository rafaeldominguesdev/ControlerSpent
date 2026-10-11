import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../store.dart';

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
