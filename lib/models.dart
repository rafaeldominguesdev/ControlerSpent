// Valores em dinheiro são guardados em centavos (int) para evitar erro de arredondamento.

int _ultimoId = 0;

/// Id único e sempre crescente. Só o relógio não basta: itens criados no
/// mesmo instante (no web o relógio tem precisão de milissegundo) repetiam o id
/// e a receita acabava usando o ingrediente errado.
int _nextId() {
  final agora = DateTime.now().microsecondsSinceEpoch;
  _ultimoId = agora > _ultimoId ? agora : _ultimoId + 1;
  return _ultimoId;
}

enum Unidade { g, ml, un }

extension UnidadeLabel on Unidade {
  String get label => name;
}

/// Ingrediente ou embalagem comprado: ex. "Leite condensado, 395 g por R$ 7,50".
class Insumo {
  final int id;
  String nome;
  Unidade unidade;
  double qtdEmbalagem;
  int precoCentavos;
  bool ehEmbalagem;

  Insumo({
    int? id,
    required this.nome,
    required this.unidade,
    required this.qtdEmbalagem,
    required this.precoCentavos,
    this.ehEmbalagem = false,
  }) : id = id ?? _nextId();

  /// Custo em centavos de 1 g / 1 ml / 1 un.
  double get custoPorUnidade => qtdEmbalagem <= 0 ? 0 : precoCentavos / qtdEmbalagem;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'unidade': unidade.name,
        'qtdEmbalagem': qtdEmbalagem,
        'precoCentavos': precoCentavos,
        'ehEmbalagem': ehEmbalagem,
      };

  factory Insumo.fromJson(Map<String, dynamic> j) => Insumo(
        id: j['id'],
        nome: j['nome'],
        unidade: Unidade.values.byName(j['unidade']),
        qtdEmbalagem: (j['qtdEmbalagem'] as num).toDouble(),
        precoCentavos: j['precoCentavos'],
        ehEmbalagem: j['ehEmbalagem'] ?? false,
      );
}

/// Quanto de um insumo a receita inteira usa.
class ItemReceita {
  int insumoId;
  double qtd;

  ItemReceita({required this.insumoId, required this.qtd});

  Map<String, dynamic> toJson() => {'insumoId': insumoId, 'qtd': qtd};

  factory ItemReceita.fromJson(Map<String, dynamic> j) =>
      ItemReceita(insumoId: j['insumoId'], qtd: (j['qtd'] as num).toDouble());
}

/// Produto vendido, com sua ficha técnica.
class Produto {
  final int id;
  String nome;
  String categoria;
  int rendimento; // quantas unidades a receita rende
  double margem; // 0.40 = 40% de lucro sobre o preço
  int? precoVendaCentavos; // preço que ela realmente cobra (opcional)
  List<ItemReceita> itens;
  String? fotoBase64; // foto já reduzida (até 700 pixels de lado) para caber no aparelho

  Produto({
    int? id,
    required this.nome,
    this.categoria = '',
    this.rendimento = 1,
    this.margem = 0.4,
    this.precoVendaCentavos,
    List<ItemReceita>? itens,
    this.fotoBase64,
  })  : id = id ?? _nextId(),
        itens = itens ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'categoria': categoria,
        'rendimento': rendimento,
        'margem': margem,
        'precoVendaCentavos': precoVendaCentavos,
        'itens': itens.map((e) => e.toJson()).toList(),
        'foto': fotoBase64,
      };

  factory Produto.fromJson(Map<String, dynamic> j) => Produto(
        id: j['id'],
        nome: j['nome'],
        categoria: j['categoria'] ?? '',
        rendimento: j['rendimento'],
        margem: (j['margem'] as num).toDouble(),
        precoVendaCentavos: j['precoVendaCentavos'],
        itens: (j['itens'] as List).map((e) => ItemReceita.fromJson(e)).toList(),
        fotoBase64: j['foto'],
      );
}

enum StatusPreco { lucrativo, atencao, prejuizo, semPreco }

/// Resultado do cálculo de um produto, com a mesma regra da planilha.
class Calculo {
  final double custoReceita; // centavos, receita inteira
  final double custoUnitario; // centavos
  final double precoSugerido; // centavos
  final int? precoVenda;

  Calculo(this.custoReceita, this.custoUnitario, this.precoSugerido, this.precoVenda);

  double? get lucroUnitario => precoVenda == null ? null : precoVenda! - custoUnitario;

  double? get margemReal =>
      (precoVenda == null || precoVenda == 0) ? null : lucroUnitario! / precoVenda!;

  StatusPreco get status {
    final m = margemReal;
    if (m == null) return StatusPreco.semPreco;
    if (m < 0) return StatusPreco.prejuizo;
    if (m < 0.30) return StatusPreco.atencao;
    return StatusPreco.lucrativo;
  }

  static Calculo de(Produto p, Map<int, Insumo> insumos) {
    var total = 0.0;
    for (final it in p.itens) {
      final ins = insumos[it.insumoId];
      if (ins != null) total += ins.custoPorUnidade * it.qtd;
    }
    final un = p.rendimento > 0 ? total / p.rendimento : total;
    final margem = p.margem.clamp(0.0, 0.95);
    return Calculo(total, un, un / (1 - margem), p.precoVendaCentavos);
  }
}

/// `lote` é o formato antigo ("fez 50, vendeu 44"); ao carregar ele é separado
/// em produção + venda + perda (ver Store.carregar).
enum TipoLancamento { lote, venda, perda, producao }

enum Pagamento { dinheiro, pix, debito, credito }

extension PagamentoLabel on Pagamento {
  String get label => switch (this) {
        Pagamento.dinheiro => 'Dinheiro',
        Pagamento.pix => 'Pix',
        Pagamento.debito => 'Débito',
        Pagamento.credito => 'Crédito',
      };
}

/// Um registro do caderno: venda, produção ou perda. O custo é congelado no dia,
/// assim o histórico não muda quando o preço de um ingrediente sobe.
class Lancamento {
  final int id;
  int produtoId;
  String produtoNome;
  DateTime data;
  int feitos;
  int vendidos;
  int precoUnitCentavos;
  double custoUnitCentavos;
  double taxaPct; // taxa da maquininha, 0.05 = 5%
  TipoLancamento tipo;
  Pagamento? pagamento;
  String? cliente;
  String? obs;

  Lancamento({
    int? id,
    required this.produtoId,
    required this.produtoNome,
    required this.data,
    required this.feitos,
    required this.vendidos,
    required this.precoUnitCentavos,
    required this.custoUnitCentavos,
    this.taxaPct = 0,
    this.tipo = TipoLancamento.lote,
    this.pagamento,
    this.cliente,
    this.obs,
  }) : id = id ?? _nextId();

  /// Venda avulsa: o custo é só do que foi vendido.
  factory Lancamento.venda(Produto p, double custoUnit,
          {required int qtd,
          required int preco,
          required Pagamento pagamento,
          required double taxa,
          String? cliente,
          String? obs}) =>
      Lancamento(
        produtoId: p.id,
        produtoNome: p.nome,
        data: DateTime.now(),
        feitos: qtd,
        vendidos: qtd,
        precoUnitCentavos: preco,
        custoUnitCentavos: custoUnit,
        taxaPct: taxa,
        tipo: TipoLancamento.venda,
        pagamento: pagamento,
        cliente: _limpo(cliente),
        obs: _limpo(obs),
      );

  /// Produção: quantos ficaram prontos. Não entra no lucro (o custo entra quando
  /// vende ou quando perde); serve para o estoque.
  factory Lancamento.producao(Produto p, double custoUnit, int qtd) => Lancamento(
        produtoId: p.id,
        produtoNome: p.nome,
        data: DateTime.now(),
        feitos: qtd,
        vendidos: 0,
        precoUnitCentavos: 0,
        custoUnitCentavos: custoUnit,
        tipo: TipoLancamento.producao,
      );

  /// Perda: estragou, caiu, sobrou e não deu para vender.
  factory Lancamento.perda(Produto p, double custoUnit, int qtd) => Lancamento(
        produtoId: p.id,
        produtoNome: p.nome,
        data: DateTime.now(),
        feitos: qtd,
        vendidos: 0,
        precoUnitCentavos: 0,
        custoUnitCentavos: custoUnit,
        tipo: TipoLancamento.perda,
      );

  int get sobra => (feitos - vendidos).clamp(0, feitos);
  double get faturamento => (vendidos * precoUnitCentavos).toDouble();
  double get custo => feitos * custoUnitCentavos; // inclui o que sobrou
  double get perda => sobra * custoUnitCentavos;
  double get taxas => faturamento * taxaPct;
  double get lucro => faturamento - custo - taxas;

  Map<String, dynamic> toJson() => {
        'id': id,
        'produtoId': produtoId,
        'produtoNome': produtoNome,
        'data': data.toIso8601String(),
        'feitos': feitos,
        'vendidos': vendidos,
        'precoUnitCentavos': precoUnitCentavos,
        'custoUnitCentavos': custoUnitCentavos,
        'taxaPct': taxaPct,
        'tipo': tipo.name,
        'pagamento': pagamento?.name,
        if (cliente != null) 'cliente': cliente,
        if (obs != null) 'obs': obs,
      };

  factory Lancamento.fromJson(Map<String, dynamic> j) => Lancamento(
        id: j['id'],
        produtoId: j['produtoId'],
        produtoNome: j['produtoNome'],
        data: DateTime.parse(j['data']),
        feitos: j['feitos'],
        vendidos: j['vendidos'],
        precoUnitCentavos: j['precoUnitCentavos'],
        custoUnitCentavos: (j['custoUnitCentavos'] as num).toDouble(),
        taxaPct: (j['taxaPct'] as num?)?.toDouble() ?? 0,
        tipo: TipoLancamento.values.byName(j['tipo'] ?? 'lote'),
        pagamento: j['pagamento'] == null ? null : Pagamento.values.byName(j['pagamento']),
        cliente: j['cliente'],
        obs: j['obs'],
      );
}

class CustoFixo {
  String nome;
  int valorCentavos;

  CustoFixo({required this.nome, required this.valorCentavos});

  Map<String, dynamic> toJson() => {'nome': nome, 'valorCentavos': valorCentavos};

  factory CustoFixo.fromJson(Map<String, dynamic> j) =>
      CustoFixo(nome: j['nome'], valorCentavos: j['valorCentavos']);
}

/// Custos do mês que não dependem de quanto ela produz.
/// Aparência do app: seguir o celular, sempre claro ou sempre escuro.
enum TemaApp { sistema, claro, escuro }

extension TemaAppLabel on TemaApp {
  String get label => switch (this) {
        TemaApp.sistema => 'Automático',
        TemaApp.claro => 'Claro',
        TemaApp.escuro => 'Escuro',
      };
}

class Ajustes {
  String nomeNegocio;
  int salarioCentavos;
  List<CustoFixo> fixos;
  Map<Pagamento, double> taxas; // 0.02 = 2%
  TemaApp tema;

  Ajustes(
      {this.nomeNegocio = 'Minha Confeitaria',
      this.salarioCentavos = 0,
      List<CustoFixo>? fixos,
      Map<Pagamento, double>? taxas,
      this.tema = TemaApp.sistema})
      : taxas = taxas ?? {for (final p in Pagamento.values) p: 0.0},
        fixos = fixos ??
            ['Gás', 'Energia', 'Água', 'Internet']
                .map((n) => CustoFixo(nome: n, valorCentavos: 0))
                .toList();

  double taxa(Pagamento p) => taxas[p] ?? 0;

  int get totalFixos => fixos.fold(0, (s, f) => s + f.valorCentavos);

  Map<String, dynamic> toJson() => {
        'nomeNegocio': nomeNegocio,
        'salarioCentavos': salarioCentavos,
        'fixos': fixos.map((f) => f.toJson()).toList(),
        'taxas': {for (final e in taxas.entries) e.key.name: e.value},
        'tema': tema.name,
      };

  factory Ajustes.fromJson(Map<String, dynamic> j) => Ajustes(
        nomeNegocio: j['nomeNegocio'] ?? 'Minha Confeitaria',
        salarioCentavos: j['salarioCentavos'] ?? 0,
        fixos: (j['fixos'] as List).map((e) => CustoFixo.fromJson(e)).toList(),
        taxas: {
          for (final p in Pagamento.values)
            p: ((j['taxas'] as Map?)?[p.name] as num?)?.toDouble() ?? 0,
        },
        tema: TemaApp.values.asNameMap()[j['tema']] ?? TemaApp.sistema,
      );
}

typedef PorProduto = ({int id, String nome, double faturamento, double lucro, int vendidos});

String? _limpo(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
