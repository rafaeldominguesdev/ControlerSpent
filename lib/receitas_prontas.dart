import 'models.dart';
import 'store.dart';

/// Receitas prontas: produto completo com ingredientes, embalagem e preço.
/// Os preços dos ingredientes são de referência (mercado, 2026); a pessoa ajusta
/// depois em Ingredientes com o que ela paga.

class ModeloInsumo {
  final String nome;
  final Unidade unidade;
  final double qtdEmbalagem;
  final int precoCentavos;
  final bool embalagem;
  const ModeloInsumo(this.nome, this.unidade, this.qtdEmbalagem, this.precoCentavos,
      {this.embalagem = false});
}

class ModeloReceita {
  final String nome;
  final String categoria;
  final String descricao;
  final int rendimento;
  final int precoVendaCentavos;
  final List<(ModeloInsumo, double)> itens;
  const ModeloReceita({
    required this.nome,
    required this.categoria,
    required this.descricao,
    required this.rendimento,
    required this.precoVendaCentavos,
    required this.itens,
  });
}

// Ingredientes e embalagens (pacote como vem no mercado).
const _leiteCondensado = ModeloInsumo('Leite condensado', Unidade.g, 395, 790);
const _cremeDeLeite = ModeloInsumo('Creme de leite', Unidade.g, 200, 450);
const _chocolatePo = ModeloInsumo('Chocolate em pó', Unidade.g, 200, 1290);
const _cacau = ModeloInsumo('Cacau em pó', Unidade.g, 100, 1500);
const _chocolateMeioAmargo = ModeloInsumo('Chocolate meio amargo', Unidade.g, 1000, 5500);
const _manteiga = ModeloInsumo('Manteiga', Unidade.g, 200, 1150);
const _granulado = ModeloInsumo('Granulado', Unidade.g, 500, 1800);
const _cocoRalado = ModeloInsumo('Coco ralado', Unidade.g, 100, 650);
const _farinha = ModeloInsumo('Farinha de trigo', Unidade.g, 1000, 550);
const _acucar = ModeloInsumo('Açúcar', Unidade.g, 1000, 480);
const _acucarMascavo = ModeloInsumo('Açúcar mascavo', Unidade.g, 1000, 1400);
const _mel = ModeloInsumo('Mel', Unidade.g, 500, 2500);
const _leite = ModeloInsumo('Leite integral', Unidade.ml, 1000, 550);
const _bicarbonato = ModeloInsumo('Bicarbonato', Unidade.g, 80, 400);
const _canela = ModeloInsumo('Canela em pó', Unidade.g, 30, 500);
const _doceDeLeite = ModeloInsumo('Doce de leite', Unidade.g, 400, 1200);
const _ovos = ModeloInsumo('Ovos', Unidade.un, 12, 1400);
const _cenoura = ModeloInsumo('Cenoura', Unidade.g, 1000, 600);
const _oleo = ModeloInsumo('Óleo', Unidade.ml, 900, 800);
const _fermento = ModeloInsumo('Fermento em pó', Unidade.g, 100, 500);
const _forminha = ModeloInsumo('Forminha nº4', Unidade.un, 100, 600, embalagem: true);
const _saquinho = ModeloInsumo('Saquinho celofane', Unidade.un, 100, 1000, embalagem: true);
const _pote = ModeloInsumo('Pote 250 ml com tampa', Unidade.un, 25, 2500, embalagem: true);
const _caixaBolo = ModeloInsumo('Caixa de bolo', Unidade.un, 10, 2500, embalagem: true);
const _embalagemBrownie =
    ModeloInsumo('Embalagem de brownie', Unidade.un, 50, 2000, embalagem: true);

const receitasProntas = <ModeloReceita>[
  ModeloReceita(
    nome: 'Pão de mel',
    categoria: 'Doces',
    descricao: 'Massa com mel e especiarias, recheio de doce de leite e cobertura de chocolate.',
    rendimento: 20,
    precoVendaCentavos: 600,
    itens: [
      (_leite, 240),
      (_mel, 170),
      (_acucarMascavo, 180),
      (_farinha, 350),
      (_chocolatePo, 50),
      (_bicarbonato, 10),
      (_canela, 3),
      (_doceDeLeite, 400),
      (_chocolateMeioAmargo, 500),
      (_saquinho, 20),
    ],
  ),
  ModeloReceita(
    nome: 'Brigadeiro gourmet',
    categoria: 'Docinhos',
    descricao: 'Brigadeiro de panela com creme de leite, enrolado no granulado.',
    rendimento: 25,
    precoVendaCentavos: 300,
    itens: [
      (_leiteCondensado, 395),
      (_cremeDeLeite, 100),
      (_chocolatePo, 40),
      (_manteiga, 20),
      (_granulado, 100),
      (_forminha, 25),
    ],
  ),
  ModeloReceita(
    nome: 'Beijinho',
    categoria: 'Docinhos',
    descricao: 'Docinho de coco enrolado no coco ralado.',
    rendimento: 25,
    precoVendaCentavos: 250,
    itens: [
      (_leiteCondensado, 395),
      (_cocoRalado, 150),
      (_manteiga, 20),
      (_forminha, 25),
    ],
  ),
  ModeloReceita(
    nome: 'Brownie',
    categoria: 'Doces',
    descricao: 'Brownie de chocolate meio amargo, em pedaços embalados.',
    rendimento: 12,
    precoVendaCentavos: 800,
    itens: [
      (_chocolateMeioAmargo, 200),
      (_manteiga, 150),
      (_acucar, 200),
      (_ovos, 3),
      (_farinha, 100),
      (_cacau, 30),
      (_embalagemBrownie, 12),
    ],
  ),
  ModeloReceita(
    nome: 'Bolo de pote de brigadeiro',
    categoria: 'Bolos',
    descricao: 'Massa de chocolate com camadas de brigadeiro, no pote de 250 ml.',
    rendimento: 8,
    precoVendaCentavos: 1200,
    itens: [
      (_farinha, 200),
      (_acucar, 200),
      (_ovos, 3),
      (_chocolatePo, 140),
      (_leite, 200),
      (_oleo, 100),
      (_fermento, 10),
      (_leiteCondensado, 790),
      (_cremeDeLeite, 200),
      (_manteiga, 30),
      (_pote, 8),
    ],
  ),
  ModeloReceita(
    nome: 'Trufa',
    categoria: 'Docinhos',
    descricao: 'Ganache de chocolate com casquinha de chocolate meio amargo.',
    rendimento: 30,
    precoVendaCentavos: 350,
    itens: [
      (_chocolateMeioAmargo, 800),
      (_cremeDeLeite, 200),
      (_manteiga, 20),
      (_forminha, 30),
    ],
  ),
  ModeloReceita(
    nome: 'Cookie',
    categoria: 'Biscoitos',
    descricao: 'Cookie com gotas de chocolate, embalado no saquinho.',
    rendimento: 12,
    precoVendaCentavos: 700,
    itens: [
      (_farinha, 300),
      (_manteiga, 150),
      (_acucarMascavo, 150),
      (_acucar, 50),
      (_ovos, 2),
      (_chocolateMeioAmargo, 150),
      (_fermento, 5),
      (_saquinho, 12),
    ],
  ),
  ModeloReceita(
    nome: 'Bolo de cenoura com chocolate',
    categoria: 'Bolos',
    descricao: 'Bolo de cenoura de 20 cm com cobertura de chocolate, na caixa.',
    rendimento: 1,
    precoVendaCentavos: 6000,
    itens: [
      (_cenoura, 300),
      (_ovos, 4),
      (_oleo, 240),
      (_acucar, 300),
      (_farinha, 300),
      (_fermento, 15),
      (_chocolateMeioAmargo, 200),
      (_cremeDeLeite, 200),
      (_caixaBolo, 1),
    ],
  ),
];

/// "Açúcar  Mascavo" e "acucar mascavo" são o mesmo ingrediente.
String normalizar(String s) {
  const acentos = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
    'é': 'e', 'ê': 'e', 'è': 'e', 'í': 'i', 'î': 'i',
    'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ú': 'u', 'ü': 'u', 'ç': 'c',
  };
  final minusculo = s.trim().toLowerCase();
  final semAcento = minusculo.split('').map((ch) => acentos[ch] ?? ch).join();
  return semAcento.replaceAll(RegExp(r'\s+'), ' ');
}

bool jaAdicionada(Store store, ModeloReceita m) =>
    store.produtos.any((p) => normalizar(p.nome) == normalizar(m.nome));

/// Usa o ingrediente que a pessoa já tem (mesmo nome e unidade) ou o da receita.
Insumo? _existente(Store store, ModeloInsumo mi) => store.insumos
    .where((i) => normalizar(i.nome) == normalizar(mi.nome) && i.unidade == mi.unidade)
    .firstOrNull;

/// Custo por unidade da receita com os preços que valeriam ao adicionar.
double custoEstimado(Store store, ModeloReceita m) {
  var total = 0.0;
  for (final (mi, qtd) in m.itens) {
    final ins = _existente(store, mi);
    final porUnidade = ins?.custoPorUnidade ?? mi.precoCentavos / mi.qtdEmbalagem;
    total += porUnidade * qtd;
  }
  return total / m.rendimento;
}

/// Cria o produto (e os ingredientes que faltam). Devolve o produto criado.
Future<Produto> adicionarReceitaPronta(Store store, ModeloReceita m) async {
  final itens = <ItemReceita>[];
  for (final (mi, qtd) in m.itens) {
    var ins = _existente(store, mi);
    if (ins == null) {
      ins = Insumo(
        nome: mi.nome,
        unidade: mi.unidade,
        qtdEmbalagem: mi.qtdEmbalagem,
        precoCentavos: mi.precoCentavos,
        ehEmbalagem: mi.embalagem,
      );
      await store.salvarInsumo(ins);
    }
    itens.add(ItemReceita(insumoId: ins.id, qtd: qtd));
  }
  final p = Produto(
    nome: m.nome,
    categoria: m.categoria,
    rendimento: m.rendimento,
    margem: 0.5,
    precoVendaCentavos: m.precoVendaCentavos,
    itens: itens,
  );
  await store.salvarProduto(p);
  return p;
}
