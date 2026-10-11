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
