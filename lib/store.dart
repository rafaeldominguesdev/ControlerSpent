
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


final _real = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

/// "R$ 1.234,50"; negativo sai com o sinal de menos tipográfico: "−R$ 12,00".
String reais(num centavos) => centavos <= -0.5
    ? '\u2212${_real.format(-centavos / 100)}'
    : _real.format(centavos.abs() < 0.5 ? 0 : centavos / 100);

/// Converte "7,50" ou "7.50" em 750 centavos.
int? parseCentavos(String s) {
  final v = parseNum(s.replaceAll('R\$', ''));
  return v == null ? null : (v * 100).round();
}

final _milhar = RegExp(r'^[1-9]\d{0,2}(\.\d{3})+$');

/// Aceita "1.234,5", "1234,5", "1234.5" e "1.000" (mil, como se escreve no Brasil).
double? parseNum(String s) {
  final t = s.trim().replaceAll(' ', '');
  if (t.isEmpty) return null;
  final normal =
      t.contains(',') || _milhar.hasMatch(t) ? t.replaceAll('.', '').replaceAll(',', '.') : t;
  return double.tryParse(normal);
}

final _qtd = NumberFormat('#,##0.###', 'pt_BR');

/// Quantidade para mostrar na tela: "1.000", "2,5".
String fmtQtd(double v) => _qtd.format(v);

/// Quantidade para preencher um campo (sem separador de milhar).
/// Até 3 casas, sem zeros sobrando: 0.0399 * 100 vira "3,99", não "3,9899999999999998".
String fmtNum(double v) =>
    v.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '').replaceAll('.', ',');
