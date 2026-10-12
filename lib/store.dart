import 'dart:convert';
import 'dart:math' as math;

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

/// Guarda tudo localmente no aparelho. Pode haver mais de uma loja: cada uma
/// tem os seus dados em chaves próprias ("produtos_2"), e as listas abaixo são
/// sempre as da loja em uso.
class Store extends ChangeNotifier {
  static const _kInsumos = 'insumos';
  static const _kProdutos = 'produtos';
  static const _kLojas = 'lojas';
  static const _kLojaAtual = 'lojaAtual';

  final List<Loja> lojas = [];
  int _lojaAtualId = 1;

  final List<Insumo> insumos = [];
  final List<Produto> produtos = [];
  final List<Lancamento> lancamentos = [];
  Ajustes ajustes = Ajustes();

  /// Separado do resto para o app só trocar o tema quando ele muda.
  final tema = ValueNotifier(TemaApp.sistema);
  late SharedPreferences _prefs;

  static const _kLancamentos = 'lancamentos';
  static const _kAjustes = 'ajustes';
  static const _kVendasEmLista = 'vendasEmLista';

  Map<int, Insumo> get insumosPorId => {for (final i in insumos) i.id: i};

  Calculo calcular(Produto p) => Calculo.de(p, insumosPorId);

  Loja get lojaAtual => lojas.firstWhere((l) => l.id == _lojaAtualId);

  static const _dadosDaLoja = [_kInsumos, _kProdutos, _kLancamentos, _kAjustes];

  /// Chave de um dado da loja em uso: "produtos_1".
  String _chave(String base) => '${base}_$_lojaAtualId';

  Future<void> carregar() async {
    _prefs = await SharedPreferences.getInstance();
    final salvas = _prefs.getString(_kLojas);
    if (salvas == null) {
      await _migrarLojaUnica();
    } else {
      lojas.addAll((jsonDecode(salvas) as List).map((e) => Loja.fromJson(e)));
    }
    if (lojas.isEmpty) {
      lojas.add(Loja(id: 1, nome: 'Minha Confeitaria'));
      await _salvarLojas();
    }
    final atual = _prefs.getInt(_kLojaAtual);
    _lojaAtualId = lojas.any((l) => l.id == atual) ? atual! : lojas.first.id;
    await _carregarLoja();
  }

  /// Antes de existirem lojas, os dados ficavam em chaves sem número. Eles viram
  /// a loja 1; as chaves antigas só são apagadas depois de tudo copiado.
  Future<void> _migrarLojaUnica() async {
    final a = _prefs.getString(_kAjustes);
    final nome = a == null ? 'Minha Confeitaria' : Ajustes.fromJson(jsonDecode(a)).nomeNegocio;
    lojas.add(Loja(id: 1, nome: nome));
    for (final base in _dadosDaLoja) {
      final valor = _prefs.getString(base);
      if (valor != null) await _prefs.setString('${base}_1', valor);
    }
    await _salvarLojas();
    await _prefs.setInt(_kLojaAtual, 1);
    for (final base in _dadosDaLoja) {
      await _prefs.remove(base);
    }
  }

  Future<void> _carregarLoja() async {
    insumos.clear();
    produtos.clear();
    lancamentos.clear();
    final i = _prefs.getString(_chave(_kInsumos));
    final p = _prefs.getString(_chave(_kProdutos));
    if (i != null) {
      insumos.addAll((jsonDecode(i) as List).map((e) => Insumo.fromJson(e)));
    }
    if (p != null) {
      produtos.addAll((jsonDecode(p) as List).map((e) => Produto.fromJson(e)));
    }
    final l = _prefs.getString(_chave(_kLancamentos));
    if (l != null) {
      lancamentos.addAll((jsonDecode(l) as List).map((e) => Lancamento.fromJson(e)));
    }
    final a = _prefs.getString(_chave(_kAjustes));
    ajustes = a == null ? Ajustes(nomeNegocio: lojaAtual.nome) : Ajustes.fromJson(jsonDecode(a));
    tema.value = ajustes.tema;
    if (_separarLotesAntigos()) await _salvar();
    notifyListeners();
  }

  Future<void> _salvarLojas() =>
      _prefs.setString(_kLojas, jsonEncode([for (final l in lojas) l.toJson()]));

  /// Troca a loja em uso: o app inteiro passa a mostrar os dados dela.
  Future<void> trocarLoja(int id) async {
    if (id == _lojaAtualId || !lojas.any((l) => l.id == id)) return;
    _lojaAtualId = id;
    await _prefs.setInt(_kLojaAtual, id);
    await _carregarLoja();
  }

  /// Cria uma loja vazia e já passa a usá-la.
  Future<Loja> novaLoja(String nome) async {
    final loja = Loja(id: lojas.fold(0, (m, l) => math.max(m, l.id)) + 1, nome: nome);
    lojas.add(loja);
    await _salvarLojas();
    await trocarLoja(loja.id);
    return loja;
  }

  /// Nome e logo da loja em uso (o nome também é o do negócio nos ajustes).
  Future<void> editarLoja({required String nome, String? foto}) async {
    lojaAtual
      ..nome = nome
      ..fotoBase64 = foto;
    ajustes.nomeNegocio = nome;
    await _salvarLojas();
    await _salvar();
  }

  /// Troca a logo de qualquer loja (não só da que está em uso).
  Future<void> mudarFotoLoja(int id, String? foto) async {
    lojas.firstWhere((l) => l.id == id).fotoBase64 = foto;
    await _salvarLojas();
    notifyListeners();
  }

  /// Apaga uma loja com tudo o que é dela. Sempre sobra pelo menos uma.
  Future<void> removerLoja(int id) async {
    if (lojas.length <= 1 || !lojas.any((l) => l.id == id)) return;
    lojas.removeWhere((l) => l.id == id);
    for (final base in _dadosDaLoja) {
      await _prefs.remove('${base}_$id');
    }
    await _salvarLojas();
    if (id == _lojaAtualId) {
      _lojaAtualId = lojas.first.id;
      await _prefs.setInt(_kLojaAtual, _lojaAtualId);
      await _carregarLoja();
    } else {
      notifyListeners();
    }
  }

  /// Cópia de segurança da loja em uso, em texto, para guardar num arquivo.
  String exportarLoja() => jsonEncode({
        'app': 'Controler Spent',
        'versao': 1,
        'feitaEm': DateTime.now().toIso8601String(),
        'loja': {'nome': lojaAtual.nome, 'foto': lojaAtual.fotoBase64},
        'insumos': [for (final i in insumos) i.toJson()],
        'produtos': [for (final p in produtos) p.toJson()],
        'lancamentos': [for (final l in lancamentos) l.toJson()],
        'ajustes': ajustes.toJson(),
      });

  /// Lê uma cópia feita por [exportarLoja]. Com [comoNova], cria outra loja com
  /// esses dados; sem, troca os dados da loja em uso pelos da cópia. Tudo é lido
  /// antes de mexer em qualquer coisa: se o arquivo estiver errado, nada muda.
  Future<void> importarLoja(String texto, {required bool comoNova}) async {
    final j = jsonDecode(texto);
    if (j is! Map<String, dynamic> || j['app'] != 'Controler Spent' || j['produtos'] is! List) {
      throw const FormatException('Esse arquivo não é uma cópia do Controler Spent.');
    }
    final novosInsumos = [for (final e in j['insumos'] as List) Insumo.fromJson(e)];
    final novosProdutos = [for (final e in j['produtos'] as List) Produto.fromJson(e)];
    final novosLancamentos = [for (final e in j['lancamentos'] as List) Lancamento.fromJson(e)]
      ..sort((a, b) => b.data.compareTo(a.data));
    final novosAjustes = j['ajustes'] == null ? null : Ajustes.fromJson(j['ajustes']);
    final info = (j['loja'] as Map?) ?? const {};
    final nome = (info['nome'] as String?) ?? novosAjustes?.nomeNegocio ?? 'Loja restaurada';

    if (comoNova) await novaLoja(nome);
    lojaAtual
      ..nome = nome
      ..fotoBase64 = info['foto'] as String?;
    insumos
      ..clear()
      ..addAll(novosInsumos);
    produtos
      ..clear()
      ..addAll(novosProdutos);
    lancamentos
      ..clear()
      ..addAll(novosLancamentos);
    ajustes = (novosAjustes ?? Ajustes())..nomeNegocio = nome;
    tema.value = ajustes.tema;
    await _salvarLojas();
    await _salvar();
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

  /// Em Vendas, os produtos aparecem em lista (true) ou em grade (false).
  bool get vendasEmLista => _prefs.getBool(_kVendasEmLista) ?? false;

  Future<void> mudarModoVendas({required bool lista}) async {
    await _prefs.setBool(_kVendasEmLista, lista);
    notifyListeners();
  }

  /// Categorias que já existem nos produtos da loja, na ordem alfabética.
  List<String> get categorias {
    final nomes = {
      for (final p in produtos)
        if (p.categoria.trim().isNotEmpty) p.categoria.trim()
    };
    return nomes.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  /// Forma de pagamento da venda mais recente (a próxima venda já começa nela).
  Pagamento? get ultimoPagamento => lancamentos
      .where((l) => l.tipo == TipoLancamento.venda && l.pagamento != null)
      .firstOrNull
      ?.pagamento;

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
    await _prefs.setString(
        _chave(_kLancamentos), jsonEncode(lancamentos.map((e) => e.toJson()).toList()));
    await _prefs.setString(_chave(_kAjustes), jsonEncode(ajustes.toJson()));
    await _prefs.setString(_chave(_kInsumos), jsonEncode(insumos.map((e) => e.toJson()).toList()));
    await _prefs.setString(
        _chave(_kProdutos), jsonEncode(produtos.map((e) => e.toJson()).toList()));
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

  Future<void> salvarAjustes(Ajustes a) async {
    ajustes = a;
    tema.value = a.tema;
    if (lojaAtual.nome != a.nomeNegocio) {
      lojaAtual.nome = a.nomeNegocio;
      await _salvarLojas();
    }
    await _salvar();
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
