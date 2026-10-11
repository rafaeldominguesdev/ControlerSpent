import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

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

/// Guarda tudo localmente no aparelho.
class Store extends ChangeNotifier {
  static const _kInsumos = 'insumos';
  static const _kProdutos = 'produtos';

  final List<Insumo> insumos = [];
  final List<Produto> produtos = [];
  final List<Lancamento> lancamentos = [];
  Ajustes ajustes = Ajustes();

  /// Separado do resto para o app só trocar o tema quando ele muda.
  final tema = ValueNotifier(TemaApp.sistema);
  late SharedPreferences _prefs;

  static const _kLancamentos = 'lancamentos';
  static const _kAjustes = 'ajustes';

  Map<int, Insumo> get insumosPorId => {for (final i in insumos) i.id: i};

  Calculo calcular(Produto p) => Calculo.de(p, insumosPorId);

  Future<void> carregar() async {
    _prefs = await SharedPreferences.getInstance();
    final i = _prefs.getString(_kInsumos);
    final p = _prefs.getString(_kProdutos);
    if (i != null) {
      insumos.addAll((jsonDecode(i) as List).map((e) => Insumo.fromJson(e)));
    }
    if (p != null) {
      produtos.addAll((jsonDecode(p) as List).map((e) => Produto.fromJson(e)));
    }
    final l = _prefs.getString(_kLancamentos);
    if (l != null) {
      lancamentos.addAll((jsonDecode(l) as List).map((e) => Lancamento.fromJson(e)));
    }
    final a = _prefs.getString(_kAjustes);
    if (a != null) ajustes = Ajustes.fromJson(jsonDecode(a));
    tema.value = ajustes.tema;
    if (_separarLotesAntigos()) await _salvar();
    notifyListeners();
  }

  /// O formato antigo "fez 50, vendeu 44" vira produção de 50 + venda de 44 +
  /// perda de 6. O lucro fica igual (o custo dos 50 continua contado).
  bool _separarLotesAntigos() {
    final lotes = lancamentos.where((l) => l.tipo == TipoLancamento.lote).toList();
    for (final l in lotes) {
      lancamentos.remove(l);
      Lancamento novo(TipoLancamento tipo, int feitos, int vendidos) => Lancamento(
            produtoId: l.produtoId,
            produtoNome: l.produtoNome,
            data: l.data,
            feitos: feitos,
            vendidos: vendidos,
            precoUnitCentavos: tipo == TipoLancamento.venda ? l.precoUnitCentavos : 0,
            custoUnitCentavos: l.custoUnitCentavos,
            taxaPct: tipo == TipoLancamento.venda ? l.taxaPct : 0,
            tipo: tipo,
          );
      lancamentos.add(novo(TipoLancamento.producao, l.feitos, 0));
      if (l.vendidos > 0) lancamentos.add(novo(TipoLancamento.venda, l.vendidos, l.vendidos));
      if (l.sobra > 0) lancamentos.add(novo(TipoLancamento.perda, l.sobra, 0));
    }
    lancamentos.sort((a, b) => b.data.compareTo(a.data));
    return lotes.isNotEmpty;
  }

  /// Unidades prontas: o que foi produzido menos o que foi vendido ou perdido.
  /// Conta a partir da primeira produção registrada do produto; vendas de antes
  /// disso (de quando ainda não se anotava a produção) não deixam o estoque negativo.
  int estoque(int produtoId) {
    final doProduto = lancamentos.where((l) => l.produtoId == produtoId);
    final producoes = doProduto.where((l) => l.tipo == TipoLancamento.producao);
    if (producoes.isEmpty) return 0;
    final inicio = producoes.map((l) => l.data).reduce((a, b) => a.isBefore(b) ? a : b);
    var n = 0;
    for (final l in doProduto) {
      if (l.data.isBefore(inicio)) continue;
      n += switch (l.tipo) {
        TipoLancamento.producao => l.feitos,
        TipoLancamento.venda => -l.vendidos,
        TipoLancamento.perda => -l.feitos,
        TipoLancamento.lote => 0, // já separado em produção, venda e perda ao carregar
      };
    }
    return n;
  }

  /// Nomes de clientes, do mais recente para o mais antigo, sem repetir.
  List<String> clientesRecentes({int limite = 6}) {
    final vistos = <String>{};
    final nomes = <String>[];
    for (final l in lancamentos) {
      final c = l.cliente;
      if (c == null || !vistos.add(c.toLowerCase())) continue;
      nomes.add(c);
      if (nomes.length == limite) break;
    }
    return nomes;
  }

  Future<void> _salvar() async {
    await _prefs.setString(_kLancamentos, jsonEncode(lancamentos.map((e) => e.toJson()).toList()));
    await _prefs.setString(_kAjustes, jsonEncode(ajustes.toJson()));
    await _prefs.setString(_kInsumos, jsonEncode(insumos.map((e) => e.toJson()).toList()));
    await _prefs.setString(_kProdutos, jsonEncode(produtos.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  Future<void> salvarInsumo(Insumo novo) {
    final idx = insumos.indexWhere((e) => e.id == novo.id);
    idx >= 0 ? insumos[idx] = novo : insumos.add(novo);
    insumos.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return _salvar();
  }

  bool insumoEmUso(Insumo i) => produtos.any((p) => p.itens.any((it) => it.insumoId == i.id));

  Future<void> removerInsumo(Insumo i) {
    insumos.removeWhere((e) => e.id == i.id);
    return _salvar();
  }

  Future<void> salvarProduto(Produto novo) {
    final idx = produtos.indexWhere((e) => e.id == novo.id);
    idx >= 0 ? produtos[idx] = novo : produtos.add(novo);
    produtos.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return _salvar();
  }

  Future<void> removerProduto(Produto p) {
    produtos.removeWhere((e) => e.id == p.id);
    return _salvar();
  }

  Future<void> salvarLancamento(Lancamento novo) {
    final idx = lancamentos.indexWhere((e) => e.id == novo.id);
    idx >= 0 ? lancamentos[idx] = novo : lancamentos.add(novo);
    lancamentos.sort((a, b) => b.data.compareTo(a.data));
    return _salvar();
  }

  Future<void> removerLancamento(Lancamento l) {
    lancamentos.removeWhere((e) => e.id == l.id);
    return _salvar();
  }

  Future<void> salvarAjustes(Ajustes a) {
    ajustes = a;
    tema.value = a.tema;
    return _salvar();
  }

  /// Aplica na hora e já guarda.
  Future<void> mudarTema(TemaApp t) {
    ajustes.tema = t;
    tema.value = t;
    return _salvar();
  }

  ResumoMes resumo(int ano, int mes) => ResumoMes(
      lancamentos.where((l) => l.data.year == ano && l.data.month == mes).toList(), ajustes);
}
