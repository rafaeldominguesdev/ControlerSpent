import 'dart:math';

import 'models.dart';
import 'store.dart';

/// Preenche o app com uma confeitaria de exemplo, para ver como fica.
Future<void> carregarExemplo(Store store) async {
  Insumo i(String n, Unidade u, double q, int p, {bool emb = false}) =>
      Insumo(nome: n, unidade: u, qtdEmbalagem: q, precoCentavos: p, ehEmbalagem: emb);

  final leite = i('Leite condensado', Unidade.g, 395, 790);
  final cacau = i('Chocolate em pó', Unidade.g, 200, 1290);
  final mant = i('Manteiga', Unidade.g, 200, 1150);
  final gran = i('Granulado', Unidade.g, 500, 1800);
  final farinha = i('Farinha de trigo', Unidade.g, 1000, 550);
  final ovos = i('Ovos', Unidade.un, 12, 1400);
  final acucar = i('Açúcar', Unidade.g, 1000, 480);
  final cream = i('Cream cheese', Unidade.g, 300, 1590);
  final forminha = i('Forminha nº4', Unidade.un, 100, 600, emb: true);
  final caixa = i('Caixa de bolo', Unidade.un, 10, 2500, emb: true);
  for (final x in [leite, cacau, mant, gran, farinha, ovos, acucar, cream, forminha, caixa]) {
    await store.salvarInsumo(x);
  }

  ItemReceita r(Insumo x, double q) => ItemReceita(insumoId: x.id, qtd: q);
  final produtos = [
    Produto(
        nome: 'Brigadeiro gourmet',
        categoria: 'Docinhos',
        rendimento: 25,
        margem: .5,
        precoVendaCentavos: 300,
        itens: [r(leite, 395), r(cacau, 40), r(mant, 20), r(gran, 100), r(forminha, 25)]),
    Produto(
        nome: 'Bolo de chocolate',
        categoria: 'Bolos',
        rendimento: 1,
        margem: .5,
        precoVendaCentavos: 8500,
        itens: [
          r(farinha, 400),
          r(ovos, 4),
          r(cacau, 150),
          r(acucar, 300),
          r(mant, 100),
          r(caixa, 1)
        ]),
    Produto(
        nome: 'Cheesecake no pote',
        categoria: 'Doces',
        rendimento: 8,
        margem: .45,
        precoVendaCentavos: 1200,
        itens: [r(cream, 300), r(leite, 200), r(acucar, 50)]),
    Produto(
        nome: 'Cookie recheado',
        categoria: 'Biscoitos',
        rendimento: 12,
        margem: .5,
        precoVendaCentavos: 700,
        itens: [r(farinha, 300), r(mant, 150), r(acucar, 150), r(ovos, 2), r(cacau, 50)]),
  ];
  for (final p in produtos) {
    await store.salvarProduto(p);
  }

  final rnd = Random(3);
  final hoje = DateTime.now();
  final pagamentos = [
    Pagamento.pix,
    Pagamento.pix,
    Pagamento.dinheiro,
    Pagamento.credito,
    Pagamento.debito
  ];
  final taxas = {
    Pagamento.dinheiro: 0.0,
    Pagamento.pix: 0.0,
    Pagamento.debito: .0199,
    Pagamento.credito: .0399
  };
  const clientes = ['Ana', 'Carla', 'Dona Rosa', 'Marcos', 'Juliana', null, null, null];
  const observacoes = ['Entregar sábado', 'Sem granulado', 'Para aniversário', null, null, null];
  for (var d = 0; d < 160; d += 2) {
    final p = produtos[rnd.nextInt(produtos.length)];
    final pg = pagamentos[rnd.nextInt(pagamentos.length)];
    final q = p.rendimento == 1 ? 1 + rnd.nextInt(3) : 5 + rnd.nextInt(25);
    final l = Lancamento.venda(p, store.calcular(p).custoUnitario,
        qtd: q,
        preco: p.precoVendaCentavos!,
        pagamento: pg,
        taxa: taxas[pg]!,
        cliente: clientes[rnd.nextInt(clientes.length)],
        obs: observacoes[rnd.nextInt(observacoes.length)])
      ..data = hoje.subtract(Duration(days: d, hours: rnd.nextInt(6)));
    store.lancamentos.add(l);
  }
  // Produção (de manhã cedo, antes das vendas do dia) e o que saiu dela.
  DateTime cedo(int diasAtras) {
    final d = hoje.subtract(Duration(days: diasAtras));
    return DateTime(d.year, d.month, d.day, 6);
  }

  double custo(Produto p) => store.calcular(p).custoUnitario;
  store.lancamentos.addAll([
    Lancamento.producao(produtos[0], custo(produtos[0]), 50)..data = cedo(1),
    Lancamento.perda(produtos[0], custo(produtos[0]), 6)
      ..data = cedo(1).add(const Duration(hours: 14)),
    Lancamento.producao(produtos[3], custo(produtos[3]), 24)..data = cedo(1),
    Lancamento.producao(produtos[0], custo(produtos[0]), 40)..data = cedo(0),
  ]);
  store.lancamentos.add(Lancamento.perda(produtos[2], store.calcular(produtos[2]).custoUnitario, 2)
    ..data = hoje.subtract(const Duration(days: 3)));

  await store.salvarAjustes(Ajustes(
    nomeNegocio: 'Doces da Lu',
    salarioCentavos: 150000,
    fixos: [
      CustoFixo(nome: 'Gás', valorCentavos: 12000),
      CustoFixo(nome: 'Energia', valorCentavos: 18000),
      CustoFixo(nome: 'Internet', valorCentavos: 9900),
    ],
    taxas: taxas,
  ));
  store.lancamentos.sort((a, b) => b.data.compareTo(a.data));
  await store.salvarAjustes(store.ajustes);
}
