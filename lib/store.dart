
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


final _real = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

/// "R$ 1.234,50"; negativo sai com o sinal de menos tipográfico: "−R$ 12,00".
String reais(num centavos) => centavos <= -0.5
    ? '\u2212${_real.format(-centavos / 100)}'
    : _real.format(centavos.abs() < 0.5 ? 0 : centavos / 100);

final _milhar = RegExp(r'^[1-9]\d{0,2}(\.\d{3})+$');

/// Aceita "1.234,5", "1234,5", "1234.5" e "1.000" (mil, como se escreve no Brasil).
double? parseNum(String s) {
  final t = s.trim().replaceAll(' ', '');
  if (t.isEmpty) return null;
  final normal =
      t.contains(',') || _milhar.hasMatch(t) ? t.replaceAll('.', '').replaceAll(',', '.') : t;
  return double.tryParse(normal);
}
