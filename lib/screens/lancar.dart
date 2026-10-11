import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../theme.dart';

/// Partes comuns das abas Vendas e Produção: registrar rápido, editar,
/// e as linhas do histórico agrupadas por dia.

final formatoDia = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');
final formatoDiaCurto = DateFormat("d 'de' MMMM", 'pt_BR');

bool mesmoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

List<(DateTime, List<Lancamento>)> agruparPorDia(Iterable<Lancamento> ls) {
  final grupos = <(DateTime, List<Lancamento>)>[];
  for (final l in ls) {
    final d = DateTime(l.data.year, l.data.month, l.data.day);
    if (grupos.isNotEmpty && grupos.last.$1 == d) {
      grupos.last.$2.add(l);
    } else {
      grupos.add((d, [l]));
    }
  }
  return grupos;
}

String nomeDia(DateTime d) {
  final hoje = DateTime.now();
  if (mesmoDia(d, hoje)) return 'Hoje';
  if (mesmoDia(d, hoje.subtract(const Duration(days: 1)))) return 'Ontem';
  return formatoDia.format(d);
}

String _plural(int n, String um, String varios) => n == 1 ? '1 $um' : '$n $varios';

/// Sugestão tocável (ex.: nome de cliente que já comprou).
class _Sugestao extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;
  const _Sugestao({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Material(
      color: c.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Raio.pequeno),
        side: BorderSide(color: c.linha),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Raio.pequeno),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Espaco.m, vertical: Espaco.s),
          child: Text(texto, style: context.tipos.apoio(color: c.tinta)),
        ),
      ),
    );
  }
}
