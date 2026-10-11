import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


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
